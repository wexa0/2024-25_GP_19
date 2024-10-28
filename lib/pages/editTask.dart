import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application/pages/task_page.dart';

class EditTaskPage extends StatefulWidget {
  final String taskId;

  EditTaskPage({required this.taskId});

  @override
  _EditTaskPageState createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
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

  Color darkBlue = Color(0xFF104A73);
  Color mediumBlue = Color(0xFF3B7292);
  Color lightBlue = Color(0xFF79A3B7);
  Color lightestBlue = Color(0xFFC7D9E1);
  Color lightGray = Color(0xFFF5F7F8);
  Color darkGray = Color(0xFF545454);

  @override
  void initState() {
    super.initState();
    _loadTaskDetails();
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
        subtaskSnapshot.docs.forEach((doc) {
          var subtaskData = doc.data() as Map<String, dynamic>;
          fetchedSubtasks.add(subtaskData['title']);
          subtaskControllers[subtaskData['title']] =
              TextEditingController(text: subtaskData['title']);
        });

        setState(() {
          subtasks = fetchedSubtasks;
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

      await FirebaseFirestore.instance
          .collection('Task')
          .doc(widget.taskId)
          .update({
        'title': taskNameController.text,
        'note': notesController.text,
        'priority': _getPriorityValue(),
        'scheduledDate': taskTimestamp,
      });

      await _handleCategoryChanges();

      for (String deletedSubtask in deletedSubtasks) {
        QuerySnapshot subtaskSnapshot = await FirebaseFirestore.instance
            .collection('SubTask')
            .where('taskID', isEqualTo: widget.taskId)
            .where('title', isEqualTo: deletedSubtask)
            .get();

        for (var doc in subtaskSnapshot.docs) {
          await doc.reference.delete();
        }
      }

      for (String subtask in subtasks) {
        final subtaskTitle = subtaskControllers[subtask]?.text ?? subtask;
        QuerySnapshot subtaskSnapshot = await FirebaseFirestore.instance
            .collection('SubTask')
            .where('taskID', isEqualTo: widget.taskId)
            .where('title', isEqualTo: subtask)
            .get();

        if (subtaskSnapshot.docs.isNotEmpty) {
          DocumentReference subtaskRef = subtaskSnapshot.docs.first.reference;
          await subtaskRef.update({
            'title': subtaskTitle,
          });
        } else {
          await FirebaseFirestore.instance.collection('SubTask').add({
            'completionStatus': 0,
            'taskID': widget.taskId,
            'timer': '',
            'title': subtaskTitle,
          });
        }
      }

      _showTopNotification('Task updated successfully!');

      deletedSubtasks.clear();
    } catch (e) {
      print('Failed to update task: $e');
      _showTopNotification('Failed to update task. Please try again.');
    }
  }

  Future<void> _handleCategoryChanges() async {
    if (selectedCategory.isEmpty) return;

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    QuerySnapshot oldCategorySnapshot = await FirebaseFirestore.instance
        .collection('Category')
        .where('taskIDs', arrayContains: widget.taskId)
        .where('userID', isEqualTo: currentUser.uid)
        .get();

    if (oldCategorySnapshot.docs.isNotEmpty) {
      DocumentReference oldCategoryRef =
          oldCategorySnapshot.docs.first.reference;
      await oldCategoryRef.update({
        'taskIDs': FieldValue.arrayRemove([widget.taskId])
      });
    }

    QuerySnapshot newCategorySnapshot = await FirebaseFirestore.instance
        .collection('Category')
        .where('categoryName', isEqualTo: selectedCategory)
        .where('userID', isEqualTo: currentUser.uid)
        .get();

    if (newCategorySnapshot.docs.isNotEmpty) {
      DocumentReference newCategoryRef =
          newCategorySnapshot.docs.first.reference;
      await newCategoryRef.update({
        'taskIDs': FieldValue.arrayUnion([widget.taskId])
      });
    } else {
      DocumentReference newCategoryRef =
          FirebaseFirestore.instance.collection('Category').doc();
      await newCategoryRef.set({
        'categoryName': selectedCategory,
        'userID': currentUser.uid,
        'taskIDs': [widget.taskId],
      });
    }
  }

  Future<void> _deleteTask() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Delete subtasks
      QuerySnapshot subtaskSnapshot = await FirebaseFirestore.instance
          .collection('SubTask')
          .where('taskID', isEqualTo: widget.taskId)
          .get();

      for (var subtaskDoc in subtaskSnapshot.docs) {
        await subtaskDoc.reference.delete();
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

      _showTopNotification('Task and related subtasks deleted successfully!');
      // Pop back to the TaskPage
      Navigator.pop(
          context, true); // Passing `true` to indicate successful deletion
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
        if (currentUser == null) return;

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

        // If a task exists, show a message to the user
        if (existingTaskSnapshot.docs.isNotEmpty) {
          _showTopNotification(
              'Another task already exists with the same date and time. Please choose a different time.');
          return;
        }

        // Save changes to Firebase
        await _saveChangesToFirebase();

        _showTopNotification('Task updated successfully!');

        // Navigate back to TaskPage
        Navigator.pop(
            context, true); // Returning `true` to indicate a task update
      } catch (e) {
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

    overlayState?.insert(overlayEntry);
    Future.delayed(Duration(seconds: 2), () {
      overlayEntry.remove();
    });
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
                    errorText: _isTitleMissing ? 'Task Name is required' : null,
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
                SizedBox(height: 20),
                _buildPrioritySection(),
                SizedBox(height: 30),
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
                  style: TextButton.styleFrom(
                    foregroundColor: mediumBlue,
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: mediumBlue,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: Text(
                    'Leave',
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
                onSelected: (bool selected) {
                  setState(() {
                    selectedCategory = category;
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
              style: TextButton.styleFrom(
                foregroundColor:
                    mediumBlue, // Use mediumBlue for the Cancel button
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('Cancel'),
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


  // Future<bool> _showDiscardConfirmation() async {
  //   return await showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         backgroundColor: lightGray,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         title: Text(
  //           'Are you sure?',
  //           style: TextStyle(
  //             fontFamily: 'Poppins',
  //             fontSize: 18,
  //             fontWeight: FontWeight.bold,
  //             color: darkGray,
  //           ),
  //         ),
  //         content: Text(
  //           'Changes won\'t be saved.',
  //           style: TextStyle(
  //             fontFamily: 'Poppins',
  //             fontSize: 14,
  //             fontWeight: FontWeight.w400,
  //             color: darkGray,
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop(false);
  //             },
  //             style: TextButton.styleFrom(
  //               foregroundColor:
  //                   mediumBlue,
  //             ),
  //             child: Text(
  //               'Cancel',
  //               style: TextStyle(
  //                 fontFamily: 'Poppins',
  //                 fontSize: 14,
  //                 fontWeight: FontWeight.w600,
  //                 color:
  //                     mediumBlue,
  //               ),
  //             ),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop(true);
  //             },
  //             style: TextButton.styleFrom(
  //               foregroundColor: Colors.red,
  //             ),
  //             child: Text(
  //               'Discard',
  //               style: TextStyle(
  //                 fontFamily: 'Poppins',
  //                 fontSize: 14,
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.red,
  //               ),
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  Widget _buildSubtaskSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subtasks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Row(
              children: [
                SizedBox(width: 8),
                Text(
                  'Subtasks',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: darkGray,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: 10),
        ...subtasks.map((subtask) => ListTile(
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: subtaskControllers[subtask],
                  decoration: InputDecoration(
                    labelText: '',
                    labelStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: darkBlue,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: darkBlue, width: 2.0),
                    ),
                  ),
                ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete,
                    color: Color.fromARGB(255, 125, 125, 125)),
                onPressed: () {
                  setState(() {
                    deletedSubtasks.add(subtask);
                    subtasks.remove(subtask);
                    subtaskControllers.remove(subtask);
                  });
                },
              ),
            )),
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
                      subtaskControllers[subtaskController.text] =
                          TextEditingController(text: subtaskController.text);
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
