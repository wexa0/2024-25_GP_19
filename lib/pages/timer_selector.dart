import 'package:flutter/material.dart';
import 'package:flutter_application/pages/timer_pomodoro.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimerSelectionPage extends StatefulWidget {
  final String taskId; // The task ID
  final String taskName; // The task name
  final String subTaskID; // The task name
  final String subTaskName;
  final String page;
  TimerSelectionPage(
      {required this.taskId,
      required this.subTaskID,
      required this.subTaskName,
      required this.taskName,
      required this.page
      });

  @override
  _TimerSelectionPageState createState() => _TimerSelectionPageState();
}

class _TimerSelectionPageState extends State<TimerSelectionPage> {
  int _focusMinutes = 25; // Default focus time in minutes
  int _shortBreakMinutes = 5; // Default short break time in minutes
  int _longBreakMinutes = 30; // Default long break time in minutes
  int _rounds = 4; // Default rounds (Pomodoro sessions)
  bool _loading = true; // Flag to indicate whether preferences are being loaded
  bool _isSaved = false; // this to toggle the color of text after pressing on it
  Map<String, bool> blockedApps = {};


  final FixedExtentScrollController _focusController =
      FixedExtentScrollController();
  final FixedExtentScrollController _shortBreakController =
      FixedExtentScrollController();
  final FixedExtentScrollController _longBreakController =
      FixedExtentScrollController();

  // Load preferences from Firestore
  Future<bool?> _loadPreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        DocumentReference userRef =
            FirebaseFirestore.instance.collection('User').doc(user.uid);
        DocumentSnapshot userDoc = await userRef.get();

        if (userDoc.exists && userDoc.data() != null) {
          var data = userDoc.data() as Map<String, dynamic>;
          if (data.containsKey('preferences')) {
            var preferences = data['preferences'];
            setState(() {
              _focusMinutes = preferences['focusMinutes'];
              _shortBreakMinutes = preferences['shortBreakMinutes'];
              _longBreakMinutes = preferences['longBreakMinutes'];
              _rounds = preferences['rounds'];
              _loading = false; // Data is loaded, so hide loading indicator
            });
            return true; // Return true if data loading is successful
          }
        } else {
          // Default values if no preferences are found
          setState(() {
            _focusMinutes = 25;
            _shortBreakMinutes = 5;
            _longBreakMinutes = 30;
            _rounds = 4;
            _loading = false; // Data is loaded, so hide loading indicator
          });
          return true; // Return true even if no preferences were found (successful loading with default values)
        }
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("User not logged in.")));
        return false; // Return false if user is not logged in
      }
    } catch (e) {
      setState(() {
        _loading = false; // Hide loading on error
      });
      print("Error loading preferences: $e");
      return false; // Return false if there was an error
    }
    return null;
  }

  // Save preferences to Firestore
  Future<void> _savePreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        DocumentReference userRef =
            FirebaseFirestore.instance.collection('User').doc(user.uid);

        Map<String, dynamic> preferencesEntry = {
          'focusMinutes': _focusMinutes,
          'shortBreakMinutes': _shortBreakMinutes,
          'longBreakMinutes': _longBreakMinutes,
          'rounds': _rounds,
        };

        await userRef.update({
          'preferences': preferencesEntry,
        });

        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Times set as default.")));
        _showTopNotification("Timer settings updated succefully!");
        setState(() {
          _isSaved = true; // Mark as saved and trigger UI update
          print("Preferences saved. _isSaved = $_isSaved"); // Debug statement
        });
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("User not logged in.")));
        _showTopNotification("user not logged in error!");
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      _showTopNotification("Error saving preferences: $e");
    }
  }

  // Function to open the bottom sheet to select time
  void _openTimeSelector() {
    // Check if preferences have finished loading before opening the bottom sheet
    if (_loading) {
      return; // Prevent opening the bottom sheet if data is still loading
    }

    // Ensure the context is valid and use the proper context
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Select Pomodoro Times:",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20),
                  // Focus Time, Short Break, and Long Break Time all in a Row next to each other
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _buildTimePickerColumn(
                          label: "Focus Time",
                          value: _focusMinutes,
                          controller: _focusController,
                          minTime: 1,
                          maxTime: 60,
                          onTimeChanged: (newTime) {
                            setState(() {
                              _focusMinutes = newTime;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: _buildTimePickerColumn(
                          label: "Short Break",
                          value: _shortBreakMinutes,
                          controller: _shortBreakController,
                          minTime: 1,
                          maxTime: 30,
                          onTimeChanged: (newTime) {
                            setState(() {
                              _shortBreakMinutes = newTime;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: _buildTimePickerColumn(
                          label: "Long Break",
                          value: _longBreakMinutes,
                          controller: _longBreakController,
                          minTime: 1,
                          maxTime: 60,
                          onTimeChanged: (newTime) {
                            setState(() {
                              _longBreakMinutes = newTime;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 25),
                  // Number of Rounds Slider
                  Text(
                    "Rounds: $_rounds",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  Slider(
                    min: 1,
                    max: 10,
                    divisions: 9,
                    value: _rounds.toDouble(),
                    activeColor: const Color(0xFF79A3B7),
                    inactiveColor: Colors.grey[400],
                    onChanged: (value) {
                      setState(() {
                        _rounds = value.toInt();
                      });
                    },
                  ),
                  SizedBox(height: 15),
                  // "Set Times as Default" option
                  GestureDetector(
                    onTap: () async {
                      await _savePreferences();
                      setState(() {
                        // reload the page
                      });
                    },
                    child: Text(
                      "Set Times as Default",
                      style: TextStyle(
                        fontSize: 16,
                        color: _isSaved
                            ? Colors.grey
                            : Colors.blue, // Change color based on _isSaved
                        decoration: TextDecoration.underline,
                        decorationColor: _isSaved ? Colors.grey : Colors.blue,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  // Start Timer Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TimerPomodoro(
                            taskId: widget.taskId,
                            taskName: widget.taskName,
                            subTaskID: widget.subTaskID,
                            subTaskName: widget.subTaskName,
                            focusMinutes: _focusMinutes,
                            shortBreakMinutes: _shortBreakMinutes,
                            longBreakMinutes: _longBreakMinutes,
                            rounds: _rounds,
                            page: widget.page,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(
                          0xFF3B7292), // Use the same color as in the second button
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            12), // Match the border radius
                      ),
                      minimumSize: Size(160,
                          50), // Set width and height same as in second button
                      elevation: 5,
                    ),
                    child: Text(
                      "          Start Timer          ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Reusable widget for the time picker columns
  Widget _buildTimePickerColumn({
    required String label,
    required int value,
    required FixedExtentScrollController controller,
    required int minTime,
    required int maxTime,
    required Function(int) onTimeChanged,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black),
        ),
        _buildDigitalPicker(
          controller: controller,
          initialMinutes: value,
          minTime: minTime,
          maxTime: maxTime,
          onTimeChanged: onTimeChanged,
        ),
        Text(
          "  minutes",
          style: TextStyle(fontSize: 17, color: Colors.black),
        ),
      ],
    );
  }

  // The Picker Widget itself
  Widget _buildDigitalPicker({
    required FixedExtentScrollController controller,
    required int initialMinutes,
    required int minTime,
    required int maxTime,
    required Function(int) onTimeChanged,
  }) {
    List<int> minutesList =
        List.generate(maxTime - minTime + 1, (index) => minTime + index);
    int initialIndex = minutesList.indexOf(initialMinutes);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.jumpToItem(initialIndex);
    });

    return Container(
      width: 120,
      height: 120,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 60,
        diameterRatio: 1.8,
        magnification: 1.2,
        onSelectedItemChanged: (index) {
          onTimeChanged(minutesList[index]);
        },
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            return Center(
              child: Text(
                '${minutesList[index]}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            );
          },
          childCount: minutesList.length,
        ),
      ),
    );
  }

  void _showTopNotification(String message) {
    OverlayState? overlayState = Overlay.of(context);
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);
    Future.delayed(Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeSettings(); // Call the async function to initialize
  }

  Future<void> _initializeSettings() async {
    bool? loaded =
        await _loadPreferences(); // Await the result of _loadPreferences
    while (loaded == null) {
      print("Waiting for preferences to load...");
      await Future.delayed(
          Duration(milliseconds: 10)); // Wait 1 second before checking again
      loaded = await _loadPreferences(); // Recheck the preferences
    }
    if (loaded) {
      _openTimeSelector();
    } else {
      print("Failed to load preferences.");
      // Handle the failure case (e.g., show an error message)
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Building TimerSelectionPage. _isSaved: $_isSaved");

    // Construct the string to display the current times
    String timeDisplay =
        "Focus: $_focusMinutes min, Break: $_shortBreakMinutes min, Long Break: $_longBreakMinutes min, Rounds: $_rounds";

    return Scaffold(
      backgroundColor: Color(0xFFEAEFF0),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(
            255, 226, 231, 234), // Light grayish background
        elevation: 0, // No shadow, flat AppBar
        centerTitle: true, // Center the title in the AppBar
        title: Text(
          'Pomodoro', // Title text
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 15.0), // Adjusted padding to reduce the space
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.start, // Align content at the top
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align content to the left
          children: [
            SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                children: [
                  Icon(Icons.category, color: Color(0xFF3B7292)),
                  SizedBox(width: 8),
                  Text(
                    'Current timer defaults',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: Color(0xFF545454),
                    ),
                  ),
                  Spacer(), // Pushes the edit icon to the far right
                  IconButton(
                    icon: Icon(Icons.edit, color: Color(0xFF3B7292)),
                    onPressed: () {
                      _openTimeSelector();
                    },
                  ),
                ],
              ),
            ),
            // Display the current selected times in blocks
            Padding(
              padding: const EdgeInsets.only(
                  bottom: 15.0), // Adjusted bottom padding
              child: Column(
                children: [
                  _buildTopTimeBlock("Focus", _focusMinutes),
                  Divider(
                    color: Color.fromRGBO(
                        16, 74, 115, 1), // Set the color of the divider
                    thickness: 0.5, // Set the thickness of the divider
                    indent: 20, // Set the indent on the left
                    endIndent: 20, // Set the indent on the right
                    height: 0,
                  ),
                  _buildMiddleTimeBlock("Short Break", _shortBreakMinutes),
                  Divider(
                    color: Color.fromRGBO(
                        16, 74, 115, 0.405), // Set the color of the divider
                    thickness: 0.5, // Set the thickness of the divider
                    indent: 20, // Set the indent on the left
                    endIndent: 20, // Set the indent on the right
                    height: 0,
                  ),
                  _buildMiddleTimeBlock("Long Break", _longBreakMinutes),
                  Divider(
                    color: Color.fromRGBO(
                        16, 74, 115, 1), // Set the color of the divider
                    thickness: 0.5, // Set the thickness of the divider
                    indent: 20, // Set the indent on the left
                    endIndent: 20, // Set the indent on the right
                    height: 0,
                  ),
                  _buildBottomTimeBlock("Rounds", _rounds),
                ],
              ),
            ),
            SizedBox(
              height: 12,
            ),
            Center(
              child: ElevatedButton(
                onPressed: _openTimeSelector, // Button to open bottom sheet
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(
                      0xFF3B7292), // Use the same color as in the second button
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12), // Match the border radius
                  ),
                  minimumSize: Size(
                      160, 50), // Set width and height same as in second button
                  elevation: 5,
                ),
                child: Text(
                  "          Start Timer          ",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTimeBlock(String label, int value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF545454),
            ),
          ),
          Text(
            "$value min",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Color(0xFF545454),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiddleTimeBlock(String label, int value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF545454),
            ),
          ),
          Text(
            "$value min",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Color(0xFF545454),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTimeBlock(String label, int value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF545454),
            ),
          ),
          Text(
            "$value min",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Color(0xFF545454),
            ),
          ),
        ],
      ),
    );
  }
}
