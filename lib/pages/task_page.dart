import 'package:flutter/material.dart';
import 'package:flutter_application/models/BottomNavigationBar.dart';
import 'package:flutter_application/pages/editTask.dart';
import 'package:flutter_application/welcome_page.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application/pages/calender_page.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_application/pages/timer_page';
import 'package:flutter_application/pages/progress_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application/pages/addTaskForm.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application/Classes/Task';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  _TaskPageState createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  String selectedSort = 'timeline';
  bool showEmptyState = true;
  String? userID;

  //list for empty list state.
  final List<String> emptyStateMessages = [
    "You have no tasks for today. Start planning!",
    "Nothing on your to-do list today. Add your tasks!",
    "You're free today! Add new tasks to stay organized.",
    "All set! Want to add more tasks for today?"
  ];

  final List<Map<String, dynamic>> tasks = []; // store task from Firestore.
  List<String> availableCategories = []; // store categories from Firestore.

  DateTime? startOfDay;
  DateTime? endOfDay;
  bool isLoading = true;
  @override
  void dispose() {
    tasks.clear();
    userID = null;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // إذا كان المستخدم غير مسجل الدخول، قم بتعيين userID إلى null ووقف جلب المهام
      setState(() {
        userID = null;
        isLoading = false;
      });
    } else {
      // إذا كان المستخدم مسجل الدخول، قم بجلب المهام
      userID = user.uid;
      selectedCategories = ['All']; // تعيين "All" كالفئة الافتراضية
      fetchTasksFromFirestore();
    }
  }

  Future<void> _fetchUserID() async {
    // Get the current user from FirebaseAuth
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userID = user.uid; // Assign the logged-in user's UID
      });
      fetchTasksFromFirestore(); // Fetch tasks now that we have the user ID
    }
  }

  void fetchTasksFromFirestore() async {
    setState(() {
      isLoading = true;
    });

    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Fetch tasks based on userID
    QuerySnapshot taskSnapshot = await firestore
        .collection('Task')
        .where('userID', isEqualTo: userID) // Filter by the logged-in user's ID
        .get();

    List<QueryDocumentSnapshot> taskDocuments = taskSnapshot.docs;

    // Set start and end of the current day
    startOfDay = DateTime.now();
    startOfDay = DateTime(startOfDay!.year, startOfDay!.month, startOfDay!.day);
    endOfDay = startOfDay!
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));

    // Fetch categories and store taskIDs for each category
    QuerySnapshot categorySnapshot = await firestore
        .collection('Category')
        .where('userID', isEqualTo: userID)
        .get();

    setState(() {
      tasks.clear();
      availableCategories.clear();

      // Use a Set to ensure unique categories
      Set<String> categorySet = {};

      // Add default categories
      categorySet.add('All');
      categorySet.add('Uncategorized');
      //categorySet.add('Home');

      // Fetch and add categories
      Map<String, List<String>> categoryTaskMap = {};
      for (var doc in categorySnapshot.docs) {
        String categoryName = doc['categoryName'];
        Map<String, dynamic> categoryData = doc.data() as Map<String, dynamic>;
        List<dynamic> taskIDs =
            categoryData.containsKey('taskIDs') ? categoryData['taskIDs'] : [];

        categorySet.add(categoryName); // Ensure category is added only once

        for (var taskId in taskIDs) {
          if (categoryTaskMap.containsKey(taskId)) {
            categoryTaskMap[taskId]?.add(categoryName);
          } else {
            categoryTaskMap[taskId] = [categoryName];
          }
        }
      }

      // Process and add tasks
      for (var taskDoc in taskDocuments) {
        Map<String, dynamic> taskData = taskDoc.data() as Map<String, dynamic>;
        DateTime taskTime = (taskData['scheduledDate'] as Timestamp).toDate();

        // Check if the task falls within the current day
        if (taskTime.year == startOfDay!.year &&
            taskTime.month == startOfDay!.month &&
            taskTime.day == startOfDay!.day) {
          print(
              "Task Date: $taskTime, Start of Day: $startOfDay, End of Day: $endOfDay");

          String taskId = taskDoc.id;
          Map<String, dynamic> task = {
            'id': taskId,
            'title': taskData['title'] ?? 'Untitled',
            'time': taskTime,
            'priority': taskData['priority'] as int,
            'completed': taskData['completionStatus'] == 2,
            'expanded': false,
            'subtasks': [],
            'categories': categoryTaskMap[taskId] ?? ['Uncategorized'],
          };

          // Fetch subtasks for each task
          firestore
              .collection('SubTask')
              .where('taskID', isEqualTo: taskId)
              .get()
              .then((subtaskSnapshot) {
            List<Map<String, dynamic>> subtasks =
                subtaskSnapshot.docs.map((subDoc) {
              Map<String, dynamic> subtaskData =
                  subDoc.data() as Map<String, dynamic>;
              return {
                'id': subDoc.id,
                'title': subtaskData['title'],
                'completed': subtaskData['completionStatus'] == 1,
              };
            }).toList();

            setState(() {
              task['subtasks'] = subtasks; // Update subtasks after fetching
            });
          });

          tasks.add(task); // Add task to the list
        }
      }

      // Convert the Set to a List for further use
      availableCategories = categorySet.toList();

      isLoading = false; // Loading is done
    });
    Map<String, bool> categoryCompletionStatus = {};

for (String category in availableCategories) {
  bool allTasksComplete = tasks.where((task) => task['categories'].contains(category))
                               .every((task) => task['completed']);
  categoryCompletionStatus[category] = allTasksComplete;
}
  }

  String getEmptyStateMessage() {
    return emptyStateMessages[
        DateTime.now().weekday % emptyStateMessages.length];
  }

  bool areAllTasksCompleted() {
    return tasks.every(
        (task) => task['completed'] ?? false); // If null, default to false
  }

  void deleteTask(Map<String, dynamic> task) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Delete the task from Firestore
    await firestore.collection('Task').doc(task['id']).delete();

    setState(() {
      tasks.remove(task); // Remove task from the local list
    });
    _showTopNotification("Task deleted successfully.");
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
    }
  }

  List<String> selectedCategories = [];

  // Functions for Hamburger Menu options

  String getFormattedDate() {
    final now = DateTime.now();
    final formatter = DateFormat('EEE, d MMM yyyy');
    return formatter.format(now);
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

  void showViewDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedView = 'list'; // Default view selection
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor:
                  const Color(0xFFF5F7F8), // Light background color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              title: const Text(
                'View Options',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 6, 6, 6),// Title color
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    activeColor:
                        const Color(0xFF79A3B7), // Active color for selection
                    title: const Text(
                      'View as List',
                      style: TextStyle(
                        color: Color(0xFF545454), // Text color for radio item
                        fontWeight: FontWeight.w500, // Slightly bold text
                      ),
                    ),
                    value: 'list',
                    groupValue: selectedView,
                    onChanged: (value) {
                      setState(() {
                        selectedView = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    activeColor:
                        const Color(0xFF79A3B7), // Active color for selection
                    title: const Text(
                      'View as Calendar',
                      style: TextStyle(
                        color: Color(0xFF545454), // Text color for radio item
                        fontWeight: FontWeight.w500, // Slightly bold text
                      ),
                    ),
                    value: 'calendar',
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
                    backgroundColor:
                        Colors.white, // White background for cancel button
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                          color: Color(0xFF79A3B7)), // Border color
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF79A3B7), // Button text color
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (selectedView == 'calendar') {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => CalendarPage()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF79A3B7), // Apply button background
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      color: Colors.white, // White text for apply button
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

  void showSortDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor:
                  const Color(0xFFF5F7F8), // Change background color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              title: const Text(
                'Sort by',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 6, 6, 6), // Text color matching your theme
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
                        color: Color(0xFF545454), // Text color for radio item
                        fontWeight: FontWeight.w500, // Slightly bold text
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
                        color: Color(0xFF545454), // Text color for radio item
                        fontWeight: FontWeight.w500, // Slightly bold text
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
                    backgroundColor: Colors.white, // White button background
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                          color: Color(0xFF79A3B7)), // Border color
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF79A3B7), // Button text color
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      sortTasks(); // Ensure sorting happens here
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF79A3B7), // Apply button color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      color: Colors.white, // White text for the apply button
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

  bool isValidTimeFormat(String time) {
    final timePattern =
        RegExp(r'^[1-9]|1[0-2]:[0-5][0-9] (AM|PM)$', caseSensitive: false);
    return timePattern.hasMatch(time);
  }

  void sortTasks() {
    if (selectedSort == 'priority') {
      // فرز المهام بناءً على القيم العددية للأولوية (4 = urgent، 1 = low)
      tasks.sort((a, b) =>
          b['priority'].compareTo(a['priority'])); // ترتيب تنازلي حسب الأولوية
    } else if (selectedSort == 'timeline') {
      try {
        tasks.sort((a, b) {
          DateTime timeA = a['time'] is DateTime
              ? a['time']
              : DateTime.parse(a['time'].toString());
          DateTime timeB = b['time'] is DateTime
              ? b['time']
              : DateTime.parse(b['time'].toString());
          return timeA.compareTo(timeB); // ترتيب تصاعدي حسب الوقت
        });
      } catch (e) {
        print('General error: $e');
      }
    }
    setState(() {}); // تحديث الواجهة بعد الفرز
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



void showCategoryDialog() {
  List<String> tempSelectedCategories = List.from(selectedCategories);

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xFFF5F7F8), // Light gray background
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Text(
          'Category',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 6, 6, 6), // Dark blue text color
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
                    bool isSelected = tempSelectedCategories.contains(category);
                    bool isAllCategory = category == 'All';
                    Color chipColor;

                    // تحديد اللون بناءً على حالة المهام
                    bool allTasksComplete = tasks.isNotEmpty && tasks.every((task) => task['completed'] == true);
                    bool categoryComplete = tasks
                        .where((task) => task['categories'] != null && task['categories'].contains(category))
                        .every((task) => task['completed'] == true);

                    // تحديث لون "All" بناءً على المهام المتاحة
                    if (isAllCategory) {
                      chipColor = tasks.isEmpty
                          ? Colors.grey // اللون الرمادي إذا لم توجد أي مهام
                          : (allTasksComplete ? Colors.green : const Color(0xFF79A3B7)); // أخضر إذا كانت كل المهام مكتملة، أزرق إذا لم تكن مكتملة
                    } else if (!tasks.any((task) => task['categories'].contains(category))) {
                      chipColor = Colors.grey; // اللون الرمادي إذا لم توجد مهام في هذه الفئة
                    } else {
                      chipColor = categoryComplete ? Colors.green : const Color(0xFF79A3B7);
                    }

                    return Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          // إضافة ظل خارجي
                          BoxShadow(
                            color: Color(0xFFFAFBFF).withOpacity(1.0), // 100% opacity
                            offset: Offset(-5, -5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: ChoiceChip(
                        label: Text(
                          category,
                          style: const TextStyle(
                            color: Colors.white, // لون النص الأبيض
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: chipColor,
                        backgroundColor: chipColor,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              if (category == 'All') {
                                // إذا تم اختيار "All"، قم بتحديدها وإلغاء تحديد الفئات الأخرى
                                tempSelectedCategories.clear();
                                tempSelectedCategories.add('All');
                              } else {
                                // إذا تم اختيار فئة أخرى، قم بإلغاء تحديد "All" وأضف الفئة المحددة
                                tempSelectedCategories.remove('All');
                                tempSelectedCategories.add(category);
                              }
                            } else {
                              tempSelectedCategories.remove(category);
                              if (tempSelectedCategories.isEmpty) {
                                // إذا كانت الفئات فارغة، قم بتحديد "All" تلقائيًا
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
                // Legend for color codes in a vertical column
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendCircle(Colors.grey, 'No Tasks'),
                      _buildLegendCircle(const Color(0xFF79A3B7), 'Incomplete Tasks'),
                      _buildLegendCircle(Colors.green, 'All Completed'),
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
              backgroundColor: const Color(0xFFF5F7F8), // Light gray background
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

  void toggleTaskCompletion(Map<String, dynamic> task) async {
    bool newTaskCompletionStatus =
        !task['completed']; // عكس حالة الإكمال للمهمة الرئيسية

    setState(() {
      task['completed'] = newTaskCompletionStatus;
    });

    FirebaseFirestore firestore = FirebaseFirestore.instance;

    if (newTaskCompletionStatus) {
      // إذا كانت المهمة الرئيسية مكتملة، اجعل جميع المهام الفرعية مكتملة
      for (var subtask in task['subtasks']) {
        subtask['completed'] = true;
        await firestore
            .collection('SubTask')
            .doc(subtask['id'])
            .update({'completionStatus': 1});
      }
      // تحديث حالة المهمة الرئيسية في قاعدة البيانات كـ"مكتملة"
      await firestore
          .collection('Task')
          .doc(task['id'])
          .update({'completionStatus': 2});
    } else {
      // إذا كانت المهمة الرئيسية غير مكتملة، اجعل جميع المهام الفرعية غير مكتملة
      for (var subtask in task['subtasks']) {
        subtask['completed'] = false;
        await firestore
            .collection('SubTask')
            .doc(subtask['id'])
            .update({'completionStatus': 0});
      }
      // تحديث حالة المهمة الرئيسية في قاعدة البيانات كـ"غير مكتملة"
      await firestore
          .collection('Task')
          .doc(task['id'])
          .update({'completionStatus': 0});
    }

    if (mounted) {
      setState(() {}); // تحديث واجهة المستخدم
    }
  }

  void toggleSubtaskCompletion(
      Map<String, dynamic> task, Map<String, dynamic> subtask) async {
    bool newSubtaskCompletionStatus =
        !subtask['completed']; // عكس حالة إكمال المهام الفرعية

    setState(() {
      subtask['completed'] = newSubtaskCompletionStatus;
    });

    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // تحديث حالة المهمة الفرعية في قاعدة البيانات
    await firestore
        .collection('SubTask')
        .doc(subtask['id'])
        .update({'completionStatus': newSubtaskCompletionStatus ? 1 : 0});

    // التحقق مما إذا كانت جميع المهام الفرعية مكتملة أو على الأقل واحدة مكتملة
    bool allSubtasksComplete =
        task['subtasks'].every((s) => s['completed'] == true);
    bool anySubtaskComplete =
        task['subtasks'].any((s) => s['completed'] == true);

    int newTaskStatus;
    if (allSubtasksComplete) {
      newTaskStatus = 2; // المهمة الرئيسية مكتملة
      task['completed'] = true;
    } else if (anySubtaskComplete) {
      newTaskStatus = 1; // المهمة الرئيسية قيد التنفيذ
      task['completed'] = false;
    } else {
      newTaskStatus = 0; // المهمة الرئيسية غير مكتملة
      task['completed'] = false;
    }
    if (mounted) {
      setState(() {}); // تحديث واجهة المستخدم
    }

    // تحديث حالة المهمة الرئيسية في قاعدة البيانات
    await firestore
        .collection('Task')
        .doc(task['id'])
        .update({'completionStatus': newTaskStatus});
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
                Navigator.of(context).pop(); // إغلاق النافذة بدون حذف
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
                Navigator.of(context).pop(); // إغلاق النافذة بعد الحذف
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

    overlayState?.insert(overlayEntry);
    Future.delayed(Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool hasTodayTasks = tasks.any((task) =>
        task['time'].isAfter(startOfDay!) && task['time'].isBefore(endOfDay!));

    // التحقق إذا كانت الفئة المختارة لا تحتوي على أي مهام
    bool noTasksInSelectedCategory = !tasks.any((task) =>
        selectedCategories.contains('All') ||
        (selectedCategories.contains('Uncategorized') &&
            task['categories'].contains('Uncategorized')) ||
        selectedCategories
            .any((category) => task['categories'].contains(category)));

    return GestureDetector(
      onTap:
          closeAllSubtasks, // This closes the expanded subtasks when clicking outsid
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            'Tasks page',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color.fromARGB(255, 226, 231, 234),
          elevation: 0,
          automaticallyImplyLeading: false,

          // Hamburger Menu
          actions: [
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
              icon: const Icon(Icons.more_vert,
                  color: Color(0xFF104A73)), // Adjusted icon color
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: 'view',
                    child: Row(
                      children: const [
                        Icon(Icons.list,
                            size: 24,
                            color: Color(0xFF545454)), // Adjust icon color
                        SizedBox(width: 10),
                        Text(
                          'View',
                          style: TextStyle(
                            fontSize: 18,
                            color:
                                Color(0xFF545454), // Text color matching theme
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'sort',
                    child: Row(
                      children: const [
                        Icon(Icons.sort,
                            size: 24,
                            color: Color(0xFF545454)), // Adjust icon color
                        SizedBox(width: 10),
                        Text(
                          'Sort',
                          style: TextStyle(
                            fontSize: 18,
                            color:
                                Color(0xFF545454), // Text color matching theme
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'categorize',
                    child: Row(
                      children: const [
                        Icon(Icons.label,
                            size: 24,
                            color: Color(0xFF545454)), // Adjust icon color
                        SizedBox(width: 10),
                        Text(
                          'Categorize',
                          style: TextStyle(
                            fontSize: 18,
                            color:
                                Color(0xFF545454), // Text color matching theme
                          ),
                        ),
                      ],
                    ),
                  ),
                ];
              },
              // Set the background color for the popup menu
              color: Color(0xFFF5F7F8),
            ),
          ],
        ),

        // Body content
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/logo.png', // شعار التطبيق الخاص بك
                        width: 170,
                        height: 170,
                      ),
                      const SizedBox(height: 0),
                      Lottie.asset(
                        'assets/animations/loading.json', // ملف الأنيميشن Lottie
                        width: 150,
                        height: 150,
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getFormattedDate(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    if (tasks.isEmpty ||
                        !tasks.any((task) =>
                            task['time'].isAfter(startOfDay!) &&
                            task['time'].isBefore(endOfDay!)))
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(
                                height: 80), // إضافة مسافة رأسية قبل الصورة
                            Image.asset(
                              'assets/images/empty_list.png', // المسار الصحيح للصورة
                              width: 150, // عرض الصورة
                              height: 150, // ارتفاع الصورة
                            ),
                            const SizedBox(
                                height: 20), // المسافة بين الصورة والنص
                            Text(
                              getEmptyStateMessage(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3B7292),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(
                                height: 50), // إضافة مسافة رأسية بعد النص
                          ],
                        ),
                      )

// Existing Expanded widget for displaying tasks
                    else
                      Expanded(
                        child: (!tasks.any((task) =>
                                selectedCategories.contains('All') ||
                                (selectedCategories.contains('Uncategorized') &&
                                    task['categories']
                                        .contains('Uncategorized')) ||
                                selectedCategories.any((category) =>
                                    task['categories'].contains(category))))
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 30),
                                  Center(
                                    child: Image.asset(
                                      'assets/images/empty_list.png', // تأكد من وجود الصورة في المسار المحدد
                                      width: 100,
                                      height: 110,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Center(
                                    child: Text(
                                      'There are no tasks in this category\.',
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
    spacing: 8.0,
    children: selectedCategories.map((category) {
      return ActionChip(
        label: Text(category),
        onPressed: () {
          // Remove specific category on tap
          setState(() {
            selectedCategories.remove(category);
            if (selectedCategories.isEmpty) {
              selectedCategories = ['All']; // Reset to "All" if no categories remain
            }
          });
        },
        avatar: const Icon(Icons.close, size: 18, color: Colors.white),
        backgroundColor: const Color(0xFF79A3B7),
        labelStyle: const TextStyle(color: Colors.white),
      );
    }).toList(),
  ),
const SizedBox(height: 1),
                                  // Show Pending Tasks section if there are any uncompleted tasks
                                  if (tasks.any((task) =>
    !task['completed'] &&
    (selectedCategories.contains('All') ||
        (selectedCategories.contains('Uncategorized') &&
            (task['categories'] == null || task['categories'].contains('Uncategorized'))) ||
        selectedCategories.any((category) => task['categories'].contains(category)))))

                                    // Add this snippet above the pending tasks section to show multiple selected categories
// Ensure category chips are always displayed if there are selected categories



                                    Row(
                                      children: const [
                                        Expanded(child: Divider(thickness: 1)),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8.0),
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
  // تحقق إذا كانت الفئة المختارة تحتوي على "All"، قم بإظهار جميع المهام الغير مكتملة
  if (selectedCategories.contains('All')) {
    return !task['completed'];
  }
  // تحقق إذا كانت الفئة المختارة تحتوي على "Uncategorized"، وأي فئات أخرى
  else {
    return !task['completed'] &&
        (selectedCategories.contains('Uncategorized') &&
            (task['categories'] == null || task['categories'].contains('Uncategorized')) ||
        selectedCategories.any((category) => task['categories'].contains(category)));
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
                                          toggleSubtaskCompletion(
                                              task, subtask),
                                      onSubtaskDeleted: (subtask) async {
                                        await FirebaseFirestore.instance
                                            .collection('SubTask')
                                            .doc(subtask['id'])
                                            .delete();
                                        task['subtasks'].remove(subtask);
                                        setState(
                                            () {}); // تحديث الواجهة بعد الحذف
                                        _showTopNotification(
                                            "Subtask deleted successfully.");
                                      },
                                      getPriorityColor: getPriorityColor,
                                      onDeleteTask: () =>
                                          showDeleteConfirmationDialog(task),
                                      onEditTask: () => editTask(task),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  if (areAllTasksCompleted() &&
                                      selectedCategories.contains('All'))
                                    Center(
                                      child: Column(
                                        children: [
                                          const SizedBox(height: 70),
                                          Image.asset(
                                            'assets/images/done.png', // عرض الصورة
                                            height: 110, // ارتفاع الصورة
                                          ),
                                          const SizedBox(
                                              height:
                                                  20), // المسافة بين الصورة والنص
                                          const Text(
                                            'Awesome job! You\'ve conquered your\n to-do list today!',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF3B7292),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 20),
                                        ],
                                      ),
                                    ),

                                  // Show Completed Tasks section if there are any completed tasks
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
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8.0),
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
  }
  else {
    return task['completed'] &&
        (selectedCategories.contains('Uncategorized') &&
            (task['categories'] == null || task['categories'].contains('Uncategorized')) ||
        selectedCategories.any((category) => task['categories'].contains(category)));
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
                                          toggleSubtaskCompletion(
                                              task, subtask),
                                      onSubtaskDeleted: (subtask) async {
                                        await FirebaseFirestore.instance
                                            .collection('SubTask')
                                            .doc(subtask['id'])
                                            .delete();
                                        task['subtasks'].remove(subtask);
                                        setState(
                                            () {}); // تحديث الواجهة بعد الحذف
                                        _showTopNotification(
                                            "Subtask deleted successfully.");
                                      },
                                      getPriorityColor: getPriorityColor,
                                      onDeleteTask: () =>
                                          showDeleteConfirmationDialog(task),
                                      onEditTask: () => editTask(task),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                  ],
                ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            if (userID != null) {
              // Navigate to AddTaskPage if the user is logged in
              bool? result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTaskPage(),
                ),
              );

              // Check if a task was added (i.e., result is true) and refresh tasks
              if (result == true) {
                fetchTasksFromFirestore();
              }
            } else {
              // Show a dialog prompting the user to sign in
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: const Color(0xFFF5F7F8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    title: const Text(
                      'Sign In Required',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    content: const Text(
                      'You need to sign in to add tasks. Please log in or create an account.',
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
                          style: TextStyle(color: Color(0xFF79A3B7)),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Navigate to Sign-In page or provide sign-in functionality
                          // Implement navigation to your sign-in page here if needed
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF79A3B7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Text(
                          'Sign In',
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
      ), //jjjj
    ); //jjjj
  }
}

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback onTaskToggle;
  final VoidCallback onExpandToggle;
  final Function(Map<String, dynamic>) onSubtaskToggle;
  final Function(Map<String, dynamic>)
      onSubtaskDeleted; // Callback for deletion
  final Color Function(int) getPriorityColor;
  final VoidCallback onDeleteTask;
  final VoidCallback onEditTask;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onTaskToggle,
    required this.onExpandToggle,
    required this.onSubtaskToggle,
    required this.onSubtaskDeleted, // Add this line to the constructor
    required this.getPriorityColor,
    required this.onDeleteTask,
    required this.onEditTask,
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
                Navigator.of(context).pop(); // Close dialog without deleting
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
                Navigator.of(context).pop(); // Close dialog before deletion

                // Call the onSubtaskDeleted callback to handle the deletion in TaskPage
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(
          16.0), // إضافة الحواف المستديرة إلى بطاقة المهام بأكملها
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
              16.0), // إضافة الحواف المستديرة لبطاقة المهام
        ),
        child: Slidable(
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
                backgroundColor: const Color(0xFFC2C2C2), // لون الخلفية
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                ),
              ),
              SizedBox(
                width: 1,
                child: Container(
                  color: Colors.grey, // اللون الرمادي للفاصل
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
                  message: "Mark Task as complete!", // التلميح المطلوب
                  showDuration: Duration(milliseconds: 500),
                  child: InkWell(
                    onTap:
                        onTaskToggle, // يحافظ على الـ onTap لتنفيذ الإجراء عند النقر
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
                subtitle: Text(
                  DateFormat('h:mm a').format(
                      task['time']), // Display the time in "10 AM" format
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TimerPage()),
                        );
                      },
                    ),
                    if (task['subtasks'] != null &&
                        task['subtasks']
                            .isNotEmpty) // Show arrow if subtasks are present
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
                            );
                          },
                          leading: Tooltip(
                            message:
                                "Mark SubTask as complete!", // التلميح الذي يظهر للمستخدم
                            showDuration:
                                Duration(milliseconds: 500), // مدة ظهور التلميح
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
                          trailing: IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => TimerPage()),
                              );
                            },
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
