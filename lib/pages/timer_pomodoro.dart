import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application/pages/calender_page.dart';
import 'package:flutter_application/pages/task_page.dart'; // Firestore import
import 'package:audioplayers/audioplayers.dart'; //audio import

class TimerPomodoro extends StatefulWidget {
  final String taskId; 
  final String taskName; 
  final String subTaskID;
  final String subTaskName;
  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int rounds;
  final String page;

  TimerPomodoro({
    required this.taskId,
    required this.taskName,
    required this.subTaskID,
    required this.subTaskName,
    required this.focusMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.rounds,
    required this.page,
  });

  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPomodoro> {
  Timer? _timer;
  bool _isTimerInitialized = false; // Track if the timer is initialized

  int _elapsedTime = 0; // Time in seconds
  bool _isRunning = false;
  String _timerText = "00:00"; // Timer display text
  bool _isFocusTime = true; // To determine whether it's focus or break time
  int _pauseCount = 0; // Count the number of times the timer is paused
  int _completedRounds = 0; // Track the number of completed rounds
  bool displayshow = true; // to not repeat the completionmsg
  int _totalFocusTime = 0; // focus time excluding pauses and breaks
  int _scndDayTotalFocusTime =
      0; // had the user started timer right begore midnight
  bool isCompletionDialogShown =
      false; // to make sure the dialod doesnot loop in infinity
  late AudioPlayer _audioPlayer;
  DateTime now = DateTime.now();
  DateTime end = DateTime.now();
  DateTime first = DateTime.now();
  DateTime second = DateTime.now();
  bool accessed = true;
  String firstString = '';

  // Helper function to format time as mm:ss
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return "${_twoDigits(minutes)}:${_twoDigits(remainingSeconds)}";
  }

  // Helper function to add leading zeros
  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  // Start the timer
  void _startTimer() {
    if (mounted) {
      setState(() {
        _isRunning = true;
        if (_isFocusTime) {
          // Set focus time when starting
          if (_elapsedTime == 0) {
            _elapsedTime =
                widget.focusMinutes * 60; // Initialize focus time in seconds
          }
        } else {
          // Decide whether it's short break or long break based on rounds
          if (_completedRounds < widget.rounds - 1) {
            if (_elapsedTime == 0) {
              _elapsedTime = widget.shortBreakMinutes * 60; // Short break
            }
          } else {
            if (_elapsedTime == 0) {
              _elapsedTime = widget.longBreakMinutes * 60; // Long break
            }
          }
        }
        _timerText = _formatTime(_elapsedTime);
      });
    }

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_elapsedTime > 0) {
        if (mounted) {
          setState(() {
            _elapsedTime--;
            _timerText = _formatTime(_elapsedTime);

            // If it's focus time, increment total focus time by 1 second
            if (_isFocusTime) {
              if (accessed) {
                firstString = "${first.day}/${first.month}/${first.year}";
                accessed = false;
              }
              String scndString =
                  "${second.day}/${second.month}/${second.year}";
              if (scndString == firstString) {
                _totalFocusTime++; // Increment focus time each second during focus period
              } else {
                _scndDayTotalFocusTime++;
              }
            }
          });
        }
      } else {
        _stopTimer(); // Stop the timer when it reaches zero
      }
    });
  }

  // Stop the timer
  void _stopTimer() {
    _timer?.cancel();

    if (mounted) {
      setState(() {
        _isRunning = false;
      });
    }

    _playEndSound();

    // After focus time ends, switch to break time
    if (_isFocusTime) {
      if (mounted) {
        setState(() {
          _isFocusTime = false; // Switch to break time
        });
      }
    } else {
      // After break time, check if we need to switch to long break or back to focus time
      if (_completedRounds < widget.rounds - 1) {
        // If not the last round, increment the round and go back to focus time

        if (mounted) {
          setState(() {
            _isFocusTime = true; // Switch back to focus time
            displayshow = true; // Ensure the "LONG BREAK" text shows first
          });
        }
        _completedRounds++; // Increment completed rounds after short break
      } else {
        // *Before transitioning to long break, show dialog*
        // Show the completion dialog before the long break
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showCompletionDialog(); // Show dialog after the widget is built
        });
      }
    }
  }

  @override
  void dispose() {
    if (_isTimerInitialized) {
      _timer?.cancel(); // Safely cancel the timer if initialized
    }
    _audioPlayer.dispose(); // Dispose of the audio player
    super.dispose();
  }

  void _showCongratsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/check.png', // المسار إلى الصورة
                width: 80, // عرض الصورة
                height: 80, // ارتفاع الصورة
              ),
              const SizedBox(height: 10), // إضافة مسافة بين الصورة والعنوان
              Text(
                "Congratulations!",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF545454),
                ),
              ),
            ],
          ),
          content: Text(
            "You have completed your task!",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Color(0xFF545454),
            ),
          ),
          actions: <Widget>[
            // TextButton(
            //   child: Text("Thanks", style: TextStyle(
            //       color: const Color.fromARGB(255, 91, 127, 188),
            //       fontSize: 17,
            //       fontWeight: FontWeight.w500,
            //     ),),
            //   onPressed: () {
            //     // Dismiss the dialog after showing it
            //     Navigator.of(context).pop();
            //   },
            // ),
          ],
        );
      },
    );

    // Wait for 2 seconds, close the dialog, and navigate to the task page
    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context).pop(); // Close the dialog
      Navigator.pop(
          context); // Navigate back to the previous screen (task page)
    });
  }

  void _showEncouragementDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            "You're doing great! Keep it up!!",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF545454),
            ),
          ),
          content: Text(
            "would you like to save the time spent working?",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Color(0xFF545454),
            ),
          ),
          actions: <Widget>[
            // "Save time" option
            TextButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Color(0xFF79A3B7)),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                "No",
                style: TextStyle(
                  color: const Color(0xFF79A3B7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                // Handle "Save Time" action
                print("Time saved!");
                Future.delayed(Duration(seconds: 2), () {
                  if (widget.page == "1") {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => TaskPage()),
                    );
                  } else if (widget.page == "2") {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => CalendarPage()),
                    );
                  }
                });
              },
            ),
            // "Do not save it" option

            TextButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF79A3B7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                "Yes",
                style: TextStyle(
                  color: Color.fromARGB(
                      255, 255, 255, 255), // Customize button color as you wish
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () async {
                await _updateTasktimerStatus(widget.taskId);
                // Handle "Do not save it" action
                print("Time not saved.");

                if (widget.page == "1") {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => TaskPage()),
                  );
                } else if (widget.page == "2") {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => CalendarPage()),
                  );
                }
              },
            ),
          ],
        );
      },
    );

    // Close dialog and navigate back after 2 seconds
    // Future.delayed(Duration(seconds: 2), () {
    //   Navigator.of(context).pop(); // Close the dialog
    //   // Pass all values to TimerPomodoro page
    //   Navigator.pop(context);
    // });
  }

  // Show a dialog with choices when the user has completed the goal
  void _showCompletionDialog() {
    if (isCompletionDialogShown) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            "You have completed your rounds goal!",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF545454),
            ),
          ),
          content: Column(
            mainAxisSize:
                MainAxisSize.min, // Prevent the column from taking extra space
            mainAxisAlignment:
                MainAxisAlignment.center, // Center the buttons vertically
            children: <Widget>[
              Text(
                "What would you like to do next?",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Color(0xFF545454),
                ),
              ),
              SizedBox(height: 20), // Add space between text and buttons
              TextButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF79A3B7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  "        Task Completed        ",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                onPressed: () async {
                  // Update task completion status in Firestore
                  await _updateTaskCompletionStatus(
                      widget.taskId, widget.subTaskID);
                  await _updateTasktimerStatus(widget.taskId);
                  _showCongratsDialog(); // Show the "Congratulations" dialog

                  // Reset rounds and timer if needed
                  _completedRounds = 0;
                  _resetTimer();

                  // After showing the congrats dialog, navigate back to the TaskPage
                  Future.delayed(Duration(seconds: 2), () {
                    if (widget.page == "1") {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => TaskPage()),
                      );
                    } else if (widget.page == "2") {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => CalendarPage()),
                      );
                    }
                  });
                },
              ),
              TextButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF79A3B7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  "             Redo Rounds            ",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                onPressed: () {
                  if (!isCompletionDialogShown) {
                    Navigator.of(context).pop();
                    // Reset rounds and start from the beginning with the long break first
                    setState(() {
                      _completedRounds = 0; // Reset completed rounds
                      _isFocusTime =
                          true; // Start with long break, not focus time
                      displayshow =
                          true; // Ensure the "LONG BREAK" text shows first
                      _elapsedTime = widget.longBreakMinutes *
                          60; // Set to long break duration
                      _timerText =
                          _formatTime(_elapsedTime); // Update the timer text
                    });
                    print("Completed Rounds: $_completedRounds");
                    _startTimer(); // Start the timer
                  }

                  if (mounted) {
                    setState(() {
                      //isCompletionDialogShown = true; // Set the flag to true when the dialog is shown
                    });
                  }
                },
              ),
              TextButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF79A3B7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  "                        Quit                       ",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                onPressed: () async {
                  await _updateTasktimerStatus(widget.taskId);
                  _showEncouragementDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Reset the timer
  void _resetTimer() {
    setState(() {
      _elapsedTime = widget.focusMinutes * 60;
      _timerText = _formatTime(_elapsedTime);
      _isRunning = false;
    });
    if (_isTimerInitialized) {
      _timer?.cancel();
    }
  }

  // Function to handle pausing the timer
  void _pauseTimer() {
    _pauseCount++; // Increment pause count
    if (_pauseCount >= 3) {
      _showPauseWarning(); // Show warning if paused 3 times
      _pauseCount = 0; // Reset pause count after showing warning
    }

    if (mounted) {
      setState(() {
        _isRunning =
            false; // Simply stop the timer without resetting the elapsed time
      });
    }

    _timer?.cancel(); // Just pause the timer, no reset of elapsed time
  }

  bool _isRadioChecked = false; // Radio button state (unchecked by default)

  // Toggle the radio button state and update Firestore
  void _toggleRadioButton() async {
    setState(() {
      _isRadioChecked = !_isRadioChecked; // Toggle the radio button state
    });

    if (_isRadioChecked) {
      // Update the task completion status in Firestore
      await _updateTaskCompletionStatus(
          widget.taskId, widget.subTaskID); // Pass taskId from the widget
      await _updateTasktimerStatus(widget.taskId);
      _showCongratsDialog();
      Future.delayed(Duration(seconds: 2), () {
        if (widget.page == "1") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => TaskPage()),
          );
        } else if (widget.page == "2") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => CalendarPage()),
          );
        }
      });
    }
  }

  // Function to update Firestore when task is completed
 Future<void> _updateTaskCompletionStatus(String taskId, String subTaskID) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  if (taskId == subTaskID) {
    await firestore
        .collection('Task')
        .doc(taskId)
        .update({'completionStatus': 2});

    QuerySnapshot subtasksSnapshot = await firestore
        .collection('SubTask')
        .where('taskID', isEqualTo: taskId)
        .get();

    for (var subtaskDoc in subtasksSnapshot.docs) {
      await subtaskDoc.reference.update({'completionStatus': 1});
    }
  } else {
    await firestore
        .collection('SubTask')
        .doc(subTaskID)
        .update({'completionStatus': 1});

    QuerySnapshot subtasksSnapshot = await firestore
        .collection('SubTask')
        .where('taskID', isEqualTo: taskId)
        .get();

    // Ensure allSubtasksComplete and anySubtaskComplete handle null or missing data
    bool allSubtasksComplete = subtasksSnapshot.docs.every((doc) {
      var data = doc.data() as Map<String, dynamic>?; // Safely cast to Map
      return data != null && data['completionStatus'] == 1;
    });

    bool anySubtaskComplete = subtasksSnapshot.docs.any((doc) {
      var data = doc.data() as Map<String, dynamic>?; // Safely cast to Map
      return data != null && data['completionStatus'] == 1;
    });

    int newTaskStatus;
    if (allSubtasksComplete) {
      newTaskStatus = 2;
    } else if (anySubtaskComplete) {
      newTaskStatus = 1;
    } else {
      newTaskStatus = 0;
    }

    await firestore
        .collection('Task')
        .doc(taskId)
        .update({'completionStatus': newTaskStatus});
  }
}



  Future<void> _updateTasktimerStatus(String taskId) async {
    try {
      // Reference to the task document in Firestore using the taskId
      DocumentReference taskRef =
          FirebaseFirestore.instance.collection('Task').doc(taskId);
      end = DateTime.now();
      String endDateTimeString =
          "${end.hour}:${end.minute} ${end.day}/${end.month}/${end.year}";

      String dateTimeString =
          "${now.hour}:${now.minute} ${now.day}/${now.month}/${now.year}";
      // Create a new entry with the current dateTime and timeElapsed
      Map<String, dynamic> timerEntry = {
        'firstDayStartDatetime': dateTimeString,
        'firstDayActualTimeSpent': _totalFocusTime,
        'secondDayEndDatetime': endDateTimeString,
        'secondDayActualTimeSpent': _scndDayTotalFocusTime,
      };

      await taskRef.update({
        'timer': FieldValue.arrayUnion(
            [timerEntry]), // Add the new timer entry to the list
      });
    } catch (e) {
      print("Error updating task timer: $e");
    }

// else if(subTaskID!= taskId){
//   try {

//     // Reference to the task document in Firestore using the taskId
//     DocumentReference taskRef = FirebaseFirestore.instance.collection('SubTask').doc(subTaskID);
//    end = DateTime.now();
//     String endDateTimeString = "${end.hour}:${end.minute} ${end.day}/${end.month}/${end.year}";

//     String dateTimeString = "${now.hour}:${now.minute} ${now.day}/${now.month}/${now.year}";
//     // Create a new entry with the current dateTime and timeElapsed
//     Map<String, dynamic> timerEntry = {
//       'firstDayStartDatetime': dateTimeString,
//       'firstDayActualTimeSpent': _totalFocusTime,
//       'secondDayEndDatetime': endDateTimeString,
//       'secondDayActualTimeSpent': _scndDayTotalFocusTime,
//     };

//     await taskRef.update({
//       'timer': FieldValue.arrayUnion([timerEntry]), // Add the new timer entry to the list
//     });

//   } catch (e) {
//     print("Error updating task timer: $e");
//   }}
  }

  void _playEndSound() async {
    // هذه طبعتها للتحقق من عمل الصوت
    print("Playing sound...");
    await _audioPlayer.play(AssetSource('sounds/countdown-timer.wav'));
    print("Sound played.");
  }

  @override
  void initState() {
    super.initState();
    // Initialize the timer with the selected focus time
    _elapsedTime = widget.focusMinutes * 60;
    _timerText = _formatTime(_elapsedTime);
    _audioPlayer = AudioPlayer();
  }

  @override
  Widget build(BuildContext context) {
    // Determine the background color based on whether it's focus time or break time
    Color backgroundColor = _isFocusTime
        ? Color.fromARGB(255, 13, 46, 89) // Work time background color
        : (_completedRounds == widget.rounds - 1
            ? Color.fromARGB(255, 46, 68,
                81) // Long break background color (green for last round)
            : Color.fromARGB(255, 23, 72, 89)); // Short break background color

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        title: Padding(
          padding: EdgeInsets.only(top: 7.0),
          child: Text(
            widget.taskId == widget.subTaskID
                ? widget
                    .taskName // Display taskId if taskId and subTaskId are equal
                : widget.subTaskName, // Otherwise, display taskName
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        leading: Padding(
          padding: EdgeInsets.only(left: 16.0, top: 13, bottom: 3),
          child: IconButton(
            icon: Icon(
              _isRadioChecked
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: Colors.white,
            ),
            onPressed:
                _toggleRadioButton, // Toggle radio button state when clicked
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 30),
              child: Builder(
                builder: (context) {
                  // Determine the text to display based on the state
                  String displayText = _isFocusTime
                      ? "FOCUS"
                      : (_completedRounds == widget.rounds - 1
                          ? "LONG BREAK"
                          : "BREAK");

                  // If the text is "LONG BREAK", show the completion dialog
                  if (_completedRounds == widget.rounds) {
                    displayshow = false;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _showCompletionDialog(); // Show dialog after the widget is built
                    });
                  }

                  return Text(
                    displayText,
                    style: TextStyle(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      fontSize: 35,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10), // Space between the text and round counter
            // Display the round counter text
            Text(
              "Round ${_completedRounds + 1} / ${widget.rounds}",
              style: TextStyle(
                color: const Color.fromARGB(255, 255, 255, 255),
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(
                height: 90), // Space between the text and circular progress bar
            // Circular progress bar around the timer text
            Stack(
              alignment: Alignment.center,
              children: [
                // Circular progress bar with custom size
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: _elapsedTime /
                        (_isFocusTime
                            ? widget.focusMinutes * 60
                            : (_completedRounds == widget.rounds
                                ? widget.longBreakMinutes * 60
                                : widget.shortBreakMinutes * 60)),
                    strokeWidth: 10, // Width of the progress indicator's stroke
                    valueColor: AlwaysStoppedAnimation<Color>(
                        const Color.fromARGB(255, 255, 255, 255)),
                    backgroundColor: Colors.transparent,
                  ),
                ),
                // Timer countdown display
                Text(
                  _timerText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            // Play/Pause button
            ElevatedButton(
              onPressed: _isRunning
                  ? _pauseTimer
                  : _startTimer, // Toggle between start and stop
              child: Icon(
                _isRunning ? Icons.pause : Icons.play_arrow,
                color: Colors.white, // Toggle icon
                size: 40,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(0, 255, 255, 255),
                shape: CircleBorder(), // Circular shape for the button
                padding: EdgeInsets.all(20),
              ),
            ),
            SizedBox(height: 20),
            // Row for Quit and Done buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Quit button with icon and rounded corners
                ElevatedButton.icon(
                  onPressed: _isRunning
                      ? () async {
                          await _updateTasktimerStatus(widget.taskId);
                          _showEncouragementDialog(); // Show encouragement message before quitting
                        }
                      : null, // Disable if timer is not running
                  icon: Icon(
                    Icons.cancel_outlined, // Cancel icon for "Quit"
                    size: 18,
                  ),
                  label: Text("Quit"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 234, 113, 107),
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(30), // Rounded corners
                    ),
                    elevation:
                        5, // Shadow for better separation from the background
                  ),
                ),
                SizedBox(width: 20), // Space between the buttons

                // Done button with icon and rounded corners
                ElevatedButton.icon(
                  onPressed: _isRunning
                      ? () async {
                          // Mark the task as done when "Done" button is pressed
                          await _updateTaskCompletionStatus(widget.taskId,
                              widget.subTaskID); // Update Firestore
                          await _updateTasktimerStatus(widget.taskId);
                          _resetTimer();

                          // Dismiss any open dialogs (e.g., completion dialog or other dialogs)
                          // Navigator.of(context).pop(); // Close the current dialog (such as completion dialog)
                          _showCongratsDialog();
                          // Reset rounds and navigate to TaskPage
                          _completedRounds = 0;
                          Future.delayed(Duration(seconds: 2), () {
                            if (widget.page == "1") {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => TaskPage()),
                              );
                            } else if (widget.page == "2") {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => CalendarPage()),
                              );
                            }
                          });
                        }
                      : null, // Disable if the timer is not running
                  icon: Icon(
                    Icons.check_circle_outline, // Checkmark icon for "Done"
                    size: 18,
                  ),
                  label: Text("Done"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 84, 164, 112),
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(30), // Rounded corners
                    ),
                    elevation:
                        5, // Shadow for better separation from the background
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showPauseWarning() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Frequent Pauses",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF545454),
            ),
          ),
          content: Text(
            "You have paused frequently. Make sure your workspace is quiet and free of distractions.",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Color(0xFF545454),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "OK",
                style: TextStyle(
                  color: const Color.fromARGB(255, 91, 127, 188),
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
