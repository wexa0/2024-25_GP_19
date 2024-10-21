import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      FirebaseAuth.instance.currentUser; // Get the current logged-in user

  String selectedCategory = 'Home';
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

  // Method to show the Time Picker
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

      // Add user-created categories to the list
      for (var doc in categorySnapshot.docs) {
        fetchedCategories.add(doc['categoryName']);
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

  // Method to add category and return its reference
  Future<DocumentReference> _addCategoryAndReturnReference(
      String categoryName) async {
    User? currentUser = await _getCurrentUser();
    if (currentUser == null) throw Exception("No user found");

    // Check if the category already exists for the user
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('Category')
        .where('categoryName', isEqualTo: categoryName)
        .where('userID', isEqualTo: currentUser.uid)
        .get();

    if (querySnapshot.docs.isEmpty) {
      // If the category doesn't exist, create it
      DocumentReference categoryRef =
          FirebaseFirestore.instance.collection('Category').doc();
      await categoryRef.set({
        'categoryName': categoryName,
        'userID': currentUser.uid,
      });
      return categoryRef;
    } else {
      // If it exists, return the existing category reference
      return querySnapshot.docs.first.reference;
    }
  }

  // Add and link category to the task
  Future<void> _saveCategoryAndLinkToTask(
      String categoryName, DocumentReference taskRef) async {
    try {
      DocumentReference categoryRef =
          await _addCategoryAndReturnReference(categoryName);
      await FirebaseFirestore.instance.collection('CategoryTask').add({
        'categoryID': categoryRef,
        'taskID': taskRef,
      });
    } catch (e) {
      print('Failed to save category or link to task: $e');
    }
  }

  // Add a task to Firebase Firestore
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

      // Add the task to the "Task" collection in Firestore
      await taskRef.set({
        'notes': notesController.text,
        'priority': _getPriorityValue(),
        'startDate': Timestamp.fromDate(taskDateTime),
        'status': '',
        'taskTitle': taskNameController.text,
        'timer': '0',
        'timeSpent': '',
        'userID': FirebaseFirestore.instance
            .collection('User')
            .doc(_user!.uid), // Reference to the logged-in user
      });

      await _saveCategoryAndLinkToTask(selectedCategory, taskRef);

      // Save each subtask to the "SubTask" collection
      for (String subtask in subtasks) {
        await FirebaseFirestore.instance.collection('SubTask').add({
          'status': '',
          'subTaskTitle': subtask,
          'taskID': taskRef,
        });
      }

      // Show a confirmation
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

  void _saveTask() {
    List<String> missingFields = [];

    if (taskNameController.text.isEmpty) {
      missingFields.add("Task Title");
    }
    if (formattedDate == 'Select Date') {
      missingFields.add("Date");
    }
    if (formattedTime == 'Select Time') {
      missingFields.add("Time");
    }

    // If there are any missing fields, show a single error message
    if (missingFields.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please Choose a: ${missingFields.join(', ')}')),
      );
      return;
    }

    _saveTaskToFirebase();
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
                  labelText: 'Task name',
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
                  onPressed: _saveTask,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(darkBlue),
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
            bool isNewCategory = _newlyAddedCategories.contains(category);

            return isEditingCategory && isNewCategory
                ? Chip(
                    label: Text(category),
                    deleteIcon: Icon(Icons.close,
                        color: const Color.fromARGB(255, 1, 39, 71)),
                    onDeleted: () {
                      setState(() {
                        categories
                            .remove(category); // Remove from categories list
                        _newlyAddedCategories.remove(
                            category); // Remove from newly added categories
                      });
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
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: darkBlue, // Header background color
            colorScheme: ColorScheme.light(
              primary: darkBlue, // Primary color for header
              onPrimary: Color(0xFFF5F7F8), // Text color on header
              surface: Color(0xFFF5F7F8), // Dialog background color
              onSurface: darkGray, // Text color for dates
              secondary: lightBlue, // Selected date color
            ),
            dialogBackgroundColor:
                Color(0xFFF5F7F8), // Background color for the date picker
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

  // Priority Section with colored flags
  Widget _buildPrioritySection() {
    return Column(
      children: [
        // Top Divider (invisible)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(
            color: Colors.transparent,
            thickness: 1.5,
          ),
        ),

        // The ExpansionTile
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
                color: darkGray,
              ),
            ),
            children: [
              // Priority options
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
          child: Divider(
            color: Colors.transparent,
            thickness: 1.5,
          ),
        ),
      ],
    );
  }

  // Method to show colored flags for each priority
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
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: darkGray,
          ),
        ),
      ],
    );
  }

  // Build the Date and Time Picker Section
  Widget _buildDateTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(Icons.calendar_today, color: Color(0xFF3B7292)),
          title: Text(
            'Date',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: darkGray,
            ),
          ),
          trailing: Text(
            formattedDate,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: darkGray,
            ),
          ),
          onTap: () => _pickDate(context),
        ),
        SizedBox(height: 16),
        ListTile(
          leading: Icon(Icons.access_time, color: Color(0xFF3B7292)),
          title: Text(
            'Time',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: darkGray,
            ),
          ),
          trailing: Text(
            formattedTime,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: darkGray,
            ),
          ),
          onTap: () => _pickTime(context),
        ),
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

  // Add category when user presses Enter
  void _addCategory(String text) {
    if (text.isNotEmpty) {
      setState(() {
        categories.add(text);
        _newlyAddedCategories.add(text); // Track new category
        categoryController.clear();
      });
    }
  }
}
