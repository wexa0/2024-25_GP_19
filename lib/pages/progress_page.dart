import 'package:flutter/material.dart';
import 'package:flutter_application/Classes/Task';
import 'package:flutter_application/models/BottomNavigationBar.dart';
import 'package:flutter_application/models/GuestBottomNavigationBar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_application/Classes/Category';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:streak_calendar/streak_calendar.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({Key? key}) : super(key: key);

  @override
  _ProgressPageState createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  String? userID;
  int selectedIndex = 3;
  String selectedSegment = "Time";
  String selectedTime = "Daily";
  int periodOffset = 0; // Tracks the offset for the date period navigation

  // Category Dropdown Variables
  List<String> availableCategories = [];
  String selectedCategory = "All"; // Default selected category
  bool isLoading = true;

  // Store the mapping of taskID to its categoryName
  Map<String, String> taskIDToCategoryMap = {};

  final colorList = <Color>[
    const Color(0xFF0072B2), // Strong Blue
    const Color(0xFFE69F00), // Orange
    const Color(0xFF56B4E9), // Sky Blue
    const Color(0xFF009E73), // Green
    const Color(0xFFF0E442), // Yellow
    const Color(0xFFD55E00), // Vermilion (red-orange)
    const Color(0xFFCC79A7), // Pinkish Purple
    const Color(0xFF999999), // Medium Gray
    const Color(0xFF8C564B), // Brownish Red
    const Color(0xFF5D9CBE), // Muted Blue-Gray
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserID();
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fetch categories when the user is logged in
      fetchCategories(user.uid);
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchUserID() async {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      userID = user?.uid; // Set userID if logged in, otherwise null
    });
  }

  @override
  Widget build(BuildContext context) {
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
                        _buildPeriodSelector(),
                        const SizedBox(height: 20),
                        _buildDateNavigation(
                            formattedCurrentDate(selectedTime, periodOffset)),
                        const SizedBox(height: 10),
                        _buildProgressMessageCard(),
                        const SizedBox(height: 10),
                        _buildTaskSummaryCards(),
                        const SizedBox(height: 20),
                        if (selectedSegment == "Task") ...[
                          _buildCategoryChart(colorList),
                          const SizedBox(height: 40),
                          _buildTaskCompletionSection(),
                        ],
                        if (selectedSegment == "Time") ...[
                          _buildStreakCalendar(),
                          const SizedBox(height: 40),
                          _buildTimeSpentSection(),
                          //_buildTaskSpentTimeSection(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: userID != null
            ? CustomNavigationBar(
                selectedIndex: selectedIndex,
                onTabChange: (index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
              )
            : GuestCustomNavigationBar(
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

  Widget _buildProgressMessageCard() {
    final currentDate = DateTime.now(); // Current date for task calculation

    return FutureBuilder<Map<String, int>>(
      future:
          countTasksByStatus(selectedTime, currentDate), // Fetch task counts
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Error loading task counts"));
        }

        final counts =
            snapshot.data ?? {'uncompleted': 0, 'pending': 0, 'completed': 0};

        // Calculate total tasks and completion percentage
        int totalTasks =
            counts['uncompleted']! + counts['pending']! + counts['completed']!;
        double completionPercentage =
            totalTasks == 0 ? 0.0 : counts['completed']! / totalTasks;

        // Format percentage to display with two decimal places
        String formattedPercentage =
            (completionPercentage * 100).toStringAsFixed(0);

        // Generate the appropriate progress message based on the calculated percentage
        String getProgressMessage(double percentage, int totalTasks) {
          if (totalTasks == 0) {
            return "It looks like you haven’t started planning yet! Let’s set some goals and begin your journey—Ateena is here to help!";
          } else if (percentage < 0.15) {
            return "Need help? Ateena is always here to assist you! You're at $formattedPercentage% of your tasks.";
          } else if (percentage < 0.25) {
            return "You’ve only completed $formattedPercentage%. Let’s focus on one small task! Ateena is here if you need any help.";
          } else if (percentage < 0.50) {
            return "Small steps matter! You’re at $formattedPercentage%. Let’s tackle one task together. You've got this!";
          } else if (percentage <= 0.70) {
            return "Great progress! You’ve reached $formattedPercentage%. Stay focused on your priorities, and you’ll achieve even more. Keep going!";
          } else if (percentage <= 0.85) {
            return "You’re doing amazing! With a little extra focus, you’ll finish strong. You’re at $formattedPercentage%, so celebrate your wins!";
          } else if (percentage < 1.00) {
            return "Incredible work! Your effort is paying off—keep up the fantastic momentum! You’re almost there at $formattedPercentage%!";
          } else {
            return "You’ve completed all your work—great job!";
          }
        }

        // Get the screen width for responsive design
        double screenWidth = MediaQuery.of(context).size.width;

        // Adjust widthFactor as 80% of the screen width (can adjust as needed)
        double widthFactor = 0.85;

        return Center(
          child: Container(
            width:
                screenWidth * widthFactor, // Adjust width based on widthFactor
            padding: const EdgeInsets.symmetric(
                vertical: 16, horizontal: 22), // Same padding as _buildTaskCard
            margin: const EdgeInsets.symmetric(
                vertical: 10), // Same margin as _buildTaskCard
            decoration: BoxDecoration(
              color: const Color(0xFFE2E2E2), // Set background color
              borderRadius: BorderRadius.circular(15), // Rounded corners
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26, // Shadow color
                  blurRadius: 1, // Shadow blur effect
                  offset: Offset(0, 2), // Shadow position
                ),
              ],
            ),
            child: Column(
              children: [
                // Dynamic progress message based on the calculation
                Text(
                  getProgressMessage(completionPercentage, totalTasks),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSegment(String label, {required bool isSelected}) {
    // to switch between Time and Task Progress
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedSegment = label;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF79A3B7) : Colors.grey[200],
            borderRadius: BorderRadius.horizontal(
              left: label == "Time" ? Radius.circular(20) : Radius.zero,
              right: label == "Task" ? Radius.circular(20) : Radius.zero,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    // to switch between period progress
    const List<String> labels = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
    const Color activeColor = Color(0xFF79A3B7);

    return LayoutBuilder(
      builder: (context, constraints) {
        double segmentWidth = constraints.maxWidth /
            labels.length; // Dynamic segment width based on label count

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: ToggleSwitch(
            minWidth: segmentWidth, // Set width based on calculation
            cornerRadius: 8.0, // Rounded corners
            activeBgColors: List.generate(labels.length,
                (_) => [activeColor]), // Active color for each option
            activeFgColor: Colors.white, // Text color for active option
            inactiveBgColor:
                Colors.grey[200]!, // Background color for inactive options
            inactiveFgColor: Colors.black, // Text color for inactive options
            initialLabelIndex:
                labels.indexOf(selectedTime), // Get initial index dynamically
            totalSwitches: labels.length, // Number of options
            labels: labels, // Use predefined labels
            onToggle: (index) {
              if (index != null) {
                // Ensure index is not null
                setState(() {
                  selectedTime = labels[index]; // Set the selected time option
                  periodOffset =
                      0; // Reset the period offset when switching views
                });
                getCurrentDate(selectedTime,
                    periodOffset); // Update date range based on the new selection
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildSegmentControl() {
    return Container(
      width: double.infinity, // Full width of the parent
      child: Row(
        children: [
          _buildSegment("Time", isSelected: selectedSegment == "Time"),
          _buildSegment("Task", isSelected: selectedSegment == "Task"),
        ],
      ),
    );
  }

  Widget _buildDateNavigation(String currentDate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              periodOffset -= 1; // Move to previous period
              getCurrentDate(selectedTime,
                  periodOffset); // Ensure tasks and dates are updated
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
              getCurrentDate(selectedTime,
                  periodOffset); // Ensure tasks and dates are updated
            });
          },
          icon: const Icon(Icons.arrow_forward),
        ),
      ],
    );
  }

  Widget _buildTaskSummaryCards() {
    //Present the total number of task/time
    final currentDate = DateTime.now().add(Duration(days: periodOffset));

    return FutureBuilder<Map<String, int>>(
      future: countTasksByStatus(selectedTime, currentDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Error loading task counts"));
        }

        final counts =
            snapshot.data ?? {'uncompleted': 0, 'pending': 0, 'completed': 0};

        // Generate Task cards based on selectedSegment
        return selectedSegment == "Task"
            ? _buildTaskCards(counts)
            : selectedSegment == "Time"
                ? _buildTotalTimeCard()
                : const SizedBox.shrink();
      },
    );
  }

  Widget _buildTaskCards(Map<String, int> counts) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTaskCard("Completed Task", counts['completed'].toString(),
            widthFactor: 0.4),
        _buildTaskCard("Pending Task", counts['pending'].toString(),
            widthFactor: 0.4),
      ],
    );
  }

//this will be modified
  Widget _buildTotalTimeCard() {
    return FutureBuilder<double>(
      future: _fetchSpentHoursByPeriod(selectedTime), // Fetch spent hours
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator()); // Show loading indicator
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          ); // Show error message if an error occurs
        }

        // Get the total spent hours
        final spentHours = snapshot.data ?? 0.0;

        return Center(
          child: _buildTaskCard(
            "Time Spent",
            "${spentHours.toStringAsFixed(2)} Hours", // Display hours with two decimal points
            widthFactor: 0.85, // Wider card for Time view
          ),
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
          ),
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

  /// Helper method to build the CleanCalendar widget for streaks, wrapped in a styled card
  Widget _buildStreakCalendar() {
    return FutureBuilder<List<DateTime>>(
      future: _fetchStreakDates(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Error loading streak dates"));
        }

        // Use the calculated streak dates from the Future
        List<DateTime> streakDates = snapshot.data ?? [];
        DateTime today = DateTime.now();

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9), // Background color
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5), // Shadow color
                blurRadius: 6, // Blur radius
                offset: const Offset(0, 3), // Shadow offset
              ),
            ],
            borderRadius: BorderRadius.circular(16), // Rounded corners
          ),
          padding: const EdgeInsets.all(20), // Inner padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Streak Calendar",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16), // Space between title and calendar
              CleanCalendar(
                // Pass streak dates dynamically
                datesForStreaks: streakDates,

                // Conditionally set the calendar view
                datePickerCalendarView:
                    (selectedTime == "Daily" || selectedTime == "Weekly")
                        ? DatePickerCalendarView.weekView
                        : DatePickerCalendarView.monthView,

                // Apply properties to the current date
                currentDateProperties: DatesProperties(
                  datesDecoration: DatesDecoration(
                    datesBorderRadius: 1000,
                    datesBackgroundColor: Colors.transparent,
                    datesBorderColor:
                        Colors.red, // Highlight current date with a red border
                    datesTextColor: Colors.black,
                  ),
                ),

                // Apply general properties to other dates
                generalDatesProperties: DatesProperties(
                  datesDecoration: DatesDecoration(
                    datesBorderRadius: 1000,
                    datesBackgroundColor: Colors.grey[200],
                    datesBorderColor: const Color.fromARGB(255, 205, 203, 203),
                    datesTextColor: Colors.black,
                  ),
                ),

                // Style for streak dates
                streakDatesProperties: DatesProperties(
                  datesDecoration: DatesDecoration(
                    datesBorderRadius: 1000,
                    datesBackgroundColor: const Color(0xFF79A3B7),
                    datesBorderColor: const Color.fromARGB(255, 91, 126, 142),
                    datesTextColor: Colors.white,
                  ),
                ),

                // Style for leading and trailing dates
                leadingTrailingDatesProperties: DatesProperties(
                  datesDecoration: DatesDecoration(
                    datesBorderRadius: 1000,
                    datesBackgroundColor: Colors.transparent, // No background
                    datesBorderColor: Colors.transparent, // No border
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<DateTime>> _fetchStreakDates() async {
    // Fetch the current user
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return []; // No user, return an empty list
    }

    List<DateTime> streakDates = [];

    // Fetch tasks for the current user
    final tasksSnapshot = await FirebaseFirestore.instance
        .collection('Task')
        .where('userID', isEqualTo: user.uid)
        .get();

    for (var doc in tasksSnapshot.docs) {
      final data = doc.data();
      final timerList = data['timer'];

      if (timerList is List) {
        for (var timerEntry in timerList) {
          if (timerEntry is Map) {
            // Ensure `time`, `startTime`, and `endTime` fields are not empty after trimming
            final timeField = timerEntry['time']?.toString().trim();
            final startTimeField = timerEntry['startTime']?.toString().trim();
            final endTimeField = timerEntry['endTime']?.toString().trim();

            // Check for valid `time` and corresponding `dateTime`
            if (timeField != "" && timeField != null) {
              final dateTime = parseDateTime(timerEntry['dateTime']);
              if (dateTime != null) streakDates.add(dateTime);
            }

            // Check for valid `startTime` and corresponding `startDateTime`
            if (startTimeField != "" && startTimeField != null) {
              final startDateTime = parseDateTime(timerEntry['startDateTime']);
              if (startDateTime != null) streakDates.add(startDateTime);
            }

            // Check for valid `endTime` and corresponding `endDateTime`
            if (endTimeField != "" && endTimeField != null) {
              final endDateTime = parseDateTime(timerEntry['endDateTime']);
              if (endDateTime != null) streakDates.add(endDateTime);
            }
          }
        }
      }
    }

    // Remove duplicates and return streak dates
    return streakDates
        .toSet()
        .toList(); // Use Set to ensure unique streak dates
  }

// Helper function to parse date and time strings into DateTime objects
  DateTime? parseDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return null;

    try {
      // Parse using the expected format of "HH:mm dd/MM/yyyy"
      return DateFormat('H:mm dd/MM/yyyy').parse(dateTimeString);
    } catch (e) {
      print("Error parsing dateTime string: $dateTimeString, error: $e");
      return null;
    }
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
            color: Color(0xFFF9F9F9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5), // Shadow color
                blurRadius: 6, // Blur radius
                offset: const Offset(0, 3), // Shadow offset
              ),
            ],
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

// Method to build stacked series for the chart
  List<ChartSeries<TaskCompletionData, String>> _buildStackedSeries(
      List<TaskCompletionData> data) {
    // Get all unique categories
    Set<String> categories = {};
    data.forEach((periodData) {
      categories
          .addAll(periodData.categoryCounts.keys); // Collect all category keys
    });

    List<ChartSeries<TaskCompletionData, String>> series = [];
    int colorIndex = 0;

    // Loop through categories and create stacked series for each
    for (var category in categories) {
      series.add(
        StackedColumnSeries<TaskCompletionData, String>(
          dataSource: data,
          xValueMapper: (TaskCompletionData data, _) =>
              data.period, // Use the period value (e.g., day, week, etc.)
          yValueMapper: (TaskCompletionData data, _) =>
              data.categoryCounts[category] ??
              0, // Task count for each category
          name: category, // Name of the category (e.g., "Work", "Personal")
          color: colorList[colorIndex %
              colorList.length], // Assign color from the pre-defined color list
          markerSettings:
              MarkerSettings(isVisible: false), // Hide the circular markers
        ),
      );
      colorIndex++; // Move to the next color in the list
    }

    return series;
  }

// Helper function to get all periods (even those without tasks)
  Widget _buildTaskCompletionSection() {
    return FutureBuilder<List<Task>>(
      future: Task.fetchTasksForUser(FirebaseAuth.instance.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Error loading tasks"));
        }

        final tasks = snapshot.data ?? [];

        // Get current DateTime instead of a string
        final currentDate =
            getCurrentDate(selectedTime, periodOffset); // Get DateTime directly

        return FutureBuilder<List<Task>>(
          future: filterTasksBySelectedPeriod(
            selectedTime,
            currentDate, // Now passing DateTime here
            tasks,
          ),
          builder: (context, filterSnapshot) {
            if (filterSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (filterSnapshot.hasError) {
              return const Center(child: Text("Error filtering tasks"));
            }

            final filteredTasks = filterSnapshot.data ?? [];

            // Initialize a map to hold task counts by period and category
            Map<String, Map<String, int>> tasksByPeriodAndCategory = {};

            // Group tasks by period (day, week, month, year) and category
            for (var task in filteredTasks) {
              // Check for completed tasks (completionStatus == 2)
              if (task.completionStatus == 2) {
                //check id the task is completed
                String period = getPeriodLabel(task.scheduledDate);
                String category =
                    taskIDToCategoryMap[task.taskID] ?? 'Uncategorized';

                // Skip tasks that don't match the selected category
                if (selectedCategory != "All" && category != selectedCategory) {
                  continue;
                }

                // Initialize category count for the period if it doesn't exist
                if (!tasksByPeriodAndCategory.containsKey(period)) {
                  tasksByPeriodAndCategory[period] = {};
                }

                if (!tasksByPeriodAndCategory[period]!.containsKey(category)) {
                  tasksByPeriodAndCategory[period]![category] = 0;
                }

                tasksByPeriodAndCategory[period]![category] =
                    tasksByPeriodAndCategory[period]![category]! + 1;
              }
            }

            // Ensure that all periods (day, week, month, year) have an entry, even if it's zero
            List<TaskCompletionData> chartData = [];
            Set<String> allPeriods = _getAllPeriods(
                currentDate); // Get all periods that should be represented

            // Create chart data for all periods, even those with no tasks
            allPeriods.forEach((period) {
              Map<String, int> categoryCounts =
                  tasksByPeriodAndCategory[period] ?? {};

              // Ensure that periods without tasks show a zero count
              if (!categoryCounts.containsKey('Uncategorized')) {
                categoryCounts['Uncategorized'] =
                    0; // Add 'Uncategorized' with count 0 if no tasks
              }

              // Add the period data to the chartData list
              chartData.add(TaskCompletionData(period, categoryCounts));
            });

            // Sort the chart data by period (ascending order)
            chartData.sort((a, b) {
              return a.period
                  .compareTo(b.period); // Sort alphabetically or by date
            });

            return Container(
              decoration: BoxDecoration(
                color: Color(0xFFF9F9F9), // Background color
                borderRadius: BorderRadius.circular(16), // Rounded corners
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5), // Shadow color
                    blurRadius: 6, // Blur radius
                    offset: const Offset(0, 3), // Shadow offset
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Task Completion", // Title for the chart section
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16), // Space between title and chart

                  // Dropdown to select category
                  DropdownUnderWidget(
                    availableCategories: availableCategories,
                    selectedCategory: selectedCategory,
                    onCategoryChange: (category) {
                      handleCategoryChange(category);
                    },
                  ),

                  const SizedBox(
                      height: 20), // Space between dropdown and chart
                  SfCartesianChart(
                    legend: Legend(isVisible: false), // Hide the legend
                    primaryXAxis: CategoryAxis(
                      majorGridLines:
                          MajorGridLines(width: 0), // Hide vertical grid lines
                    ),
                    primaryYAxis: NumericAxis(
                      minimum: 0,
                      majorGridLines: MajorGridLines(
                        width: 1, // Show horizontal grid lines
                        color:
                            Colors.grey.shade400, // Horizontal grid line color
                      ),
                      interval:
                          1, // Set the interval to 1 to show only integer values
                      labelFormat:
                          '{value}', // Ensure that only integer values are shown
                      isInversed:
                          false, // To keep the values increasing from bottom to top
                    ),
                    series: _buildStackedSeries(chartData),
                    tooltipBehavior: TooltipBehavior(enable: true),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeSpentSection() {
    Future<List<TaskTimerData>> _fetchTimeSpentData() async {
      // Fetch the current user
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return []; // No user, return an empty list
      }

      // Query Firestore for tasks
      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('Task')
          .where('userID', isEqualTo: user.uid)
          .get();

      // Define the start and end period dynamically
      final currentDate = getCurrentDate(selectedTime, periodOffset);
      final startOfPeriod =
          _getStartOfPeriod(currentDate, selectedTime).toUtc();
      final endOfPeriod = _getEndOfPeriod(currentDate, selectedTime).toUtc();

      // Get all periods within the selected range
      final Set<String> allPeriods = _getAllPeriods(currentDate);

      // Map to hold time spent grouped by period and category
      Map<String, Map<String, double>> hoursByPeriodAndCategory = {};

      for (var doc in tasksSnapshot.docs) {
        final data = doc.data();

        final timerList = data['timer'];
        final scheduledDate = (data['scheduledDate'] as Timestamp?)?.toDate();
        final category = data['category'] ?? 'Uncategorized';

        if (timerList is List && scheduledDate != null) {
          if ((scheduledDate.isAfter(startOfPeriod) ||
                  scheduledDate.isAtSameMomentAs(startOfPeriod)) &&
              (scheduledDate.isBefore(endOfPeriod) ||
                  scheduledDate.isAtSameMomentAs(endOfPeriod))) {
            for (var timerEntry in timerList) {
              if (timerEntry is Map) {
                final timeField = timerEntry['time']?.toString().trim();
                double totalSeconds = 0.0;
                if (timeField != null && timeField != "") {
                  totalSeconds += double.tryParse(timeField) ?? 0.0;
                }

                if (totalSeconds > 0) {
                  final period = getPeriodLabel(scheduledDate);
                  hoursByPeriodAndCategory[period] ??= {};
                  hoursByPeriodAndCategory[period]![category] =
                      (hoursByPeriodAndCategory[period]![category] ?? 0.0) +
                          (totalSeconds / 3600.0);
                }
              }
            }
          }
        }
      }

      // Create chart data for all periods
      List<TaskTimerData> chartData = [];
      allPeriods.forEach((period) {
        final categoryData = hoursByPeriodAndCategory[period] ?? {};
        final allCategories = {
          'Uncategorized'
        }; // Add all predefined categories if needed

        // Add all missing categories with 0.0 hours
        allCategories.forEach((category) {
          categoryData[category] = categoryData[category] ?? 0.0;
        });

        // Add the period data to the chartData list
        categoryData.forEach((category, hours) {
          chartData.add(
              TaskTimerData(period: period, category: category, hours: hours));
        });
      });

      // Sort the chart data by period
      chartData.sort((a, b) => a.period.compareTo(b.period));

      return chartData;
    }

    return FutureBuilder<List<TaskTimerData>>(
      future: _fetchTimeSpentData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Error loading time spent data"));
        }

        final chartData = snapshot.data ?? [];

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Time Spent (Hours)",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SfCartesianChart(
                legend: Legend(isVisible: true),
                primaryXAxis: CategoryAxis(
                  majorGridLines: MajorGridLines(width: 0),
                  labelRotation: -45,
                ),
                primaryYAxis: NumericAxis(
                  minimum: 0,
                  majorGridLines:
                      MajorGridLines(width: 1, color: Colors.grey.shade400),
                  labelFormat: '{value} hrs',
                ),
                series: _buildTimeSpentSeries(chartData),
                tooltipBehavior: TooltipBehavior(enable: true),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build the chart series for time spent visualization
  List<ChartSeries<TaskTimerData, String>> _buildTimeSpentSeries(
      List<TaskTimerData> chartData) {
    final groupedByCategory = <String, List<TaskTimerData>>{};

    for (var data in chartData) {
      groupedByCategory[data.category] ??= [];
      groupedByCategory[data.category]!.add(data);
    }

    return groupedByCategory.entries.map((entry) {
      return StackedBarSeries<TaskTimerData, String>(
        dataSource: entry.value,
        xValueMapper: (data, _) => data.period,
        yValueMapper: (data, _) => data.hours,
        name: entry.key,
        dataLabelSettings: DataLabelSettings(isVisible: true),
      );
    }).toList();
  }

  List<ChartSeries<TaskTimerData, String>> _buildStackedTimeSpentSeries(
      List<TaskTimerData> data, Set<String> categories) {
    return categories.map((category) {
      return StackedBarSeries<TaskTimerData, String>(
        dataSource: data.where((entry) => entry.category == category).toList(),
        xValueMapper: (entry, _) => entry.period, // Period should be a String
        yValueMapper: (entry, _) => entry.hours, // Hours should be a double
        name: category, // Legend shows the category
        dataLabelSettings: DataLabelSettings(isVisible: true),
      );
    }).toList();
  }

// Helper function to get all periods (even those without tasks) until the end of the current period
  Set<String> _getAllPeriods(DateTime currentDate) {
    Set<String> periods = {};

    DateTime startDate;
    DateTime endDate;

    switch (selectedTime) {
      case 'Daily':
        // Get the current date (today)
        DateTime today =
            DateTime(currentDate.year, currentDate.month, currentDate.day);

        // Find the most recent Sunday (start of the week)
        startDate = today.subtract(Duration(
            days: today.weekday % 7)); // Subtract days to get to Sunday

        // Calculate the end date (Saturday of the same week)
        endDate =
            startDate.add(Duration(days: 6)); // Saturday is 6 days after Sunday

        // Iterate through each day from Sunday to Saturday
        for (int i = 0;
            startDate.add(Duration(days: i)).isBefore(endDate) ||
                startDate.add(Duration(days: i)).isAtSameMomentAs(endDate);
            i++) {
          DateTime date = startDate.add(Duration(days: i));
          periods.add(getPeriodLabel(
              date)); // Add the formatted period label for the day
        }
        break;

      case 'Weekly':
        // Get the start of the month
        DateTime startOfMonth =
            DateTime(currentDate.year, currentDate.month, 1);
        endDate = DateTime(currentDate.year, currentDate.month + 1,
            0); // Last day of the current month

        // Find the first Sunday of the month (start of the first week)
        startDate = startOfMonth.subtract(Duration(
            days: startOfMonth.weekday % 7)); // Subtract days to get to Sunday

        while (startDate.isBefore(endDate)) {
          int weekNumber = getWeekNumber(
              startDate); // Get the week number for the start of the week
          periods.add('Week $weekNumber'); // Add the week number to the list
          startDate = startDate
              .add(Duration(days: 7)); // Move to the next week (next Sunday)
        }
        break;

      case 'Monthly':
        startDate = DateTime(currentDate.year, 1, 1); // Start of the year
        endDate = DateTime(
            currentDate.year, currentDate.month, 1); // End of current month

        // Loop through all months of the current year
        for (int i = 0; i < 12; i++) {
          DateTime monthStart = DateTime(currentDate.year, i + 1, 1);
          if (monthStart.isAfter(endDate))
            break; // Stop if month is after the end of the year
          periods.add(DateFormat('yyyy-MM').format(
              monthStart)); // Change the format to include year for monthly periods
        }
        break;

      case 'Yearly':
        startDate =
            DateTime(currentDate.year, 1, 1); // Start of the selected year
        endDate =
            DateTime(currentDate.year, 12, 31); // End of the selected year

        // Add the year to the set
        for (int i = 0;
            i <= currentDate.year - DateTime(currentDate.year).year;
            i++) {
          periods.add('${currentDate.year + i}');
        }
        break;

      default:
        break;
    }

    return periods;
  }

// Helper function to map the task date to a day of the week
// Function to return the period label based on the selected time
  String getPeriodLabel(DateTime scheduledDate) {
    switch (selectedTime) {
      case 'Daily':
        return DateFormat('yyyy-MM-dd')
            .format(scheduledDate); // Sortable format
      case 'Weekly':
        return 'Week ${getWeekNumber(scheduledDate)}'; // Week number or date range
      case 'Monthly':
        return DateFormat('yyyy-MM')
            .format(scheduledDate); // Sort by year and month
      case 'Yearly':
        return scheduledDate.year.toString();
      default:
        return '';
    }
  }

  int getWeekNumber(DateTime date) {
    // Get the first day of the month
    DateTime firstDayOfMonth = DateTime(date.year, date.month, 1);

    // Calculate the difference in days
    int dayDifference = date.day - firstDayOfMonth.day;

    // Calculate the week number in relation to the month
    return (dayDifference ~/ 7) + 1; // Using integer division
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

  //fetching and filtring task and categories

  Future<void> fetchCategories(String userID) async {
    // fetch all tasks with any status with its category
    try {
      print("Fetching categories for userID: $userID");

      // Use the Category class to fetch categories and task-category mapping
      final result = await Category.fetchCategoriesForUser(userID);

      // Extract the categories and task-category map from the result
      final categories = result['categories'] as List<String>;
      final taskCategoryMap =
          result['taskCategoryMap'] as Map<String, List<String>>;

      if (categories.isEmpty) {
        print("No categories found for userID: $userID");
      } else {
        print("Fetched categories: $categories");

        // Populate the taskIDToCategoryMap with task-category mapping
        taskCategoryMap.forEach((taskID, categories) {
          taskIDToCategoryMap[taskID] =
              categories.join(', '); // Map each taskID to its categories
        });
      }

      setState(() {
        // Update availableCategories with the fetched categories
        availableCategories = categories;
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

  String formattedCurrentDate(String selectedTime, int offset) {
    //To represent the format in the date navigator
    DateTime today = DateTime.now();
    DateTime targetDate;

    // Adjust targetDate based on the selected time period and offset
    switch (selectedTime) {
      case "Daily":
        targetDate = today.add(Duration(days: offset));
        return DateFormat('dd MMM yyyy').format(targetDate);

      case "Weekly":
        // Find the start of the week (Sunday) and adjust by offset (weeks)
        final startOfWeek = today
            .subtract(Duration(days: today.weekday % 7)); // Start on Sunday
        targetDate =
            startOfWeek.add(Duration(days: offset * 7)); // Apply week offset
        final endOfWeek = targetDate.add(Duration(days: 6)); // End on Saturday
        return "${DateFormat('dd MMM').format(targetDate)} - ${DateFormat('dd MMM').format(endOfWeek)}";

      case "Monthly":
        targetDate = DateTime(today.year, today.month + offset);
        return DateFormat('MMMM yyyy').format(targetDate);

      case "Yearly":
        targetDate = DateTime(today.year + offset, 1, 1);
        return DateFormat('yyyy').format(targetDate);

      default:
        return DateFormat('dd MMM yyyy').format(today);
    }
  }

  Future<List<Task>> filterTasksBySelectedPeriod(String selectedTime,
      DateTime currentDate, List<Task> additionalFilterArray) async {
    // Check if there are tasks to filter
    if (additionalFilterArray.isEmpty) {
      print("No tasks to filter.");
      return [];
    }

    // Initialize period start and end dates
    DateTime startOfPeriod;
    DateTime endOfPeriod;

    switch (selectedTime) {
      case "Daily":
        // Get the most recent Sunday (start of the week)
        final startOfWeek = currentDate.subtract(
            Duration(days: currentDate.weekday)); // Start of the week (Sunday)
        startOfPeriod = DateTime(startOfWeek.year, startOfWeek.month,
            startOfWeek.day); // Ensure it starts at midnight (00:00:00)
        endOfPeriod = startOfPeriod
            .add(Duration(days: 6)); // End of the selected week (Saturday)
        break;

      case "Weekly":
        // Start of the selected month (from the first day of the month at midnight)
        startOfPeriod = DateTime(currentDate.year, currentDate.month, 1, 0, 0,
            0, 0); // First day of the month at midnight

        // End of the selected month (last second of the last day of the month)
        endOfPeriod = DateTime(currentDate.year, currentDate.month + 1, 0, 23,
            59, 59, 999); // Last second of the last day of the month
        break;

      case "Monthly":
        // Start of the selected year (January 1st at midnight)
        startOfPeriod = DateTime(currentDate.year, 1, 1, 0, 0, 0,
            0); // First day of the year at midnight

        // End of the selected year (December 31st at the last second)
        endOfPeriod = DateTime(currentDate.year, 12, 31, 23, 59, 59,
            999); // Last second of the last day of the year
        break;

      case "Yearly":
        // Start of the year (January 1st)
        startOfPeriod = DateTime(currentDate.year, 1, 1); // Start of the year
        endOfPeriod = DateTime(
            currentDate.year + 1, 1, 0); // End of the year (December 31st)
        break;

      default:
        // Default case for invalid period
        startOfPeriod = DateTime(currentDate.year, currentDate.month,
            currentDate.day); // Today's date at midnight
        endOfPeriod = startOfPeriod.add(Duration(days: 1)); // Next day
        break;
    }

// Convert to UTC for consistency
    startOfPeriod = startOfPeriod.toUtc();
    endOfPeriod = endOfPeriod.toUtc();

// Debugging: Print start and end of period
    print("Start of period: $startOfPeriod");
    print("End of period: $endOfPeriod");

    // Initialize the list of filtered tasks
    List<Task> filteredTasks = [];

    // Filter tasks based on the period and additionalFilterArray (taskID)
    for (var task in additionalFilterArray) {
      // Ensure scheduledDate is not null and falls within the selected period

      bool isWithinPeriod = (task.scheduledDate.isAfter(startOfPeriod) ||
              task.scheduledDate.isAtSameMomentAs(startOfPeriod)) &&
          (task.scheduledDate.isBefore(endOfPeriod) ||
              task.scheduledDate.isAtSameMomentAs(endOfPeriod));

      if (isWithinPeriod) {
        filteredTasks
            .add(task); // Add task to the filtered list if within range
        print("Task ${task.taskID} added to filtered tasks.");
      } else {
        print(
            "Task ${task.taskID} is out of the selected period or has invalid date.");
      }
    }

    print("Filtered tasks count: ${filteredTasks.length}");
    return filteredTasks; // Return the filtered list of tasks
  }

  Future<double> _fetchSpentHoursByPeriod(String selectedTime) async {
    // Fetch the current user
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return 0.0; // No user, return 0 spent hours
    }

    // Get the start and end of the period dynamically
    final currentDate = getCurrentDate(selectedTime, periodOffset);
    var startOfPeriod = _getStartOfPeriod(currentDate, selectedTime);
    var endOfPeriod = _getEndOfPeriod(currentDate, selectedTime);

    // Convert dates to UTC for consistent comparison
    startOfPeriod = startOfPeriod.toUtc();
    endOfPeriod = endOfPeriod.toUtc();

    // Debugging: Print the date range to ensure it's correct
    print("Start of period: $startOfPeriod");
    print("End of period: $endOfPeriod");

    double totalSpentHours = 0.0;

    // Fetch tasks for the current user
    final tasksSnapshot = await FirebaseFirestore.instance
        .collection('Task')
        .where('userID', isEqualTo: user.uid)
        .get();

    for (var doc in tasksSnapshot.docs) {
      final data = doc.data();
      final timerList = data['timer'];

      if (timerList is List) {
        for (var timerEntry in timerList) {
          if (timerEntry is Map) {
            // Check for valid `time`
            final timeField = timerEntry['time']?.toString().trim();
            final dateTime = parseDateTime(timerEntry['dateTime']);

            if (timeField != "" && timeField != null && dateTime != null) {
              // Ensure the `dateTime` falls within the specified period
              if (dateTime.isAfter(startOfPeriod) &&
                  dateTime.isBefore(endOfPeriod)) {
                // Convert seconds to hours
                totalSpentHours += (double.tryParse(timeField) ?? 0.0) / 3600.0;
              }
            }

            // Check for valid `startTime` and `endTime`
            final startTimeField = timerEntry['startTime']?.toString().trim();
            final endTimeField = timerEntry['endTime']?.toString().trim();
            final startDateTime = parseDateTime(timerEntry['startDateTime']);
            final endDateTime = parseDateTime(timerEntry['endDateTime']);

            if (startTimeField != "" &&
                startTimeField != null &&
                startDateTime != null) {
              if (startDateTime.isAfter(startOfPeriod) &&
                  startDateTime.isBefore(endOfPeriod)) {
                // Convert seconds to hours
                totalSpentHours +=
                    (double.tryParse(startTimeField) ?? 0.0) / 3600.0;
              }
            }

            if (endTimeField != "" &&
                endTimeField != null &&
                endDateTime != null) {
              if (endDateTime.isAfter(startOfPeriod) &&
                  endDateTime.isBefore(endOfPeriod)) {
                // Convert seconds to hours
                totalSpentHours +=
                    (double.tryParse(endTimeField) ?? 0.0) / 3600.0;
              }
            }
          }
        }
      }
    }

    print("Total spent hours in the period: $totalSpentHours");

    return totalSpentHours;
  }

  Future<Map<String, int>> countTasksByCategory(
      String selectedTime, DateTime currentDate) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("No user logged in.");
      return {};
    }

    // Get the start and end of the period dynamically
    // Define the start and end period based on `selectedTime`
    final currentDate = getCurrentDate(selectedTime, periodOffset);
    var startOfPeriod = _getStartOfPeriod(currentDate, selectedTime);
    var endOfPeriod = _getEndOfPeriod(currentDate, selectedTime);

    // Convert dates to UTC for consistent comparison
    startOfPeriod = startOfPeriod.toUtc();
    endOfPeriod = endOfPeriod.toUtc();

    // Debugging: Print the date range to ensure it's correct
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

        // Populate the map with task IDs to category names
        for (var taskID in taskIDs) {
          taskIDToCategoryMap[taskID] = categoryName;
        }
      }

      // Debugging: Check the task-to-category mapping
      print("Task-to-category mapping: $taskIDToCategoryMap");

      // Fetch tasks for the specific user within the date range
      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('Task')
          .where('userID', isEqualTo: user.uid)
          .get();

      if (tasksSnapshot.docs.isEmpty) {
        print("No tasks found for user: ${user.uid}");
        return {};
      }

      // Debugging: Check fetched tasks
      print(
          "Tasks fetched for user: ${tasksSnapshot.docs.map((doc) => doc.id).toList()}");

      // Initialize task counts by category
      final taskCounts = <String, int>{};

      // Map tasks to their respective categories
      for (var doc in tasksSnapshot.docs) {
        final taskID = doc.id;
        final data = doc.data();
        final scheduledDate = (data['scheduledDate'] as Timestamp)
            .toDate(); // Ensure date is parsed

        // Debugging: Log task scheduled date
        print("Task ID: $taskID, Scheduled Date: $scheduledDate");

        // Check if the task falls within the selected period
        if (scheduledDate.isAfter(startOfPeriod) &&
            scheduledDate.isBefore(endOfPeriod)) {
          final categoryName = taskIDToCategoryMap[taskID] ?? 'Uncategorized';
          taskCounts[categoryName] = (taskCounts[categoryName] ?? 0) + 1;

          // Debugging: Log task ID and its mapped category
          print(
              "Task ${taskID} belongs to category '${categoryName}'. Updated count: ${taskCounts[categoryName]}");
        }
      }

      print("Final task counts by category: $taskCounts");
      return taskCounts;
    } catch (e) {
      print("Error fetching tasks in countTasksByCategory: $e");
      return {};
    }
  }

  Future<Map<String, int>> countTasksByStatus(
      String selectedTime, DateTime currentDate) async {
    // Fetch tasks using the Task class
    final tasks =
        await Task.fetchTasksForUser(FirebaseAuth.instance.currentUser!.uid);

    if (tasks == null || tasks.isEmpty) {
      return {'uncompleted': 0, 'pending': 0, 'completed': 0};
    }

    // Define the start and end period based on selectedTime
    final currentDate = getCurrentDate(selectedTime, periodOffset);
    final startOfPeriod = _getStartOfPeriod(currentDate, selectedTime);
    final endOfPeriod = _getEndOfPeriod(currentDate, selectedTime);

    int uncompleted = 0;
    int pending = 0;
    int completed = 0;

    // Iterate through tasks to filter and count statuses
    for (var task in tasks) {
      final scheduledDate = task.scheduledDate;

      if (scheduledDate.isAfter(startOfPeriod) &&
          scheduledDate.isBefore(endOfPeriod)) {
        if (task.completionStatus == 0) {
          uncompleted++;
        } else if (task.completionStatus == 1) {
          pending++;
        } else if (task.completionStatus == 2) {
          completed++;
        }
      }
    }

    return {
      'uncompleted': uncompleted,
      'pending': pending,
      'completed': completed,
    };
  }

//dealing with time

  DateTime getCurrentDate(String selectedTime, int offset) {
    final now = DateTime.now();
    DateTime currentDate = now;

    DateTime startOfPeriod = _getStartOfPeriod(currentDate, selectedTime);
    currentDate = startOfPeriod.add(Duration(days: offset));

    return currentDate;
  }

  DateTime _getStartOfPeriod(DateTime currentDate, String periodType) {
    switch (periodType) {
      case 'Daily':
        // Return the start of the day (00:00:00.000) for the current date
        return DateTime(
            currentDate.year, currentDate.month, currentDate.day, 0, 0, 0, 0);

      case 'Weekly':
        // Start of the week (Sunday at 00:00:00.000)
        DateTime startOfWeek =
            currentDate.subtract(Duration(days: currentDate.weekday % 7));
        return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day, 0,
            0, 0, 0); // Set time to 00:00:00.000

      case 'Monthly':
        // Start of the month (1st day of the month at 00:00:00.000)
        return DateTime(currentDate.year, currentDate.month, 1, 0, 0, 0, 0);

      case 'Yearly':
        // Start of the year (1st day of January at 00:00:00.000)
        return DateTime(currentDate.year, 1, 1, 0, 0, 0, 0);

      default:
        return currentDate; // In case of an unrecognized period type, just return the current date
    }
  }

  DateTime _getEndOfPeriod(DateTime startDate, String periodType) {
    switch (periodType) {
      case 'Daily':
        return startDate
            .add(const Duration(days: 1))
            .subtract(const Duration(seconds: 1));
      case 'Weekly':
        return startDate
            .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      case 'Monthly':
        final nextMonth = DateTime(startDate.year, startDate.month + 1, 1);
        return nextMonth
            .subtract(const Duration(seconds: 1)); // Last day of the month
      case 'Yearly':
        return DateTime(startDate.year + 1, 1, 1)
            .subtract(const Duration(seconds: 1)); // Last day of the year
      default:
        return startDate;
    }
  }
}

/// Chart data class
class TaskTimerData {
  final String period;
  final String category;
  final double hours;

  TaskTimerData(
      {required this.period, required this.category, required this.hours});
}

// TaskCompletionData class to represent the data for the chart
class TaskCompletionData {
  final String period; // Period (day/week/month/year)
  final Map<String, int> categoryCounts; // Task counts for each category

  TaskCompletionData(this.period, this.categoryCounts);
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
    // Ensure the selected value is valid, defaulting to "All" if invalid
    selectedValue = widget.availableCategories.contains(widget.selectedCategory)
        ? widget.selectedCategory
        : "All";
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
