import 'package:flutter/material.dart';
import 'package:flutter_application/pages/editTask.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_application/pages/timer_page';
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

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now(); // اليوم المحدد
  List<Map<String, dynamic>> tasks = []; // تخزين المهام المسترجعة

  bool isLoading = true;
  String? userID;

  @override
  void initState() {
    super.initState();
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        userID = null;
        isLoading = false;
      });
    } else {
      userID = user.uid;
      fetchTasksFromFirestore();
    }
  }

  Future<void> fetchTasksFromFirestore() async {
    setState(() {
      isLoading = true;
    });

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DateTime startOfDay = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));

    QuerySnapshot taskSnapshot = await firestore
        .collection('Task')
        .where('userID', isEqualTo: userID)
        .get();

    setState(() {
      tasks = taskSnapshot.docs.map((taskDoc) {
        Map<String, dynamic> taskData = taskDoc.data() as Map<String, dynamic>;
        DateTime taskTime = (taskData['scheduledDate'] as Timestamp).toDate();
        return {
          'id': taskDoc.id,
          'title': taskData['title'] ?? 'Untitled',
          'time': taskTime,
          'priority': taskData['priority'] as int,
          'completed': taskData['completionStatus'] == 2,
          'categories': taskData['categories'] ?? ['Uncategorized'],
          'expanded': false,
          'subtasks': []
        };
      }).where((task) =>
          task['time'].isAfter(startOfDay) &&
          task['time'].isBefore(endOfDay)).toList();
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

  void showAddTaskDialog() async {
    bool? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddTaskPage()),
    );

    if (result == true) {
      fetchTasksFromFirestore();
    }
  }

  String getFormattedDate() {
    return DateFormat('EEE, d MMM yyyy').format(_focusedDay);
  }

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
                  color: Color(0xFF545454),
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
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF79A3B7))),
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
                  child: const Text('Apply', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
          backgroundColor: const Color.fromARGB(255, 226, 231, 234),
          elevation: 0,
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
              icon: const Icon(Icons.more_vert, color: Colors.black),
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: 'view',
                    child: Row(
                      children: const [
                        Icon(Icons.visibility, size: 24),
                        SizedBox(width: 10),
                        Text('View', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'sort',
                    child: Row(
                      children: const [
                        Icon(Icons.sort, size: 24),
                        SizedBox(width: 10),
                        Text('Sort', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'categorize',
                    child: Row(
                      children: const [
                        Icon(Icons.label, size: 24),
                        SizedBox(width: 10),
                        Text('Categorize', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2010, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
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
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Expanded(
                      child: ListView(
                        children: tasks.map((task) {
                          return ListTile(
                            title: Text(task['title']),
                            subtitle: Text(getFormattedDate()),
                          );
                        }).toList(),
                      ),
                    ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: showAddTaskDialog,
          backgroundColor: const Color(0xFF3B7292),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  void showSortDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Color(0xFFF5F7F8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              title: const Text(
                'Sort by',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF545454), // Dark gray color for title
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    activeColor: const Color(0xFF79A3B7),
                    title: const Text(
                      'Time',
                      style:
                          TextStyle(color: Color(0xFF545454)), // Dark gray text
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
                      style:
                          TextStyle(color: Color(0xFF545454)), // Dark gray text
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
                  child: const Text('Cancel',
                      style: TextStyle(color: Color(0xFF79A3B7))),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Perform sorting action here
                    });
                    Navigator.of(context).pop();
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

  void showCategoryDialog() {
    List<String> tempSelectedCategories = List.from(selectedCategories);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFF5F7F8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const Text(
            'Category',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF545454), // Dark gray for title
            ),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: ['All', 'Uncategorized', 'Work', 'Personal']
                    .map((category) => ChoiceChip(
                          label: Text(category),
                          labelStyle: const TextStyle(
                            color: Colors
                                .white, // White text color for selected chips
                          ),
                          selected: tempSelectedCategories.contains(category),
                          selectedColor: const Color(
                              0xFF79A3B7), // Custom color for selected chips
                          backgroundColor:
                              Colors.grey[300], // Color for unselected chips
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                if (!tempSelectedCategories
                                    .contains(category)) {
                                  tempSelectedCategories.add(category);
                                }
                              } else {
                                tempSelectedCategories
                                    .removeWhere((item) => item == category);
                              }
                            });
                          },
                        ))
                    .toList(),
              );
            },
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
              child: const Text('Apply', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
