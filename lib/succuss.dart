import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Page',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFFF5F7F8),  // Background color #f5f7f8
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
  String selectedCategory = 'Work';
  String selectedPriority = 'Normal'; // Priority starts as 'Normal'
  Color priorityIconColor = Colors.blue; // Initial priority color
 DateTime selectedDateTime = DateTime.now(); // Store selected date and time
  String formattedDateTime = ''; 
  List<String> categories = ['Work', 'Family', 'Univer'];
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
        categoryController.clear();
      });
    }
  }
  
  

  // Method to show the custom Date and Time Picker
  void dateTimePickerWidget(BuildContext context) {
    DatePicker.showDateTimePicker(
      context,
      showTitleActions: true, // Show Done and Cancel buttons
      minTime: DateTime(2000, 1, 1),
      maxTime: DateTime(3000, 12, 31),
      currentTime: selectedDateTime, // Use previously selected date or default to current time
      locale: LocaleType.en, // Customize locale if necessary
      onConfirm: (dateTime) {
        setState(() {
          selectedDateTime = dateTime; // Update the selected date and time
          formattedDateTime = DateFormat('dd MMMM yyyy - HH:mm').format(selectedDateTime); // Format the selected date
        });
      },
    );
  }
  // Subtask Section (Thread-like view)
  Widget _buildSubtaskSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...subtasks.map((subtask) => ListTile(
              title: Text(subtask),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Color(0xFF5AA9E6)),
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
            suffixIcon: IconButton(
              icon: Icon(Icons.add, color: Color(0xFF5AA9E6)),
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
// Priority Section with colored flags
  Widget _buildPrioritySection() {
    return ExpansionTile(
      leading: Icon(Icons.flag, color: priorityIconColor),
      title: Text('Priority: $selectedPriority', style: TextStyle(color: darkGray)),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _priorityFlag('Urgent', Colors.red, Icons.flag),
            _priorityFlag('High', Colors.yellow, Icons.flag),
            _priorityFlag('Normal', Colors.blue, Icons.flag),
            _priorityFlag('Low', Colors.grey, Icons.flag),
          ],
        ),
      ],
    );
  }

  Widget _priorityFlag(String label, Color color, IconData icon) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: color),
          onPressed: () {
            setState(() {
              selectedPriority = label;
              priorityIconColor = color;
            });
          },
        ),
        Text(label),
      ],
    );
  }

  // Category Section with edit and delete functionality
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category, color: mediumBlue), // Category Icon
            SizedBox(width: 8),
            Text('Category', style: TextStyle(fontWeight: FontWeight.bold, color: darkGray)),
            Spacer(),
            IconButton(
              icon: Icon(Icons.edit, color: mediumBlue), // Pencil Icon next to label
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
            return isEditingCategory
                ? Chip(
                    label: Text(category),
                    deleteIcon: Icon(Icons.close, color: Colors.red), // "X" icon for deletion
                    onDeleted: () {
                      setState(() {
                        categories.remove(category);
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
                      color: selectedCategory == category ? Colors.white : darkGray,
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
            onSubmitted: _addCategory, // Add category on Enter
            decoration: InputDecoration(
              labelText: 'Add New Category',
              filled: true,
              fillColor: lightGray,
              border: OutlineInputBorder(
                 borderSide: BorderSide(color: lightestBlue),
              ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: darkBlue, // Dark blue background color for the app bar title
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Add Task',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: darkGray),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task name input
              TextField(
                controller: taskNameController,
                decoration: InputDecoration(
                  labelText: 'Task name',
                  filled: true,
                  fillColor: lightGray, // Light gray background for the text field
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: lightestBlue),
                  ),
                ),
              ),
              SizedBox(height: 10),

              // Subtask input (threaded)
              _buildSubtaskSection(),
              SizedBox(height: 20),

              // Category section with icon and chips below label
              _buildCategorySection(),
              SizedBox(height: 20),

             // Date and time picker section
              ListTile(
                leading: Icon(Icons.calendar_today, color: Color(0xFF3B7292)),
                title: Text('Date', style: TextStyle(color: Color(0xFF545454))),
                trailing: Text(
                  formattedDateTime.isEmpty
                      ? 'Select Date'
                      : formattedDateTime, // Display formatted date or placeholder text
                  style: TextStyle(color: Color(0xFF545454)),
                ),
                onTap: () => dateTimePickerWidget(context), // Open custom date and time picker
              ),
              SizedBox(height: 10),

              // Priority section with flags
              _buildPrioritySection(),
              SizedBox(height: 20),

              // Reminder and Timer (placeholders)
              ListTile(
                leading: Icon(Icons.notifications, color: mediumBlue),
                title: Text('Set Reminder', style: TextStyle(color: darkGray)),
              ),
              ListTile(
                leading: Icon(Icons.timer, color: mediumBlue),
                title: Text('Set Timer', style: TextStyle(color: darkGray)),
              ),
              SizedBox(height: 20),

              // Notes input
              TextField(
                controller: notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  filled: true,
                  fillColor: lightGray, // Light gray background for text fields
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: lightestBlue),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle Save functionality
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(darkBlue), // Dark blue Save button
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
}