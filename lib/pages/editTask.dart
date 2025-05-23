import 'package:flutter/material.dart';
import 'package:flutter_application/services/notification_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_application/Classes/Task';
import 'package:flutter_application/Classes/SubTask';

class EditTaskPage extends StatefulWidget {
  final String taskId;

  EditTaskPage({required this.taskId});

  @override
  _EditTaskPageState createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
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
  String? userID;

  List<String> categories = [];
  List<String> hardcodedCategories = [];
  List<String> deletedSubtasks = [];

  List<String> subtasks = [];
  TextEditingController subtaskController = TextEditingController();
  TextEditingController taskNameController = TextEditingController();
  TextEditingController notesController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  Map<String, TextEditingController> subtaskControllers = {};
  bool isEditingCategory = false;
  bool _isTitleMissing = false;
  bool _isDateMissing = false;
  bool _isTimeMissing = false;

  bool isReminderOn = false;
  List<Map<String, dynamic>> reminderOptions = [
    {"id": 1, "label": "1 day before", "duration": Duration(days: 1)},
    {"id": 2, "label": "3 hours before", "duration": Duration(hours: 3)},
    {"id": 3, "label": "1 hour before", "duration": Duration(hours: 1)},
    {"id": 4, "label": "30 minutes before", "duration": Duration(minutes: 30)},
    {"id": 5, "label": "10 minutes before", "duration": Duration(minutes: 10)},
    {"id": 6, "label": "Custom Time", "duration": null},
  ];

  Map<String, dynamic>? selectedReminderOption;
  DateTime? customReminderDateTime;

  Map<String, bool> subtaskCompletionStatus = {};
  double progress = 0.0; // Current progress (0.0 to 1.0)

  Color darkBlue = Color(0xFF104A73);
  Color mediumBlue = Color(0xFF3B7292);
  Color lightBlue = Color(0xFF79A3B7);
  Color lightestBlue = Color(0xFFC7D9E1);
  Color lightGray = Color(0xFFF5F7F8);
  Color darkGray = Color(0xFF545454);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int userPoints = 0;
  int userLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadTaskDetails();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      userID = user?.uid; // Set the user ID if logged in, otherwise null
    });
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
      print('Failed to fetch categories: $e');
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

  Future<void> _loadTaskDetails() async {
    try {
      await _getCategories();

      DocumentSnapshot taskSnapshot = await FirebaseFirestore.instance
          .collection('Task')
          .doc(widget.taskId)
          .get();

      if (taskSnapshot.exists) {
        var taskData = taskSnapshot.data() as Map<String, dynamic>;

        setState(() {
          taskNameController.text = taskData['title'] ?? '';
          notesController.text = taskData['note'] ?? '';
          selectedPriority = _getPriorityLabel(taskData['priority']);
          priorityIconColor = _getPriorityColor(selectedPriority!);
          formattedDate = DateFormat('MMM dd, yyyy')
              .format(taskData['scheduledDate'].toDate());
          selectedDate = taskData['scheduledDate'].toDate();
          formattedTime =
              TimeOfDay.fromDateTime(taskData['scheduledDate'].toDate())
                  .format(context);
          selectedTime =
              TimeOfDay.fromDateTime(taskData['scheduledDate'].toDate());
          // Load reminder details
          final DateTime taskDateTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );

          if (taskData['reminder'] != null) {
            isReminderOn = true;
            final reminderDate = taskData['reminder'].toDate();

            // Check if the reminder matches a predefined option
            selectedReminderOption = reminderOptions.firstWhere(
              (option) =>
                  option['duration'] != null &&
                  taskDateTime.subtract(option['duration']) == reminderDate,
              orElse: () {
                // If no predefined option matches, it's a custom reminder
                customReminderDateTime = reminderDate;
                return {"label": "Custom Time", "duration": null};
              },
            );
          }
        });

        QuerySnapshot categorySnapshot = await FirebaseFirestore.instance
            .collection('Category')
            .where('taskIDs', arrayContains: widget.taskId)
            .get();

        if (categorySnapshot.docs.isNotEmpty) {
          String taskCategory = categorySnapshot.docs.first['categoryName'];

          setState(() {
            selectedCategory = taskCategory;
          });
        }

        QuerySnapshot subtaskSnapshot = await FirebaseFirestore.instance
            .collection('SubTask')
            .where('taskID', isEqualTo: widget.taskId)
            .get();

        List<String> fetchedSubtasks = [];
        subtaskCompletionStatus
            .clear(); // Clear the existing map to avoid duplication

        for (var doc in subtaskSnapshot.docs) {
          var subtaskData = doc.data() as Map<String, dynamic>;
          String subtaskTitle = subtaskData['title'];
          bool isCompleted =
              subtaskData['completionStatus'] == 1; // Use Firestore data

          fetchedSubtasks.add(subtaskTitle);
          subtaskCompletionStatus[subtaskTitle] =
              isCompleted; // Populate the map

          subtaskControllers[subtaskTitle] =
              TextEditingController(text: subtaskTitle);

          // Load reminder data
          if (subtaskData['reminder'] != null) {
            DateTime reminderDate = subtaskData['reminder'].toDate();
            DateTime taskDateTime = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              selectedTime.hour,
              selectedTime.minute,
            );

            // Determine if the reminder matches a predefined option or is custom
            subtaskReminders[subtaskTitle] = reminderOptions.firstWhere(
              (option) =>
                  option['duration'] != null &&
                  taskDateTime.subtract(option['duration']) == reminderDate,
              orElse: () => {
                'duration': null,
                'customDateTime': reminderDate,
              },
            );
          } else {
            subtaskReminders[subtaskTitle] = null;
          }
        }
        ;

        setState(() {
          subtasks = fetchedSubtasks;
          _updateProgress();
          if (progress == 1.0) {
            FirebaseFirestore.instance
                .collection('Task')
                .doc(widget.taskId)
                .update({'completionStatus': 2});
          } else if (progress > 0.0) {
            FirebaseFirestore.instance
                .collection('Task')
                .doc(widget.taskId)
                .update({'completionStatus': 1});
          } else {
            FirebaseFirestore.instance
                .collection('Task')
                .doc(widget.taskId)
                .update({'completionStatus': 0});
          }
        });
      }
    } catch (e) {
      print('Failed to load task details: $e');
    }
  }

  Future<void> _saveChangesToFirebase() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final DateTime taskDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      // Validate Task Time
      if (taskDateTime.isBefore(DateTime.now())) {
        _showTopNotification(
          'Scheduled date and time must be in the future.',
        );
        return;
      }

      // Check for Duplicate Tasks
      Timestamp taskTimestamp = Timestamp.fromDate(taskDateTime);
      QuerySnapshot existingTaskSnapshot = await FirebaseFirestore.instance
          .collection('Task')
          .where('userID', isEqualTo: currentUser.uid)
          .where('scheduledDate', isEqualTo: taskTimestamp)
          .where(FieldPath.documentId, isNotEqualTo: widget.taskId)
          .get();

      if (existingTaskSnapshot.docs.isNotEmpty) {
        _showTopNotification(
          'Another task already exists with the same date and time. Please choose a different time.',
        );
        return;
      }

      // Validate Task Reminder
      DateTime? reminderDateTime = _validateReminder(
        isReminderOn,
        taskDateTime,
        selectedReminderOption,
        customReminderDateTime,
      );
      if (reminderDateTime == null && isReminderOn) {
        return; // Invalid reminder
      }

      // Update Main Task in Firestore
      await FirebaseFirestore.instance
          .collection('Task')
          .doc(widget.taskId)
          .update({
        'title': taskNameController.text,
        'note': notesController.text,
        'priority': _getPriorityValue(),
        'scheduledDate': taskTimestamp,
        'reminder': reminderDateTime != null
            ? Timestamp.fromDate(reminderDateTime)
            : null,
      });

      // Schedule or Cancel Notification for Main Task
      if (isReminderOn && reminderDateTime != null) {
        await NotificationHandler.cancelNotification(widget.taskId);
        await _scheduleTaskNotification(
          taskId: widget.taskId,
          taskTitle: taskNameController.text,
          scheduledDateTime: reminderDateTime,
        );
      } else {
        await NotificationHandler.cancelNotification(widget.taskId);
      }

      // Handle Category Updates
      await _handleCategoryChanges();

      // Handle Subtask Updates
      await _updateSubtasks(taskDateTime);

      // Notify Success
      _showTopNotification('Task updated successfully!');
      deletedSubtasks.clear();
    } catch (e) {
      print('Failed to update task: $e');
      _showTopNotification('Failed to update task. Please try again.');
    }
  }

  Future<void> _updateSubtasks(DateTime taskDateTime) async {
    // Delete removed subtasks
    for (String deletedSubtask in deletedSubtasks) {
      QuerySnapshot subtaskSnapshot = await FirebaseFirestore.instance
          .collection('SubTask')
          .where('taskID', isEqualTo: widget.taskId)
          .where('title', isEqualTo: deletedSubtask)
          .get();

      for (var doc in subtaskSnapshot.docs) {
        await doc.reference.delete();
        await NotificationHandler.cancelNotification(
            doc.id); // Cancel notification
      }
    }

    // Add or Update existing subtasks
    for (String subtask in subtasks) {
      final subtaskTitle = subtaskControllers[subtask]?.text ?? subtask;

      QuerySnapshot subtaskSnapshot = await FirebaseFirestore.instance
          .collection('SubTask')
          .where('taskID', isEqualTo: widget.taskId)
          .where('title', isEqualTo: subtask)
          .get();

      DateTime? subtaskReminderDateTime = _validateSubtaskReminder(
        subtask,
        subtaskReminders[subtask],
        taskDateTime,
      );

      if (subtaskSnapshot.docs.isNotEmpty) {
        // Update existing subtask
        DocumentReference subtaskRef = subtaskSnapshot.docs.first.reference;

        await subtaskRef.update({
          'title': subtaskTitle,
          'reminder': subtaskReminderDateTime != null
              ? Timestamp.fromDate(subtaskReminderDateTime)
              : null,
        });

        // Update Notification for Subtask
        if (subtaskReminderDateTime != null) {
          await _scheduleTaskNotification(
            taskId: subtaskRef.id,
            taskTitle: subtaskTitle,
            scheduledDateTime: subtaskReminderDateTime,
          );
        } else {
          await NotificationHandler.cancelNotification(subtaskRef.id);
        }
      } else {
        // Create new subtask
        DocumentReference newSubtaskRef =
            FirebaseFirestore.instance.collection('SubTask').doc();

        await newSubtaskRef.set({
          'completionStatus': 0,
          'taskID': widget.taskId,
          'timer': '',
          'title': subtaskTitle,
          'reminder': subtaskReminderDateTime != null
              ? Timestamp.fromDate(subtaskReminderDateTime)
              : null,
        });

        // Schedule Notification for New Subtask
        if (subtaskReminderDateTime != null) {
          await _scheduleTaskNotification(
            taskId: newSubtaskRef.id,
            taskTitle: subtaskTitle,
            scheduledDateTime: subtaskReminderDateTime,
          );
        }
      }
    }
  }

  DateTime? _validateReminder(bool isReminderOn, DateTime taskDateTime,
      Map<String, dynamic>? selectedOption, DateTime? customReminder) {
    if (!isReminderOn) return null;

    DateTime? reminderDateTime;
    if (selectedOption?['duration'] != null) {
      reminderDateTime = taskDateTime.subtract(selectedOption!['duration']);
    } else if (customReminder != null) {
      reminderDateTime = customReminder;
    }

    if (reminderDateTime != null && reminderDateTime.isBefore(DateTime.now())) {
      _showTopNotification("Reminder time must be in the future.");
      return null;
    }

    return reminderDateTime;
  }

  DateTime? _validateSubtaskReminder(String subtask,
      Map<String, dynamic>? reminderData, DateTime taskDateTime) {
    if (reminderData == null) return null;

    DateTime? reminderDateTime;
    if (reminderData['customDateTime'] != null) {
      reminderDateTime = reminderData['customDateTime'];
    } else if (reminderData['duration'] != null) {
      reminderDateTime = taskDateTime.subtract(reminderData['duration']);
    }

    if (reminderDateTime != null && reminderDateTime.isBefore(DateTime.now())) {
      _showTopNotification(
        "Reminder for subtask '$subtask' is in the past. Please update it.",
      );
      return null;
    }

    return reminderDateTime;
  }

  Future<void> _handleCategoryChanges() async {
    if (selectedCategory.isEmpty) return;

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Remove task from any old category
      QuerySnapshot oldCategorySnapshot = await FirebaseFirestore.instance
          .collection('Category')
          .where('taskIDs', arrayContains: widget.taskId)
          .where('userID', isEqualTo: currentUser.uid)
          .get();

      for (var oldCategoryDoc in oldCategorySnapshot.docs) {
        await oldCategoryDoc.reference.update({
          'taskIDs': FieldValue.arrayRemove([widget.taskId])
        });
      }

      // Add task to the selected category
      QuerySnapshot newCategorySnapshot = await FirebaseFirestore.instance
          .collection('Category')
          .where('categoryName', isEqualTo: selectedCategory)
          .where('userID', isEqualTo: currentUser.uid)
          .get();

      if (newCategorySnapshot.docs.isNotEmpty) {
        await newCategorySnapshot.docs.first.reference.update({
          'taskIDs': FieldValue.arrayUnion([widget.taskId])
        });
      } else {
        // If the category does not exist, create it
        await FirebaseFirestore.instance.collection('Category').add({
          'categoryName': selectedCategory,
          'userID': currentUser.uid,
          'taskIDs': [widget.taskId],
        });
      }
    } catch (e) {
      print('Failed to handle category changes: $e');
    }
  }

  Future<void> _deleteTask() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await NotificationHandler.cancelNotification(widget.taskId);
      await NotificationHandler.debugPendingNotifications();
      // Delete subtasks
      QuerySnapshot subtaskSnapshot = await FirebaseFirestore.instance
          .collection('SubTask')
          .where('taskID', isEqualTo: widget.taskId)
          .get();

      for (var subtaskDoc in subtaskSnapshot.docs) {
        print(
            "Attempting to cancel notification for subtask ID: ${subtaskDoc.id}");
        await NotificationHandler.cancelNotification(subtaskDoc.id);
        print("Deleting subtask: ${subtaskDoc.id}");
        await subtaskDoc.reference.delete();
      }

      // Debugging: Check pending notifications
      final List<PendingNotificationRequest> pendingNotificationRequests =
          await flutterLocalNotificationsPlugin.pendingNotificationRequests();

      for (var pendingNotification in pendingNotificationRequests) {
        print('Pending Notification ID: ${pendingNotification.id}');
      }

      // Remove the task from categories
      QuerySnapshot categorySnapshot = await FirebaseFirestore.instance
          .collection('Category')
          .where('taskIDs', arrayContains: widget.taskId)
          .where('userID', isEqualTo: currentUser.uid)
          .get();

      if (categorySnapshot.docs.isNotEmpty) {
        DocumentReference categoryRef = categorySnapshot.docs.first.reference;
        await categoryRef.update({
          'taskIDs': FieldValue.arrayRemove([widget.taskId])
        });
      }

      // Delete the task
      await FirebaseFirestore.instance
          .collection('Task')
          .doc(widget.taskId)
          .delete();

      _showTopNotification('Task deleted successfully!');
      // Pop back to the TaskPage
      Navigator.pop(
          context, true); // Passing true to indicate successful deletion
    } catch (e) {
      print('Failed to delete task and subtasks: $e');
      _showTopNotification('Failed to delete task. Please try again.');
    }
  }

  String _getPriorityLabel(int priorityValue) {
    switch (priorityValue) {
      case 4:
        return 'Urgent';
      case 3:
        return 'High';
      case 2:
        return 'Normal';
      case 1:
        return 'Low';
      default:
        return 'Normal';
    }
  }

  Color _getPriorityColor(String priorityLabel) {
    switch (priorityLabel) {
      case 'Urgent':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Normal':
        return Colors.blue;
      case 'Low':
        return Colors.grey;
      default:
        return Colors.blue;
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

  Future<void> _validateAndSaveTask() async {
    setState(() {
      _isTitleMissing = taskNameController.text.isEmpty;
      _isDateMissing = formattedDate == 'Select Date';
      _isTimeMissing = formattedTime == 'Select Time';
    });

    if (!_isTitleMissing && !_isDateMissing && !_isTimeMissing) {
      try {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw Exception("No current user is logged in.");
        }

        // Create the full DateTime object using the selected date and time
        final DateTime taskDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        // Convert it to Firebase Timestamp
        Timestamp taskTimestamp = Timestamp.fromDate(taskDateTime);

        // Check for existing tasks with the same date and time
        QuerySnapshot existingTaskSnapshot = await FirebaseFirestore.instance
            .collection('Task')
            .where('userID', isEqualTo: currentUser.uid)
            .where('scheduledDate', isEqualTo: taskTimestamp)
            .where(FieldPath.documentId, isNotEqualTo: widget.taskId)
            .get();

        if (existingTaskSnapshot.docs.isNotEmpty) {
          throw Exception(
              'Another task already exists with the same date and time. Please choose a different time.');
        }

        // Validate reminder
        DateTime? reminderDateTime = _validateReminder(
          isReminderOn,
          taskDateTime,
          selectedReminderOption,
          customReminderDateTime,
        );
        if (isReminderOn && reminderDateTime == null) {
          throw Exception("Please choose a reminder time that is in the future.");
        }

        // Save changes to Firebase
        await _saveChangesToFirebase();

        // Show success message only if everything is successful
        _showTopNotification('Task updated successfully!');
        Navigator.pop(context, true); // Returning true to indicate success
      } catch (e) {
        // Log and show error messages for failures
        print('Error updating task: $e');
        _showTopNotification('Failed to update task: $e');
      }
    } else {
      _showTopNotification('Please fill in all mandatory fields.');
    }
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
              color: Colors.black,
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

  void _updateProgress() {
    if (subtasks.isEmpty) {
      progress = 0.0; // No progress for tasks without subtasks
    } else {
      int completedSubtasks =
          subtaskCompletionStatus.values.where((completed) => completed).length;
      progress = completedSubtasks / subtasks.length;
    }
  }

  void _toggleSubtaskCompletion(String subtask) async {
    bool isSubtaskComplete = !(subtaskCompletionStatus[subtask] ?? false);
    DateTime? completionDate = isSubtaskComplete ? DateTime.now() : null;

    setState(() {
      subtaskCompletionStatus[subtask] = isSubtaskComplete;

      // Update progress based on completed subtasks
      int completedSubtasks =
          subtaskCompletionStatus.values.where((status) => status).length;
      progress =
          subtasks.isNotEmpty ? completedSubtasks / subtasks.length : 0.0;
    });

    FirebaseFirestore firestore = FirebaseFirestore.instance;

    QuerySnapshot subtaskSnapshot = await firestore
        .collection('SubTask')
        .where('taskID', isEqualTo: widget.taskId)
        .where('title', isEqualTo: subtask)
        .get();

    for (var doc in subtaskSnapshot.docs) {
      SubTask subTask = SubTask(
        subTaskID: doc.id,
        taskID: widget.taskId,
        title: subtask,
        completionStatus: isSubtaskComplete ? 1 : 0,
      );

      // ✅ Update Firestore: Assign/Remove completion date
      await firestore.collection('SubTask').doc(subTask.subTaskID).update({
        'completionStatus': isSubtaskComplete ? 1 : 0,
        'completionDate': isSubtaskComplete
            ? Timestamp.fromDate(completionDate!)
            : FieldValue.delete(), // Remove date if uncompleted
      });

      // ✅ Apply points based on subtask state
      Task task = Task(
        taskID: widget.taskId,
        title: taskNameController.text,
        scheduledDate: selectedDate,
        priority: _getPriorityValue(),
        reminder: [],
        timer: DateTime.now(),
        note: notesController.text,
        completionStatus: progress == 1.0 ? 2 : 1,
        userID: FirebaseAuth.instance.currentUser!.uid,
      );

      if (isSubtaskComplete) {
        await assignSubtaskPoints(task, subTask);
      } else {
        await subtractSubtaskPoints(task, subTask);
      }

      // ✅ Ensure level updates
      await updateLevel();
    }

    // ✅ Check if all subtasks are completed
    QuerySnapshot allSubtasksSnapshot = await firestore
        .collection('SubTask')
        .where('taskID', isEqualTo: widget.taskId)
        .get();

    bool allSubtasksComplete = allSubtasksSnapshot.docs.every((doc) {
      var data = doc.data() as Map<String, dynamic>?;
      return data != null && data['completionStatus'] == 1;
    });

    // ✅ Update task status based on progress
    int taskStatus = progress == 1.0 ? 2 : (progress > 0.0 ? 1 : 0);

    await firestore.collection('Task').doc(widget.taskId).update({
      'completionStatus': taskStatus,
      if (taskStatus == 2)
        'completionDate': Timestamp.fromDate(completionDate!),
    });

    // ✅ Assign task points if all subtasks are complete
    if (allSubtasksComplete) {
      print("🎯 All subtasks are completed! Assigning Task Points...");
      Task task = Task(
        taskID: widget.taskId,
        title: taskNameController.text,
        scheduledDate: selectedDate,
        priority: _getPriorityValue(),
        reminder: [],
        timer: DateTime.now(),
        note: notesController.text,
        completionStatus: 2,
        userID: FirebaseAuth.instance.currentUser!.uid,
      );

      await assignTaskPoints(task);
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

  bool _isReminderValid(DateTime reminderDateTime, String itemName) {
    if (reminderDateTime.isBefore(DateTime.now())) {
      _showTopNotification(
          "Reminder date for '$itemName' is in the past. Please select a future date.");
      return false;
    }
    return true;
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
    print(
        "Scheduling notification for taskId: $taskId, title: $taskTitle, at: $scheduledDateTime");

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
        'Reminder for your task scheduled at $scheduledDateTime',
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
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool shouldLeave = await _showExitConfirmationDialog();
        return shouldLeave;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Color(0xFFEAEFF0),
          elevation: 0,
          centerTitle: true, // لضبط العنوان في المنتصف

          title: Center(
            child: Text(
              'Edit Task',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(30.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressBar(),
                SizedBox(height: 12),
                _buildTaskTitleSection(),
                SizedBox(height: 20),
                _buildSubtaskSection(),
                SizedBox(height: 20),
                _buildCategorySection(),
                SizedBox(height: 20),
                _buildDateTimePicker(),
                SizedBox(height: 20),
                _buildPrioritySection(),
                SizedBox(height: 30),
                _buildReminderSection(),
                SizedBox(height: 20),
                _buildNotesSection(),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: showDeleteConfirmationDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: Size(160, 50), // Set width and height
                      ),
                      child: Text(
                        'Delete Task',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _validateAndSaveTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mediumBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: Size(160, 50), // Set width and height
                      ),
                      child: Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: lightGray,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),

              title: Text(
                'Unsaved Changes',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkGray,
                ),
              ),
              content: Text(
                'Are you sure you want to leave? Your changes won’t be saved.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: darkGray,
                ),
              ),
              actionsPadding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              actionsAlignment:
                  MainAxisAlignment.end, // Aligns buttons to the right
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Color(0xFF79A3B7)),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF79A3B7),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text(
                    'Leave',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: const Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Widget _buildTaskTitleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: lightestBlue),
          color: Colors.white,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () async {
                bool isTaskComplete = progress < 1.0; // Toggle task completion
                DateTime? completionDate =
                    isTaskComplete ? DateTime.now() : null;

                setState(() {
                  // Update all subtasks' completion statuses
                  subtaskCompletionStatus.updateAll((key, _) => isTaskComplete);
                  progress = isTaskComplete ? 1.0 : 0.0;
                });

                // ✅ Update task completion status & completion date
                int taskStatus = isTaskComplete ? 2 : 0;
                Task task = Task(
                  taskID: widget.taskId,
                  title: taskNameController.text,
                  scheduledDate: selectedDate,
                  priority: _getPriorityValue(),
                  reminder: [],
                  timer: DateTime.now(),
                  note: notesController.text,
                  completionStatus: taskStatus,
                  userID: FirebaseAuth.instance.currentUser!.uid,
                );

                await FirebaseFirestore.instance
                    .collection('Task')
                    .doc(widget.taskId)
                    .update({
                  'completionStatus': taskStatus,
                  'completionDate': isTaskComplete
                      ? Timestamp.fromDate(completionDate!)
                      : FieldValue.delete(), // Remove date if uncompleted
                });

                // ✅ Apply points based on completion state
                if (isTaskComplete) {
                  await assignTaskPoints(task);
                } else {
                  await subtractTaskPoints(task);
                }

                // Update all subtasks in Firestore
                QuerySnapshot subtaskSnapshot = await FirebaseFirestore.instance
                    .collection('SubTask')
                    .where('taskID', isEqualTo: widget.taskId)
                    .get();

                for (var doc in subtaskSnapshot.docs) {
                  SubTask subTask = SubTask(
                    subTaskID: doc.id,
                    taskID: widget.taskId,
                    title: doc['title'],
                    completionStatus: isTaskComplete ? 1 : 0,
                  );

                  await FirebaseFirestore.instance
                      .collection('SubTask')
                      .doc(subTask.subTaskID)
                      .update({
                    'completionStatus': isTaskComplete ? 1 : 0,
                    'completionDate': isTaskComplete
                        ? Timestamp.fromDate(completionDate!)
                        : FieldValue.delete(), // Remove date if uncompleted
                  });
                }

                // ✅ Ensure level updates
                await updateLevel();
              },
              child: Container(
                width: 24.0,
                height: 24.0,
                margin: EdgeInsets.only(
                    right: 12), // Spacing between checkbox and input field
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: progress == 1.0 ? Colors.grey : mediumBlue,
                    width: 4.0,
                  ),
                  color: progress == 1.0 ? Colors.grey : Colors.white,
                ),
                child: progress == 1.0
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            Expanded(
              child: TextField(
                controller: taskNameController,
                decoration: InputDecoration(
                  labelText: 'Task name *',
                  labelStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: darkGray,
                  ),
                  border: InputBorder.none, // Remove default border
                  errorText: _isTitleMissing ? 'Task Name is required' : null,
                ),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: darkGray,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Padding(
      padding: const EdgeInsets.only(left: 14.0),
      child: TextField(
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
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
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
              Icon(Icons.category, color: Color(0xFF3B7292)),
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
                onSelected: (bool selected) async {
                  if (selectedCategory == category) {
                    // Unselect and update Firestore
                    await _updateCategoryInFirestore(remove: true);
                    setState(() {
                      selectedCategory = ''; // Unselect category
                    });
                  } else {
                    // Switch to the new category and update Firestore
                    if (selectedCategory.isNotEmpty) {
                      // Remove from the previous category
                      await _updateCategoryInFirestore(remove: true);
                    }
                    setState(() {
                      selectedCategory = category; // Select the new category
                    });
                    await _updateCategoryInFirestore(remove: false);
                  }
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

    final scaffoldContext = context;

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
                              border: InputBorder.none, // No border
                              hintStyle: TextStyle(color: Colors.grey),
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
            //);
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
      await addCategory(category);
    }

    for (var renameMap in renamedCategories) {
      String oldName = renameMap['oldName']!;
      String newName = renameMap['newName']!;
      await updateCategory(oldName, newName);
    }

    for (String deletedCategory in deletedCategories) {
      await deleteCategory(deletedCategory);
    }

    await _getCategories();
  }

  Future<void> addCategory(String categoryName) async {
    User? currentUser = await _getCurrentUser();
    if (currentUser == null) return;

    try {
      // Check if the category already exists for the current user
      QuerySnapshot existingCategorySnapshot = await FirebaseFirestore.instance
          .collection('Category')
          .where('categoryName', isEqualTo: categoryName)
          .where('userID', isEqualTo: currentUser.uid)
          .get();

      if (existingCategorySnapshot.docs.isNotEmpty) {
        // Display a message if the category already exists
        _showTopNotification('Category "$categoryName" already exists.');
        return;
      }

      // If it doesn't exist, add the new category
      await FirebaseFirestore.instance.collection('Category').add({
        'categoryName': categoryName,
        'userID': currentUser.uid,
        'taskIDs': [],
      });

      _showTopNotification('Category "$categoryName" added successfully.');
    } catch (e) {
      _showTopNotification('Failed to add category: $e');
    }
  }

  Future<void> updateCategory(String oldCategory, String newCategory) async {
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

  Future<void> deleteCategory(String categoryName) async {
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

  Future<void> _updateCategoryInFirestore({required bool remove}) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || selectedCategory.isEmpty) return;

    try {
      QuerySnapshot categorySnapshot = await FirebaseFirestore.instance
          .collection('Category')
          .where('categoryName', isEqualTo: selectedCategory)
          .where('userID', isEqualTo: currentUser.uid)
          .get();

      if (categorySnapshot.docs.isNotEmpty) {
        DocumentReference categoryRef = categorySnapshot.docs.first.reference;

        if (remove) {
          // Remove the task ID from the category
          await categoryRef.update({
            'taskIDs': FieldValue.arrayRemove([widget.taskId])
          });
        } else {
          // Add the task ID to the category
          await categoryRef.update({
            'taskIDs': FieldValue.arrayUnion([widget.taskId])
          });
        }
      }
    } catch (e) {
      print('Failed to update category in Firestore: $e');
      _showTopNotification('Error updating category. Please try again.');
    }
  }

  void showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: lightGray, // Use the light gray as the background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const Text(
            'Are you sure you want to delete this task?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              // Match title text color with your dark gray
            ),
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
              onPressed: () {
                _deleteTask(); // Call the delete method
                Navigator.of(context).pop(); // Close dialog after deleting
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red, // Keep the red background for the Delete button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white, // White text on Delete button
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
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
                onChanged: (value) async {
                  setState(() {
                    isReminderOn = value;
                    if (!isReminderOn) {
                      selectedReminderOption = null;
                      customReminderDateTime = null;
                    }
                  });

                  if (!value) {
                    // Cancel reminder for the task when the switch is turned off
                    await NotificationHandler.cancelNotification(widget.taskId);

                    // Update Firestore to remove the reminder
                    await FirebaseFirestore.instance
                        .collection('Task')
                        .doc(widget.taskId)
                        .update({'reminder': null});
                    print("Reminder canceled for task: ${widget.taskId}");
                  }
                },
                activeColor: mediumBlue,
                activeTrackColor: lightBlue,
                inactiveThumbColor: const Color.fromARGB(255, 172, 172, 172),
                inactiveTrackColor: Colors.grey[350],
              ),
            ],
          ),
          if (isReminderOn)
            DropdownButtonFormField<int>(
              value: selectedReminderOption != null
                  ? selectedReminderOption!['id']
                  : null, // Use the id for comparison
              isExpanded: true,
              items: reminderOptions.map((option) {
                return DropdownMenuItem<int>(
                  value: option['id'], // Use the id as the dropdown value
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
              onChanged: (id) {
                setState(() {
                  selectedReminderOption = reminderOptions
                      .firstWhere((option) => option['id'] == id);
                  if (selectedReminderOption?['label'] == "Custom Time") {
                    _pickCustomReminderTime();
                  } else {
                    customReminderDateTime =
                        null; // Clear custom time if not selected
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

  Future<void> _pickCustomReminderTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
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

        // if (selectedReminder.isAfter(taskDateTime)) {
        //   _showTopNotification(
        //       "Custom reminder time cannot be after the scheduled task time. Please select a valid time.");
        //   setState(() {
        //     customReminderDateTime = null;
        //   });
        // } else {
          setState(() {
            customReminderDateTime = selectedReminder;
          });
        // }
      }
    }
  }

  Map<String, Map<String, dynamic>?> subtaskReminders = {};

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
        SizedBox(height: 10),
        ...subtasks.map((subtask) {
          final TextEditingController? subtaskEditingController =
              subtaskControllers[subtask];

          return Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
            child: Slidable(
              key: ValueKey(subtask),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (_) async {
                      try {
                        QuerySnapshot subtaskSnapshot = await FirebaseFirestore
                            .instance
                            .collection('SubTask')
                            .where('taskID', isEqualTo: widget.taskId)
                            .where('title', isEqualTo: subtask)
                            .get();

                        for (var doc in subtaskSnapshot.docs) {
                          String subtaskId = doc.id;

                          // Cancel the notification for the subtask
                          await NotificationHandler.cancelNotification(
                              subtaskId);

                          // Delete the subtask from Firestore
                          await doc.reference.delete();
                        }

                        // Update state after deletion
                        setState(() {
                          deletedSubtasks.add(subtask);
                          subtasks.remove(subtask);
                          subtaskControllers.remove(subtask);
                          subtaskReminders.remove(subtask);
                          subtaskCompletionStatus.remove(subtask);

                          // Update progress
                          int completedSubtasks = subtaskCompletionStatus.values
                              .where((status) => status)
                              .length;
                          progress = subtasks.isNotEmpty
                              ? completedSubtasks / subtasks.length
                              : 0.0;
                        });
                        _showTopNotification("Subtask deleted successfully.");

                        print("Subtask $subtask deleted successfully.");
                      } catch (e) {
                        print("Failed to delete subtask: $e");
                      }
                    },
                    backgroundColor: const Color(0xFFC2C2C2),
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
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
                  leading: GestureDetector(
                    onTap: () {
                      if (subtaskCompletionStatus.containsKey(subtask)) {
                        _toggleSubtaskCompletion(subtask);

                        // Update Firestore (optional)
                        FirebaseFirestore.instance
                            .collection('SubTask')
                            .where('taskID', isEqualTo: widget.taskId)
                            .where('title', isEqualTo: subtask)
                            .get()
                            .then((snapshot) {
                          for (var doc in snapshot.docs) {
                            doc.reference.update({
                              'completionStatus':
                                  subtaskCompletionStatus[subtask] == true
                                      ? 1
                                      : 0,
                            });
                          }
                        });
                      }
                    },
                    child: Container(
                      width: 24.0,
                      height: 24.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: subtaskCompletionStatus[subtask] == true
                              ? Colors.grey
                              : mediumBlue,
                          width: 4.0,
                        ),
                        color: subtaskCompletionStatus[subtask] == true
                            ? Colors.grey
                            : Colors.white,
                      ),
                      child: subtaskCompletionStatus[subtask] == true
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.white)
                          : null,
                    ),
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
                      await _showSubtaskReminderDialog(subtask);
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
                onPressed: () async {
                  if (subtasks.length >= 10) {
                    _showTopNotification('You can only add up to 10 subtasks.');
                    return;
                  }
                  if (subtaskController.text.isNotEmpty) {
                    setState(() {
                      subtasks.add(subtaskController.text);
                      subtaskControllers[subtaskController.text] =
                          TextEditingController(text: subtaskController.text);
                      subtaskReminders[subtaskController.text] = null;
                      subtaskCompletionStatus[subtaskController.text] = false;
                      subtaskController.clear();

                      // Update progress
                      int completedSubtasks = subtaskCompletionStatus.values
                          .where((status) => status)
                          .length;
                      progress = subtasks.isNotEmpty
                          ? completedSubtasks / subtasks.length
                          : 0.0;
                    });
                    DocumentReference newSubtaskRef =
                        FirebaseFirestore.instance.collection('SubTask').doc();

                    await newSubtaskRef.set({
                      'completionStatus': 0,
                      'taskID': widget.taskId,
                      'title': subtasks.last,
                      'reminder': null,
                    });

                    // تحديث حالة المهمة لتصبح غير مكتملة
                    await FirebaseFirestore.instance
                        .collection('Task')
                        .doc(widget.taskId)
                        .update({
                      'completionStatus': 0,
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

  Widget _buildProgressBar() {
    if (subtasks.isEmpty)
      return SizedBox.shrink(); // Hide progress bar if no subtasks

    int totalSubtasks = subtasks.length;
    int completedSubtasks =
        subtaskCompletionStatus.values.where((status) => status).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$completedSubtasks/$totalSubtasks subtasks completed",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: darkGray,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: List.generate(totalSubtasks, (index) {
                bool isCompleted = index < completedSubtasks;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isCompleted ? mediumBlue : Colors.grey[300],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(index == 0 ? 6 : 0),
                        bottomLeft: Radius.circular(index == 0 ? 6 : 0),
                        topRight:
                            Radius.circular(index == totalSubtasks - 1 ? 6 : 0),
                        bottomRight:
                            Radius.circular(index == totalSubtasks - 1 ? 6 : 0),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSubtaskReminderDialog(String subtask) async {
    bool isReminderOn = subtaskReminders[subtask] != null;
    Map<String, dynamic>? selectedOption = subtaskReminders[subtask];

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
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
                            setStateDialog(() {
                              isReminderOn = value;
                              if (!isReminderOn) {
                                selectedOption = null;
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
                    if (isReminderOn)
                      ...reminderOptions.map((option) {
                        bool isSelected = selectedOption != null &&
                            ((option['duration'] != null &&
                                    selectedOption?['duration'] ==
                                        option['duration']) ||
                                (option['label'] == "Custom Time" &&
                                    selectedOption?['customDateTime'] != null));

                        return GestureDetector(
                          onTap: () {
                            setStateDialog(() {
                              selectedOption = {
                                'duration': option['duration'],
                                'customDateTime': null,
                              };
                              if (option['label'] == "Custom Time") {
                                _pickCustomSubtaskReminderTime(subtask)
                                    .then((customTime) {
                                  if (customTime != null) {
                                    setStateDialog(() {
                                      selectedOption = {
                                        'duration': null,
                                        'customDateTime': customTime,
                                      };
                                    });
                                  }
                                });
                              }
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
                      print("Updated reminder for subtask: $subtask");
                      print("Reminder details: ${subtaskReminders[subtask]}");
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
      lastDate:  DateTime(2100),
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

  Future<DateTime?> _pickSubtaskReminderTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: darkBlue,
            colorScheme: ColorScheme.light(
              primary: darkBlue,
              onPrimary: Colors.white,
              onSurface: darkGray,
            ),
            dialogBackgroundColor: lightGray,
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
                onPrimary: Colors.white,
                onSurface: darkGray,
              ),
              dialogBackgroundColor: lightGray,
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        return DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }
    }

    return null;
  }

  Widget _buildDateTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(Icons.calendar_today,
              color: _isDateMissing
                  ? const Color.fromARGB(255, 164, 24, 14)
                  : mediumBlue),
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
                  : mediumBlue),
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

  Widget _buildPrioritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Row(
            children: [
              Icon(Icons.flag, color: priorityIconColor),
              SizedBox(width: 8),
              Text(
                'Priority',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: darkGray,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
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
    );
  }

  Widget _priorityFlag(String label, Color color) {
    return Column(
      children: [
        IconButton(
          icon: Icon(Icons.flag,
              color: selectedPriority == label ? color : Colors.grey[300]),
          onPressed: () {
            setState(() {
              selectedPriority = label;
              priorityIconColor = color;
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

  void _pickDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: darkBlue, // Header color
            colorScheme: ColorScheme.light(
              primary: darkBlue, // Background for header and buttons
              onPrimary: Colors.white, // Text color on the header
              onSurface: darkGray, // Text color for dates
            ),
            dialogBackgroundColor: lightGray, // Dialog background
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

  void _pickTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: darkBlue, // Background color for header and buttons
              onPrimary: Colors.white, // Text color for selected time
              onSurface: darkGray, // Text color for unselected time and AM/PM
            ),
            dialogBackgroundColor: lightGray, // Background color for the dialog
            timePickerTheme: TimePickerThemeData(
              dayPeriodColor: lightBlue, // Background color for AM/PM selector
              dayPeriodTextColor: darkGray, // Text color for AM/PM
              dialHandColor: darkBlue, // Color of the dial hand
              dialBackgroundColor: Colors.white, // Background of the dial
            ),
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
}
