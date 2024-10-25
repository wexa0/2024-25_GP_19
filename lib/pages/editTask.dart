import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditTaskPage extends StatefulWidget {
  final String taskId;

  EditTaskPage({required this.taskId});

  @override
  _EditTaskPageState createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  User? _user = FirebaseAuth.instance.currentUser; // Current logged-in user
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

  List<String> subtasks = [];
  TextEditingController subtaskController = TextEditingController();
  TextEditingController taskNameController = TextEditingController();
  TextEditingController notesController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  Map<String, TextEditingController> subtaskControllers =
      {}; 
bool isEditingCategory = false;
  bool _isTitleMissing = false;
  bool _isDateMissing = false;
  bool _isTimeMissing = false;

  Future<void> _loadTaskDetails() async {
    try {
      DocumentSnapshot taskSnapshot = await FirebaseFirestore.instance
          .collection('Task')
          .doc(widget.taskId)
          .get();

      if (taskSnapshot.exists) {
        var taskData = taskSnapshot.data() as Map<String, dynamic>;

        setState(() {
          taskNameController.text = taskData['title'] ?? '';
          notesController.text = taskData['note'] ?? '';

          selectedPriority = _getPriorityLabel(
              taskData['priority']); 
          priorityIconColor = _getPriorityColor(
              selectedPriority!); 

          formattedDate =
              DateFormat('MMM dd, yyyy').format(taskData['date'].toDate());
          selectedDate = taskData['date'].toDate();
          formattedTime =
              TimeOfDay.fromDateTime(taskData['date'].toDate()).format(context);
          selectedTime = TimeOfDay.fromDateTime(taskData['date'].toDate());
        });

        // Fetch Subtasks
        QuerySnapshot subtaskSnapshot = await FirebaseFirestore.instance
            .collection('SubTask')
            .where('taskID',
                isEqualTo: FirebaseFirestore.instance
                    .collection('Task')
                    .doc(widget.taskId)) 
            .get();

        List<String> fetchedSubtasks = [];
        subtaskSnapshot.docs.forEach((doc) {
          var subtaskData = doc.data() as Map<String, dynamic>;
          fetchedSubtasks.add(subtaskData['title']);
          subtaskControllers[subtaskData['title']] = TextEditingController(
              text:
                  subtaskData['title']); 
        });

        setState(() {
          subtasks = fetchedSubtasks;
        });

        QuerySnapshot categorySnapshot = await FirebaseFirestore.instance
            .collection('Category')
            .where('taskIDs', arrayContains: widget.taskId)
            .get();

        List<String> fetchedCategories = [];
        categorySnapshot.docs.forEach((doc) {
          var categoryData = doc.data() as Map<String, dynamic>;
          fetchedCategories.add(categoryData['categoryName']);
        });

        setState(() {
          categories = [...hardcodedCategories, ...fetchedCategories];
          if (categorySnapshot.docs.isNotEmpty) {
            selectedCategory = categorySnapshot.docs.first['categoryName'];
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

      await FirebaseFirestore.instance
          .collection('Task')
          .doc(widget.taskId)
          .update({
        'title': taskNameController.text,
        'note': notesController.text,
        'priority': _getPriorityValue(),
        'date': Timestamp.fromDate(taskDateTime),
      });

      await _handleCategoryChanges();

      for (String subtask in subtasks) {
        final subtaskTitle = subtaskControllers[subtask]?.text ?? subtask;
        QuerySnapshot subtaskSnapshot = await FirebaseFirestore.instance
            .collection('SubTask')
            .where('taskID',
                isEqualTo: FirebaseFirestore.instance
                    .collection('Task')
                    .doc(widget.taskId))
            .where('title', isEqualTo: subtask)
            .get();

        if (subtaskSnapshot.docs.isNotEmpty) {
          DocumentReference subtaskRef = subtaskSnapshot.docs.first.reference;
          await subtaskRef.update({
            'title': subtaskTitle, 
          });
        } else {
          await FirebaseFirestore.instance.collection('SubTask').add({
            'completionStatus': '0',
            'taskID': FirebaseFirestore.instance
                .collection('Task')
                .doc(widget.taskId),
            'timer': '',
            'title': subtaskTitle, 
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Task updated successfully!'),
      ));
    } catch (e) {
      print('Failed to update task: $e');
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
      await FirebaseFirestore.instance
          .collection('Task')
          .doc(widget.taskId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Task deleted successfully!'),
      ));

      Navigator.of(context).pop(); 
    } catch (e) {
      print('Failed to delete task: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTaskDetails(); 
  }

  String _getPriorityLabel(int priorityValue) {
    switch (priorityValue) {
      case 0:
        return 'Urgent';
      case 1:
        return 'High';
      case 2:
        return 'Normal';
      case 3:
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Task'),
        backgroundColor: Color(0xFFEAEFF0),
        iconTheme: IconThemeData(color: Colors.black),
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
                    color: Colors.black,
                  ),
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
              SizedBox(height: 20),
              TextField(
                controller: notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _saveChangesToFirebase,
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Color(0xFF3B7292)),
                    ),
                    child: Text(
                      'Save Changes',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _deleteTask,
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.red),
                    ),
                    child: Text(
                      'Delete Task',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
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
        Row(
          children: [
            Icon(Icons.category, color: Color(0xFF3B7292)),
            SizedBox(width: 8),
            Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.edit, color: Color(0xFF3B7292)),
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

            return isEditingCategory && !isHardcoded
                ? Chip(
                    label: GestureDetector(
                      onTap: () {
                        if (!isHardcoded) {
                          _showRenameCategoryDialog(category);
                        }
                      },
                      child: Text(category),
                    ),
                    deleteIcon: Icon(Icons.close, color: Color(0xFF3B7292)),
                    onDeleted: () {
                      _showDeleteCategoryConfirmation(category);
                    },
                    backgroundColor: Colors.grey[200],
                  )
                : ChoiceChip(
                    label: Text(category),
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
                Navigator.of(context).pop(false); 
              },
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF3B7292),
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
          backgroundColor: Color(0xFFF5F7F8),
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

  Future<void> _saveCategoryToDatabase(String categoryName) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await FirebaseFirestore.instance.collection('Category').add({
      'categoryName': categoryName,
      'userID': currentUser.uid,
    });
  }

  Future<void> _deleteCategoryFromDatabase(String categoryName) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
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

  Future<void> _renameCategoryInDatabase(
      String oldCategory, String newCategory) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
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

  Widget _buildSubtaskSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...subtasks.map((subtask) => ListTile(
              title: TextField(
                controller: subtaskControllers[
                    subtask],
                decoration: InputDecoration(
                  labelText: 'Subtask',
                ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    subtasks.remove(subtask);
                    subtaskControllers.remove(subtask);
                  });
                },
              ),
            )),
        TextField(
          controller: subtaskController,
          decoration: InputDecoration(
            labelText: 'Add Subtask',
            suffixIcon: IconButton(
              icon: Icon(Icons.add),
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
      ],
    );
  }

  Widget _buildDateTimePicker() {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.calendar_today, color: Color(0xFF3B7292)),
          title: Text('Date *'),
          trailing: Text(formattedDate),
          onTap: () => _pickDate(context),
        ),
        ListTile(
          leading: Icon(Icons.access_time, color: Color(0xFF3B7292)),
          title: Text('Time *'),
          trailing: Text(formattedTime),
          onTap: () => _pickTime(context),
        ),
      ],
    );
  }

  Widget _buildPrioritySection() {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.flag, color: priorityIconColor), 
            SizedBox(width: 8),
            Text(
              'Priority',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
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
          icon: Icon(
            Icons.flag,
            color: selectedPriority == label
                ? color
                : Colors.grey[300], 
          ),
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

  void _pickDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
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
    );
    if (pickedTime != null && pickedTime != selectedTime) {
      setState(() {
        selectedTime = pickedTime;
        formattedTime = selectedTime.format(context);
      });
    }
  }
}
