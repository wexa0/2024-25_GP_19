import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application/Classes/Category';
import 'package:flutter_application/Classes/SubTask';
import 'package:flutter_application/Classes/Task';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(addTask());
}

class addTask extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Add Task',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFFF5F7F8),
        textTheme: Theme.of(context).textTheme.apply(
              fontFamily: 'Poppins',
            ),
      ),
      home: AddTaskPage(),
    );
  }
}

class AddTaskPage extends StatefulWidget {
  @override
  _AddTaskPageState createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  User? _user = FirebaseAuth.instance.currentUser;

  String selectedCategory = '';
  String? selectedPriority;
  Color priorityIconColor = Color(0xFF3B7292);
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  String formattedDate = 'Select Date';
  String formattedTime = 'Select Time';

  List<String> categories = [];
  List<String> hardcodedCategories = [];
  bool isEditingCategory = false;
  String newCategory = '';
  List<String> subtasks = [];
  TextEditingController subtaskController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  TextEditingController taskNameController = TextEditingController();
  TextEditingController notesController = TextEditingController();

  Color darkBlue = Color(0xFF104A73);
  Color mediumBlue = Color(0xFF3B7292);
  Color lightBlue = Color(0xFF79A3B7);
  Color lightestBlue = Color(0xFFC7D9E1);
  Color lightGray = Color(0xFFF5F7F8);
  Color darkGray = Color(0xFF545454);

  bool _isTitleMissing = false;
  bool _isDateMissing = false;
  bool _isTimeMissing = false;

  void _pickTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: darkBlue,
              onPrimary: Color(0xFFF5F7F8),
              onSurface: darkGray,
              secondary: lightBlue,
            ),
            dialogBackgroundColor: Color(0xFFF5F7F8),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime != null && pickedTime != selectedTime) {
      setState(() {
        selectedTime = pickedTime;
        formattedTime = selectedTime.format(context);
      });
    }
  }

  void initState() {
    super.initState();
    _getCategories();
    _preselectReminderBasedOnPriority("Normal");
  }

  Future<void> _getCategories() async {
    User? currentUser = await _getCurrentUser();
    if (currentUser == null) return;

    try {
      QuerySnapshot categorySnapshot = await FirebaseFirestore.instance
          .collection('Category')
          .where('userID', isEqualTo: currentUser.uid)
          .get();

      List<String> fetchedCategories = [];

      for (var doc in categorySnapshot.docs) {
        String categoryName = doc['categoryName'] ?? '';
        if (categoryName.isNotEmpty) {
          fetchedCategories.add(categoryName);
        }
      }

      List<String> combinedCategories = [
        ...hardcodedCategories,
        ...fetchedCategories
      ];

      List<String> uniqueCategories = combinedCategories.toSet().toList();

      setState(() {
        categories = uniqueCategories;
      });
    } catch (e) {
      _showTopNotification('Failed to fetch categories: $e');
    }
  }

  Future<User?> _getCurrentUser() async {
    if (_user == null) {
      _user = FirebaseAuth.instance.currentUser;
      if (_user == null) {
        _showTopNotification('No logged-in user found');
      }
    }
    return _user;
  }

  //

  Future<String?> _saveTaskToFirebase() async {
    try {
      User? currentUser = await _getCurrentUser();
      if (currentUser == null) return null;

    final DateTime taskDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

      DateTime? reminderDateTime;

      // Schedule reminder for the main task
      if (isReminderOn) {
        if (selectedReminderOption != null &&
            selectedReminderOption!['duration'] != null) {
          reminderDateTime =
              taskDateTime.subtract(selectedReminderOption!['duration']);
        } else if (customReminderDateTime != null) {
          reminderDateTime = customReminderDateTime;
        }

        // Ensure reminder is valid and in the future
        if (reminderDateTime != null &&
            reminderDateTime.isBefore(DateTime.now())) {
          _showTopNotification("Reminder time must be in the future.");
          return null;
        }
      }

      // Save the task to Firestore
      DocumentReference taskRef =
          FirebaseFirestore.instance.collection('Task').doc();
      String taskId = taskRef.id;

      await taskRef.set({
        'completionStatus': 0,
        'scheduledDate': Timestamp.fromDate(taskDateTime),
        'note': notesController.text,
        'priority': _getPriorityValue(),
        'reminder': isReminderOn && reminderDateTime != null
            ? Timestamp.fromDate(reminderDateTime)
            : null,
        'timer': '',
        'title': taskNameController.text,
        'userID': currentUser.uid,
      });

      // Schedule main task notification if reminder is valid
      if (isReminderOn && reminderDateTime != null) {
        await _scheduleTaskNotification(
          taskId: taskId,
          taskTitle: taskNameController.text,
          scheduledDateTime: reminderDateTime,
        );
      }

      // Save and schedule notifications for subtasks
      for (String subtask in subtasks) {
        if (subtask.trim().isEmpty) continue;

        DateTime? subtaskReminderDateTime;
        var subtaskReminder = subtaskReminders[subtask];
        if (subtaskReminder != null) {
          if (subtaskReminder['duration'] != null) {
            subtaskReminderDateTime =
                taskDateTime.subtract(subtaskReminder['duration']);
          } else if (subtaskReminder['customDateTime'] != null) {
            subtaskReminderDateTime = subtaskReminder['customDateTime'];
          }
        }

        // Validate subtask reminder
        if (subtaskReminderDateTime != null &&
            subtaskReminderDateTime.isBefore(DateTime.now())) {
          print("Invalid subtask reminder for: $subtask");
          continue;
        }

        DocumentReference subtaskRef =
            FirebaseFirestore.instance.collection('SubTask').doc();

        await subtaskRef.set({
          'completionStatus': 0,
          'taskID': taskRef.id,
          'timer': '',
          'title': subtask.trim(),
          'reminder': subtaskReminderDateTime != null
              ? Timestamp.fromDate(subtaskReminderDateTime)
              : null,
        });

        // Schedule notification for valid subtask reminders
        if (subtaskReminderDateTime != null) {
          await _scheduleTaskNotification(
            taskId: subtaskRef.id,
            taskTitle: subtask,
            scheduledDateTime: subtaskReminderDateTime,
          );
        }
      }

      return taskId;
    } catch (e) {
      _showTopNotification('Failed to save task. Please try again: $e');
      return null;
    }
  }


  int _getPriorityValue() {
    switch (selectedPriority) {
      case 'Urgent':
        return 4;
      case 'High':
        return 3;
      case 'Normal':
        return 2;
      case 'Low':
        return 1;
      default:
        return 2;
    }
  }

  Future<void> _saveTask() async {
    setState(() {
      _isTitleMissing = taskNameController.text.isEmpty;
      _isDateMissing = formattedDate == 'Select Date';
      _isTimeMissing = formattedTime == 'Select Time';
    });

    if (!_isTitleMissing && !_isDateMissing && !_isTimeMissing) {
      try {
        String? taskId = await _saveTaskToFirebase(); // taskId is a String

        if (taskId != null) {
          int notificationId =
              taskId.hashCode.abs(); // Generate numeric ID from taskId

          DateTime? reminderDateTime;

          if (selectedReminderOption != null &&
              selectedReminderOption!['duration'] != null) {
            reminderDateTime =
                DateTime.now().add(selectedReminderOption!['duration']);
          } else if (customReminderDateTime != null) {
            reminderDateTime = customReminderDateTime;
          }

          if (reminderDateTime != null) {
            if (reminderDateTime.isBefore(DateTime.now())) {
              print(
                  "Reminder date is in the past. Please select a future date.");
            } else {
              // Schedule the reminder notification
              await _scheduleTaskNotification(
                taskId: taskId, // Pass taskId as String
                taskTitle: taskNameController.text,
                scheduledDateTime: reminderDateTime,
              );
            }
          } else {
            print("No valid reminder date selected.");
          }

          Navigator.pop(context, true);
        }
      } catch (e) {
        _showTopNotification('Failed to save task: $e');
      }
    } else {
      _showTopNotification('Please fill in all mandatory fields.');
    }
  }

  void _showTopNotification(String message) {
    final overlayState =
        Navigator.of(context).overlay; // Access the root navigator's overlay
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.1, // Top position
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlayState?.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

 Future<void> _scheduleTaskNotification({
    required String taskId,
    required String taskTitle,
    required DateTime scheduledDateTime,
  }) async {
    final tz.TZDateTime scheduledTZDateTime =
        tz.TZDateTime.from(scheduledDateTime, tz.local);

    if (scheduledTZDateTime.isBefore(tz.TZDateTime.now(tz.local))) {
      print("Failed to schedule notification: Date must be in the future.");
      return;
    }

    final int notificationId = _generateNotificationId(taskId); // Unique ID

    const AndroidNotificationAction markDoneAction = AndroidNotificationAction(
      'mark_done',
      'Mark Task as Done',
      showsUserInterface: true,
    );

    final androidDetails = AndroidNotificationDetails(
      'task_channel',
      'Task Reminders',
      channelDescription: 'Task reminders with customizable intervals',
      actions: [markDoneAction],
    ); 

    final platformDetails = NotificationDetails(android: androidDetails);

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        '$taskTitle Reminder',
        'Reminder for your subtask scheduled at $scheduledDateTime',
        scheduledTZDateTime,
        platformDetails,
        payload: taskId, // Store taskId in the payload
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      print("Notification scheduled successfully! ID: $notificationId");
    } catch (e) {
      print("Failed to schedule notification: $e");
    }
  }
int _generateNotificationId(String documentId) {
    return documentId
        .hashCode; // Convert the Firestore document ID to an integer
  }


  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 226, 231, 234),
        elevation: 0,
        iconTheme: IconThemeData(color: darkGray),
        title: Center(
          child: Text(
            'Add Task',
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 12),
              TextField(
                controller: taskNameController,
                decoration: InputDecoration(
                  labelText: 'Task name *',
                  labelStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: darkGray,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: lightestBlue),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: darkBlue),
                  ),
                  errorText: _isTitleMissing
                      ? 'Task Name is required'
                      : null, // Red underline when missing
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                ),
              ),
              SizedBox(height: 20),
              _buildSubtaskSection(),
              SizedBox(height: 20),
              _buildCategorySection(),
              SizedBox(height: 20),
              _buildDateTimePicker(),
              SizedBox(height: 5),
              _buildPrioritySection(),
              SizedBox(height: 20),
              _buildReminderSection(),
              SizedBox(height: 20),
              _buildTimerSection(),
              TextField(
                controller: notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: null,
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: lightestBlue),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: darkBlue),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.note, color: darkGray),
                      SizedBox(width: 8),
                      Text(
                        'Notes',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: darkGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _saveTask();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B7292),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text('Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtaskSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subtasks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(
              'Subtasks',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: darkGray,
              ),
            ),
          ),
        ...subtasks.map((subtask) {
          final TextEditingController subtaskEditingController =
              TextEditingController(text: subtask);

          return Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
            child: Slidable(
              key: ValueKey(subtask),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  CustomSlidableAction(
                    onPressed: (_) {
                      setState(() {
                        subtasks.remove(subtask);
                        subtaskReminders.remove(subtask);
                      });
                    },
                    backgroundColor: const Color(0xFFC2C2C2),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  title: TextField(
                    controller: subtaskEditingController,
                    onChanged: (newValue) {
                      setState(() {
                        final index = subtasks.indexOf(subtask);
                        if (index != -1) {
                          subtasks[index] = newValue;
                        }
                      });
                    },
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: darkGray,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    ),
                  ),
                  
                  trailing: IconButton(
                    icon: Icon(
                      Icons.notifications,
                      color: subtaskReminders[subtask] != null
                          ? mediumBlue
                          : Colors.grey,
                    ),
                    onPressed: () async {
                      _pickSubtaskReminderTime(subtask);
                    },
                  ),
                ),
              ),
            ),
          );
        }).toList(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            controller: subtaskController,
            decoration: InputDecoration(
              labelText: 'Add sub tasks',
              labelStyle: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: darkBlue,
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: darkBlue, width: 2.0),
              ),
              suffixIcon: IconButton(
                icon: Icon(Icons.add, color: Color.fromARGB(255, 79, 79, 79)),
                onPressed: () {
                  if (subtaskController.text.isNotEmpty) {
                    setState(() {
                      subtasks.add(subtaskController.text);
                      subtaskReminders[subtaskController.text] = null;
                      subtaskController.clear();
                    });
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

 Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Icon(Icons.label, color: Color(0xFF3B7292)),
              SizedBox(width: 8),
              Text(
                'Category',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: darkGray,
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.edit, color: Color(0xFF3B7292)),
                onPressed: () {
                  _showCategoryEditDialog();
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: categories.map((category) {
              return ChoiceChip(
                label: Text(
                  category,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    fontSize: 14,
                  ),
                ),
                selected: selectedCategory == category,
                selectedColor: Color(0xFF3B7292),
                backgroundColor: Colors.grey[200],
                onSelected: (bool selected) {
                  setState(() {
                    // If the selected category is already active, unselect it
                    if (selectedCategory == category) {
                      selectedCategory = '';
                    } else {
                      selectedCategory = category;
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }


  void _showCategoryEditDialog() {
    List<String> tempCategories = List.from(categories);
    List<Map<String, String>> renamedCategories = [];
    List<String> deletedCategories = [];
    List<String> addedCategories = [];

    FocusNode firstCategoryFocusNode = FocusNode();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor: lightGray,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categories',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkGray,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Rename, create, or delete categories.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: darkGray,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      children: tempCategories.asMap().entries.map((entry) {
                        int index = entry.key;
                        String category = entry.value;
                        TextEditingController renameController =
                            TextEditingController(text: category);

                        return ListTile(
                          title: TextField(
                            controller: renameController,
                            focusNode:
                                index == 0 ? firstCategoryFocusNode : null,
                            onSubmitted: (newName) {
                              if (newName.isNotEmpty && newName != category) {
                                setState(() {
                                  int index = tempCategories.indexOf(category);
                                  if (index != -1) {
                                    renamedCategories.add({
                                      'oldName': category,
                                      'newName': newName,
                                    });
                                    tempCategories[index] = newName;
                                  }
                                });
                              }
                            },
                            decoration: InputDecoration(
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: darkGray,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                deletedCategories.add(category);
                                tempCategories.remove(category);
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    Divider(),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: categoryController,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Add new category...',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.send, color: mediumBlue),
                              onPressed: () {
                                if (categoryController.text.isNotEmpty) {
                                  if (tempCategories.length < 7) {
                                    setState(() {
                                      tempCategories
                                          .add(categoryController.text);
                                      addedCategories
                                          .add(categoryController.text);
                                      categoryController.clear();
                                    });
                                  } else {
                                    _showTopNotification(
                                        'You can only create up to 7 categories.');
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: darkBlue,
                      ),
                      child: Text(
                        'Discard',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    TextButton(
                      onPressed: () async {
                        await _saveChangesToDatabase(
                          addedCategories,
                          renamedCategories,
                          deletedCategories,
                        );
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: darkBlue,
                      ),
                      child: Text(
                        'Save and Close',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          color: darkBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      firstCategoryFocusNode.requestFocus();
    });
  }

  Future<void> _saveChangesToDatabase(
      List<String> addedCategories,
      List<Map<String, String>> renamedCategories,
      List<String> deletedCategories) async {
    User? currentUser = await _getCurrentUser();
    if (currentUser == null) return;

    for (String category in addedCategories) {
      await _saveCategoryToDatabase(category);
    }

    for (var renameMap in renamedCategories) {
      String oldName = renameMap['oldName']!;
      String newName = renameMap['newName']!;
      await _renameCategoryInDatabase(oldName, newName);
    }

    for (String deletedCategory in deletedCategories) {
      await _deleteCategoryFromDatabase(deletedCategory);
    }

    await _getCategories();
  }

  Future<void> _saveCategoryToDatabase(String categoryName) async {
    User? currentUser = await _getCurrentUser();
    if (currentUser == null) return;

    await FirebaseFirestore.instance.collection('Category').add({
      'categoryName': categoryName,
      'userID': currentUser.uid,
    });
  }

  Future<void> _renameCategoryInDatabase(
      String oldCategory, String newCategory) async {
    User? currentUser = await _getCurrentUser();
    if (currentUser == null) return;

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Category')
        .where('categoryName', isEqualTo: oldCategory)
        .where('userID', isEqualTo: currentUser.uid)
        .get();

    if (snapshot.docs.isNotEmpty) {
      DocumentReference categoryRef = snapshot.docs.first.reference;
      await categoryRef.update({'categoryName': newCategory});
    }
  }

  Future<void> _deleteCategoryFromDatabase(String categoryName) async {
    User? currentUser = await _getCurrentUser();
    if (currentUser == null) return;

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Category')
        .where('categoryName', isEqualTo: categoryName)
        .where('userID', isEqualTo: currentUser.uid)
        .get();

    if (snapshot.docs.isNotEmpty) {
      List<dynamic> taskIDs = snapshot.docs.first['taskIDs'];

      if (taskIDs.isNotEmpty) {
        bool confirmDelete =
            await _showCategoryDeleteConfirmation(categoryName, taskIDs.length);

        if (!confirmDelete) {
          return;
        }

        for (var taskId in taskIDs) {
          await FirebaseFirestore.instance
              .collection('Task')
              .doc(taskId)
              .update({
            'category': '',
          });
        }
      }

      await snapshot.docs.first.reference.delete();
      _showTopNotification('Category "$categoryName" deleted successfully');
    }
  }

  Future<bool> _showCategoryDeleteConfirmation(
      String categoryName, int taskCount) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: lightGray,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                'Delete Category?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkGray,
                ),
              ),
              content: Text(
                'The category "$categoryName" is assigned to $taskCount tasks. '
                'Deleting this category will remove it from all those tasks. '
                'Do you still want to proceed?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: darkGray,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: mediumBlue,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text(
                    'Delete',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _pickDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1990),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: darkBlue,
            colorScheme: ColorScheme.light(
              primary: darkBlue,
              onPrimary: Color(0xFFF5F7F8),
              surface: Color(0xFFF5F7F8),
              onSurface: darkGray,
              secondary: lightBlue,
            ),
            dialogBackgroundColor: Color(0xFFF5F7F8),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
        formattedDate = DateFormat('MMM dd, yyyy').format(selectedDate);
      });
    }
  }

  Widget _buildPrioritySection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
        ),
        Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
          ),
          child: ExpansionTile(
            leading: Icon(Icons.flag, color: priorityIconColor),
            title: Text(
              'Priority',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                fontSize: 16,
                color: darkGray,
              ),
            ),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _priorityFlag('Urgent', Colors.red),
                  _priorityFlag('High', Colors.orange),
                  _priorityFlag('Normal', Colors.blue),
                  _priorityFlag('Low', Colors.grey),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
        ),
      ],
    );
  }

  Widget _priorityFlag(String label, Color color) {
    return Column(
      children: [
        IconButton(
          icon: Icon(Icons.flag, color: color),
          onPressed: () {
            setState(() {
              selectedPriority = label;
              priorityIconColor = color;

              // Preselect reminder based on priority
              _preselectReminderBasedOnPriority(label);
            });
          },
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: darkGray,
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(Icons.calendar_today,
              color: _isDateMissing
                  ? const Color.fromARGB(255, 164, 24, 14)
                  : Color(0xFF3B7292)),
          title: Text(
            'Date *',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: _isDateMissing
                  ? const Color.fromARGB(255, 164, 24, 14)
                  : darkGray,
            ),
          ),
          trailing: Text(
            formattedDate,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: _isDateMissing
                  ? const Color.fromARGB(255, 164, 24, 14)
                  : darkGray,
            ),
          ),
          onTap: () => _pickDate(context),
        ),
        SizedBox(height: 16),
        ListTile(
          leading: Icon(Icons.access_time,
              color: _isTimeMissing
                  ? const Color.fromARGB(255, 164, 24, 14)
                  : Color(0xFF3B7292)),
          title: Text(
            'Time *',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: _isTimeMissing
                  ? const Color.fromARGB(255, 164, 24, 14)
                  : darkGray,
            ),
          ),
          trailing: Text(
            formattedTime,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: _isTimeMissing
                  ? const Color.fromARGB(255, 164, 24, 14)
                  : darkGray,
            ),
          ),
          onTap: () => _pickTime(context),
        ),
      ],
    );
  }

  bool isReminderOn = false;
  List<Map<String, dynamic>> reminderOptions = [
    {"label": "1 day before", "duration": Duration(days: 1)},
    {"label": "3 hours before", "duration": Duration(hours: 3)},
    {"label": "1 hour before", "duration": Duration(hours: 1)},
    {"label": "30 minutes before", "duration": Duration(minutes: 30)},
    {"label": "10 minutes before", "duration": Duration(minutes: 10)},
    {"label": "Custom Time", "duration": null},
  ];
  Map<String, dynamic>? selectedReminderOption;
  DateTime? customReminderDateTime;

  Widget _buildTimerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timer Section
        ListTile(
          leading: Icon(Icons.timer, color: Color(0xFF3B7292)),
          title: Text(
            'Set Timer',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: darkGray,
            ),
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildReminderSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications, color: mediumBlue),
                  SizedBox(width: 8),
                  Text(
                    'Reminder',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      color: darkGray,
                    ),
                  ),
                ],
              ),
              Switch(
                value: isReminderOn,
                onChanged: (value) {
                  setState(() {
                    isReminderOn = value;
                    if (!isReminderOn) {
                      selectedReminderOption = null;
                      customReminderDateTime = null;
                    }
                  });
                },
                activeColor: mediumBlue, // Thumb color when switch is ON
                activeTrackColor: lightBlue, // Track color when switch is ON
                inactiveThumbColor: const Color.fromARGB(
                    255, 172, 172, 172), // Thumb color when switch is OFF
                inactiveTrackColor:
                    Colors.grey[350], // Track color when switch is OFF
              ),
            ],
          ),
          if (isReminderOn)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: DropdownButtonFormField<Map<String, dynamic>>(
                value: selectedReminderOption,
                isExpanded: true,
                items: reminderOptions.map((option) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: option,
                    child: Text(
                      option['label'],
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: darkGray,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedReminderOption = value;
                    if (value?['label'] == "Custom Time") {
                      _pickCustomReminderTime();
                    }
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: lightestBlue),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                hint: Text(
                  "Select a reminder time",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: darkGray,
                  ),
                ),
                dropdownColor: const Color.fromARGB(255, 245, 245, 245),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: darkGray,
                ),
                iconEnabledColor: mediumBlue,
              ),
            ),
          if (selectedReminderOption != null &&
              selectedReminderOption!['label'] == "Custom Time" &&
              customReminderDateTime != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "Custom Reminder: ${DateFormat('MMM dd, yyyy - hh:mm a').format(customReminderDateTime!)}",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: darkGray,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _pickCustomReminderTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: selectedDate,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: darkBlue,
            colorScheme: ColorScheme.light(
              primary: darkBlue,
              onPrimary: Color(0xFFF5F7F8),
              surface: Color(0xFFF5F7F8),
              onSurface: darkGray,
              secondary: lightBlue,
            ),
            dialogBackgroundColor: Color(0xFFF5F7F8),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              primaryColor: darkBlue,
              colorScheme: ColorScheme.light(
                primary: darkBlue,
                onPrimary: Color(0xFFF5F7F8),
                surface: Color(0xFFF5F7F8),
                onSurface: darkGray,
                secondary: lightBlue,
              ),
              dialogBackgroundColor: Color(0xFFF5F7F8),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        DateTime selectedReminder = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        DateTime taskDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        if (selectedReminder.isAfter(taskDateTime)) {
          _showTopNotification(
              "Custom reminder time cannot be after the scheduled task time. Please select a valid time.");
          setState(() {
            customReminderDateTime = null; // Reset invalid time
          });
        } else {
          setState(() {
            customReminderDateTime = selectedReminder;
          });
        }
      }
    }
  }

  void _preselectReminderBasedOnPriority(String priority) {
    setState(() {
      switch (priority) {
        case 'Urgent':
          selectedReminderOption = reminderOptions.firstWhere(
              (option) => option['label'] == "10 minutes before",
              orElse: () =>
                  reminderOptions.first); // Default to the first option
          break;
        case 'High':
          selectedReminderOption = reminderOptions.firstWhere(
              (option) => option['label'] == "30 minutes before",
              orElse: () => reminderOptions.first);
          break;
        case 'Normal':
          selectedReminderOption = reminderOptions.firstWhere(
              (option) => option['label'] == "1 day before",
              orElse: () => reminderOptions.first);
          break;
        case 'Low':
          selectedReminderOption = reminderOptions.firstWhere(
              (option) => option['label'] == "1 day before",
              orElse: () => reminderOptions.first);
          break;
        default:
          selectedReminderOption =
              reminderOptions.first; // Default to the first option
      }
    });
  }

  Map<String, Map<String, dynamic>?> subtaskReminders = {};

  void _pickSubtaskReminderTime(String subtask) async {
    bool isReminderOn = subtaskReminders[subtask] != null;
    Map<String, dynamic>? selectedOption = subtaskReminders[subtask];

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            // Filter options to prevent duplicate "Custom Time"
            List<Map<String, dynamic>> filteredOptions = reminderOptions
                .where((option) => option['label'] != "Custom Time")
                .toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              backgroundColor: lightGray,
              title: Row(
                children: [
                  Icon(Icons.notifications, color: mediumBlue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Set Reminder for "$subtask"',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: darkGray,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Toggle switch for reminder On/Off
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Reminder On/Off",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: darkGray,
                          ),
                        ),
                        Switch(
                          value: isReminderOn,
                          onChanged: (value) {
                            setState(() {
                              isReminderOn = value;
                              if (!isReminderOn) {
                                selectedOption =
                                    null; // Clear reminder settings
                              }
                            });
                          },
                          activeColor: mediumBlue,
                          activeTrackColor: lightBlue,
                          inactiveThumbColor: Colors.grey,
                          inactiveTrackColor: Colors.grey[350],
                        ),
                      ],
                    ),
                    // Show predefined options if reminder is on
                    if (isReminderOn)
                      ...filteredOptions.map((option) {
                        bool isSelected = selectedOption != null &&
                            selectedOption?['duration'] == option['duration'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedOption = {
                                'duration': option['duration'],
                                'customDateTime': null,
                              };
                            });
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 8),
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? mediumBlue.withOpacity(0.2)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, color: mediumBlue),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    option['label'],
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: darkGray,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    // Custom Time option handled separately
                    if (isReminderOn)
                      GestureDetector(
                        onTap: () async {
                          final customTime =
                              await _pickCustomSubtaskReminderTime(subtask);
                          if (customTime != null) {
                            setState(() {
                              selectedOption = {
                                'duration': null,
                                'customDateTime': customTime,
                              };
                            });
                          }
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: selectedOption?['customDateTime'] != null
                                ? mediumBlue.withOpacity(0.2)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: mediumBlue),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Custom Time",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: darkGray,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      subtaskReminders[subtask] =
                          isReminderOn ? selectedOption : null;
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: mediumBlue,
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

  Future<DateTime?> _pickCustomSubtaskReminderTime(String subtask) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: selectedDate,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: darkBlue,
              onPrimary: Color(0xFFF5F7F8),
              surface: Color(0xFFF5F7F8),
              onSurface: darkGray,
              secondary: lightBlue,
            ),
            dialogBackgroundColor: Color(0xFFF5F7F8),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: darkBlue,
                onPrimary: Color(0xFFF5F7F8),
                onSurface: darkGray,
                secondary: lightBlue,
              ),
              dialogBackgroundColor: Color(0xFFF5F7F8),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final DateTime customTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        if (customTime.isAfter(DateTime.now())) {
          return customTime;
        } else {
          _showTopNotification(
              "Custom reminder time must be in the future. Please select a valid time.");
        }
      }
    }
    return null;
  }

  void _addSubtask(String text) {
    if (text.isNotEmpty) {
      setState(() {
        subtasks.add(text);
        subtaskController.clear();
      });
    }
  }
}
//Future<void> _saveCategoryAndLinkToTask(
//     String categoryName, DocumentReference taskRef) async {
//   try {
//     User? currentUser = await _getCurrentUser();
//     if (currentUser == null) return;

//     QuerySnapshot querySnapshot = await FirebaseFirestore.instance
//         .collection('Category')
//         .where('categoryName', isEqualTo: categoryName)
//         .where('userID', isEqualTo: currentUser.uid)
//         .get();

//     if (querySnapshot.docs.isNotEmpty) {
//       DocumentReference categoryRef = querySnapshot.docs.first.reference;

//       await categoryRef.update({
//         'taskIDs': FieldValue.arrayUnion([taskRef.id])
//       });
//     } else {
//       DocumentReference categoryRef =
//           FirebaseFirestore.instance.collection('Category').doc();
//       await categoryRef.set({
//         'categoryName': categoryName,
//         'userID': currentUser.uid,
//         'taskIDs': [taskRef.id],
//       });
//     }
//   } catch (e) {
//     _showTopNotification('Failed to save category or link to task: $e');
//   }
// }
