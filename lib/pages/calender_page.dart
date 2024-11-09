import 'package:flutter/material.dart';
import 'package:flutter_application/pages/task_page.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  String selectedSort = 'timeline';
  List<String> selectedCategories = [];
  CalendarFormat _calendarFormat = CalendarFormat.month;

  DateTime _focusedDay = DateTime.now(); // استخدم هذا لتحديث اليوم المركّز
  DateTime? _selectedDay; // استخدم هذا لتحديد اليوم الذي يختاره المستخدم

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
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
            PopupMenuTheme(
              data: PopupMenuThemeData(
                color: Color(0xFFF5F7F8),
              ),
              child: PopupMenuButton<String>(
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
                          Icon(Icons.list, size: 24),
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
            ),
          ],
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TableCalendar(
                    firstDay: DateTime.utc(2010, 10, 16),
                    lastDay: DateTime.utc(2030, 3, 14),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) {
                      // للتحقق ما إذا كان اليوم هو اليوم المحدد
                      return isSameDay(_selectedDay, day);
                    },
                   onDaySelected: (selectedDay, focusedDay) {
  if (selectedDay.isBefore(DateTime.utc(2030, 3, 14)) &&
      selectedDay.isAfter(DateTime.utc(2010, 10, 16))) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }
},

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
                      // تحديث اليوم المركّز عند تغيير الشهر
                      _focusedDay = focusedDay;
                    },
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: const TextStyle(color: Colors.black),
                      weekendTextStyle: const TextStyle(color: Colors.black),
                     todayDecoration: BoxDecoration(
  shape: BoxShape.circle,
  border: Border.all(color: Color(0xFF3B7292), width: 2), // اللون والحجم للحواف
),
 todayTextStyle: TextStyle(color: Colors.black), // لضبط لون النص داخل الدائرة
                      selectedDecoration: BoxDecoration(
                         color: const Color(0xFF3B7292),
  shape: BoxShape.circle, // استخدام الدائرة هنا
  // أو إذا كنت تفضل الشكل المستطيل بزوايا مستديرة، استخدم هذا السطر بدلًا من ذلك:
  // borderRadius: BorderRadius.circular(30),
),
                      ),
                    ),
                  
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  

  void showViewDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedView = 'calendar'; // Default view selection
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Color(0xFFF5F7F8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              title: const Text(
                'View Options',
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
                      'View as List',
                      style:
                          TextStyle(color: Color(0xFF545454)), // Dark gray text
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
                    activeColor: const Color(0xFF79A3B7),
                    title: const Text(
                      'View as Calendar',
                      style:
                          TextStyle(color: Color(0xFF545454)), // Dark gray text
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
