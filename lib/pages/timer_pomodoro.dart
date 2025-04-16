import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/Classes/SubTask';
import 'package:flutter_application/Classes/Task';
import 'package:flutter_application/pages/calender_page.dart';
import 'package:flutter_application/pages/task_page.dart'; // Firestore import
import 'package:audioplayers/audioplayers.dart'; //audio import
import 'package:device_apps/device_apps.dart';
//import 'package:flutter_application/services/notification_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AppBlocker {
  static const platform = MethodChannel('app_blocker_channel');
}

Future<void> requestAccessibilityPermission() async {
  try {
    await AppBlocker.platform.invokeMethod('requestAccessibilityPermission');
    print("Opened Accessibility Settings successfully.");
  } catch (e) {
    print("Error requesting accessibility permission: $e");
  }
}

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
  String selectedSound;
  String selectedSoundText;

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
    required this.selectedSound,
    required this.selectedSoundText
  });

  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPomodoro> {
  Map<String, bool> blockedApps = {};

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
  bool userLeft = false; // did user pause and stapped working?
  Duration pauseDuration = Duration.zero; // to keep track of time user left
  Timer? _pause; // to keep a real time clock of pause
  String firstString = '';
  bool _isSoundOn = true;
  String selectedSound = 'none';
   // A list of available sounds
  

  List<String> soundOptions = [
    'None',
    'Nature Morning',
    'Calming Rain',
    'White Noise',
    'Midnight',
    'Sea Wave',
    'Flowing Water',
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int userPoints = 0;
  int userLevel = 1;
  String? userID;

  
  // Helper function to format time as mm:ss
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return "${_twoDigits(minutes)}:${_twoDigits(remainingSeconds)}";
  }

  // Helper function to add leading zeros
  String _twoDigits(int n) => n.toString().padLeft(2, '0');

static const platform = MethodChannel('app_blocker_channel');

void _blockApps() async {
  if (blockedApps.isEmpty) {
    print("Blocked Apps list is empty.");
    return;
  }

  List<String> blockedPackages = blockedApps.entries
      .where((entry) => entry.value == true)
      .map((entry) => entry.key)
      .toList();

  print("Blocked Apps being sent to native layer: $blockedPackages");

  try {
    await platform.invokeMethod('startBlocking', {"blockedApps": blockedPackages});
    print("Blocking initiated successfully.");
  } catch (e) {
    print("Error while blocking apps: $e");
  }
}

Future<void> _unblockApps() async {
  try {
    await platform.invokeMethod('stopBlocking'); // إلغاء الحظر باستخدام MethodChannel
    print("Apps unblocked successfully.");
  } catch (e) {
    print("Error while unblocking apps: $e");
  }
}


Future<void> _saveBlockedApps() async {
  final prefs = await SharedPreferences.getInstance();
  String jsonString = json.encode(blockedApps);
  await prefs.setString('blockedApps', jsonString);
  print("Blocked Apps saved successfully: $blockedApps");
}


Future<bool> checkAccessibilityPermission() async {
  try {
    final bool hasPermission = await AppBlocker.platform.invokeMethod('checkPermission');
    return hasPermission;
  } catch (e) {
    print("Error checking accessibility permission: $e");
    return false;
  }
}
 String _getSoundPath(String sound) {
    switch (sound) {
      case 'Nature Morning':
        return 'sounds/nature-morning.mp3';
      case 'Calming Rain':
        return 'sounds/calming-rain.mp3';
      case 'White Noise':
        return 'sounds/white-noise.mp3';
      case 'Midnight':
        return 'sounds/midnight.mp3';
      case 'Sea Wave':
        return 'sounds/sea-wave.mp3';
      case 'Flowing Water':
        return 'sounds/flowing-water.mp3';
      case 'None': // Case for when the user selects 'none'
        return ''; // Return an empty string to indicate no sound
      default:
        return ''; // If no valid sound is selected, return an empty path
    }
  }
 void _toggleSound() {
    setState(() {
      _isSoundOn = !_isSoundOn; // Toggle the sound state
    });
    if (_isSoundOn) {
      // Play sound if it's turned on
      _playSelectedSound();
    } else {
      // Stop the sound if it's turned off
      _audioPlayer.stop();
    }
  }
  
   void _showSoundMenu(BuildContext context) {
    
    showDialog(
     context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white, 
        title: Text(
          '               Select Sound',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF545454), 
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min, // Prevent column from taking unnecessary space
          children: soundOptions.map((sound) {
            bool isSelected = selectedSound == sound; // Check if this sound is the selected one

            return TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white, // Button background color
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15), // Padding inside each button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Rounded corners for buttons
                ),
                elevation: 0, // Remove shadow
              ),
              onPressed: () {
                setState(() {
                  selectedSound = sound;
                  _isSoundOn = true;
                });
                widget.selectedSound = _getSoundPath(sound);
                _playSelectedSound();
                Navigator.of(context).pop(); // Close the dialog after selection
              },
              child: Row(
                children: [
                  Radio<String>(
                    value: sound,
                    groupValue: widget.selectedSoundText, // Group value determines which one is selected
                    onChanged: (String? value) {
                      setState(() {
                        widget.selectedSoundText = value!;
                        _isSoundOn = true;
                      });
                      if (value!=null){
                      widget.selectedSound = _getSoundPath(value);
                      _playSelectedSound();
                      Navigator.of(context).pop(); // Close dialog after selecting
                    }},
                  ),
                  Text(
                    sound,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF545454), // Dark gray color for the text
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    },
  );
   
  }

   // Function to play the selected sound
  void _playSelectedSound() async {
     if (widget.selectedSound.isNotEmpty) {
       // هذه طبعتها للتحقق من عمل الصوت
    print("Playing sound...:");
    try {
      await _audioPlayer.play(AssetSource(widget.selectedSound)); // Use AssetSource instead of string path
        print("Sound played.");
    } catch (e) {
      print("Error playing sound: $e");
     }
  }
  else {
    if (widget.selectedSound.isEmpty){
       _audioPlayer.stop();

    }
  }
  }


  // Start the timer
  Future<void> _startTimer() async {

     if (blockedApps.isEmpty) {
    await _loadBlockedApps(); // تحميل التطبيقات المحظورة إذا كانت فارغة
  }

      final hasPermission = await checkAccessibilityPermission();

  if (!hasPermission) {
    await requestAccessibilityPermission();
    final newPermission = await checkAccessibilityPermission();
    if (newPermission) {
      _blockApps(); // استدعاء دالة الحظر بعد منح الصلاحيات
    } else {
      print("Accessibility permission denied.");
    }
  } else {
    _blockApps(); // إذا كانت الأذونات موجودة، استدعِ دالة الحظر مباشرةً
  }


  print("Blocked Apps before starting timer: $blockedApps");

    
    if (mounted) {
      setState(() {
        _isRunning = true;
        userLeft=false;
        _pause?.cancel(); 
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
     _unblockApps(); 

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
        // Before transitioning to long break, show dialog
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
    _audioPlayer.stop();
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
ElevatedButton(
  onPressed: () async {
    await requestAccessibilityPermission();
  },
  child: Text("Enable Accessibility Permission"),
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
                    await _unblockApps();

                  // Update task completion status in Firestore
                  await _updateTaskCompletionStatus(
                      widget.taskId, widget.subTaskID);
                  await _updateTasktimerStatus(widget.taskId);
                  _showCongratsDialog(); // Show the "Congratulations" dialog

                  // Reset rounds and timer if needed
                  _completedRounds = 0;
                  

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
  Future<void>  _resetTimer() async {
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
    userLeft = true;
  //   if(userLeft){
  //     print("pausing detected");
  //       _pause = Timer.periodic(Duration(seconds: 1), (timer) {
  //     setState(() {
  //       pauseDuration = Duration(seconds: pauseDuration.inSeconds + 1);
  //     });

  //     // 10 minutes then show notification
  //     if (pauseDuration.inSeconds >= 10) {
  //       print("Notification to be sent"); // added this just to debug
  //       //_schedulePauseReminder();  // Schedule a reminder notification
  //       print("Notification sent"); // added this just to debug
  //       _pause?.cancel();  // Stop the timer once the notification is sent
  //     }
  //   });
  // }
      
    }

/////////// paused too long reminder/ notifications/////////////// make sure to un-note the function name in any other code line 
///(لإعادة إضافة الفنكشن : عن طريق مسح علامة الملاحطة من جانب اسمها في أي جزء من الأسطر)
// Future<void> _schedulePauseReminder() async {
//   // Schedule a reminder notification after 10 minutes of consecutive pause
//   await NotificationHandler.schedulePauseReminder('pause_reminder');

//   // Reset the pause start time to prevent multiple notifications
//   pauseDuration = Duration.zero;
//   print("sent notification");
// }

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
  DateTime? completionDate = DateTime.now(); // Capture completion timestamp

  if (taskId == subTaskID) {
    // ✅ Mark Task as Completed
    await firestore.collection('Task').doc(taskId).update({
      'completionStatus': 2,
      'completionDate': Timestamp.fromDate(completionDate), // ✅ Add completion date
    });


    // ✅ Assign Task Points
    DocumentSnapshot taskDoc = await firestore.collection('Task').doc(taskId).get();
    if (taskDoc.exists) {
      Task task = Task(
        taskID: taskId,
        title: taskDoc['title'],
        scheduledDate: (taskDoc['scheduledDate'] as Timestamp).toDate(),
        priority: taskDoc['priority'],
        reminder: [],
        timer: DateTime.now(),
        note: taskDoc['note'],
        completionStatus: 2,
        userID: taskDoc['userID'],
      );
      await assignTaskPoints(task);
    }

    QuerySnapshot subtasksSnapshot = await firestore
        .collection('SubTask')
        .where('taskID', isEqualTo: taskId)
        .get();

    for (var subtaskDoc in subtasksSnapshot.docs) {
      await subtaskDoc.reference.update({
        'completionStatus': 1,
        'completionDate': Timestamp.fromDate(completionDate), // ✅ Add completion date
      });
    }
  } else {
    // ✅ Update Subtask Completion Status
    await firestore.collection('SubTask').doc(subTaskID).update({
      'completionStatus': 1,
      'completionDate': Timestamp.fromDate(completionDate), // ✅ Add completion date
    });

    QuerySnapshot subtasksSnapshot = await firestore
        .collection('SubTask')
        .where('taskID', isEqualTo: taskId)
        .get();

    // ✅ Check if all subtasks are completed
    bool allSubtasksComplete = subtasksSnapshot.docs.every((doc) {
      var data = doc.data() as Map<String, dynamic>?;
      return data != null && data['completionStatus'] == 1;
    });

    bool anySubtaskComplete = subtasksSnapshot.docs.any((doc) {
      var data = doc.data() as Map<String, dynamic>?;
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

    await firestore.collection('Task').doc(taskId).update({
      'completionStatus': newTaskStatus,
      if (newTaskStatus == 2) 'completionDate': Timestamp.fromDate(completionDate),
    });

    // ✅ Assign Subtask Points
    DocumentSnapshot subtaskDoc = await firestore.collection('SubTask').doc(subTaskID).get();
    if (subtaskDoc.exists) {
      DocumentSnapshot taskDoc = await firestore.collection('Task').doc(taskId).get();
      if (taskDoc.exists) {
        Task task = Task(
          taskID: taskId,
          title: taskDoc['title'],
          scheduledDate: (taskDoc['scheduledDate'] as Timestamp).toDate(),
          priority: taskDoc['priority'],
          reminder: [],
          timer: DateTime.now(),
          note: taskDoc['note'],
          completionStatus: newTaskStatus,
          userID: taskDoc['userID'],
        );

        SubTask subTask = SubTask(
          subTaskID: subTaskID,
          taskID: taskId,
          title: subtaskDoc['title'],
          completionStatus: 1,
        );

        await assignSubtaskPoints(task, subTask);
      }
    }
  }

  // ✅ Update User Level
  await updateLevel();
}

Future<void> assignTaskPoints(Task task) async {
  if (userID == null) return;

  try {
    print("🔹 Starting assignTaskPoints for Task: ${task.taskID}");

    double taskPoints = 10.0;
    int priority = task.priority;
    int newPoints = userPoints;

    QuerySnapshot subtasksSnapshot = await _firestore
        .collection('SubTask')
        .where('taskID', isEqualTo: task.taskID)
        .get();

    int subtaskCount = subtasksSnapshot.docs.length;
    if(subtaskCount>0){
      // ✅ Count only **incomplete subtasks before completion**
    int incompleteSubtasks = subtasksSnapshot.docs
        .where((doc) =>
            doc['completionStatus'] == null || doc['completionStatus'] != 1)
        .length;

    if (incompleteSubtasks > 0) {
      double subtaskPoints = taskPoints / subtaskCount;
      int awardedSubtaskPoints = (subtaskPoints * incompleteSubtasks).round();
      newPoints += awardedSubtaskPoints;
      print("✅ Added points for remaining incomplete subtasks: +$awardedSubtaskPoints");

      // ✅ Ensure no points are lost due to rounding
      int expectedTotal = (subtaskPoints * subtaskCount).round();
      int actualTotal = awardedSubtaskPoints +
          (subtaskCount - incompleteSubtasks) * subtaskPoints.round();

      if (actualTotal < expectedTotal) {
        int roundingFix = expectedTotal - actualTotal;
        newPoints += roundingFix;
        print("🛠 Fix applied: Adjusted for rounding error by adding +$roundingFix");
      }
        newPoints += 2;

    }
    }else {
      // ✅ If no subtasks exist, award full task points
      newPoints += taskPoints.toInt();
      print("✅ No subtasks found. Awarded full task points: +${taskPoints.toInt()}");
    }
    

    newPoints += (priority - 1); // Priority bonus

    // ✅ Fetch completion date & scheduled date
    DocumentSnapshot taskSnapshot =
        await _firestore.collection('Task').doc(task.taskID).get();

    if (taskSnapshot.exists && taskSnapshot['completionDate'] != null) {
      DateTime completionDate =
          (taskSnapshot['completionDate'] as Timestamp).toDate();
      DateTime scheduledDate = task.scheduledDate;

      // ✅ Only compare date (not time)
      DateTime normalizedScheduledDate =
          DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);
      DateTime normalizedCompletionDate =
          DateTime(completionDate.year, completionDate.month, completionDate.day);

      int dayDifference =
          normalizedScheduledDate.difference(normalizedCompletionDate).inDays;

      print("📅 Scheduled Date: $normalizedScheduledDate");
      print("✅ Completion Date: $normalizedCompletionDate");
      print("📊 Day Difference: $dayDifference");

      if (dayDifference > 0) {
        newPoints += dayDifference; // Add 1 point per early day
        print("✅ Task completed EARLY! +$dayDifference points");
      } else if (dayDifference < 0) {
        int maxPenalty = newPoints > -dayDifference ? -dayDifference : newPoints;
        newPoints -= maxPenalty; // Subtract 1 point per late day
        print("⚠ Task completed LATE! -$maxPenalty points");
      }
    }

    // ✅ Ensure points never drop below 0
    if (newPoints < 0) newPoints = 0;

    await _firestore.runTransaction((transaction) async {
      DocumentReference userRef = _firestore.collection('User').doc(userID);
      transaction.update(userRef, {'point': newPoints});
    });

    setState(() {
      userPoints = newPoints;
    });

    await updateLevel();
  } catch (e) {
    print("Error in assignTaskPoints: $e");
  }
}


Future<void> assignSubtaskPoints(Task task, SubTask subtask) async {
  if (userID == null) return;

  try {
    double taskPoints = 10.0;
    int newPoints = userPoints;

    QuerySnapshot subtasksSnapshot = await _firestore
        .collection('SubTask')
        .where('taskID', isEqualTo: task.taskID)
        .get();

    int totalSubtasks = subtasksSnapshot.docs.length;

    if (totalSubtasks > 0) {
      double subtaskPoints = taskPoints / totalSubtasks;
      newPoints += subtaskPoints.toInt();

      bool allSubtasksCompleted = subtasksSnapshot.docs.every(
          (doc) => doc['completionStatus'] != null && doc['completionStatus'] == 1);

      // Fetch the parent task
DocumentSnapshot taskSnapshot = await _firestore
    .collection('Task')
    .doc(task.taskID)
    .get();

  int taskCompletionStatus = taskSnapshot['completionStatus'];
//if (allSubtasksCompleted && taskCompletionStatus != 2)
  // Apply condition
  if (allSubtasksCompleted ) {
     if(totalSubtasks % 2 ==0)
        newPoints += 2;
      else
        newPoints += 3;
    //newPoints += 2;
  }

    } else {
      newPoints += taskPoints.toInt();
    }

    // Check completion date against scheduled date
    DocumentSnapshot subtaskSnapshot =
        await _firestore.collection('SubTask').doc(subtask.subTaskID).get();
    if (subtaskSnapshot.exists && subtaskSnapshot['completionDate'] != null) {
      DateTime completionDate =
          (subtaskSnapshot['completionDate'] as Timestamp).toDate();
      DateTime scheduledDate = task.scheduledDate;

      int dayDifference = scheduledDate.difference(completionDate).inDays;
      if (dayDifference > 0) {
        newPoints += dayDifference; // Add 1 point per early day
      } else if (dayDifference < 0) {
        newPoints -= dayDifference.abs(); // Subtract 1 point per late day
        if (newPoints < 0) newPoints = 0; // Ensure lowest score remains 0
      }
    }

    await _firestore.collection('User').doc(userID).update({'point': newPoints});

    setState(() {
      userPoints = newPoints;
    });

    await updateLevel();
  } catch (e) {
    print("Error in assignSubtaskPoints: $e");
  }
}


Future<void> updateLevel() async {
  if (userID == null) return;

  try {
    int newLevel = 1;
    int pointsRequired = 100;
    int accumulatedPoints = 0;

    while (userPoints >= accumulatedPoints + pointsRequired) {
      accumulatedPoints += pointsRequired;
      pointsRequired += 50;
      newLevel++;
    }

    // ✅ Only update Firestore if the level has changed
    if (newLevel != userLevel) {
      await _firestore.runTransaction((transaction) async {
        DocumentReference userRef = _firestore.collection('User').doc(userID);
        transaction.update(userRef, {'level': newLevel});
      });

      setState(() {
        userLevel = newLevel;
      });

      print("🎉 Level Up! New Level: $newLevel");
    } else {
      print("ℹ️ Level remains the same: $newLevel");
    }
  } catch (e) {
    print("Error in updateLevel: $e");
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
     _loadBlockedApps(); // تحميل قائمة التطبيقات المحظورة
    // Initialize the timer with the selected focus time
    _elapsedTime = widget.focusMinutes * 60;
    _timerText = _formatTime(_elapsedTime);
    _audioPlayer = AudioPlayer();
    _playSelectedSound();
    

  }

  Future<void> _loadBlockedApps() async {
  final prefs = await SharedPreferences.getInstance();
  String? jsonString = prefs.getString('blockedApps');
  if (jsonString != null) {
    try {
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      setState(() {
        blockedApps = jsonMap.map((key, value) => MapEntry(key, value as bool));
      });
      print("Loaded Blocked Apps: $blockedApps");
    } catch (e) {
      print("Error decoding blocked apps: $e");
    }
  } else {
    print("No blocked apps found in preferences.");
  }
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
          padding: EdgeInsets.only(top: 7.0,),
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
         actions: [
          Padding(
      padding: EdgeInsets.only(right: 7.0), // Add 7 padding to the right
       child: PopupMenuTheme(
          data: PopupMenuThemeData(
            color: Colors.white, // Set the background color of the menu to white
          ),
          child: GestureDetector(
            onLongPress: () {
              _showSoundMenu(context); // Show the sound menu on long press
            },
            child: IconButton(
              icon: Icon(
                _isSoundOn && widget.selectedSound != '' 
                    ? Icons.volume_up 
                    : Icons.volume_off,
                color: Colors.white,
              ),
              onPressed: _toggleSound, // Regular press to toggle sound
            ),
          ),
        ),
      ),  ],
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
                  onPressed:
                       () async {
                          await _updateTasktimerStatus(widget.taskId);
                           _unblockApps(); 
                          _showEncouragementDialog(); // Show encouragement message before quitting
                        }
                      , // Disable if timer is not running
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
                          BorderRadius.circular(15), // Rounded corners
                    ),
                    elevation:
                        5, // Shadow for better separation from the background
                  ),
                ),
                SizedBox(width: 20), // Space between the buttons

                // Done button with icon and rounded corners
                ElevatedButton.icon(
                  onPressed:
                       () async {
                          await _unblockApps(); 

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
                      , // Disable if the timer is not running
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
                          BorderRadius.circular(15), // Rounded corners
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