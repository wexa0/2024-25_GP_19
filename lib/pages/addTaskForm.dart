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
  User? _user =
      FirebaseAuth.instance.currentUser; 

  String? _currentTaskID;

  String selectedCategory = '';
  String? selectedPriority;
  Color priorityIconColor = Color(0xFF3B7292);
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  String formattedDate = 'Select Date';
  String formattedTime = 'Select Time';

  List<String> categories = [];
  List<String> hardcodedCategories = ['Home', 'Work'];
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
          'taskIDs': FieldValue.arrayUnion(
              [taskRef.id]) 
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

  Future<void> _saveTaskToFirebase() async {
    try {
      User? currentUser = await _getCurrentUser();
      if (currentUser == null) return;

      final DateTime taskDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      DocumentReference taskRef =
          FirebaseFirestore.instance.collection('Task').doc();

      await taskRef.set({
        'completionStatus': '0',
        'date': Timestamp.fromDate(taskDateTime),
        'note': notesController.text,
        'priority': _getPriorityValue(),
        'reminder': '',
        'timer': '',
        'title': taskNameController.text,
        'userID': FirebaseFirestore.instance.collection('User').doc(_user!.uid),
      });

      String taskID = taskRef.id;

      if (selectedCategory.isNotEmpty) {
        await _saveCategoryAndLinkToTask(selectedCategory, taskRef);
      }
      for (String subtask in subtasks) {
        await FirebaseFirestore.instance.collection('SubTask').add({
          'completionStatus': '0',
          'taskID': taskRef,
          'timer': '',
          'title': subtask,
        });
      }

      setState(() {
        _currentTaskID = taskID;
      });

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Task saved successfully!'),
      ));
    } catch (e) {
      print('Failed to save task: $e');
    }
  }

  // Get the priority as a number
  int _getPriorityValue() {
    switch (selectedPriority) {
      case 'Urgent':
        return 0;
      case 'High':
        return 1;
      case 'Normal':
        return 2;
      case 'Low':
        return 3;
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
        await _saveTaskToFirebase();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task saved successfully!')),
        );
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
        title: Container(
          padding: EdgeInsets.all(6),
          child: Center(
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
        ),
        backgroundColor: Color(0xFFEAEFF0),
        elevation: 0,
        iconTheme: IconThemeData(color: darkGray),
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

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _saveTask();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              EditTaskPage(taskId: 'IVGolOFAlbH6uS8Ihdst')),
                    );
                  },
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(mediumBlue),
                  ),
                  child: Text('Save', style: TextStyle(color: Colors.white)),
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
        ...subtasks.map((subtask) => ListTile(
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
            )),
        TextField(
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
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category, color: mediumBlue),
            SizedBox(width: 8),
            Text(
              'Category',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: darkGray,
              ),
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.edit, color: mediumBlue),
              onPressed: () {
                setState(() {
                  isEditingCategory = !isEditingCategory;
                });
              },
            ),
          ],
        ),
        SizedBox(height: 10),
        Wrap(
          spacing: 8.0,
          children: categories.map((category) {
            bool isHardcoded = hardcodedCategories.contains(category);

            return isEditingCategory &&
                    !isHardcoded 
                ? Chip(
                    label: GestureDetector(
                      onTap: () {
                        if (!isHardcoded) {
                          _showRenameCategoryDialog(category);
                        }
                      },
                      child: Text(category),
                    ),
                    deleteIcon: Icon(Icons.close,
                        color: const Color.fromARGB(255, 1, 39, 71)),
                    onDeleted: () {
                      _showDeleteCategoryConfirmation(category);
                    },
                    backgroundColor: lightestBlue,
                  )
                : ChoiceChip(
                    label: Text(category),
                    selected: selectedCategory == category,
                    selectedColor: mediumBlue,
                    backgroundColor: lightestBlue,
                    labelStyle: TextStyle(
                      color: selectedCategory == category
                          ? Colors.white
                          : darkGray,
                    ),
                    onSelected: (bool selected) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                  );
          }).toList(),
        ),
        if (isEditingCategory)
          TextField(
            controller: categoryController,
            onSubmitted: _addCategory,
            decoration: InputDecoration(
              labelText: 'Add New Category',
            ),
          ),
      ],
    );
  }

  void _addCategory(String text) async {
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category name cannot be empty.')),
      );
      return;
    }

    if (_newlyAddedCategories.length + categories.length >= 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You can only create up to 7 categories.')),
      );
      return;
    }

    setState(() {
      categories.add(text.trim()); 
      _newlyAddedCategories.add(text.trim()); 
      categoryController.clear();
    });

    await _saveCategoryToDatabase(text.trim());
  }

  void _showDeleteCategoryConfirmation(String category) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Category',
            style: TextStyle(
              color: Colors.black, 
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete the category "$category"? This action cannot be undone.',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.grey[800], 
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(false); 
              },
              style: TextButton.styleFrom(
                foregroundColor:
                    Color(0xFF3B7292), 
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                _deleteCategory(category, isNew: true);
                Navigator.of(context).pop(true); 
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red, 
              ),
              child: Text(
                'Delete',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          backgroundColor:
              Color(0xFFF5F7F8), 
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }

  void _deleteCategory(String category, {required bool isNew}) async {
    setState(() {
      categories.remove(category);
      if (isNew) {
        _newlyAddedCategories.remove(category);
      }
    });

    await _deleteCategoryFromDatabase(category);
  }

// Rename a category and update the database
  void _showRenameCategoryDialog(String oldCategory) {
    TextEditingController renameController =
        TextEditingController(text: oldCategory);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Rename Category'),
          content: TextField(
            controller: renameController,
            decoration: InputDecoration(
              labelText: 'New Category Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String newCategoryName = renameController.text.trim();
                if (newCategoryName.isNotEmpty &&
                    newCategoryName != oldCategory) {
                  setState(() {
                    int index = categories.indexOf(oldCategory);
                    if (index != -1) {
                      categories[index] = newCategoryName; 
                    }
                  });
                  await _renameCategoryInDatabase(oldCategory, newCategoryName);
                }
                Navigator.of(context).pop(); 
              },
              child: Text('Rename'),
            ),
          ],
        );
      },
    );
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

// Save a category to the database
  Future<void> _saveCategoryToDatabase(String categoryName) async {
    User? currentUser = await _getCurrentUser();
    if (currentUser == null) return;

    await FirebaseFirestore.instance.collection('Category').add({
      'categoryName': categoryName,
      'userID': currentUser.uid,
    });
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
      await snapshot.docs.first.reference.delete();
    }
  }

  // Field for adding a new category
  Widget _buildCategoryEditField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Add New Category',
            ),
            onChanged: (value) {
              newCategory = value;
            },
          ),
        ),
        IconButton(
          icon: Icon(Icons.add, color: Color(0xFF5AA9E6)),
          onPressed: () {
            if (newCategory.isNotEmpty) {
              setState(() {
                categories.add(newCategory);
                isEditingCategory = false;
              });
            }
          },
        ),
      ],
    );
  }

  // Method to show the Date Picker
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
            dialogBackgroundColor:
                Color(0xFFF5F7F8), 
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
                fontSize: 14,
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
              fontSize: 14,
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
              fontSize: 14,
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
          leading: Icon(Icons.notifications,
              color: Color(0xFF3B7292)), 
          title: Text(
            'Set Reminder',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: darkGray,
            ),
          ),
        ),
        SizedBox(height: 20),

        // Timer Section
        ListTile(
          leading:
              Icon(Icons.timer, color: Color(0xFF3B7292)), 
          title: Text(
            'Set Timer',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
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
