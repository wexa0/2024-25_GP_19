import 'package:flutter/material.dart';
import 'package:flutter_application/Classes/Task';
import 'package:flutter_application/Classes/Category';
import 'package:flutter_application/Classes/SubTask';
import 'package:flutter_application/models/BottomNavigationBar.dart';
import 'package:flutter_application/models/GuestBottomNavigationBar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lottie/lottie.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:streak_calendar/streak_calendar.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_sticky_header/easy_sticky_header.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:flutter/material.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({Key? key}) : super(key: key);

  @override
  _ProgressPageState createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  String? userID;
  int selectedIndex = 3;
  String selectedSegment = "Task";
  String selectedTime = "Daily";
  int periodOffset = 0; // Tracks the offset for the date period navigation
  bool _weeklyNotificationShown =
      false; // NEW: track if we already showed the snack bar

  // Category Dropdown Variables
  List<String> availableCategories = [];
  String selectedCategory = "All"; // Default selected category
  bool isLoading = true;

  // Store the mapping of taskID to its categoryName
  Map<String, String> taskIDToCategoryMap = {};

  // A map to store fixed colors for each category
  static Map<String, Color> categoryColorMap = {};

  static final colorList = <Color>[
    const Color(0xFF0072B2), // Strong Blue
    //const Color(0xFFE69F00), // Orange
    const Color(0xFF56B4E9), // Sky Blue
    //const Color(0xFF009E73), // Green
    const Color(0xFFF0E442), // Yellow
    const Color(0xFFD55E00), // Vermilion (red-orange)
    const Color(0xFFCC79A7), // Pinkish Purple
    const Color(0xFF8C564B), // Brownish Red
    const Color(0xFF5D9CBE), // Muted Blue-Gray
    const Color(0xFF999999), // Medium Gray
  ];
  List<String> labels = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
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

    // Temporary testing override to always show the notification
    _showWeeklyNotification(reset: true);

    // NEW: Check if we should show the weekly comparison
    _checkWeeklyNotification();
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
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 170,
                      height: 170,
                    ),
                    const SizedBox(height: 0),
                    Lottie.asset(
                      'assets/animations/loading.json',
                      width: 150,
                      height: 150,
                    ),
                  ],
                ),
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildSegmentControl(),
                    ),
                  ),

                  // ✅ Sticky Date Navigation using `sliver_tools`
                  SliverPinnedHeader(
                    child: Container(
                      color: const Color(0xFFF5F5F5),
                      padding: const EdgeInsets.all(8.0),
                      child: _buildDateNavigation(
                          formattedCurrentDate(selectedTime, periodOffset)),
                    ),
                  ),

                  // ✅ Main Content
                  SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 20),
                      _buildLevelSection(),
                      const SizedBox(height: 20),
                      _buildTaskSummaryCards(),
                      const SizedBox(height: 20),
                      if (selectedSegment == "Task")
                        _buildTaskCompletionSection(),
                      if (selectedSegment == "Time") ...[
                        _buildStreakCalendar(),
                        const SizedBox(height: 20),
                        _buildTimeSpentSection(),
                      ],
                    ]),
                  ),
                ],
              ),

        // ✅ Added Navigation Bar Here
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

  // Widget _buildPeriodSelector() {
  //   // to switch between period progress
  //   const List<String> labels = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
  //   const Color activeColor = Color(0xFF79A3B7);

  //   return LayoutBuilder(
  //     builder: (context, constraints) {
  //       double segmentWidth = constraints.maxWidth /
  //           labels.length; // Dynamic segment width based on label count

  //       return Container(
  //         decoration: BoxDecoration(
  //           color: Colors.grey[200],
  //           borderRadius: BorderRadius.circular(8),
  //         ),
  //         child: ToggleSwitch(
  //           minWidth: segmentWidth, // Set width based on calculation
  //           cornerRadius: 8.0, // Rounded corners
  //           activeBgColors: List.generate(labels.length,
  //               (_) => [activeColor]), // Active color for each option
  //           activeFgColor: Colors.white, // Text color for active option
  //           inactiveBgColor:
  //               Colors.grey[200]!, // Background color for inactive options
  //           inactiveFgColor: Colors.black, // Text color for inactive options
  //           initialLabelIndex:
  //               labels.indexOf(selectedTime), // Get initial index dynamically
  //           totalSwitches: labels.length, // Number of options
  //           labels: labels, // Use predefined labels
  //           onToggle: (index) {
  //             if (index != null) {
  //               // Ensure index is not null
  //               setState(() {
  //                 selectedTime = labels[index]; // Set the selected time option
  //                 periodOffset =
  //                     0; // Reset the period offset when switching views
  //               });
  //               getCurrentDate(selectedTime,
  //                   periodOffset); // Update date range based on the new selection
  //             }
  //           },
  //         ),
  //       );
  //     },
  //   );
  // }

  Future<void> _showWeeklyNotification({bool reset = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (reset) {
      // Reset the last visited date for testing
      await prefs.remove('lastVisitedWeekKey');
    }
  }

  // NEW: Check SharedPreferences to see if we've visited this week; if not, show the dialog
  Future<void> _checkWeeklyNotification() async {
    final prefs = await SharedPreferences.getInstance();

    // 1) Determine current year-week, e.g. "2023-W36"
    final now = DateTime.now();
    final currentWeekKey = _yearWeekString(now);

    // 2) Retrieve last visited week from SharedPreferences
    final lastVisitedWeek = prefs.getString('lastVisitedWeekKey');

    // If it's a new week (or there's no stored week), show the dialog
    if (lastVisitedWeek != currentWeekKey) {
      // Save the current week so we don't show again
      prefs.setString('lastVisitedWeekKey', currentWeekKey);

      // Only show the dialog if we haven't shown it during this build already
      if (!_weeklyNotificationShown) {
        _weeklyNotificationShown = true;

        // Compare this week's vs. last week's completion
        double diff = await _getWeeklyCompletionDifference();

        // Show the AlertDialog with the result
        _showWeeklyComparisonDialog(diff);
      }
    }
  }

  // NEW: Convert DateTime to "year-week" string, e.g. "2023-W36"
  String _yearWeekString(DateTime date) {
    final year = date.year;
    // Simple ISO-like approach:
    final firstDayOfYear = DateTime(year, 1, 1);
    final dayOfYear = date.difference(firstDayOfYear).inDays + 1;
    // We'll approximate the ISO week number
    final weekNumber = ((dayOfYear - date.weekday + 10) / 7).floor();
    return "$year-W$weekNumber";
  }

  // NEW: Compare "this week's" and "last week's" completion percentage
  Future<double> _getWeeklyCompletionDifference() async {
    // If no user, return 0
    if (FirebaseAuth.instance.currentUser == null) return 0.0;

    // 1) This week's data
    final thisWeekDate = _getStartOfThisWeek(DateTime.now());
    final thisWeekMap = await countTasksByStatus("Weekly", thisWeekDate);
    double thisWeekPercent = _calculateCompletionPercent(thisWeekMap);

    // 2) Last week's data
    final lastWeekDate = thisWeekDate.subtract(const Duration(days: 7));
    final lastWeekMap = await countTasksByStatus("Weekly", lastWeekDate);
    double lastWeekPercent = _calculateCompletionPercent(lastWeekMap);

    // Return difference in percentage points (e.g. +10 means +10%)
    return (thisWeekPercent - lastWeekPercent) * 100;
  }

  // NEW: Force Sunday-based start of week for the comparison
  DateTime _getStartOfThisWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday % 7));
  }

  // NEW: Convert tasks map to fraction of tasks completed
  double _calculateCompletionPercent(Map<String, int> data) {
    int completed = data['completed'] ?? 0;
    int pending = data['pending'] ?? 0;
    int total = pending + completed;
    if (total == 0) return 0.0;
    return completed / total;
  }

  // NEW: Show an AlertDialog with the difference
  void _showWeeklyComparisonDialog(double diff) {
    // Format difference to 1 decimal place, e.g. +5.0%
    final sign = diff > 0 ? "+" : ""; // for positive numbers
    final formattedDiff = diff.toStringAsFixed(1);

    String message;
    if (diff == 0) {
      message =
          "You're maintaining consistency! Keep up the good work this week!";
    } else if (diff > 0) {
      message =
          "Amazing progress! Your task completion increased by $sign$formattedDiff% compared to last week. Keep it up!";
    } else {
      message =
          "Don't worry! Your task completion decreased by $sign$formattedDiff% compared to last week. Take it one step at a time—you’ve got this!";
    }

    // Actually show the alert
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            title: const Text(
              'Weekly Task Completion Rate',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              message,
              style: const TextStyle(fontSize: 16),
            ),
            backgroundColor: const Color(0xFFF5F7F8), // Adjust as needed
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Color(0xFF79A3B7)),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Color(0xFF79A3B7)),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildSegmentControl() {
    return Container(
      width: double.infinity, // Full width of the parent
      decoration: BoxDecoration(
        color: Colors.white, // or any other background color you prefer
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
      ),
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
        // Left Arrow
        Container(
          width: 50, // Fixed width for the arrow box
          height: 40, // Match height of the dropdown box
          decoration: BoxDecoration(
            color: const Color(0xFFDDE2E4), // Background color of the arrow box
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: const Color(0xFF79A3B7), // Border color
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: () {
              setState(() {
                periodOffset -= 1;
                getCurrentDate(selectedTime, periodOffset);
              });
            },
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            padding: EdgeInsets.zero, // Remove extra padding from IconButton
            constraints: const BoxConstraints(), // Remove default constraints
          ),
        ),

        const SizedBox(
            width: 8), // Space between the arrow and the dropdown box

        /// PopupMenuButton styled to look like a fixed-width dropdown menu
        PopupMenuButton<String>(
          color: Colors.white, // Background color of the popup menu
          child: Container(
            width: 250, // Fixed width for the dropdown box
            height: 40, // Match height of the arrow boxes
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color:
                  const Color(0xFFDDE2E4), // Dropdown button background color
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color:
                    const Color(0xFF79A3B7), // Border color for dropdown button
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Center the text and icon
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    currentDate,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis, // Handles text overflow
                  ),
                ),
                const SizedBox(
                    width: 8), // Space between text and dropdown icon
                const Icon(
                  Icons.arrow_drop_down, // Dropdown arrow
                  color: Colors.black,
                ),
              ],
            ),
          ),
          initialValue: selectedTime,
          onSelected: (String value) {
            setState(() {
              selectedTime = value;
              periodOffset = 0;
              getCurrentDate(selectedTime, periodOffset);
            });
          },
          itemBuilder: (BuildContext context) {
            return labels.map((String label) {
              return PopupMenuItem<String>(
                value: label,
                child: Text(label),
              );
            }).toList();
          },
        ),

        const SizedBox(
            width: 8), // Space between the dropdown box and the arrow

        // Right Arrow
        Container(
          width: 50, // Fixed width for the arrow box
          height: 40, // Match height of the dropdown box
          decoration: BoxDecoration(
            color: const Color(0xFFDDE2E4), // Background color of the arrow box
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: const Color(0xFF79A3B7), // Border color
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: () {
              setState(() {
                periodOffset += 1;
                getCurrentDate(selectedTime, periodOffset);
              });
            },
            icon: const Icon(Icons.arrow_forward, color: Colors.black),
            padding: EdgeInsets.zero, // Remove extra padding from IconButton
            constraints: const BoxConstraints(), // Remove default constraints
          ),
        ),
      ],
    );
  }

  Widget _buildTaskSummaryCards() {
    // Present the total number of tasks/time
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
            ? Center(
                child: _buildCombinedTaskCard(context, counts),
              )
            : selectedSegment == "Time"
                ? _buildTotalTimeCard()
                : const SizedBox.shrink();
      },
    );
  }

  Widget _buildCombinedTaskCard(BuildContext context, Map<String, int> counts) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
      decoration: BoxDecoration(
        color: Color(0xFFF9F9F9), // ✅ Changed to match other cards
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4, // ✅ Increased to match other cards
            offset: Offset(0, 3), // ✅ More pronounced shadow
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Completed Task
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Completed Tasks",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                counts['completed'].toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          // Pending Task
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Pending Tasks",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                counts['pending'].toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalTimeCard() {
    return FutureBuilder<double>(
      future: _fetchSpentTimeByPeriod(selectedTime),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final double totalSeconds = snapshot.data ?? 0.0;
        final int hours = totalSeconds ~/ 3600;
        final int leftover = (totalSeconds % 3600).toInt();
        final int minutes = leftover ~/ 60;
        final int seconds = leftover % 60;

        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
            decoration: BoxDecoration(
              color: Color(0xFFF9F9F9), // ✅ Standardized color
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4, // ✅ Increased to match other cards
                  offset: Offset(0, 3), // ✅ Consistent shadow
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Time Spent",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Hours
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Hours",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hours.toString(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // Minutes
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Minutes",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          minutes.toString(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // Seconds
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Seconds",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          seconds.toString(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Calculates how many consecutive days (ending with the latest date)
  /// are present in [streakDates].
  int _calculateCurrentStreak(List<DateTime> streakDates) {
    if (streakDates.isEmpty) return 0;

    // Sort dates in ascending order
    streakDates.sort((a, b) => a.compareTo(b));

    // Start streak at 1 (since we have at least one date)
    int streak = 1;

    // Compare each date with the next-later one (starting from the end)
    for (int i = streakDates.length - 2; i >= 0; i--) {
      final currentDay = DateTime(
          streakDates[i].year, streakDates[i].month, streakDates[i].day);
      final nextDay = DateTime(streakDates[i + 1].year,
          streakDates[i + 1].month, streakDates[i + 1].day);

      // If the difference is exactly 1 day, increment the streak
      if (nextDay.difference(currentDay).inDays == 1) {
        streak++;
      } else {
        // As soon as we find a gap, we stop (current streak is broken)
        break;
      }
    }

    return streak;
  }

  /// Helper method to build the CleanCalendar widget for streaks, wrapped in a styled card
  bool _expanded = false; // Tracks if the calendar is expanded

  Widget _buildStreakCalendar() {
    return FutureBuilder<List<DateTime>>(
      future: _fetchStreakDates(), // Your method to get streakDates
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Error loading streak dates"));
        }

        // 1) Get the streak dates
        final List<DateTime> streakDates = snapshot.data ?? [];

        // 2) Calculate current streak
        final int currentStreak = _calculateCurrentStreak(streakDates);

        // 3) Check if today's date is in the streakDates (ignoring time)
        final DateTime today = DateTime.now();
        final bool isTodayInStreak = streakDates.any((date) =>
            date.year == today.year &&
            date.month == today.month &&
            date.day == today.day);

        // 4) Return a single card (Container) holding everything
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Top row: Current streak & arrow/flame on the right ----
              InkWell(
                onTap: () {
                  setState(() {
                    _expanded = !_expanded; // Toggle expansion
                  });
                },
                child: Row(
                  children: [
                    // Left side: "Current Streak" and the count
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Current Streak",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$currentStreak Day${currentStreak == 1 ? '' : 's'}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right side: Column with arrow on top, flame on bottom
                    Column(
                      children: [
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          Icons.whatshot,
                          size: 90,
                          color: isTodayInStreak ? Colors.orange : Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ---- If expanded, show the streak calendar below ----
              if (_expanded) ...[
                const SizedBox(height: 16),
                /*const Text(
                "Streak Calendar",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),*/
                CleanCalendar(
                  // Pass streak dates
                  datesForStreaks: streakDates,

                  // Conditionally set the calendar view
                  datePickerCalendarView:
                      (selectedTime == "Daily" || selectedTime == "Weekly")
                          ? DatePickerCalendarView.weekView
                          : DatePickerCalendarView.monthView,

                  // Current date style
                  currentDateProperties: DatesProperties(
                    datesDecoration: DatesDecoration(
                      datesBorderRadius: 1000,
                      datesBackgroundColor: Colors.transparent,
                      datesBorderColor: Colors.red, // highlight current date
                      datesTextColor: Colors.black,
                    ),
                  ),

                  // General style for other dates
                  generalDatesProperties: DatesProperties(
                    datesDecoration: DatesDecoration(
                      datesBorderRadius: 1000,
                      datesBackgroundColor: Colors.grey[200],
                      datesBorderColor:
                          const Color.fromARGB(255, 205, 203, 203),
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

                  // Leading/trailing dates style
                  leadingTrailingDatesProperties: DatesProperties(
                    datesDecoration: DatesDecoration(
                      datesBorderRadius: 1000,
                      datesBackgroundColor: Colors.transparent,
                      datesBorderColor: Colors.transparent,
                    ),
                  ),
                ),
              ],
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
            final startTimeField =
                timerEntry['firstDayActualTimeSpent']?.toString().trim();
            final endTimeField =
                timerEntry['secondDayActualTimeSpent']?.toString().trim();

            // Check for valid `time` and corresponding `dateTime`
            if (timeField != "" && timeField != null) {
              final dateTime = parseDateTime(timerEntry['dateTime']);
              if (dateTime != null) streakDates.add(dateTime);
            }

            // Check for valid `startTime` and corresponding `startDateTime`
            if (startTimeField != "" && startTimeField != null) {
              final startDateTime =
                  parseDateTime(timerEntry['firstDayStartDatetime']);
              if (startDateTime != null) streakDates.add(startDateTime);
            }

            // Check for valid `endTime` and corresponding `endDateTime`
            if (endTimeField != "" && endTimeField != null) {
              final endDateTime =
                  parseDateTime(timerEntry['secondDayEndDatetime']);
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
      return null;
    }
  }

// Function to get or assign a color for a category
  static Color getCategoryColor(String category) {
    if (!categoryColorMap.containsKey(category)) {
      // Assign the next available color in the list
      final newColor = colorList[categoryColorMap.length % colorList.length];
      categoryColorMap[category] = newColor;
    }
    return categoryColorMap[category]!;
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
          color: getCategoryColor(
              category), // Use getCategoryColor to fetch the color
          markerSettings:
              MarkerSettings(isVisible: false), // Hide the circular markers
        ),
      );
    }

    return series;
  }

  Widget _buildLevelSection() {
    User? firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      return const Center(
        child: Text("Please log in to see your progress."),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('User')
          .doc(firebaseUser.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Error fetching user data."));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("User data not found."));
        }

        // Retrieve points and level from Firestore
        final data = snapshot.data!.data() as Map<String, dynamic>;
        int points = data.containsKey('point') ? data['point'] : 0;

        int level = data.containsKey('level') ? data['level'] : 1;

        final String levelString = level.toString().padLeft(2, '0');

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 2,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Title "Achievement Level"

              const Text(
                "Achievement Level",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),

              // ✅ Row: Badge on the left, Centered Level text on the right
              Row(
                children: [
                  // Badge (left)
                  InkWell(
                    onTap: () {
                      // Navigate to AllBadgesPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllBadgesPage(userLevel: level),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.transparent,
                      backgroundImage: AssetImage(
                        'assets/images/lvl_Badges/lvl_$levelString.png',
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Centered Level Text (right)
                  Expanded(
                    child: Center(
                      child: Text(
                        'Level $level',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
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
  }

// Helper function to get all periods (even those without tasks)
  Widget _buildTaskCompletionSection() {
    // Check if no user is logged in
    if (FirebaseAuth.instance.currentUser == null) {
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
              "Task Completion",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Sign in to track your task completion and view progress!",
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SfCartesianChart(
              legend: Legend(isVisible: false),
              primaryXAxis: CategoryAxis(
                majorGridLines: MajorGridLines(width: 0),
                labelStyle: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              primaryYAxis: NumericAxis(
                minimum: 0,
                majorGridLines:
                    MajorGridLines(width: 1, color: Colors.grey.shade400),
                interval: 1,
                labelFormat: '{value}',
                isInversed: false,
              ),
              series: [
                StackedColumnSeries<TaskCompletionData, String>(
                  dataSource: [], // Empty data source for guest users
                  xValueMapper: (data, _) => data.period,
                  yValueMapper: (data, _) => 0, // Zero values
                  color: Colors.grey.shade300,
                  name: "No Data",
                )
              ],
              tooltipBehavior: TooltipBehavior(enable: true),
            ),
          ],
        ),
      );
    }

    // If user is logged in, proceed with fetching and displaying data
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
        final currentDate = getCurrentDate(selectedTime, periodOffset);

        return FutureBuilder<List<Task>>(
          future: filterTasksBySelectedPeriod(selectedTime, currentDate, tasks),
          builder: (context, filterSnapshot) {
            if (filterSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (filterSnapshot.hasError) {
              return const Center(child: Text("Error filtering tasks"));
            }

            final filteredTasks = filterSnapshot.data ?? [];
            Map<String, Map<String, int>> tasksByPeriodAndCategory = {};

            // Group and process data as usual
            for (var task in filteredTasks) {
              if (task.completionStatus == 2) {
                String period = getPeriodLabel(task.scheduledDate);
                String category =
                    taskIDToCategoryMap[task.taskID] ?? 'Uncategorized';
                if (selectedCategory != "All" && category != selectedCategory) {
                  continue;
                }

                if (!tasksByPeriodAndCategory.containsKey(period)) {
                  tasksByPeriodAndCategory[period] = {};
                }

                tasksByPeriodAndCategory[period]![category] =
                    (tasksByPeriodAndCategory[period]![category] ?? 0) + 1;
              }
            }

            // Create chart data
            List<TaskCompletionData> chartData = [];
            Set<String> allPeriods = _getAllPeriods(currentDate);

            allPeriods.forEach((period) {
              Map<String, int> categoryCounts =
                  tasksByPeriodAndCategory[period] ?? {};
              if (!categoryCounts.containsKey('Uncategorized')) {
                categoryCounts['Uncategorized'] = 0;
              }
              chartData.add(TaskCompletionData(period, categoryCounts));
            });

            chartData.sort((a, b) => a.period.compareTo(b.period));

            return Container(
              decoration: BoxDecoration(
                color: Color(0xFFF9F9F9),
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
                    "Task Completion",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownUnderWidget(
                    availableCategories: availableCategories,
                    selectedCategory: selectedCategory,
                    onCategoryChange: (category) {
                      handleCategoryChange(category);
                    },
                  ),
                  const SizedBox(height: 20),
                  SfCartesianChart(
                    legend: Legend(isVisible: false),
                    primaryXAxis: CategoryAxis(
                      majorGridLines: MajorGridLines(width: 0),
                      labelStyle: TextStyle(fontSize: 12, color: Colors.black),
                      axisLabelFormatter: (details) {
                        final String periodLabel = details.text;
                        final bool isCurrentPeriod =
                            periodLabel == getPeriodLabel(currentDate);

                        return ChartAxisLabel(
                          periodLabel,
                          TextStyle(
                            fontSize: 12,
                            fontWeight: isCurrentPeriod
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isCurrentPeriod ? Colors.blue : Colors.black,
                          ),
                        );
                      },
                    ),
                    primaryYAxis: NumericAxis(
                      minimum: 0,
                      majorGridLines: MajorGridLines(
                        width: 1,
                        color: Colors.grey.shade400,
                      ),
                      interval: 1,
                      labelFormat: '{value}',
                    ),
                    series: _buildStackedSeries(chartData),
                    tooltipBehavior: TooltipBehavior(enable: true),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<TaskTimerData>> _fetchTimeSpentData(
      String? selectedCategory) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return []; // No user, return an empty list
    }

    try {
      // Fetch the task-to-category mapping from the Category table
      final categorySnapshot = await FirebaseFirestore.instance
          .collection('Category')
          .where('userID', isEqualTo: user.uid)
          .get();

      // Create a map of task IDs to categories
      final Map<String, String> taskIDToCategory = {};
      for (var doc in categorySnapshot.docs) {
        final data = doc.data();
        final categoryName = data['categoryName'] ?? 'Uncategorized';
        final taskIDs = List<String>.from(data['taskIDs'] ?? []);

        for (var taskID in taskIDs) {
          taskIDToCategory[taskID] = categoryName;
        }
      }

      // Fetch tasks
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
        final taskID = doc.id;
        final timerList = data['timer'];
        final category = taskIDToCategory[taskID] ?? 'Uncategorized';

        // Apply the category filter, if one is selected
        if (selectedCategory != null &&
            selectedCategory != "All" &&
            category != selectedCategory) {
          continue;
        }

        if (timerList is List) {
          for (var timerEntry in timerList) {
            if (timerEntry is Map) {
              // Handle firstDayStartDatetime
              final firstDayStartDateTime =
                  parseDateTime(timerEntry['firstDayStartDatetime']);
              final firstDayTimeSpent =
                  timerEntry['firstDayActualTimeSpent']?.toString().trim();
              if (firstDayStartDateTime != null &&
                  firstDayTimeSpent != null &&
                  firstDayTimeSpent.isNotEmpty) {
                final period = getPeriodLabel(firstDayStartDateTime);
                final firstDaySeconds =
                    double.tryParse(firstDayTimeSpent) ?? 0.0;

                if (firstDaySeconds > 0) {
                  hoursByPeriodAndCategory[period] ??= {};
                  hoursByPeriodAndCategory[period]![category] =
                      (hoursByPeriodAndCategory[period]![category] ?? 0.0) +
                          (firstDaySeconds / 3600.0); // Convert to hours
                }
              }

              // Handle secondDayEndDatetime
              final secondDayEndDateTime =
                  parseDateTime(timerEntry['secondDayEndDatetime']);
              final secondDayTimeSpent =
                  timerEntry['secondDayActualTimeSpent']?.toString().trim();
              if (secondDayEndDateTime != null &&
                  secondDayTimeSpent != null &&
                  secondDayTimeSpent.isNotEmpty) {
                final period = getPeriodLabel(secondDayEndDateTime);
                final secondDaySeconds =
                    double.tryParse(secondDayTimeSpent) ?? 0.0;

                if (secondDaySeconds > 0) {
                  hoursByPeriodAndCategory[period] ??= {};
                  hoursByPeriodAndCategory[period]![category] =
                      (hoursByPeriodAndCategory[period]![category] ?? 0.0) +
                          (secondDaySeconds / 3600.0); // Convert to hours
                }
              }
            }
          }
        }
      }

      // Ensure all periods have all categories (with 0 hours if missing)
      List<TaskTimerData> chartData = [];
      for (var period in allPeriods) {
        final categoryData = hoursByPeriodAndCategory[period] ?? {};
        final allCategories = taskIDToCategory.values.toSet();

        // Add all missing categories with 0.0 hours
        for (var category in allCategories) {
          if (selectedCategory == null ||
              selectedCategory == "All" ||
              category == selectedCategory) {
            categoryData[category] = categoryData[category] ?? 0.0;
          }
        }

        // Add the period data to the chartData list
        categoryData.forEach((category, hours) {
          chartData.add(
              TaskTimerData(period: period, category: category, hours: hours));
        });
      }

      // Sort the chart data by period
      chartData.sort((a, b) => a.period.compareTo(b.period));

      return chartData;
    } catch (e) {
      return []; // Return an empty list in case of an error
    }
  }

  Widget _buildTimeSpentSection() {
    return FutureBuilder<List<TaskTimerData>>(
      future:
          _fetchTimeSpentData(selectedCategory), // Pass the selected category
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Error loading time spent data"));
        }

        final chartData = snapshot.data ?? [];

        // Get the current period label based on the selected time and offset
        final currentPeriodLabel = getPeriodLabel(
          getCurrentDate(selectedTime, periodOffset),
        );

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
                "Time Spent",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Dropdown to select category
              DropdownUnderWidget(
                availableCategories: availableCategories,
                selectedCategory: selectedCategory,
                onCategoryChange: (category) {
                  handleCategoryChange(category);
                },
              ),

              const SizedBox(height: 20), // Space between dropdown and chart
              SfCartesianChart(
                legend: Legend(isVisible: true),
                primaryXAxis: CategoryAxis(
                  majorGridLines: MajorGridLines(width: 0), // Hide grid lines
                  labelRotation: -45, // Rotate labels for better visibility
                  axisLabelFormatter: (AxisLabelRenderDetails details) {
                    final String label = details.text;
                    final bool isCurrentPeriod = label == currentPeriodLabel;

                    return ChartAxisLabel(
                      label,
                      TextStyle(
                        fontSize: 12,
                        fontWeight: isCurrentPeriod
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCurrentPeriod ? Colors.blue : Colors.black,
                      ),
                    );
                  },
                ),
                primaryYAxis: NumericAxis(
                  minimum: 0,
                  majorGridLines: MajorGridLines(
                    width: 1,
                    color: Colors.grey.shade400,
                  ),
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
      final categoryColor =
          getCategoryColor(entry.key); // Use getCategoryColor here

      return StackedBarSeries<TaskTimerData, String>(
        dataSource: entry.value,
        xValueMapper: (data, _) => data.period,
        yValueMapper: (data, _) => data.hours,
        name: entry.key,
        color: categoryColor, // Assign color for each category
        dataLabelSettings: const DataLabelSettings(isVisible: true),
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
        return DateFormat('MM-dd').format(scheduledDate); // Sortable format
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

  //fetching and filtring task and categories

  Future<void> fetchCategories(String userID) async {
    // fetch all tasks with any status with its category
    try {
      // Use the Category class to fetch categories and task-category mapping
      final result = await Category.fetchCategoriesForUser(userID);

      // Extract the categories and task-category map from the result
      final categories = result['categories'] as List<String>;
      final taskCategoryMap =
          result['taskCategoryMap'] as Map<String, List<String>>;

      if (!categories.isEmpty) {
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
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void handleCategoryChange(String? category) {
    if (category == null) return;

    setState(() {
      selectedCategory = category;
    });
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
      return [];
    }

    // Initialize period start and end dates
    DateTime startOfPeriod;
    DateTime endOfPeriod;

    switch (selectedTime) {
      case "Daily":
        // Get the most recent Sunday (start of the week)
        final startOfWeek =
            currentDate.subtract(Duration(days: currentDate.weekday % 7));
        startOfPeriod =
            DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        endOfPeriod = startOfPeriod
            .add(Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
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
      }
    }
    return filteredTasks; // Return the filtered list of tasks
  }

  Future<double> _fetchSpentTimeByPeriod(String selectedTime) async {
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

    double totalSpentSec = 0.0;

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
                totalSpentSec += (double.tryParse(timeField) ?? 0.0);
              }
            }
            // Check for valid `startTime` and `endTime`
            final startTimeField =
                timerEntry['firstDayActualTimeSpent']?.toString().trim();
            final endTimeField =
                timerEntry['secondDayActualTimeSpent']?.toString().trim();
            final startDateTime =
                parseDateTime(timerEntry['firstDayStartDatetime']);
            final endDateTime =
                parseDateTime(timerEntry['secondDayEndDatetime']);

            if (startTimeField != "" &&
                startTimeField != null &&
                startDateTime != null) {
              if (startDateTime.isAfter(startOfPeriod) &&
                  startDateTime.isBefore(endOfPeriod)) {
                // Convert seconds to hours
                totalSpentSec += (double.tryParse(startTimeField) ?? 0.0);
              }
            }

            if (endTimeField != "" &&
                endTimeField != null &&
                endDateTime != null) {
              if (endDateTime.isAfter(startOfPeriod) &&
                  endDateTime.isBefore(endOfPeriod)) {
                // Convert seconds to hours
                totalSpentSec += (double.tryParse(endTimeField) ?? 0.0);
              }
            }
          }
        }
      }
    }

    return totalSpentSec;
  }

  Future<Map<String, int>> countTasksByCategory(
      String selectedTime, DateTime currentDate) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
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

    try {
      // Fetch categories for the specific user
      final categoriesSnapshot = await FirebaseFirestore.instance
          .collection('Category')
          .where('userID', isEqualTo: user.uid)
          .get();

      if (categoriesSnapshot.docs.isEmpty) {
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

      // Fetch tasks for the specific user within the date range
      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('Task')
          .where('userID', isEqualTo: user.uid)
          .get();

      if (tasksSnapshot.docs.isEmpty) {
        return {};
      }

      // Initialize task counts by category
      final taskCounts = <String, int>{};

      // Map tasks to their respective categories
      for (var doc in tasksSnapshot.docs) {
        final taskID = doc.id;
        final data = doc.data();
        final scheduledDate = (data['scheduledDate'] as Timestamp)
            .toDate(); // Ensure date is parsed

        // Check if the task falls within the selected period
        if ((scheduledDate.isAfter(startOfPeriod) ||
                scheduledDate.isAtSameMomentAs(startOfPeriod)) &&
            (scheduledDate.isBefore(endOfPeriod) ||
                scheduledDate.isAtSameMomentAs(endOfPeriod))) {
          final categoryName = taskIDToCategoryMap[taskID] ?? 'Uncategorized';
          taskCounts[categoryName] = (taskCounts[categoryName] ?? 0) + 1;
        }
      }
      return taskCounts;
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, int>> countTasksByStatus(
      String selectedTime, DateTime currentDate) async {
    if (userID == null) {
      return {'uncompleted': 0, 'pending': 0, 'completed': 0};
    }
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
      'pending': pending + uncompleted,
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

// Concrete CustomPainter subclass
class StarPainter extends CustomPainter {
  final double completionPercentage;
  final Color fillColor;
  final Color backgroundColor;

  StarPainter({
    required this.completionPercentage,
    required this.fillColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()..color = backgroundColor;
    final Paint fillPaint = Paint()..color = fillColor;

    // Build the star path
    final Path starPath = _buildStarPath(size);

    // Draw the background star
    canvas.drawPath(starPath, backgroundPaint);

    // Clip the star shape
    canvas.save();
    canvas.clipPath(starPath);

    // Calculate the filled height
    final double fillHeight = size.height * completionPercentage;

    // Draw the filled portion
    canvas.drawRect(
      Rect.fromLTRB(0, size.height - fillHeight, size.width, size.height),
      fillPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  // Helper function to create the star path
  Path _buildStarPath(Size size) {
    const double outerRadiusFactor = 0.5;
    const double innerRadiusFactor = 0.25;
    const int numPoints = 5;

    final double outerRadius = size.width * outerRadiusFactor;
    final double innerRadius = size.width * innerRadiusFactor;

    final Path path = Path();
    final double angle = (2 * math.pi) / numPoints;
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < numPoints * 2; i++) {
      final double radius = (i % 2 == 0) ? outerRadius : innerRadius;

      final double x = center.dx + radius * math.cos(i * angle - math.pi / 2);
      final double y = center.dy + radius * math.sin(i * angle - math.pi / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    return path;
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

  const CategoryChart({
    Key? key,
    required this.dataMap,
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

        // Fetch the color for the category
        final color = _ProgressPageState.getCategoryColor(categories[i]);

        //final color = getCategoryColor(categories[i]);

        return PieChartSectionData(
          color: color,
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

class SingleBadgePage extends StatelessWidget {
  final int badgeLevel; // Which badge level is this (1..10, etc.)
  final bool isUnlocked; // Whether the user has reached this level
  final int userLevel; // The user's current level

  const SingleBadgePage({
    Key? key,
    required this.badgeLevel,
    required this.isUnlocked,
    required this.userLevel,
  }) : super(key: key);

  // Your helper function for total points needed:
  int getPointsRequiredForLevel(int targetLevel) {
    if (targetLevel <= 1) return 0;

    int totalPoints = 0;
    int pointsForNextLevel = 100;
    for (int level = 2; level <= targetLevel; level++) {
      totalPoints += pointsForNextLevel;
      pointsForNextLevel += 50;
    }
    return totalPoints;
  }

  @override
  Widget build(BuildContext context) {
    // Build paths for unlocked vs locked badges
    final unlockedBadgePath =
        'assets/images/lvl_Badges/lvl_${badgeLevel.toString().padLeft(2, '0')}.png';
    final lockedBadgePath =
        'assets/images/lvl_Badges/lvl_${badgeLevel.toString().padLeft(2, '0')}_locked.png';

    // Calculate total points required
    final int totalPointsNeeded = getPointsRequiredForLevel(badgeLevel);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // as requested
      appBar: AppBar(
        title: Text('Badge Level $badgeLevel'),
        centerTitle: true,
        backgroundColor: const Color(0xFFEAEFF0),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Show the badge image
            Image.asset(
              isUnlocked ? unlockedBadgePath : lockedBadgePath,
              width: 180,
              height: 180,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            // Display how many points are required for this level
            Text(
              "Points required to reach Level $badgeLevel: $totalPointsNeeded",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (!isUnlocked) ...[
              Text(
                "Keep going to unlock this badge!",
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ] else ...[
              const Text(
                "Badge unlocked! Great job!",
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Returns the total points required to *be* at [targetLevel].
/// - Level 1 means 0 points spent so far.
/// - Level 2 means you must have spent 100 points so far.
/// - Level 3 means you must have spent 250 points so far (100 + 150), etc.
int getPointsRequiredForLevel(int targetLevel) {
  if (targetLevel <= 1) return 0; // For level 1, 0 total points needed.

  int totalPoints = 0;
  int pointsForNextLevel = 100;

  // For level 2, add 100; for level 3, add 100+150; etc.
  // We'll add up from level=2 up to the targetLevel.
  for (int level = 2; level <= targetLevel; level++) {
    totalPoints += pointsForNextLevel;
    // Each subsequent level costs 50 more points.
    pointsForNextLevel += 50;
  }
  return totalPoints;
}

class AllBadgesPage extends StatelessWidget {
  final int userLevel; // The user's current level

  const AllBadgesPage({
    Key? key,
    required this.userLevel,
  }) : super(key: key);

  static const int maxLevel = 12;

  @override
  Widget build(BuildContext context) {
    // Paths for current level badge image
    final String currentBadgePath =
        'assets/images/lvl_Badges/lvl_${userLevel.toString().padLeft(2, '0')}.png';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'My Badges',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black),
            onPressed: () {
              _showPointRulesDialog(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // ✅ Large Current Level Badge (Not Sticky)
            Center(
              child: Image.asset(
                currentBadgePath,
                width: 150, // Large size
                height: 150,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 16),

            // ✅ Level Progress Bar with Remaining Points
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('User')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    !snapshot.data!.exists) {
                  return const Center(child: Text("Error loading points."));
                }

                // Retrieve current points and level from Firestore
                int currentPoints = snapshot.data!['point'] ?? 0;
                int userLevel = snapshot.data!['level'] ?? 1;

                // Get required points for next level
                int nextLevelPoints = getPointsRequiredForLevel(userLevel + 1);
                int pointsForCurrentLevel =
                    getPointsRequiredForLevel(userLevel);
                int pointsToNext = nextLevelPoints - currentPoints;
                double progress = (currentPoints.toDouble() / nextLevelPoints)
                    .clamp(0.0, 1.0);

                return Column(
                  children: [
                    Text(
                      "Level $userLevel",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Progress Bar
                    Stack(
                      children: [
                        Container(
                          height: 20,
                          width: 300,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFF79A3B7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Displaying Points Information
                    Text(
                      '$currentPoints / $nextLevelPoints points',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      '${pointsToNext > 0 ? pointsToNext : 0} points remaining to next level',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // ✅ Badge Grid Below (Remains Scrollable)
            GridView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(), // Prevents nested scrolling
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3 badges per row
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: maxLevel,
              itemBuilder: (context, index) {
                final levelIndex = index + 1;
                final bool isUnlocked = userLevel >= levelIndex;

                // Paths for each badge
                final unlockedBadgePath =
                    'assets/images/lvl_Badges/lvl_${levelIndex.toString().padLeft(2, '0')}.png';
                final lockedBadgePath =
                    'assets/images/lvl_Badges/lvl_${levelIndex.toString().padLeft(2, '0')}_locked.png';

                return InkWell(
                  onTap: () {
                    // Navigate to SingleBadgePage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SingleBadgePage(
                          badgeLevel: levelIndex,
                          isUnlocked: isUnlocked,
                          userLevel: userLevel,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Image.asset(
                          isUnlocked ? unlockedBadgePath : lockedBadgePath,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Level $levelIndex',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? Colors.black : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPointRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16.0), // ✅ Matches second dialog
          ),
          title: const Text(
            "How to Earn Points",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFFF5F7F8), // ✅ Matches second dialog
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("✔️ You earn points by completing tasks.",
                  style: TextStyle(fontSize: 16)),
              Text(
                  "✔️ Task completion date may increase or decrease your points.",
                  style: TextStyle(fontSize: 16)),
              Text(
                  "✔️ You earn more points by completing higher-priority tasks.",
                  style: TextStyle(fontSize: 16)),
              Text("✔️ Using the timer feature gives you extra points.",
                  style: TextStyle(fontSize: 16)),
              Text("✔️ You get additional points for dividing your tasks.",
                  style: TextStyle(fontSize: 16)),
              SizedBox(height: 10),
              Text(
                "Keep completing tasks to level up and unlock new badges!",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // ✅ Close the dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, // ✅ Matches second dialog
                shape: RoundedRectangleBorder(
                  side: const BorderSide(
                      color: Color(0xFF79A3B7)), // ✅ Matches second dialog
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                    color: Color(0xFF79A3B7)), // ✅ Matches second dialog
              ),
            ),
          ],
        );
      },
    );
  }
}
