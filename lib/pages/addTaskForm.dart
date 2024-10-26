import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application/pages/editTask.dart';

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
      title: 'Task Page',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFFF5F7F8),
        textTheme: Theme.of(context).textTheme.apply(
              fontFamily: 'Poppins',
            ),
      ),
      home: TaskPage(),
    );
  }
}

class TaskPage extends StatefulWidget {
  @override
  _TaskPageState createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  User? _user = FirebaseAuth.instance.currentUser;

  String? _currentTaskID;

  String selectedCategory = '';
  String? selectedPriority;
  Color priorityIconColor = Color(0xFF3B7292);
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  String formattedDate = 'Select Date';
  String formattedTime = 'Select Time';

  List<String> categories = [];
  List<String> hardcodedCategories = [];
  List<String> _newlyAddedCategories = [];
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

  @override
  void initState() {
    super.initState();
    _getCategories();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No logged-in user found')),
        );
      }
    }
    return _user;
  }

  Future<void> _saveCategoryAndLinkToTask(
      String categoryName, DocumentReference taskRef) async {
    try {
      User? currentUser = await _getCurrentUser();
      if (currentUser == null) return;

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Category')
          .where('categoryName', isEqualTo: categoryName)
          .where('userID', isEqualTo: currentUser.uid)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentReference categoryRef = querySnapshot.docs.first.reference;

        await categoryRef.update({
          'taskIDs': FieldValue.arrayUnion([taskRef.id])
        });
      } else {
        DocumentReference categoryRef =
            FirebaseFirestore.instance.collection('Category').doc();
        await categoryRef.set({
          'categoryName': categoryName,
          'userID': currentUser.uid,
          'taskIDs': [taskRef.id],
        });
      }
    } catch (e) {
      print('Failed to save category or link to task: $e');
    }
  }

  Future<bool> _saveTaskToFirebase() async {
    try {
      User? currentUser = await _getCurrentUser();
      if (currentUser == null) return false;

      final DateTime taskDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      QuerySnapshot existingTaskSnapshot = await FirebaseFirestore.instance
          .collection('Task')
          .where('userID', isEqualTo: currentUser.uid) 
          .where('scheduledDate',
              isEqualTo: Timestamp.fromDate(
                  taskDateTime)) 
          .get();

      if (existingTaskSnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'A task already exists with the same date and time. Please choose a different time.'),
          ),
        );
        return false; 
      }

      DocumentReference taskRef =
          FirebaseFirestore.instance.collection('Task').doc();

      await taskRef.set({
        'completionStatus': 0,
        'scheduledDate': Timestamp.fromDate(taskDateTime),
        'note': notesController.text,
        'priority': _getPriorityValue(),
        'reminder': '',
        'timer': '',
        'title': taskNameController.text,
        'userID': currentUser.uid,
      });

      if (selectedCategory.isNotEmpty) {
        await _saveCategoryAndLinkToTask(selectedCategory, taskRef);
      }

      for (String subtask in subtasks) {
        await FirebaseFirestore.instance.collection('SubTask').add({
          'completionStatus': 0,
          'taskID': taskRef,
          'timer': '',
          'title': subtask,
        });
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Task saved successfully!')));

      return true; 
    } catch (e) {
      print('Failed to save task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save task. Please try again.')));
      return false; 
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
        bool isTaskSaved = await _saveTaskToFirebase();
        if (isTaskSaved) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EditTaskPage(taskId: ''),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save task: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all mandatory fields.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
        backgroundColor: Color(0xFFEAEFF0),
        elevation: 0,
        iconTheme: IconThemeData(color: darkGray),
        title: Center(
          child: Text(
            'Add Task',
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

              _buildReminderTimerSection(),

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
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(mediumBlue),
                  ),
                  child: Text('Save', style: TextStyle(color: Colors.white)),
                ),
              )
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
        ...subtasks.map((subtask) => Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0), 
              child: ListTile(
                contentPadding: EdgeInsets.zero, 
                title: Text(
                  subtask,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    color: darkGray,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete,
                      color: Color.fromARGB(255, 125, 125, 125)),
                  onPressed: () {
                    setState(() {
                      subtasks.remove(subtask);
                    });
                  },
                ),
              ),
            )),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16.0), 
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
          padding: const EdgeInsets.symmetric(
              horizontal: 16.0),
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
          padding: const EdgeInsets.symmetric(
              horizontal: 16.0), 
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
            return WillPopScope(
              onWillPop: () async {
                return await _showDiscardConfirmation();
              },
              child: AlertDialog(
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
                              focusNode: index == 0
                                  ? firstCategoryFocusNode
                                  : null, 
                              onSubmitted: (newName) {
                                if (newName.isNotEmpty && newName != category) {
                                  setState(() {
                                    int index =
                                        tempCategories.indexOf(category);
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
                                  deletedCategories
                                      .add(category); 
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
                                      ScaffoldMessenger.of(scaffoldContext)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'You can only create up to 7 categories.',
                                          ),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
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
              ),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Category "$categoryName" deleted successfully'),
      ));
    }
  }
Future<bool> _showCategoryDeleteConfirmation(String categoryName, int taskCount) async {
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
  ) ?? false; 
}



Future<bool> _showDiscardConfirmation() async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: lightGray, 
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Are you sure?',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkGray, 
            ),
          ),
          content: Text(
            'Changes won\'t be saved.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: darkGray, 
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              style: TextButton.styleFrom(
                foregroundColor:
                    mediumBlue, 
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      mediumBlue, 
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
                'Discard',
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
    );
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

  Widget _buildReminderTimerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(Icons.notifications, color: Color(0xFF3B7292)),
          title: Text(
            'Set Reminder',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: darkGray,
            ),
          ),
        ),
        SizedBox(height: 20),

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

  void _addSubtask(String text) {
    if (text.isNotEmpty) {
      setState(() {
        subtasks.add(text);
        subtaskController.clear();
      });
    }
  }
}
