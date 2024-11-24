import 'package:flutter/material.dart';
import 'package:flutter_application/models/BottomNavigationBar.dart';
import 'package:flutter_application/pages/chatbot_page.dart';
import 'package:flutter_application/pages/home.dart';
import 'package:flutter_application/pages/profile_page.dart';
import 'package:flutter_application/pages/task_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ProgressPage(),
    );
  }
}

class ProgressPage extends StatefulWidget {
  const ProgressPage({Key? key}) : super(key: key);

  @override
  _ProgressPageState createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  String selectedSegment = "Task";
  String selectedTime = "Daily";
  int periodOffset = 0; // Tracks the offset for the date period navigation

  // Category Dropdown Variables
  List<String> availableCategories = ["All Categories"];
  String selectedCategory = "All Categories"; // Default selected category
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      fetchCategories(user.uid);
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchCategories(String userID) async {
    try {
      print("Fetching categories for userID: $userID");
      final snapshot = await FirebaseFirestore.instance
          .collection('Category')
          .where('userID', isEqualTo: userID)
          .get();

      if (snapshot.docs.isEmpty) {
        print("No categories found for userID: $userID");
      } else {
        print(
            "Fetched categories: ${snapshot.docs.map((doc) => doc['categoryName'])}");
      }

      setState(() {
        availableCategories = ["All Categories"] +
            snapshot.docs.map((doc) => doc['categoryName'] as String).toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching categories: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void handleCategoryChange(String? category) {
    if (category == null) return;

    setState(() {
      selectedCategory = category;
    });

    // Add logic here to filter or refresh the progress data based on the category
    print("Selected Category: $selectedCategory");
  }

  final colorList = <Color>[
    const Color(0xFF2F5496), // Dark Blue
    const Color(0xFFA5BBE3), // Light Blue
    const Color(0xFF3C6ABE), // Medium Blue
    const Color(0xFF79A3B7), // Slate Blue
    const Color(0xFFC7D3D4), // Soft Grayish Green
    const Color.fromARGB(255, 173, 193, 181), // Muted Mint Green
    const Color(0xFFF3D9C1), // Warm Beige
    const Color(0xFFE9A17A), // Muted Peach
    const Color(0xFFCBBACD), // Muted Lavender
    const Color(0xFF7F8C8D), // Gray
  ];
  String getCurrentDate(String selectedTime, int offset) {
    final now = DateTime.now();

    switch (selectedTime) {
      case "Daily":
        final targetDate = now.add(Duration(days: offset));
        return DateFormat('dd MMM yyyy').format(targetDate);
      case "Weekly":
        final startOfWeek = now.subtract(
            Duration(days: now.weekday % 7)); // Adjust to start week on Sunday
        final endOfWeek = startOfWeek.add(Duration(days: 6));
        return "${DateFormat('dd MMM').format(startOfWeek)} - ${DateFormat('dd MMM').format(endOfWeek)}";

      case "Monthly":
        final targetDate = DateTime(now.year, now.month + offset);
        return DateFormat('MMMM yyyy').format(targetDate);
      case "Yearly":
        final targetDate = DateTime(now.year + offset);
        return DateFormat('yyyy').format(targetDate);
      default:
        return DateFormat('dd MMM yyyy').format(now);
    }
  }

  @override
  @override
Widget build(BuildContext context) {
  final currentDate = getCurrentDate(selectedTime, periodOffset);
  var selectedIndex = 3;
  return Theme(
    data: ThemeData(
      textTheme: GoogleFonts.poppinsTextTheme(
        Theme.of(context).textTheme,
      ),
    ),
    child: Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Progress',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFEAEFF0),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSegmentControl(),
                      const SizedBox(height: 20),
                      _buildTimeSelector(),
                      const SizedBox(height: 20),
                      _buildDateNavigation(currentDate),
                      const SizedBox(height: 20),
                      _buildTaskSummaryCards(),
                      const SizedBox(height: 40),
                      if (selectedSegment == "Task") ...[
                        _buildCategoryChart(colorList),
                        const SizedBox(height: 40),
                        _buildTaskCompletionSection(),  
                      ],
                      if (selectedSegment == "Time") ...[
                        //this should be modified
                         _buildCategoryChart(colorList),
                        const SizedBox(height: 40),
                        _buildTaskCompletionSection(),  
                      ],
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: CustomNavigationBar(
        selectedIndex: selectedIndex,
  onTabChange: (index) {
    setState(() {
      selectedIndex = index;
    });
  },
      ),
    ),
  );
}


  Widget _buildSegmentControl() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: ["Time", "Task"].asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedSegment = option;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedSegment == option
                      ? const Color(0xFF79A3B7)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.horizontal(
                    left: index == 0 ? const Radius.circular(8) : Radius.zero,
                    right: index == 1 ? const Radius.circular(8) : Radius.zero,
                  ),
                ),
                child: Text(
                  option,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        selectedSegment == option ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: ["Daily", "Weekly", "Monthly", "Yearly"]
            .asMap()
            .entries
            .map((entry) {
          final index = entry.key;
          final option = entry.value;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedTime = option;
                  periodOffset =
                      0; // Reset the period offset when switching views
                });
                _updateDateRange();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedTime == option
                      ? const Color(0xFF79A3B7)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.horizontal(
                    left: index == 0 ? const Radius.circular(8) : Radius.zero,
                    right: index == 3 ? const Radius.circular(8) : Radius.zero,
                  ),
                ),
                child: Text(
                  option,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selectedTime == option ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _updateDateRange() {
    final now = DateTime.now();

    DateTime adjustedDate;
    switch (selectedTime) {
      case "Daily":
        adjustedDate = now.add(Duration(days: periodOffset));
        break;
      case "Weekly":
        adjustedDate = now.add(Duration(days: periodOffset * 7));
        break;
      case "Monthly":
        adjustedDate = DateTime(now.year, now.month + periodOffset);
        break;
      case "Yearly":
        adjustedDate = DateTime(now.year + periodOffset);
        break;
      default:
        adjustedDate = now;
    }

    final dateRange = _getDateRange(selectedTime, adjustedDate);

    setState(() {
      // Update the period range and print debug information
      print("Updated period: $selectedTime");
      print("Start of period: ${dateRange['start']}");
      print("End of period: ${dateRange['end']}");
    });

    // Trigger task re-fetching or any additional updates
    _refreshCategoryChart();
  }

  void _refreshCategoryChart() {
    // This will trigger a rebuild and refresh the category chart data
    setState(() {
      // Force re-fetch by updating dependent variables, if needed
    });
  }

  Widget _buildDateNavigation(String currentDate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              periodOffset -= 1; // Move to previous period
              _updateDateRange(); // Ensure tasks and dates are updated
            });
          },
          icon: const Icon(Icons.arrow_back),
        ),
        Text(
          currentDate,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              periodOffset += 1; // Move to next period
              _updateDateRange(); // Ensure tasks and dates are updated
            });
          },
          icon: const Icon(Icons.arrow_forward),
        ),
      ],
    );
  }

  Widget _buildTaskSummaryCards() {
  return StatefulBuilder(
    builder: (context, setState) {
      final currentDate = DateTime.now().add(
        Duration(days: periodOffset),
      ); // Adjust for the selected period offset

      return FutureBuilder<Map<String, int>>(
        future: fetchTaskCountsByStatus(selectedTime, currentDate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text("Error loading task counts"),
            );
          }

          final counts = snapshot.data ??
              {'uncompleted': 0, 'pending': 0, 'completed': 0};

          // Different views for "Task" and "Time"
          if (selectedSegment == "Task") {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTaskCard(
                  "Completed Task",
                  counts['completed'].toString(),
                  widthFactor: 0.4,
                ),
                _buildTaskCard(
                  "Pending Task",
                  counts['pending'].toString(),
                  widthFactor: 0.4,
                ),
              ],
            );
          } else if (selectedSegment == "Time") {
            return Center(
              child: _buildTaskCard(
                "Total Tasks",
                (counts['completed']! + counts['pending']!).toString(),
                widthFactor: 0.8, // Wider card for Time view
              ),
            );
          }

          return const SizedBox.shrink();
        },
      );
    },
  );
}


  Widget _buildTaskCard(String title, String count,
      {required double widthFactor}) {
    return Container(
      width: MediaQuery.of(context).size.width * widthFactor,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E2E2),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 1,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<Map<String, int>> fetchTaskCountsByStatus(
      String selectedTime, DateTime currentDate) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return {'uncompleted': 0, 'pending': 0, 'completed': 0};
    }

    // Define the start and end period based on `selectedTime`
    final dateRange = _getDateRange(selectedTime, currentDate);
    final startOfPeriod = dateRange['start']!;
    final endOfPeriod = dateRange['end']!;

    // Query Firestore for tasks within the date range
    final tasksSnapshot = await FirebaseFirestore.instance
        .collection('Task')
        .where('userID', isEqualTo: user.uid)
        .get();

    int uncompleted = 0;
    int pending = 0;
    int completed = 0;

    for (var doc in tasksSnapshot.docs) {
      final data = doc.data();
      final rawScheduledDate = data['scheduledDate'];
      final completionStatus = data['completionStatus'] ?? 0;

      DateTime? scheduledDate;

      // Parse Firestore date
      if (rawScheduledDate is String) {
        try {
          scheduledDate = DateFormat("MMMM d, yyyy 'at' h:mm:ss a z")
              .parse(rawScheduledDate);
        } catch (e) {
          print("Error parsing scheduledDate string: $e");
          continue;
        }
      } else if (rawScheduledDate is Timestamp) {
        scheduledDate = rawScheduledDate.toDate();
      }

      if (scheduledDate != null &&
          scheduledDate.isAfter(startOfPeriod) &&
          scheduledDate.isBefore(endOfPeriod)) {
        if (completionStatus == 0) {
          uncompleted++;
        } else if (completionStatus == 1) {
          pending++;
        } else if (completionStatus == 2) {
          completed++;
        }
      }
    }

    return {
      'uncompleted': uncompleted,
      'pending': pending,
      'completed': completed
    };
  }

  Widget _buildCategoryChart(List<Color> colorList) {
    // Adjust currentDate based on the periodOffset and selectedTime
    DateTime adjustedDate;
    final now = DateTime.now();

    switch (selectedTime) {
      case "Daily":
        adjustedDate = now.add(Duration(days: periodOffset));
        break;
      case "Weekly":
        final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
        adjustedDate = currentWeekStart.add(Duration(days: periodOffset * 7));
        break;
      case "Monthly":
        adjustedDate = DateTime(now.year, now.month + periodOffset, 1);
        break;
      case "Yearly":
        adjustedDate = DateTime(now.year + periodOffset, 1, 1);
        break;
      default:
        adjustedDate = now;
    }

    return FutureBuilder<Map<String, int>>(
      future: countTasksByCategory(selectedTime, adjustedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading data"));
        }

        final dataMap = snapshot.data ?? {};
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Category Chart",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (dataMap.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Text(
                      "No tasks in the selected period",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: dataMap.keys.map((key) {
                          final colorIndex =
                              dataMap.keys.toList().indexOf(key) %
                                  colorList.length;
                          return _buildLegend(key, colorList[colorIndex]);
                        }).toList(),
                      ),
                    ),
                    CategoryChart(dataMap: dataMap, colorList: colorList),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, int>> countTasksByCategory(
      String selectedTime, DateTime currentDate) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("No user logged in.");
      return {};
    }

    // Calculate the start and end dates dynamically based on the selected time
    final dateRange = _getDateRange(selectedTime, currentDate);
    var startOfPeriod = dateRange['start']!;
    var endOfPeriod = dateRange['end']!;

    // Convert dates to UTC for consistent comparison
    startOfPeriod = startOfPeriod.toUtc();
    endOfPeriod = endOfPeriod.toUtc();

    print("Selected period: $selectedTime");
    print("Start of period: $startOfPeriod");
    print("End of period: $endOfPeriod");

    try {
      // Fetch categories for the specific user
      final categoriesSnapshot = await FirebaseFirestore.instance
          .collection('Category')
          .where('userID', isEqualTo: user.uid)
          .get();

      if (categoriesSnapshot.docs.isEmpty) {
        print("No categories found for user: ${user.uid}");
        return {};
      }

      // Build task ID to category name map
      final taskIDToCategoryMap = <String, String>{};
      for (var doc in categoriesSnapshot.docs) {
        final data = doc.data();
        final categoryName = data['categoryName'] ?? 'Uncategorized';
        final taskIDs = List<String>.from(data['taskIDs'] ?? []);

        for (var taskID in taskIDs) {
          taskIDToCategoryMap[taskID] = categoryName;
        }
      }

      print("Task-to-category mapping: $taskIDToCategoryMap");

      // Fetch tasks for the specific user within the date range
      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('Task')
          .where('userID', isEqualTo: user.uid)
          .where('scheduledDate', isGreaterThanOrEqualTo: startOfPeriod)
          .where('scheduledDate', isLessThanOrEqualTo: endOfPeriod)
          .get();

      if (tasksSnapshot.docs.isEmpty) {
        print("No tasks found for user: ${user.uid}");
        return {};
      }

      print(
          "Tasks fetched for user: ${tasksSnapshot.docs.map((doc) => doc.id).toList()}");

      // Map to count tasks by category
      final taskCounts = <String, int>{};

      for (var doc in tasksSnapshot.docs) {
        final data = doc.data();
        final taskID = doc.id;

        final categoryName = taskIDToCategoryMap[taskID] ?? 'Uncategorized';
        taskCounts[categoryName] = (taskCounts[categoryName] ?? 0) + 1;
        print(
            "Task ${taskID} belongs to category '${categoryName}'. Updated count: ${taskCounts[categoryName]}");
      }

      print("Final task counts by category: $taskCounts");
      return taskCounts;
    } catch (e) {
      print("Error fetching tasks: $e");
      return {};
    }
  }

// Helper function to get date range
  Map<String, DateTime> _getDateRange(
      String selectedTime, DateTime currentDate) {
    DateTime startOfPeriod;
    DateTime endOfPeriod;

    switch (selectedTime) {
      case 'Daily':
        startOfPeriod =
            DateTime(currentDate.year, currentDate.month, currentDate.day);
        endOfPeriod = startOfPeriod
            .add(const Duration(days: 1))
            .subtract(const Duration(seconds: 1));
        break;
      case 'Weekly':
        final startOfWeek = currentDate.subtract(Duration(
            days: currentDate.weekday % 7)); // % 7 makes Sunday the first day
        startOfPeriod =
            DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day)
                .add(Duration(days: periodOffset * 7));
        endOfPeriod = startOfPeriod
            .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

        break;
      case 'Monthly':
        // Adjust by the periodOffset for months
        startOfPeriod =
            DateTime(currentDate.year, currentDate.month + periodOffset, 1);
        final nextMonth =
            DateTime(startOfPeriod.year, startOfPeriod.month + 1, 1);
        endOfPeriod = nextMonth.subtract(const Duration(seconds: 1));
        break;
      case 'Yearly':
        // Adjust by the periodOffset for years
        startOfPeriod = DateTime(currentDate.year + periodOffset, 1, 1);
        endOfPeriod = DateTime(startOfPeriod.year + 1, 1, 1)
            .subtract(const Duration(seconds: 1));
        break;
      default:
        startOfPeriod =
            DateTime(currentDate.year, currentDate.month, currentDate.day);
        endOfPeriod = startOfPeriod
            .add(const Duration(days: 1))
            .subtract(const Duration(seconds: 1));
    }

    return {'start': startOfPeriod, 'end': endOfPeriod};
  }

  Widget _buildLegend(String key, Color color) {
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 14),
        const SizedBox(width: 5),
        Text(
          key,
          style: const TextStyle(fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildTaskCompletionSection() {
    return FutureBuilder<List<_ChartData>>(
      future: fetchChartData(
        selectedTime,
        DateTime.now().add(Duration(days: periodOffset)),
        selectedCategory, // Pass the selected category
      ),
      builder: (context, snapshot) {
        // Dropdown is always visible
        Widget dropdown = Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Task Completion by Category",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: DropdownUnderWidget(
                  availableCategories: availableCategories,
                  selectedCategory: selectedCategory,
                  onCategoryChange: handleCategoryChange,
                ),
              ),
            ],
          ),
        );

        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                dropdown,
                const SizedBox(height: 20),
                const Center(child: CircularProgressIndicator()),
              ],
            ),
          );
        }

        // Handle error or no data
        if (snapshot.hasError ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                dropdown,
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    "No tasks in the selected period",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        }

        // Handle valid data
        final data = snapshot.data!;
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              dropdown,
              const SizedBox(height: 20),
              SizedBox(
                height: 300,
                child: SfCartesianChart(
                  legend: Legend(isVisible: true),
                  primaryXAxis: CategoryAxis(
                    title: AxisTitle(text: "Time Period"),
                  ),
                  primaryYAxis: NumericAxis(
                    title: AxisTitle(text: "Completed Tasks"),
                    minimum: 0,
                  ),
                  series: _buildStackedColumnSeries(data),
                  tooltipBehavior: TooltipBehavior(enable: true),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<StackedColumnSeries<_ChartData, String>> _buildStackedColumnSeries(
      List<_ChartData> data) {
    final categories = data
        .expand((item) => item.categoryData.keys)
        .toSet(); // Get unique categories

    // Map each category to a unique color from colorList
    final Map<String, Color> categoryColors = {
      for (var i = 0; i < categories.length; i++)
        categories.elementAt(i): colorList[i % colorList.length]
    };

    return categories.map((category) {
      return StackedColumnSeries<_ChartData, String>(
        dataSource: data,
        xValueMapper: (datum, _) => datum.periodLabel,
        yValueMapper: (datum, _) => datum.categoryData[category] ?? 0,
        name: category,
        color: categoryColors[category],
      );
    }).toList();
  }

  Future<List<_ChartData>> fetchChartData(String selectedTime,
      DateTime currentDate, String selectedCategory) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("No user logged in.");
      return [];
    }

    try {
      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('Task')
          .where('userID', isEqualTo: user.uid)
          .get();

      final categoriesSnapshot = await FirebaseFirestore.instance
          .collection('Category')
          .where('userID', isEqualTo: user.uid)
          .get();

      final taskIDToCategoryMap = <String, String>{};
      for (var categoryDoc in categoriesSnapshot.docs) {
        final data = categoryDoc.data();
        final categoryName = data['categoryName'] ?? 'Uncategorized';
        final taskIDs = List<String>.from(data['taskIDs'] ?? []);

        for (var taskID in taskIDs) {
          taskIDToCategoryMap[taskID] = categoryName;
        }
      }

      final dateRange = _getDateRange(selectedTime, currentDate);
      final startOfPeriod = dateRange['start']!;
      final endOfPeriod = dateRange['end']!;

      final filteredTasks = tasksSnapshot.docs.where((taskDoc) {
        final data = taskDoc.data();
        final taskId = taskDoc.id;
        final completionStatus = data['completionStatus'];
        final scheduledDate = (data['scheduledDate'] as Timestamp).toDate();
        final categoryName = taskIDToCategoryMap[taskId] ?? 'Uncategorized';

        return completionStatus == 2 &&
            scheduledDate.isAfter(startOfPeriod) &&
            scheduledDate.isBefore(endOfPeriod) &&
            (selectedCategory == "All Categories" ||
                categoryName == selectedCategory);
      }).toList();

      final categoryCounts = <String, int>{};
      for (var taskDoc in filteredTasks) {
        final taskId = taskDoc.id;
        final categoryName = taskIDToCategoryMap[taskId] ?? 'Uncategorized';
        categoryCounts[categoryName] = (categoryCounts[categoryName] ?? 0) + 1;
      }

      if (categoryCounts.isEmpty) {
        return [];
      }

      final chartData = [
        _ChartData(
          getCurrentDate(selectedTime, periodOffset),
          categoryCounts,
        )
      ];

      return chartData;
    } catch (e) {
      print("Error fetching chart data: $e");
      return [];
    }
  }
}

class CategoryChart extends StatefulWidget {
  final Map<String, int> dataMap;
  final List<Color> colorList;

  const CategoryChart({
    Key? key,
    required this.dataMap,
    required this.colorList,
  }) : super(key: key);

  @override
  State<CategoryChart> createState() => _CategoryChartState();
}

class _CategoryChartState extends State<CategoryChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.shortestSide * 0.5,
      height: MediaQuery.of(context).size.shortestSide * 0.5,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (event, pieTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  touchedIndex = -1;
                  return;
                }
                touchedIndex =
                    pieTouchResponse.touchedSection!.touchedSectionIndex;
              });
            },
          ),
          sections: getSections(),
          sectionsSpace: 5,
          centerSpaceRadius: 40,
          startDegreeOffset: 0.0,
        ),
      ),
    );
  }

  List<PieChartSectionData> getSections() {
    final categories = widget.dataMap.keys.toList();
    return List.generate(
      categories.length,
      (i) {
        final isTouched = i == touchedIndex;
        final value = widget.dataMap[categories[i]]!.toDouble();

        return PieChartSectionData(
          color: widget.colorList[i % widget.colorList.length],
          value: value,
          radius: isTouched ? 45 : 40,
          showTitle: false,
          badgeWidget: isTouched
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black, // Black background for the tooltip
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    '$value tasks',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Always white text
                    ),
                  ),
                )
              : null,
          badgePositionPercentageOffset: 1.2,
        );
      },
    );
  }
}

class _ChartData {
  final String periodLabel;
  final Map<String, int> categoryData;

  _ChartData(this.periodLabel, this.categoryData);
}

class DropdownUnderWidget extends StatefulWidget {
  final List<String> availableCategories;
  final String selectedCategory;
  final ValueChanged<String?> onCategoryChange;

  const DropdownUnderWidget({
    Key? key,
    required this.availableCategories,
    required this.selectedCategory,
    required this.onCategoryChange,
  }) : super(key: key);

  @override
  State<DropdownUnderWidget> createState() => _DropdownUnderWidgetState();
}

class _DropdownUnderWidgetState extends State<DropdownUnderWidget> {
  late String selectedValue;

  @override
  void initState() {
    super.initState();
    // Ensure the selected value is valid, defaulting to "All Categories" if invalid
    selectedValue = widget.availableCategories.contains(widget.selectedCategory)
        ? widget.selectedCategory
        : "All Categories";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFDDE2E4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF79A3B7)),
      ),
      child: DropdownButton<String>(
        value: widget.availableCategories.contains(selectedValue)
            ? selectedValue
            : null, // Ensure the value exists in the list
        isExpanded: true,
        dropdownColor: const Color(0xFFF5F7F8),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
        underline: Container(), // Removes the default underline
        items: widget.availableCategories
            .toSet() // Ensure unique items
            .toList()
            .map((String category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(
              category,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
        onChanged: (newCategory) {
          if (newCategory != null) {
            setState(() {
              selectedValue = newCategory;
            });
            widget.onCategoryChange(newCategory);
          }
        },
      ),
    );
  }
}
