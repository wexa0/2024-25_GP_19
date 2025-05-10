import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_application/Classes/Category';
import 'package:flutter_application/Classes/SubTask';
import 'package:flutter_application/Classes/Task';
import 'package:flutter_application/models/DailyMessageManager';
import 'package:flutter_application/models/GuestBottomNavigationBar.dart';
import 'package:flutter_application/pages/editTask.dart';
import 'package:flutter_application/models/BottomNavigationBar.dart';
import 'package:flutter_application/pages/timer_selector.dart';
import 'package:flutter_application/services/notification_handler.dart';
import 'package:flutter_application/welcome_page.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lottie/lottie.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_application/pages/addTaskForm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application/pages/task_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  String selectedSort = 'timeline';
  List<String> selectedCategories = ['All'];
  CalendarFormat _calendarFormat = CalendarFormat.month;
  int selectedIndex = 1;
  var isCalendarView = true;
  DateTime? startOfDay;
  DateTime? endOfDay;
  String? selectedCompletionMessage;
  String? selectedEmptyMessage;
  late double _xPosition = 0;
  late double _yPosition = 0;
  List<String> availableCategories = []; // store categories from Firestore.
  Map<DateTime, String> dailyMessagesCache = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  List<Map<String, dynamic>> tasks = [];
  bool isLoading = true;
  String? userID;
  Map<DateTime, List<Map<String, dynamic>>> _taskIndicators = {};
  Map<String, String> dailyMessages = {};

  @override
  void initState() {
    super.initState();
    _fetchUserID();
    fetchUserData();
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userID = user.uid;
      fetchTasksFromFirestore().then((_) {
        generateTaskIndicators();
      });
    } else {
      setState(() {
        userID = null;
        isLoading = false;
      });
    }
    // Initialize the button position using MediaQuery in a post-frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenSize = MediaQuery.of(context).size;
      setState(() {
        _xPosition =
            screenSize.width - 80.1; // Default to the right of the screen
        _yPosition = screenSize.height - 74; // Default to the bottom
      });
    });
  }

  Future<void> _fetchUserID() async {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      userID = user?.uid;
    });
  }

  /// Fetches tasks, categories, and subtasks from Firestore and filters them by the selected day.
  Future<void> fetchTasksFromFirestore() async {
    setState(() {
      isLoading = true;
      selectedEmptyMessage = null;
    });

    // Fetch tasks and categories
    List<Task> fetchedTasks =
        await Task.fetchTasksForUser(userID!); // Fetch tasks for the user.
    Map<String, dynamic> categoryData =
        await Category.fetchCategoriesForUser(userID!);
    Map<String, List<String>> categoryTaskMap =
        categoryData['taskCategoryMap'] as Map<String, List<String>>;
    availableCategories = categoryData['categories'] as List<String>;

    // Define the start and end of the selected day.
    DateTime startOfDay =
        DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    DateTime endOfDay = startOfDay
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));

    // Clear and populate the tasks list with the filtered tasks and their subtasks.
    tasks.clear();
    for (Task task in fetchedTasks) {
      DateTime taskTime = task.scheduledDate;

      // Filter tasks based on the selected day
      if (taskTime.isAfter(startOfDay) && taskTime.isBefore(endOfDay)) {
        List<SubTask> subtasks =
            await SubTask.fetchSubtasksForTask(task.taskID);
        tasks.add({
          'id': task.taskID,
          'title': task.title,
          'time': taskTime,
          'priority': task.priority,
          'completed': task.completionStatus == 2,
          'expanded': false,
          'subtasks': subtasks
              .map((sub) => {
                    'id': sub.subTaskID,
                    'title': sub.title,
                    'completed': sub.completionStatus == 1,
                  })
              .toList(),
          'categories': categoryTaskMap[task.taskID] ?? ['Uncategorized'],
        });
      }
    }
    generateTaskIndicators();
    setState(() {
      isLoading = false;
    });
  }

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    fetchTasksFromFirestore();
  }

  Future<List<Map<String, dynamic>>> fetchAllTasks() async {
    // Fetch all tasks for the user from Firestore
    List<Task> fetchedTasks = await Task.fetchTasksForUser(userID!);
    List<Map<String, dynamic>> allTasks = [];

    for (Task task in fetchedTasks) {
      allTasks.add({
        'id': task.taskID,
        'title': task.title,
        'time': task.scheduledDate,
        'priority': task.priority,
        'completed': task.completionStatus == 2,
        'categories': [],
      });
    }
    return allTasks;
  }

  /// Function to group tasks by date and update task indicators.
  Future<void> generateTaskIndicators() async {
    // بناء البيانات الجديدة في متغير مؤقت
    Map<DateTime, List<Map<String, dynamic>>> tempTaskIndicators = {};

    // جلب جميع المهام
    List<Map<String, dynamic>> allTasks = await fetchAllTasks();

    // تنظيم المهام حسب اليوم
    for (var task in allTasks) {
      DateTime taskDate = DateTime(
        task['time'].year,
        task['time'].month,
        task['time'].day,
      );

      if (!tempTaskIndicators.containsKey(taskDate)) {
        tempTaskIndicators[taskDate] = [];
      }
      tempTaskIndicators[taskDate]!.add(task);
    }

    // تحديث البيانات دفعة واحدة في setState
    if (mounted) {
      setState(() {
        _taskIndicators =
            tempTaskIndicators; // استبدل البيانات القديمة بالجديدة
      });
    }
  }

  void addNewTask(Map<String, dynamic> newTask) {
    tasks.add(newTask);
    generateTaskIndicators();
    setState(() {});
  }

  String getFormattedDate() {
    return DateFormat('EEE, d MMM yyyy').format(_focusedDay);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          closeAllSubtasks, // This closes the expanded subtasks when clicking outside
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text(
            'Calendar',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFFE2E7EA),
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            //menu options.
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'view') {
                  showViewDialog();
                } else if (value == 'sort') {
                  showSortDialog();
                } else if (value == 'categorize') {
                  showCategoryDialog();
                }
              },
              icon: const Icon(Icons.menu, color: Color(0xFF104A73)),
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: 'view',
                    child: Row(
                      children: const [
                        Icon(Icons.list, size: 24, color: Color(0xFF545454)),
                        SizedBox(width: 10),
                        Text('View',
                            style: TextStyle(
                                fontSize: 18, color: Color(0xFF545454))),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'sort',
                    child: Row(
                      children: const [
                        Icon(Icons.sort, size: 24, color: Color(0xFF545454)),
                        SizedBox(width: 10),
                        Text('Sort          ',
                            style: TextStyle(
                                fontSize: 18, color: Color(0xFF545454))),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'categorize',
                    child: Row(
                      children: const [
                        Icon(Icons.label, size: 24, color: Color(0xFF545454)),
                        SizedBox(width: 10),
                        Text('filter',
                            style: TextStyle(
                                fontSize: 18, color: Color(0xFF545454))),
                      ],
                    ),
                  ),
                ];
              },
              color: Color(0xFFF5F7F8),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TableCalendar(
                // for calender view.
                firstDay: DateTime.utc(2010, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: onDaySelected,
                calendarFormat: _calendarFormat,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month',
                  CalendarFormat.week: 'Week',
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },

                eventLoader: (day) {
                  DateTime adjustedDay = DateTime(day.year, day.month, day.day);

                  // التحقق من وجود المهام
                  if (_taskIndicators.containsKey(adjustedDay)) {
                    // المهام لليوم المحدد
                    List<Map<String, dynamic>> tasksForDay =
                        _taskIndicators[adjustedDay]!;

                    // التحقق من حالة المهام
                    bool allTasksComplete = tasksForDay.isNotEmpty &&
                        tasksForDay.every((task) => task['completed']);
                    bool hasPendingTasks =
                        tasksForDay.any((task) => !task['completed']);

                    // إرجاع الحالة بناءً على المهام
                    if (allTasksComplete) {
                      return ['green']; // جميع المهام مكتملة
                    } else if (hasPendingTasks) {
                      return ['orange']; // بعض المهام مكتملة
                    }
                  }

                  // إذا لم يكن هناك مهام لهذا اليوم
                  return ['grey'];
                },

                calendarStyle: CalendarStyle(
                  markersMaxCount: 1,
                  markerSizeScale: 0.2,
                  todayDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Color(0xFF3B7292),
                      width: 2.0,
                    ),
                    color: Colors.transparent,
                  ),
                  todayTextStyle: const TextStyle(
                    color: Color(0xFF3B7292),
                  ),
                  selectedDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF3B7292),
                  ),
                  selectedTextStyle: const TextStyle(
                    color: Colors.white,
                  ),
                  defaultTextStyle: const TextStyle(
                    color: Colors.black,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonTextStyle: const TextStyle(
                    color: Colors.white,
                  ),
                  formatButtonDecoration: BoxDecoration(
                    color: Color(0xFF3B7292),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  leftChevronIcon: const Icon(
                    Icons.chevron_left,
                    color: Color(0xFF3B7292),
                  ),
                  rightChevronIcon: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF3B7292),
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) {
                      return Positioned(
                        bottom: 1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.grey, // لون رمادي للتواريخ بدون مهام
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }

                    // تحديد اللون بناءً على الحدث
                    Color color;
                    if (events.contains('green')) {
                      color = Colors.green; // جميع المهام مكتملة
                    } else if (events.contains('orange')) {
                      color = Colors.orange; // بعض المهام مكتملة
                    } else {
                      color = Colors.grey; // لا توجد مهام
                    }

                    return Positioned(
                      bottom: 1, // وضع النقطة أسفل التاريخ
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (isLoading) ...[
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 140,
                        height: 140,
                      ),
                      Lottie.asset(
                        'assets/animations/loading.json',
                        width: 120,
                        height: 120,
                      ),
                      const SizedBox(height: 0),
                    ],
                  ),
                ),
              ] else ...[
                //If no tasks for today.
                if (tasks.isEmpty && selectedCategories.first == 'All')
                  Center(
                      child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      Image.asset(
                        'assets/images/empty_list.png',
                        width: 120,
                      ),
                      const SizedBox(height: 20),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            "Nothing to Do!",
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF3B7292),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: [
                          Text(
                            getDayMessage(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Color.fromARGB(255, 101, 156, 181),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ))
                else
                  Expanded(
                    child: (!tasks.any((task) =>
                            selectedCategories.contains('All') ||
                            (selectedCategories.contains('Uncategorized') &&
                                task['categories'].contains('Uncategorized')) ||
                            selectedCategories.any((category) =>
                                task['categories'].contains(category))))
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 18),
                              if (selectedCategories.first != 'All')
                                Wrap(
                                  alignment: WrapAlignment.start,
                                  spacing: 8.0,
                                  children: selectedCategories.map((category) {
                                    bool allTasksComplete = tasks.isNotEmpty &&
                                        tasks
                                            .where((task) =>
                                                task['categories'] != null &&
                                                task['categories']
                                                    .contains(category))
                                            .every((task) =>
                                                task['completed'] == true);
                                    bool hasPendingTasks = tasks
                                        .where((task) =>
                                            task['categories'] != null &&
                                            task['categories']
                                                .contains(category))
                                        .any((task) =>
                                            task['completed'] == false);
                                    bool hasNoTasks = tasks.every((task) =>
                                        task['categories'] == null ||
                                        !task['categories'].contains(category));

                                    Color chipColor;
                                    if (hasNoTasks) {
                                      chipColor = Colors.grey;
                                    } else if (allTasksComplete) {
                                      chipColor = const Color(0xFF24AB79);
                                    } else if (hasPendingTasks) {
                                      chipColor = const Color(0xFFF9A15A);
                                    } else {
                                      chipColor = Colors.grey;
                                    }
                                    return ActionChip(
                                      label: Text(category),
                                      onPressed: () {
                                        setState(() {
                                          selectedCategories.remove(category);
                                          if (selectedCategories.isEmpty) {
                                            selectedCategories = ['All'];
                                          }
                                        });
                                      },
                                      avatar: const Icon(Icons.close,
                                          size: 18, color: Colors.white),
                                      backgroundColor: chipColor,
                                      labelStyle:
                                          const TextStyle(color: Colors.white),
                                    );
                                  }).toList(),
                                ),
                              const SizedBox(height: 30),
                              Center(
                                child: Image.asset(
                                  'assets/images/empty_list.png',
                                  width: 100,
                                  height: 110,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Center(
                                child: Text(
                                  ' No tasks are available in the selected category(ies).',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3B7292),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          )
                        : ListView(
                            children: [
                              SizedBox(height: 18),
                              if (selectedCategories.first != 'All')
                                Wrap(
                                  alignment: WrapAlignment.start,
                                  spacing: 8.0,
                                  children: selectedCategories.map((category) {
                                    bool allTasksComplete = tasks.isNotEmpty &&
                                        tasks
                                            .where((task) =>
                                                task['categories'] != null &&
                                                task['categories']
                                                    .contains(category))
                                            .every((task) =>
                                                task['completed'] == true);
                                    bool hasPendingTasks = tasks
                                        .where((task) =>
                                            task['categories'] != null &&
                                            task['categories']
                                                .contains(category))
                                        .any((task) =>
                                            task['completed'] == false);
                                    bool hasNoTasks = tasks.every((task) =>
                                        task['categories'] == null ||
                                        !task['categories'].contains(category));
                                    Color chipColor;
                                    if (hasNoTasks) {
                                      chipColor = Colors.grey;
                                    } else if (allTasksComplete) {
                                      chipColor = const Color(0xFF24AB79);
                                    } else if (hasPendingTasks) {
                                      chipColor = const Color(0xFFF9A15A);
                                    } else {
                                      chipColor = Colors.grey;
                                    }
                                    print(
                                        'Category: $category, AllComplete: $allTasksComplete, Pending: $hasPendingTasks, NoTasks: $hasNoTasks');

                                    return ActionChip(
                                      label: Text(category),
                                      onPressed: () {
                                        setState(() {
                                          selectedCategories.remove(category);
                                          if (selectedCategories.isEmpty) {
                                            selectedCategories = ['All'];
                                          }
                                        });
                                      },
                                      avatar: const Icon(Icons.close,
                                          size: 18, color: Colors.white),
                                      backgroundColor: chipColor,
                                      labelStyle:
                                          const TextStyle(color: Colors.white),
                                    );
                                  }).toList(),
                                ),
                              const SizedBox(height: 1),
                              // Show Pending Tasks section if there are any uncompleted tasks.
                              if (tasks.any((task) =>
                                  !task['completed'] &&
                                  (selectedCategories.contains('All') ||
                                      (selectedCategories
                                              .contains('Uncategorized') &&
                                          (task['categories'] == null ||
                                              task['categories'].contains(
                                                  'Uncategorized'))) ||
                                      selectedCategories.any((category) =>
                                          task['categories']
                                              .contains(category)))))
                                Row(
                                  children: const [
                                    Expanded(child: Divider(thickness: 1)),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text(
                                        'Pending Tasks',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Divider(thickness: 1)),
                                  ],
                                ),
                              ...tasks.where((task) {
                                if (selectedCategories.contains('All')) {
                                  // If the "All" category is selected, return tasks that are not completed.
                                  return !task['completed'];
                                } else {
                                  // If "All" is not selected, filter tasks based on more specific conditions:
                                  return !task['completed'] &&
                                      (selectedCategories
                                                  .contains('Uncategorized') &&
                                              (task['categories'] == null ||
                                                  task['categories'].contains(
                                                      'Uncategorized')) ||
                                          selectedCategories.any((category) =>
                                              task['categories']
                                                  .contains(category)));
                                }
                              }).map(
                                (task) => TaskCard(
                                  task: task,
                                  onTaskToggle: () =>
                                      toggleTaskCompletion(task),
                                  onExpandToggle: () {
                                    setState(() {
                                      task['expanded'] = !task['expanded'];
                                    });
                                  },
                                  onSubtaskToggle: (subtask) =>
                                      toggleSubtaskCompletion(task, subtask),
                                  onSubtaskDeleted: (subtask) async {
                                    // Create an instance of SubTask from the subtask data.
                                    SubTask subtaskInstance = SubTask(
                                      subTaskID: subtask['id'],
                                      taskID: task['id'],
                                      title: subtask['title'],
                                      completionStatus:
                                          subtask['completed'] ? 1 : 0,
                                    );
                                    await subtaskInstance.deleteSubTask();
                                    setState(() {
                                      task['subtasks'].remove(subtask);
                                    });
                                    _showTopNotification(
                                        "Subtask deleted successfully.");
                                  },
                                  getPriorityColor: getPriorityColor,
                                  onDeleteTask: () =>
                                      showDeleteConfirmationDialog(task),
                                  onEditTask: () => editTask(task),
                                  onRefresh: fetchTasksFromFirestore,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // if all tasks are completed.
                              if (areAllTasksCompleted() &&
                                  selectedCategories.contains('All'))
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/done.png',
                                        width: 140,
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        "Congratulations!",
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 23,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF24AB79),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 10),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20.0),
                                        child: Text(
                                          getDayMessage(),
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF546E7A),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(height: 30),
                                    ],
                                  ),
                                ),

                              // Show Completed Tasks section if all tasks completed.
                              if (tasks.any((task) =>
                                  task['completed'] &&
                                  (selectedCategories.contains('All') ||
                                      (selectedCategories
                                              .contains('Uncategorized') &&
                                          (task['categories'] == null ||
                                              task['categories'].contains(
                                                  'Uncategorized'))) ||
                                      selectedCategories.any((category) =>
                                          task['categories']
                                              .contains(category)))))
                                Row(
                                  children: const [
                                    Expanded(child: Divider(thickness: 1)),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text(
                                        'Completed Tasks',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Divider(thickness: 1)),
                                  ],
                                ),

                              ...tasks.where((task) {
                                if (selectedCategories.contains('All')) {
                                  return task['completed'];
                                } else {
                                  return task['completed'] &&
                                      (selectedCategories
                                                  .contains('Uncategorized') &&
                                              (task['categories'] == null ||
                                                  task['categories'].contains(
                                                      'Uncategorized')) ||
                                          selectedCategories.any((category) =>
                                              task['categories']
                                                  .contains(category)));
                                }
                              }).map(
                                (task) => TaskCard(
                                  task: task,
                                  onTaskToggle: () =>
                                      toggleTaskCompletion(task),
                                  onExpandToggle: () {
                                    setState(() {
                                      task['expanded'] = !task['expanded'];
                                    });
                                  },
                                  onSubtaskToggle: (subtask) =>
                                      toggleSubtaskCompletion(task, subtask),
                                  onSubtaskDeleted: (subtask) async {
                                    await FirebaseFirestore.instance
                                        .collection('SubTask')
                                        .doc(subtask['id'])
                                        .delete();
                                    setState(() {
                                      task['subtasks'].remove(subtask);
                                    });
                                    setState(() {});
                                    _showTopNotification(
                                        "Subtask deleted successfully.");
                                  },
                                  getPriorityColor: getPriorityColor,
                                  onDeleteTask: () =>
                                      showDeleteConfirmationDialog(task),
                                  onEditTask: () => editTask(task),
                                  onRefresh: fetchTasksFromFirestore,
                                ),
                              ),
                            ],
                          ),
                  ),
              ]
            ],
          ),
        ),
        // Allows the floating action button to be dragged and repositioned within screen bounds.
        floatingActionButton: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) {
                return Positioned(
                  left: _xPosition,
                  top: _yPosition,
                  child: Draggable(
                    feedback: FloatingActionButton(
                      onPressed: null,
                      backgroundColor: const Color(0xFF3B7292),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                    childWhenDragging: Container(),
                    onDragEnd: (details) {
                      setState(() {
                        final screenSize = MediaQuery.of(context).size;
                        _xPosition = details.offset.dx.clamp(
                          0.0,
                          screenSize.width - 58.0,
                        );
                        _yPosition = details.offset.dy.clamp(
                          0.0,
                          screenSize.height - 112.0,
                        );
                      });
                    },
                    child: FloatingActionButton(
                      onPressed: () async {
                        if (userID != null) {
                          // Navigate to AddTaskPage if the user is logged in.
                          bool? result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddTaskPage(),
                            ),
                          );
                          // Check if a task was added and refresh tasks.
                          if (result == true) {
                            fetchTasksFromFirestore();
                          }
                        } else {
                          // Show a dialog prompting the user to sign in (for guest user).
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: const Color(0xFFF5F7F8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                title: const Text(
                                  'SignIn & Explor!',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                content: const Text(
                                  'Ready to add tasks? Sign in or create an account to access all features.',
                                ),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        side: const BorderSide(
                                            color: Color(0xFF79A3B7)),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                    ),
                                    child: const Text(
                                      'Cancel',
                                      style:
                                          TextStyle(color: Color(0xFF79A3B7)),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                WelcomePage()),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF79A3B7),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                    ),
                                    child: const Text(
                                      'Join Now',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      },
                      backgroundColor: const Color(0xFF3B7292),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: userID != null
            //showing nav bar for registered user.
            ? CustomNavigationBar(
                selectedIndex: selectedIndex,
                onTabChange: (index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
              )
            //showing nav bar for guest user.
            : GuestCustomNavigationBar(
                selectedIndex: selectedIndex,
                onTabChange: (index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
              ),
      ),
    );
  }

  String getDayMessage() {
    //for current day.
    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    if (isSameDay(_selectedDay!, DateTime.now())) {
      if (tasks.isEmpty) {
        return DailyMessageManager.getDayMessage(tasks);
      } else if (areAllTasksCompleted()) {
        return DailyMessageManager.getDayMessage(tasks);
      }
    }
    // for another days.
    if (tasks.isEmpty) {
      dailyMessages[formattedDate] = "No tasks for the selected date.";
      return "No tasks for the selected date.";
    } else if (areAllTasksCompleted()) {
      dailyMessages[formattedDate] =
          "All tasks for the selected date have been completed! ";
      return "All tasks for the selected date have been completed! ";
    }

    return "Keep pushing forward! You're doing great! 🚀";
  }

  bool areAllTasksCompleted() {
    if (tasks.isEmpty) {
      return false;
    }
    return tasks.every((task) => task['completed']);
  }

  void deleteTask(Map<String, dynamic> taskData) async {
    // Call the static deleteTask method on the Task class.
    await Task.deleteTask(taskData['id']);

    // Remove the task locally and update the UI.
    setState(() {
      tasks.removeWhere((t) => t['id'] == taskData['id']);
      getDayMessage();
    });
    generateTaskIndicators();
    setState(() {});
    // Show notification
    _showTopNotification("Task deleted successfully.");
  }

  void deleteSubTask(
      Map<String, dynamic> taskData, Map<String, dynamic> subtaskData) async {
    // Create an instance of SubTask using the provided data.
    SubTask subtask = SubTask(
      subTaskID: subtaskData['id'],
      taskID: taskData['id'],
      title: subtaskData['title'],
      completionStatus: subtaskData['completed'] ? 1 : 0,
    );

    // Call the instance method deleteSubTask.
    await subtask.deleteSubTask();

    // Remove the subtask locally and update the UI.
    setState(() {
      final taskIndex = tasks.indexWhere((t) => t['id'] == taskData['id']);
      if (taskIndex != -1) {
        tasks[taskIndex]['subtasks']
            .removeWhere((s) => s['id'] == subtask.subTaskID);
      }
    });

    // Show notification
    _showTopNotification("Subtask deleted successfully.");
  }

  Color getPriorityColor(int priority) {
    switch (priority) {
      case 4:
        return const Color(0xFFEFB1B1); // urgent
      case 3:
        return const Color(0xFFEBC591); // high
      case 2:
        return const Color(0xFF9ABEF1); // normal
      case 1:
        return const Color(0xFF969696); // low
      default:
        return const Color(0xFF9ABEF1); // default to normal
    }
  }

  void editTask(Map<String, dynamic> task) async {
    bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTaskPage(taskId: task['id']),
      ),
    );

    // If result is true, refresh the task list
    if (result == true) {
      fetchTasksFromFirestore();
      generateTaskIndicators();
    }
  }

  Widget _buildLegendCircle(Color color, String label) {
    return Row(
      children: [
        CircleAvatar(
          radius: 5,
          backgroundColor: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  //show view dialog function.
  void showViewDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedView = 'calendar';
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFF5F7F8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              title: const Text(
                'View Options',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    activeColor: const Color(0xFF79A3B7),
                    title: const Text(
                      'View as Calendar',
                      style: TextStyle(color: Color(0xFF545454)),
                    ),
                    value: 'calendar',
                    groupValue: selectedView,
                    onChanged: (value) {
                      setState(() {
                        selectedView = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    activeColor: const Color(0xFF79A3B7),
                    title: const Text(
                      'View as List',
                      style: TextStyle(color: Color(0xFF545454)),
                    ),
                    value: 'list',
                    groupValue: selectedView,
                    onChanged: (value) {
                      setState(() {
                        selectedView = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Color(0xFF79A3B7)),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(color: Color(0xFF79A3B7))),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (selectedView == 'list') {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => TaskPage()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF79A3B7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text('Apply',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  //show Category dialog function.
  void showCategoryDialog() {
    List<String> tempSelectedCategories = List.from(selectedCategories);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF5F7F8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const Text(
            'Category',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 6, 6, 6),
            ),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: availableCategories.map((category) {
                      bool isSelected =
                          tempSelectedCategories.contains(category);
                      bool isAllCategory = category == 'All';
                      Color chipColor;
                      bool allTasksComplete = tasks.isNotEmpty &&
                          tasks.every((task) => task['completed'] == true);
                      bool categoryComplete = tasks
                          .where((task) =>
                              task['categories'] != null &&
                              task['categories'].contains(category))
                          .every((task) => task['completed'] == true);
                      if (isAllCategory) {
                        chipColor = tasks.isEmpty
                            ? Colors.grey
                            : (allTasksComplete
                                ? Color(0xFF24AB79)
                                : const Color(0xFFF9A15A));
                      } else if (!tasks.any(
                          (task) => task['categories'].contains(category))) {
                        chipColor = Colors.grey;
                      } else {
                        chipColor = categoryComplete
                            ? Color(0xFF24AB79)
                            : const Color(0xFFF9A15A);
                      }
                      return Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFFAFBFF).withOpacity(1.0),
                              offset: Offset(-5, -5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: ChoiceChip(
                          label: Text(
                            category,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: chipColor,
                          backgroundColor: chipColor,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                if (category == 'All') {
                                  tempSelectedCategories.clear();
                                  tempSelectedCategories.add('All');
                                } else {
                                  tempSelectedCategories.remove('All');
                                  tempSelectedCategories.add(category);
                                }
                              } else {
                                tempSelectedCategories.remove(category);
                                if (tempSelectedCategories.isEmpty) {
                                  tempSelectedCategories.add('All');
                                }
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendCircle(Colors.grey, 'No Tasks'),
                        _buildLegendCircle(
                            const Color(0xFFF9A15A), 'Pending Tasks'),
                        _buildLegendCircle(
                            Color(0xFF24AB79), 'Completed Tasks '),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5F7F8),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Color(0xFF79A3B7)),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF79A3B7)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedCategories = tempSelectedCategories;
                });
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF79A3B7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Apply',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void closeAllSubtasks() {
    setState(() {
      for (var task in tasks) {
        task['expanded'] = false;
      }
    });
  }

  //show sort dialog function.
  void showSortDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFF5F7F8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              title: const Text(
                'Sort by',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 6, 6, 6),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    activeColor: const Color(0xFF79A3B7),
                    title: const Text(
                      'Time',
                      style: TextStyle(
                        color: Color(0xFF545454),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    value: 'timeline',
                    groupValue: selectedSort,
                    onChanged: (value) {
                      setState(() {
                        selectedSort = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    activeColor: const Color(0xFF79A3B7),
                    title: const Text(
                      'Priority',
                      style: TextStyle(
                        color: Color(0xFF545454),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    value: 'priority',
                    groupValue: selectedSort,
                    onChanged: (value) {
                      setState(() {
                        selectedSort = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Color(0xFF79A3B7)),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF79A3B7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      sortTasks();
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF79A3B7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void sortTasks() {
    //sort by priority
    if (selectedSort == 'priority') {
      tasks.sort((a, b) => b['priority'].compareTo(a['priority']));
      //sort by time
    } else if (selectedSort == 'timeline') {
      try {
        tasks.sort((a, b) {
          DateTime timeA = a['time'] is DateTime
              ? a['time']
              : DateTime.parse(a['time'].toString());
          DateTime timeB = b['time'] is DateTime
              ? b['time']
              : DateTime.parse(b['time'].toString());
          return timeA.compareTo(timeB);
        });
      } catch (e) {
        print('General error: $e');
      }
    }
    setState(() {});
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int userPoints = 0;
  int userLevel = 1;

  Future<void> fetchUserData() async {
    if (userID == null) return;

    try {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('User').doc(userID).get();

      if (userSnapshot.exists) {
        setState(() {
          userPoints = userSnapshot['point'] ?? 0;
          userLevel = userSnapshot['level'] ?? 1;
        });
      } else {
        await _firestore.collection('User').doc(userID).set({
          'point': 0,
          'level': 1,
        });
        print("User document created");
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> toggleTaskCompletion(Map<String, dynamic> taskData) async {
    if (userID == null) return;

    Task task = Task.fromMap(taskData);
    bool newTaskCompletionStatus = !taskData['completed'];

    setState(() {
      taskData['completed'] = newTaskCompletionStatus;
      selectedCompletionMessage = null;
    });

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DateTime? completionDate = newTaskCompletionStatus ? DateTime.now() : null;

    List<Future<void>> updates = [];

    try {
      if (newTaskCompletionStatus) {
        // ✅ Now update the parent task with completion date
        await firestore.collection('Task').doc(task.taskID).update({
          'completionStatus': 2,
          'completionDate': completionDate, // Store completion date
        });

        await assignTaskPoints(task);

        // ✅ Mark all subtasks as completed & store completion date
        for (var subtask in taskData['subtasks']) {
          setState(() {
            subtask['completed'] = true;
          });

          updates.add(
            firestore.collection('SubTask').doc(subtask['id']).update({
              'completionStatus': 1,
              'completionDate': completionDate, // Store completion date
            }),
          );
        }

        await Future.wait(updates); // ✅ Ensure all subtasks update first
      } else {
        // ✅ Mark all subtasks as uncompleted & remove completion date
        for (var subtask in taskData['subtasks']) {
          setState(() {
            subtask['completed'] = false;
          });

          updates.add(
            firestore.collection('SubTask').doc(subtask['id']).update({
              'completionStatus': 0,
              'completionDate': FieldValue.delete(), // Remove completion date
            }),
          );
        }

        await Future.wait(updates); // ✅ Ensure all subtasks update first

        // ✅ Now update the parent task & remove completion date
        await firestore.collection('Task').doc(task.taskID).update({
          'completionStatus': 0,
          'completionDate': FieldValue.delete(), // Remove completion date
        });

        await subtractTaskPoints(task);
      }

      // ✅ Ensure notifications are canceled **after** Firestore updates
      try {
        for (var subtask in taskData['subtasks']) {
          await NotificationHandler.cancelNotification(subtask['id']);
        }
        await NotificationHandler.cancelNotification(task.taskID);
      } catch (e) {
        print("Error canceling notifications: $e");
      }
    } catch (e) {
      print("Error updating task completion: $e");
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> updateLevel() async {
    if (userID == null) return;

    try {
      int newLevel = 1;
      int pointsRequired = 100;
      int accumulatedPoints = 0;

      while (userPoints >= accumulatedPoints + pointsRequired) {
        accumulatedPoints += pointsRequired;
        pointsRequired += 50;
        newLevel++;
      }

      // ✅ Only update Firestore if the level has changed
      if (newLevel != userLevel) {
        await _firestore.runTransaction((transaction) async {
          DocumentReference userRef = _firestore.collection('User').doc(userID);
          transaction.update(userRef, {'level': newLevel});
        });

        setState(() {
          userLevel = newLevel;
        });

        print("🎉 Level Up! New Level: $newLevel");
      } else {
        print("ℹ️ Level remains the same: $newLevel");
      }
    } catch (e) {
      print("Error in updateLevel: $e");
    }
  }

  Future<void> toggleSubtaskCompletion(
      Map<String, dynamic> task, Map<String, dynamic> subtask) async {
    if (userID == null) return;

    bool newSubtaskCompletionStatus = !subtask['completed'];

    setState(() {
      subtask['completed'] = newSubtaskCompletionStatus;
    });

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DateTime? completionDate =
        newSubtaskCompletionStatus ? DateTime.now() : null;

    try {
      // ✅ Update subtask completion status **before** canceling notifications
      await firestore.collection('SubTask').doc(subtask['id']).update({
        'completionStatus': newSubtaskCompletionStatus ? 1 : 0,
        'completionDate':
            newSubtaskCompletionStatus ? completionDate : FieldValue.delete(),
      });

      // Convert task Map to Task object
      Task updatedTask = Task.fromMap(task);
      SubTask updatedSubtask = SubTask(
        subTaskID: subtask['id'],
        taskID: task['id'],
        title: subtask['title'],
        completionStatus: newSubtaskCompletionStatus ? 1 : 0,
      );

      // ✅ Process points before canceling notifications
      if (newSubtaskCompletionStatus) {
        await assignSubtaskPoints(updatedTask, updatedSubtask);
      } else {
        await subtractSubtaskPoints(updatedTask, updatedSubtask);
      }

      // ✅ Fetch all subtasks for this task
      QuerySnapshot subtasksSnapshot = await firestore
          .collection('SubTask')
          .where('taskID', isEqualTo: task['id'])
          .get();

      bool allSubtasksComplete = subtasksSnapshot.docs.every((doc) =>
          doc['completionStatus'] != null && doc['completionStatus'] == 1);
      bool anySubtaskIncomplete = subtasksSnapshot.docs.any((doc) =>
          doc['completionStatus'] != null && doc['completionStatus'] == 0);

      int newTaskStatus;
      if (allSubtasksComplete) {
        // ✅ If all subtasks are complete, mark the parent task as complete
        newTaskStatus = 2;
        task['completed'] = true;
        await firestore.collection('Task').doc(task['id']).update({
          'completionStatus': 2,
          'completionDate': completionDate, // Store completion date
        });

        await assignTaskPoints(updatedTask);
      } else if (anySubtaskIncomplete) {
        // ✅ If any subtask is incomplete, mark the task as in-progress
        newTaskStatus = 1;
        task['completed'] = false;
        await firestore.collection('Task').doc(task['id']).update({
          'completionStatus': 1,
          'completionDate': FieldValue.delete(), // Remove completion date
        });
      } else {
        // ✅ If no subtasks are completed, mark the task as not completed
        newTaskStatus = 0;
        task['completed'] = false;
        await firestore.collection('Task').doc(task['id']).update({
          'completionStatus': 0,
          'completionDate': FieldValue.delete(), // Remove completion date
        });
      }

      if (mounted) {
        setState(() {});
      }

      // ✅ Cancel notifications **AFTER** Firestore updates
      try {
        if (newSubtaskCompletionStatus) {
          await NotificationHandler.cancelNotification(subtask['id']);
        }
        if (allSubtasksComplete) {
          await NotificationHandler.cancelNotification(task['id']);
        }
      } catch (e) {
        print("Error canceling notifications: $e");
      }
    } catch (e) {
      print("Error updating subtask completion: $e");
    }
  }

  Future<void> assignTaskPoints(Task task) async {
    if (userID == null) return;

    try {
      print("🔹 Starting assignTaskPoints for Task: ${task.taskID}");

      double taskPoints = 10.0;
      int priority = task.priority;
      int newPoints = userPoints;

      QuerySnapshot subtasksSnapshot = await _firestore
          .collection('SubTask')
          .where('taskID', isEqualTo: task.taskID)
          .get();

      int subtaskCount = subtasksSnapshot.docs.length;
      if (subtaskCount > 0) {
        // ✅ Count only **incomplete subtasks before completion**
        int incompleteSubtasks = subtasksSnapshot.docs
            .where((doc) =>
                doc['completionStatus'] == null || doc['completionStatus'] != 1)
            .length;

        if (incompleteSubtasks > 0) {
          double subtaskPoints = taskPoints / subtaskCount;
          int awardedSubtaskPoints =
              (subtaskPoints * incompleteSubtasks).round();
          newPoints += awardedSubtaskPoints;
          print(
              "✅ Added points for remaining incomplete subtasks: +$awardedSubtaskPoints");

          // ✅ Ensure no points are lost due to rounding
          int expectedTotal = (subtaskPoints * subtaskCount).round();
          int actualTotal = awardedSubtaskPoints +
              (subtaskCount - incompleteSubtasks) * subtaskPoints.round();

          if (actualTotal < expectedTotal) {
            int roundingFix = expectedTotal - actualTotal;
            newPoints += roundingFix;
            print(
                "🛠 Fix applied: Adjusted for rounding error by adding +$roundingFix");
          }
          newPoints += 2;
        }
      } else {
        // ✅ If no subtasks exist, award full task points
        newPoints += taskPoints.toInt();
        print(
            "✅ No subtasks found. Awarded full task points: +${taskPoints.toInt()}");
      }

      newPoints += (priority - 1); // Priority bonus

      // ✅ Fetch completion date & scheduled date
      DocumentSnapshot taskSnapshot =
          await _firestore.collection('Task').doc(task.taskID).get();

      if (taskSnapshot.exists && taskSnapshot['completionDate'] != null) {
        DateTime completionDate =
            (taskSnapshot['completionDate'] as Timestamp).toDate();
        DateTime scheduledDate = task.scheduledDate;

        // ✅ Only compare date (not time)
        DateTime normalizedScheduledDate = DateTime(
            scheduledDate.year, scheduledDate.month, scheduledDate.day);
        DateTime normalizedCompletionDate = DateTime(
            completionDate.year, completionDate.month, completionDate.day);

        int dayDifference =
            normalizedScheduledDate.difference(normalizedCompletionDate).inDays;

        print("📅 Scheduled Date: $normalizedScheduledDate");
        print("✅ Completion Date: $normalizedCompletionDate");
        print("📊 Day Difference: $dayDifference");

        if (dayDifference > 0) {
          newPoints += dayDifference; // Add 1 point per early day
          print("✅ Task completed EARLY! +$dayDifference points");
        } else if (dayDifference < 0) {
          int maxPenalty =
              newPoints > -dayDifference ? -dayDifference : newPoints;
          newPoints -= maxPenalty; // Subtract 1 point per late day
          print("⚠ Task completed LATE! -$maxPenalty points");
        }
      }

      // ✅ Ensure points never drop below 0
      if (newPoints < 0) newPoints = 0;

      await _firestore.runTransaction((transaction) async {
        DocumentReference userRef = _firestore.collection('User').doc(userID);
        transaction.update(userRef, {'point': newPoints});
      });

      setState(() {
        userPoints = newPoints;
      });

      await updateLevel();
    } catch (e) {
      print("Error in assignTaskPoints: $e");
    }
  }

  Future<void> subtractTaskPoints(Task task) async {
    if (userID == null) return;

    try {
      double taskPoints = 10.0;
      int priority = task.priority;
      int newPoints = userPoints;

      QuerySnapshot subtasksSnapshot = await _firestore
          .collection('SubTask')
          .where('taskID', isEqualTo: task.taskID)
          .get();

      int subtaskCount = subtasksSnapshot.docs.length;

      if (subtaskCount > 0) {
        double subtaskPoints = taskPoints / subtaskCount;
        newPoints -= (subtaskPoints * subtaskCount).toInt();
        newPoints -= 2;
      } else {
        newPoints -= taskPoints.toInt();
      }

      newPoints -= (priority - 1);
      if (newPoints < 0) newPoints = 0;

      await _firestore.runTransaction((transaction) async {
        DocumentReference userRef = _firestore.collection('User').doc(userID);
        transaction.update(userRef, {'point': newPoints});
      });

      setState(() {
        userPoints = newPoints;
      });

      await updateLevel();
    } catch (e) {
      print("Error in subtractTaskPoints: $e");
    }
  }

  Future<void> assignSubtaskPoints(Task task, SubTask subtask) async {
    if (userID == null) return;

    try {
      double taskPoints = 10.0;
      int newPoints = userPoints;

      QuerySnapshot subtasksSnapshot = await _firestore
          .collection('SubTask')
          .where('taskID', isEqualTo: task.taskID)
          .get();

      int totalSubtasks = subtasksSnapshot.docs.length;

      if (totalSubtasks > 0) {
        double subtaskPoints = taskPoints / totalSubtasks;
        newPoints += subtaskPoints.toInt();

        bool allSubtasksCompleted = subtasksSnapshot.docs.every((doc) =>
            doc['completionStatus'] != null && doc['completionStatus'] == 1);

        // Fetch the parent task
        DocumentSnapshot taskSnapshot =
            await _firestore.collection('Task').doc(task.taskID).get();

        int taskCompletionStatus = taskSnapshot['completionStatus'];
//if (allSubtasksCompleted && taskCompletionStatus != 2)
        // Apply condition
        if (allSubtasksCompleted) {
          if (totalSubtasks % 2 == 0)
            newPoints += 2;
          else
            newPoints += 3;
          //newPoints += 2;
        }
      } else {
        newPoints += taskPoints.toInt();
      }

      // Check completion date against scheduled date
      DocumentSnapshot subtaskSnapshot =
          await _firestore.collection('SubTask').doc(subtask.subTaskID).get();
      if (subtaskSnapshot.exists && subtaskSnapshot['completionDate'] != null) {
        DateTime completionDate =
            (subtaskSnapshot['completionDate'] as Timestamp).toDate();
        DateTime scheduledDate = task.scheduledDate;

        int dayDifference = scheduledDate.difference(completionDate).inDays;
        if (dayDifference > 0) {
          newPoints += dayDifference; // Add 1 point per early day
        } else if (dayDifference < 0) {
          newPoints -= dayDifference.abs(); // Subtract 1 point per late day
          if (newPoints < 0) newPoints = 0; // Ensure lowest score remains 0
        }
      }

      await _firestore
          .collection('User')
          .doc(userID)
          .update({'point': newPoints});

      setState(() {
        userPoints = newPoints;
      });

      await updateLevel();
    } catch (e) {
      print("Error in assignSubtaskPoints: $e");
    }
  }

  Future<void> subtractSubtaskPoints(Task task, SubTask subtask) async {
    if (userID == null) return;

    try {
      print(
          "🔹 Starting subtractSubtaskPoints for SubTask: ${subtask.subTaskID}");

      double taskPoints = 10.0;
      int newPoints = userPoints;

      QuerySnapshot subtasksSnapshot = await _firestore
          .collection('SubTask')
          .where('taskID', isEqualTo: task.taskID)
          .get();

      int totalSubtasks = subtasksSnapshot.docs.length;

      if (totalSubtasks > 0) {
        double subtaskPoints = taskPoints / totalSubtasks;
        newPoints -= subtaskPoints.toInt();
        print("✅ Removed subtask points. New points: $newPoints");
      } else {
        newPoints -= taskPoints.toInt();
        print("✅ Removed full task points. New points: $newPoints");
      }

      // ✅ Check if the full task was completed, then remove extra 2 points
      DocumentSnapshot taskSnapshot =
          await _firestore.collection('Task').doc(task.taskID).get();

      if (taskSnapshot.exists &&
          taskSnapshot.data().toString().contains('completionStatus')) {
        int? taskCompletionStatus = taskSnapshot['completionStatus'];
        if (taskCompletionStatus == 2) {
          if (totalSubtasks % 2 == 0)
            newPoints -= 2;
          else
            newPoints -= 3;
          newPoints -= (task.priority - 1);
          print("🎯 Task was fully completed. Removed extra 2 points.");
        }
      }

      // ✅ Fetch completion date & scheduled date
      DocumentSnapshot subtaskSnapshot =
          await _firestore.collection('SubTask').doc(subtask.subTaskID).get();

      if (subtaskSnapshot.exists &&
          subtaskSnapshot.data().toString().contains('completionDate')) {
        Timestamp? completionTimestamp = subtaskSnapshot['completionDate'];
        Timestamp? scheduledTimestamp = subtaskSnapshot['scheduledDate'];

        if (completionTimestamp != null && scheduledTimestamp != null) {
          DateTime scheduledDate = scheduledTimestamp.toDate();
          DateTime completionDate = completionTimestamp.toDate();

          // ✅ Normalize both dates to midnight (00:00:00) for accurate date comparison
          DateTime normalizedScheduledDate = DateTime(
              scheduledDate.year, scheduledDate.month, scheduledDate.day);
          DateTime normalizedCompletionDate = DateTime(
              completionDate.year, completionDate.month, completionDate.day);

          // ✅ Calculate only **full days difference**, ignoring hours/minutes
          int dayDifference = normalizedScheduledDate
              .difference(normalizedCompletionDate)
              .inDays;

          print("📊 Days Difference (Ignoring Time): $dayDifference");

          if (dayDifference > 0) {
            newPoints -=
                dayDifference; // Remove previously added early completion bonus
            print("❌ Removed early completion bonus. New points: $newPoints");
          } else if (dayDifference < 0) {
            newPoints += dayDifference
                .abs(); // Restore previously subtracted late penalty
            print("✅ Restored late penalty points. New points: $newPoints");
          }
        }
      }

      // ✅ Ensure points never drop below 0
      if (newPoints < 0) {
        newPoints = 0;
        print("⚠️ Points cannot go below zero. Reset to 0.");
      }

      // ✅ Update user points in Firestore
      await _firestore
          .collection('User')
          .doc(userID)
          .update({'point': newPoints});
      setState(() {
        userPoints = newPoints;
      });

      await updateLevel();
    } catch (e) {
      print("Error in subtractSubtaskPoints: $e");
    }
  }

  void showDeleteConfirmationDialog(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFF5F7F8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const Text(
            'Are you sure you want to delete this task?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Color(0xFF79A3B7)),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF79A3B7)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                deleteTask(task);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showTopNotification(String message) {
    OverlayState? overlayState = Overlay.of(context);
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 112, 112, 112),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);
    Future.delayed(Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }
}

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback onTaskToggle;
  final VoidCallback onExpandToggle;
  final Function(Map<String, dynamic>) onSubtaskToggle;
  final Function(Map<String, dynamic>) onSubtaskDeleted;
  final Color Function(int) getPriorityColor;
  final VoidCallback onDeleteTask;
  final VoidCallback onEditTask;
  final VoidCallback onRefresh;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onTaskToggle,
    required this.onExpandToggle,
    required this.onSubtaskToggle,
    required this.onSubtaskDeleted,
    required this.getPriorityColor,
    required this.onDeleteTask,
    required this.onEditTask,
    required this.onRefresh,
  }) : super(key: key);

  void showDeleteConfirmationDialog(
      BuildContext context, Map<String, dynamic> subtask) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF5F7F8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const Text(
            'Are you sure you want to delete this subtask?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Color(0xFF79A3B7)),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF79A3B7)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                onSubtaskDeleted(subtask);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.red),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalSubtasks = task['subtasks']?.length ?? 0;
    int completedSubtasks = task['subtasks']
            ?.where((subtask) => subtask['completed'] == true)
            .length ??
        0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Slidable(
          //Slidable(swap) to show edit and delete each task .
          key: ValueKey(task['title']),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              CustomSlidableAction(
                onPressed: (_) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditTaskPage(taskId: task['id']),
                    ),
                  );
                },
                backgroundColor: const Color(0xFFC2C2C2),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                ),
              ),
              SizedBox(
                width: 1,
                child: Container(
                  color: Colors.grey,
                ),
              ),
              CustomSlidableAction(
                onPressed: (_) => onDeleteTask(),
                backgroundColor: const Color(0xFFC2C2C2),
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          child: Column(
            children: [
              ListTile(
                onTap: onEditTask,
                leading: Tooltip(
                  message: "Mark Task as complete!", //hint
                  showDuration: Duration(milliseconds: 500),
                  child: InkWell(
                    onTap: onTaskToggle,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: task['completed']
                              ? Colors.grey
                              : getPriorityColor(task['priority']),
                          width: 4.0,
                        ),
                        color: task['completed'] ? Colors.grey : Colors.white,
                      ),
                      child: task['completed']
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
                title: Text(
                  task['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: task['completed']
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('h:mm a').format(task['time']),
                    ),
                    if (totalSubtasks > 0)
                      Row(
                        children: List.generate(totalSubtasks, (index) {
                          bool isCompleted = index < completedSubtasks;

                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 2.0),
                            child: Tooltip(
                              message:
                                  '${completedSubtasks}/${totalSubtasks} subtasks completed',
                              child: Icon(
                                Icons.circle,
                                size: 15,
                                color: isCompleted
                                    ? const Color(0xFF24AB79)
                                    : Colors.grey,
                              ),
                            ),
                          );
                        }),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: task['completed']
                          ? "This task is already complete!" // Hint for completed task
                          : "Start task timer", // Hint for incomplete task
                      showDuration:
                          Duration(milliseconds: 500), // Hint display duration
                      child: InkWell(
                        onTap: () {
                          if (task['completed']) {
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TimerSelectionPage(
                                    taskId: task['id'],
                                    subTaskID: task['id'],
                                    subTaskName: task['title'],
                                    taskName: task['title'],
                                    page: "2"),
                              ),
                            );
                          }
                        },
                        child: Icon(
                          Icons.play_arrow,
                          color: task['completed']
                              ? Colors.grey
                              : const Color(
                                  0xFF3B7292), // Grey for completed task
                        ),
                      ),
                    ),
                    if (task['subtasks'] != null && task['subtasks'].isNotEmpty)
                      IconButton(
                        icon: Icon(task['expanded']
                            ? Icons.expand_less
                            : Icons.expand_more),
                        onPressed: onExpandToggle,
                      ),
                  ],
                ),
              ),
              if (task['expanded'] &&
                  task['subtasks'] != null &&
                  task['subtasks'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: task['subtasks'].map<Widget>((subtask) {
                      return Slidable(
                        key: ValueKey(subtask['id']),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            CustomSlidableAction(
                              onPressed: (_) => showDeleteConfirmationDialog(
                                  context, subtask),
                              backgroundColor: const Color(0xFFC2C2C2),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditTaskPage(taskId: task['id']),
                              ),
                            ).then((result) {
                              if (result == true) {
                                onRefresh();
                              }
                            });
                          },
                          leading: Tooltip(
                            message: "Mark SubTask as complete!", //hint
                            showDuration: Duration(milliseconds: 500),
                            child: GestureDetector(
                              onTap: () {
                                onSubtaskToggle(subtask);
                              },
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: subtask['completed']
                                        ? Colors.grey
                                        : Colors.grey,
                                    width: 4.0,
                                  ),
                                  color: subtask['completed']
                                      ? Colors.grey
                                      : Colors.white,
                                ),
                                child: subtask['completed']
                                    ? const Icon(Icons.check,
                                        size: 16, color: Colors.white)
                                    : null,
                              ),
                            ),
                          ),
                          title: Text(
                            subtask['title'],
                            style: TextStyle(
                              decoration: subtask['completed']
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          trailing: Tooltip(
                            message: subtask['completed']
                                ? 'This subtask is already complete!' // Hint if subtask is complete
                                : 'Start subtask timer', // Hint if subtask is not complete
                            child: IconButton(
                              icon: Icon(Icons.play_arrow,
                                  color: subtask['completed']
                                      ? Colors.grey
                                      : const Color(
                                          0xFF3B7292)), // Grey for completed, Blue for not
                              onPressed: subtask['completed']
                                  ? null // Disable the button if the subtask is complete
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              TimerSelectionPage(
                                                  taskId: task['id'] ?? '',
                                                  subTaskID:
                                                      subtask['id'] ?? '',
                                                  subTaskName:
                                                      subtask['title'] ?? '',
                                                  taskName: task['title'] ?? '',
                                                  page: "2"),
                                        ),
                                      );
                                    },
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
