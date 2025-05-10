import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/models/BottomNavigationBar.dart';
import 'package:flutter_application/models/GuestBottomNavigationBar.dart';
import 'package:flutter_application/welcome_page.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_application/services/notification_handler.dart';




class ChatbotpageWidget extends StatefulWidget {
  const ChatbotpageWidget({super.key});

  @override
  _ChatbotpageWidgetState createState() => _ChatbotpageWidgetState();
}

bool isSpeaking = false;
String? currentlySpokenText;

class _ChatbotpageWidgetState extends State<ChatbotpageWidget>
    with WidgetsBindingObserver {
  final FlutterTts flutterTts = FlutterTts();
  DateTime? currentSessionStart;

  String? userID;
  int selectedIndex = 2;
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isWaitingForResponse = false;
  final ScrollController _scrollController = ScrollController();
  bool showScrollButton = false;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  Set<String> copiedMessages = {};
  Map<String, bool> messageIsPlaying = {};
  DateTime? lastMessageDate;
  Map<String, String> typingMessages = {};
  List<DateTime> selectedDates = [];
  Map<String, bool> showAllTasksByDate = {};
///////////////////////////
// ----ADD task feature variables section----//
final TextEditingController taskTitleController = TextEditingController();
final TextEditingController taskNoteController = TextEditingController();
  DateTime? taskselectedDate;
  TimeOfDay? selectedTime;
  String selectedPriorityLabel = 'Normal'; // default
String? selectedPriority;
Color darkGray = Color(0xFF545454);
Color priorityIconColor = Color(0xFF3B7292);
TextEditingController subtaskController = TextEditingController();
Color darkBlue = Color(0xFF104A73);
List<String> subtasks = [];
  Color lightBlue = Color(0xFF79A3B7);
  Color lightestBlue = Color(0xFFC7D9E1);
  Color lightGray = Color(0xFFF5F7F8);
    Color mediumBlue = Color(0xFF3B7292);
DateTime selectedDateforSubtask = DateTime.now();
  List<String> categories = [];
    TextEditingController categoryController = TextEditingController();
  String selectedCategory = '';
  User? _user = FirebaseAuth.instance.currentUser;
  List<String> hardcodedCategories = [];
bool showOptionalFields = false;
bool taskFieldsLocked = false;
DateTime ReminderselectedDate = DateTime.now();
TimeOfDay reminderSelectedTime = TimeOfDay.now();
bool _TaskDataInitialized = false;
String? _lastInitTaskTimestamp;
Map<String, Map<String, dynamic>> tasksAddData = {};
Map<String, Widget> taskExtraContent = {};
///////////
  Future<void> pickOneDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && !selectedDates.contains(picked)) {
      setState(() {
        selectedDates.add(picked);
      });
    }
  }
  
  void _showCategoryEditDialog() {
    List<String> tempCategories = List.from(categories);
    List<Map<String, String>> renamedCategories = [];
    List<String> deletedCategories = [];
    List<String> addedCategories = [];

    FocusNode firstCategoryFocusNode = FocusNode();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor: lightGray,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categories',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkGray,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Rename, create, or delete categories.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: darkGray,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      children: tempCategories.asMap().entries.map((entry) {
                        int index = entry.key;
                        String category = entry.value;
                        TextEditingController renameController =
                            TextEditingController(text: category);

                        return ListTile(
                          title: TextField(
                            controller: renameController,
                            focusNode:
                                index == 0 ? firstCategoryFocusNode : null,
                            onSubmitted: (newName) {
                              if (newName.isNotEmpty && newName != category) {
                                setState(() {
                                  int index = tempCategories.indexOf(category);
                                  if (index != -1) {
                                    renamedCategories.add({
                                      'oldName': category,
                                      'newName': newName,
                                    });
                                    tempCategories[index] = newName;
                                  }
                                });
                              }
                            },
                            decoration: InputDecoration(
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: darkGray,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                deletedCategories.add(category);
                                tempCategories.remove(category);
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    Divider(),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: categoryController,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Add new category...',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.arrow_upward,
                                color: mediumBlue,
                                size: 24.0,
                              ),
                              onPressed: () {
                                if (categoryController.text.isNotEmpty) {
                                  if (tempCategories.length < 7) {
                                    setState(() {
                                      tempCategories
                                          .add(categoryController.text);
                                      addedCategories
                                          .add(categoryController.text);
                                      categoryController.clear();
                                    });
                                  } else {
                                    _showTopNotification(
                                        'You can only create up to 7 categories.');
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: darkBlue,
                      ),
                      child: Text(
                        'Discard',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    TextButton(
                      onPressed: () async {
                        await _saveChangesToDatabase(
                          addedCategories,
                          renamedCategories,
                          deletedCategories,
                        );
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: darkBlue,
                      ),
                      child: Text(
                        'Save and Close',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          color: darkBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      firstCategoryFocusNode.requestFocus();
    });
  }
  Future<void> sendSelectedDates() async {
    for (final date in selectedDates) {
      final formatted = DateFormat('yyyy-MM-dd').format(date);
      await _sendMessage("I want to view my tasks on $formatted");
    }
    setState(() {
      selectedDates.clear();
    });
  }

  Future<Map<DateTime, bool>> _fetchTasksStatus() async {
    Map<DateTime, bool> tasksStatus = {};

    var tasksSnapshot = await _firestore
        .collection('Tasks')
        .where('userID', isEqualTo: userID)
        .get();

    for (var doc in tasksSnapshot.docs) {
      var data = doc.data();
      DateTime taskDate = (data['date'] as Timestamp).toDate();

      bool isCompleted = data['completionStatus'] == 1;

      DateTime dayOnly = DateTime(taskDate.year, taskDate.month, taskDate.day);

      if (!tasksStatus.containsKey(dayOnly)) {
        tasksStatus[dayOnly] = true;
      }

      if (!isCompleted) {
        tasksStatus[dayOnly] = false;
      }
    }

    return tasksStatus;
  }
int _getPriorityValue() {
    switch (selectedPriority) {
      case 'Urgent':
        return 4;
      case 'High':
        return 3;
      case 'Normal':
        return 2;
      case 'Low':
        return 1;
      default:
        return 2;
    }
  }
  Widget _priorityFlag(String label, Color color) {
    return Column(
      children: [
        IconButton(
          icon: Icon(Icons.flag, color: color),
          onPressed: () {
            setState(() {
              selectedPriority = label;
              priorityIconColor = color;

            });
          },
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: darkGray,
          ),
        ),
      ],
    );
  }
  
  Widget _buildReminderSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Icon(Icons.notifications, color: mediumBlue),
                  // SizedBox(width: 8),
                  Text(
  '⏰ Reminder:',
  style: const TextStyle(
    fontWeight: FontWeight.bold, // 💪 Same as Priority
    fontSize: 14, // 📏 Same size
    color: Colors.black87, // 🎨 Same color
  ),
),
                ],
              ),
              Switch(
                value: isReminderOn,
                onChanged: (value) {
                  setState(() {
                    isReminderOn = value;
                    if (!isReminderOn) {
                      selectedReminderOption = null;
                      customReminderDateTime = null;
                    }
                  });
                },
                activeColor: mediumBlue, // Thumb color when switch is ON
                activeTrackColor: lightBlue,
                inactiveThumbColor: const Color.fromARGB(
                    255, 172, 172, 172), // Thumb color when switch is OFF
                inactiveTrackColor: Colors.grey[350],
              ),
            ],
          ),
          if (isReminderOn)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: DropdownButtonFormField<Map<String, dynamic>>(
                value: selectedReminderOption,
                isExpanded: true,
                items: reminderOptions.map((option) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: option,
                    child: Text(
                      option['label'],
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: darkGray,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedReminderOption = value;
                    if (value?['label'] == "Custom Time") {
                      _pickCustomReminderTime();
                    }
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: lightestBlue),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                hint: Text(
                  "Select a reminder time",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: darkGray,
                  ),
                ),
                dropdownColor: const Color.fromARGB(255, 245, 245, 245),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: darkGray,
                ),
                iconEnabledColor: mediumBlue,
              ),
            ),
          if (selectedReminderOption != null &&
              selectedReminderOption!['label'] == "Custom Time" &&
              customReminderDateTime != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "Custom Reminder: ${DateFormat('MMM dd, yyyy - hh:mm a').format(customReminderDateTime!)}",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: darkGray,
                ),
              ),
            ),
        ],
      ),
    );
  }

  
  void _pickCustomReminderTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: ReminderselectedDate,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: darkBlue,
            colorScheme: ColorScheme.light(
              primary: darkBlue,
              onPrimary: Color(0xFFF5F7F8),
              surface: Color(0xFFF5F7F8),
              onSurface: darkGray,
              secondary: lightBlue,
            ),
            dialogBackgroundColor: Color(0xFFF5F7F8),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              primaryColor: darkBlue,
              colorScheme: ColorScheme.light(
                primary: darkBlue,
                onPrimary: Color(0xFFF5F7F8),
                surface: Color(0xFFF5F7F8),
                onSurface: darkGray,
                secondary: lightBlue,
              ),
              dialogBackgroundColor: Color(0xFFF5F7F8),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        DateTime selectedReminder = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        DateTime taskDateTime = DateTime(
          ReminderselectedDate.year,
          ReminderselectedDate.month,
          ReminderselectedDate.day,
          reminderSelectedTime.hour,
          reminderSelectedTime.minute,
        );

       if (selectedReminder.isAfter(taskDateTime)) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _showTopNotification(
      "Custom reminder time cannot be after the scheduled task time. Please select a valid time.",
    );
    setState(() {
      customReminderDateTime = null;
    });
  });
} else {
  setState(() {
    customReminderDateTime = selectedReminder;
  });
}

      }
    }
  }

  void _pickMultipleDatesInDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Select Date(s)",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null && !selectedDates.contains(picked)) {
                        setState(() {
                          selectedDates.add(picked);
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF79A3B7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      "Pick a Date",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (selectedDates.isEmpty)
                    const Text(
                      "No dates selected",
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      children: selectedDates.map((date) {
                        return Chip(
                          label: Text(DateFormat('yyyy-MM-dd').format(date)),
                          onDeleted: () {
                            setState(() {
                              selectedDates.remove(date);
                            });
                          },
                        );
                      }).toList(),
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
                    style: TextStyle(
                      color: Color(0xFF79A3B7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    String combinedDates = selectedDates
                        .map((date) => DateFormat('yyyy-MM-dd').format(date))
                        .join(', ');

                    await _sendMessage(
                        "I want to view my tasks on $combinedDates");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF79A3B7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  late List<Map<String, dynamic>> suggestedQuestions;

  @override
  void initState() {
    super.initState();
    isInChatbotPage = true;
    WidgetsBinding.instance.addObserver(this);
    _speech = stt.SpeechToText();
    _getCategories();
    _fetchUserID().then((_) {
      checkSessionStatus();
    });
    _fetchUserID().then((_) {
      suggestedQuestions = [
        {
          "image": "assets/images/task.png",
          "text": userID != null && userID!.startsWith("guest_")
              ? "What can you help me with?"
              : "What do I have today?",
          "color": Color(0xFF2C678E)
        },
        {
          "image": "assets/images/productivity.png",
          "text": "Give me a productivity tip!",
          "color": Color(0xFF78A1BA)
        },
        {
          "image": "assets/images/focus.png",
          "text": "How can I stay focused?",
          "color": Color(0xFF78A1BA)
        },
        {
          "image": "assets/images/breakdown.png",
          "text": "Help me to break\n down a big task?",
          "color": Color(0xFF2C678E)
        },
      ];

      setState(() {});
    });

    _fetchUserID();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollToBottom(force: true);
      });
    });
    _scrollController.addListener(_removeCopyOverlayOnScroll);

    setupTts();
  }

  Future<void> checkSessionStatus() async {
    if (userID != null && userID!.startsWith('guest_')) {
      print("🚫 Guest user -> No session handling");
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedSessionStart = prefs.getString('sessionStart');

    if (savedSessionStart != null) {
      currentSessionStart = DateTime.parse(savedSessionStart);
      print("🔁 Loaded saved session start: $currentSessionStart");
    }

    QuerySnapshot firstMsgSnap = await _firestore
        .collection("ChatBot")
        .where("userID", isEqualTo: userID ?? "guest_user")
        .orderBy("timestamp", descending: false)
        .limit(1)
        .get();

    if (firstMsgSnap.docs.isNotEmpty) {
      DateTime firstTime =
          (firstMsgSnap.docs.first.data() as Map<String, dynamic>)['timestamp']
              .toDate();

      if (currentSessionStart == null) {
        currentSessionStart = firstTime;
      } else {
        print("🔄 Using already renewed session: $currentSessionStart");
      }

      Duration sinceStart = DateTime.now().difference(currentSessionStart!);
      print("⏳ Time since session start: $sinceStart");

      if (sinceStart.inHours >= 24) {
        await _showSessionExpiredDialog();
        return;
      }
    }
  }

  Timer? _exitTimer;
  bool isInChatbotPage = true;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      print('🚪 User left the app COMPLETELY');

      if (userID != null && userID!.startsWith('guest_')) {
        var chatDocs = await _firestore
            .collection("ChatBot")
            .where("userID", isEqualTo: userID)
            .get();

        for (var doc in chatDocs.docs) {
          await doc.reference.delete();
        }

        print('🗑️ Deleted ChatBot messages for guest');

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('guestUserID');
        print('🗑️ Removed guestUserID from SharedPreferences');
      }
    }
  }

  String prevText = "";

  void setupTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.1);
    await flutterTts.setVolume(0.85);
    await flutterTts
        .setVoice({"name": "en-us-x-sfg#female_2", "locale": "en-US"});

    flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {
          isSpeaking = true;
        });
      }
    });

    flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          isSpeaking = false;
        });
      }
    });

    flutterTts.setCancelHandler(() {
      if (mounted) {
        setState(() {
          isSpeaking = false;
        });
      }
    });
  }

  void sendMessage(String text) {
    _firestore.collection("ChatBot").add({
      "userID": userID,
      "message": text,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  String sanitizeString(String input) {
    final StringBuffer buffer = StringBuffer();
    for (final int codeUnit in input.runes) {
      if (_isValidCodeUnit(codeUnit)) {
        buffer.writeCharCode(codeUnit);
      } else {
        buffer.write('�');
      }
    }
    return buffer.toString();
  }

  bool _isValidCodeUnit(int codeUnit) {
    return !(codeUnit >= 0xD800 && codeUnit <= 0xDFFF);
  }

  void _showTopNotification(String message) {
    if (!mounted) return;
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
              color: const Color.fromARGB(255, 112, 112, 112),
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

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) {
        print('Speech status: $val');
        if (val == "notListening") {
          _stopListening();
        }
      },
      onError: (val) {
        print('Speech error: $val');
        _stopListening();
      },
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        localeId: 'en-US',
        listenMode: stt.ListenMode.confirmation,
        pauseFor: const Duration(seconds: 3),
        onResult: (result) {
          setState(() {
            String newText = result.recognizedWords.trim();

            newText = newText.replaceAll(RegExp(r'\s+'), ' ');

            if (newText.startsWith(prevText)) {
              String addedPart = newText.substring(prevText.length).trim();
              _messageController.text += " $addedPart";
              _messageController.selection = TextSelection.fromPosition(
                TextPosition(offset: _messageController.text.length),
              );
            }
            prevText = newText;
          });
        },
        onSoundLevelChange: (level) {
          if (level < 1 && _isListening) {
            Future.delayed(const Duration(seconds: 2), () {
              if (_isListening) _stopListening();
            });
          }
        },
      );

      Future.delayed(const Duration(seconds: 10), () {
        if (_isListening) _stopListening();
      });
    }
  }

  void _stopListening() async {
    try {
      await _speech.stop();
    } catch (e) {
      print("Error stopping speech: $e");
    }

    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }
  }

  Future<void> _fetchUserID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // هل موجود guest id محفوظ؟
      String? savedGuestID = prefs.getString('guestUserID');

      if (savedGuestID != null) {
        userID = savedGuestID;
        print('👻 Loaded existing guest userID: $userID');
      } else {
        userID = 'guest_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('guestUserID', userID!);
        print('👻 Created new guest userID: $userID');
      }
    } else {
      userID = user.uid;
    }

    setState(() {});
  }

  Future<void> _sendMessage([String? messageText]) async {
    String text = messageText?.trim() ?? _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      isWaitingForResponse = true;
    });

    DocumentReference docRef = await _firestore.collection("ChatBot").add({
      "userID": userID ?? "guest_user",
      "message": text,
      "response": "",
      "timestamp": FieldValue.serverTimestamp(),
      "actionType": "",
    });

    if (messageText == null) {
      _messageController.clear();
    }
    setState(() {
      _messageController.clear();
      _scrollToBottom(force: true);
    });

    await _waitForResponse(docRef);
  }

  void _scrollToBottom({bool force = false}) {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      if (force || currentScroll >= maxScroll - 50) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _scrollListener() {
    if (_scrollController.offset <
        _scrollController.position.maxScrollExtent - 50) {
      if (!showScrollButton) {
        setState(() {
          showScrollButton = true;
        });
      }
    } else {
      if (showScrollButton) {
        setState(() {
          showScrollButton = false;
        });
      }
    }
  }

  Future<void> _showSessionExpiredDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "THE SESSION HAS ENDED!",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF545454),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 120,
                height: 120,
                child: Image.asset("assets/images/session_bot.png",
                    fit: BoxFit.contain),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  _sessionButton(
                    text: "Continue Previous Session",
                    onPressed: () async {
                      DateTime now = DateTime.now();
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      await prefs.setString(
                          'sessionStart', now.toIso8601String());

                      setState(() {
                        currentSessionStart = now;
                      });
                      Navigator.of(context).pop();
                      _showTopNotification("Continuing previous session");
                    },
                  ),
                  _sessionButton(
                    text: "        Start New Session       ",
                    onPressed: () async {
                      var chatDocs = await _firestore
                          .collection("ChatBot")
                          .where("userID", isEqualTo: userID ?? "guest_user")
                          .get();

                      for (var doc in chatDocs.docs) {
                        await doc.reference.delete();
                      }

                      Navigator.of(context).pop();
                      _showTopNotification("Started a new session");
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sessionButton(
      {required String text, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF79A3B7),
        padding: const EdgeInsets.symmetric(horizontal: 54, vertical: 10),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF79A3B7)),
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _waitForResponse(DocumentReference docRef) async {
    docRef.snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() is Map<String, dynamic>) {
        Map<String, dynamic> data = snapshot.data()! as Map<String, dynamic>;
        if (data['response'] != null && data['response'].isNotEmpty) {
          setState(() {
            isWaitingForResponse = false;
          });
          _simulateTyping(cleanText(data['response']));
          _scrollToBottom(force: true);
        }
      }
    });
  }

  bool isFirstLoad = true;
  void _confirmStartNewSession() async {
    var chatDocs = await _firestore
        .collection("ChatBot")
        .where("userID", isEqualTo: userID ?? "guest_user")
        .get();

    for (var doc in chatDocs.docs) {
      await doc.reference.delete();
    }

    // Reset session time
    currentSessionStart = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'sessionStart', currentSessionStart!.toIso8601String());

    _showTopNotification("Started a new session");
    setState(() {});
  }

  bool isValidUtf16(String input) {
    try {
      input.runes.forEach((_) {});
      return true;
    } catch (_) {
      return false;
    }
  }
  
  
  Future<User?> _getCurrentUser() async {
    if (_user == null) {
      _user = FirebaseAuth.instance.currentUser;
      if (_user == null) {
      }
    }
    return _user;
  }

    Future<void> _saveChangesToDatabase(
      List<String> addedCategories,
      List<Map<String, String>> renamedCategories,
      List<String> deletedCategories) async {
    User? currentUser = await _getCurrentUser();
    if (currentUser == null) return;

    for (String category in addedCategories) {
      await addCategory(category);
    }

    for (var renameMap in renamedCategories) {
      String oldName = renameMap['oldName']!;
      String newName = renameMap['newName']!;
      await updateCategory(oldName, newName);
    }

    for (String deletedCategory in deletedCategories) {
      await deleteCategory(deletedCategory);
    }

    await _getCategories();
  }

  Future<void> _getCategories() async {
    User? currentUser = await _getCurrentUser();
    if (currentUser == null) return;

    try {
      QuerySnapshot categorySnapshot = await FirebaseFirestore.instance
          .collection('Category')
          .where('userID', isEqualTo: currentUser.uid)
          .get();

      List<String> fetchedCategories = [];

      for (var doc in categorySnapshot.docs) {
        String categoryName = doc['categoryName'] ?? '';
        if (categoryName.isNotEmpty) {
          fetchedCategories.add(categoryName);
        }
      }

      List<String> combinedCategories = [
        ...hardcodedCategories,
        ...fetchedCategories
      ];

      List<String> uniqueCategories = combinedCategories.toSet().toList();

      setState(() {
        categories = uniqueCategories;
      });
    } catch (e) {
      _showTopNotification('Failed to fetch categories: $e');
    }
  }
  
  Future<void> addCategory(String categoryName) async {
    User? currentUser = await _getCurrentUser();
    if (currentUser == null) return;

    try {
      // Check if the category already exists for the current user
      QuerySnapshot existingCategorySnapshot = await FirebaseFirestore.instance
          .collection('Category')
          .where('categoryName', isEqualTo: categoryName)
          .where('userID', isEqualTo: currentUser.uid)
          .get();

      if (existingCategorySnapshot.docs.isNotEmpty) {
        // Display a message if the category already exists
        _showTopNotification('Category "$categoryName" already exists.');
        return;
      }

      // If it doesn't exist, add the new category
      await FirebaseFirestore.instance.collection('Category').add({
        'categoryName': categoryName,
        'userID': currentUser.uid,
        'taskIDs': [],
      });

      _showTopNotification('Category "$categoryName" added successfully.');
    } catch (e) {
      _showTopNotification('Failed to add category: $e');
    }
  }

  Future<void> updateCategory(String oldCategory, String newCategory) async {
    User? currentUser = await _getCurrentUser();
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

  Future<void> deleteCategory(String categoryName) async {
    User? currentUser = await _getCurrentUser();
    if (currentUser == null) return;

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Category')
        .where('categoryName', isEqualTo: categoryName)
        .where('userID', isEqualTo: currentUser.uid)
        .get();

    if (snapshot.docs.isNotEmpty) {
      List<dynamic> taskIDs = snapshot.docs.first['taskIDs'];

      if (taskIDs.isNotEmpty) {
        bool confirmDelete =
            await _showCategoryDeleteConfirmation(categoryName, taskIDs.length);

        if (!confirmDelete) {
          return;
        }

        for (var taskId in taskIDs) {
          await FirebaseFirestore.instance
              .collection('Task')
              .doc(taskId)
              .update({
            'category': '',
          });
        }
      }

      await snapshot.docs.first.reference.delete();
      _showTopNotification('Category "$categoryName" deleted successfully');
    }
  }

  Future<bool> _showCategoryDeleteConfirmation(
      String categoryName, int taskCount) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: lightGray,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                'Delete Category?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkGray,
                ),
              ),
              content: Text(
                'The category "$categoryName" is assigned to $taskCount tasks. '
                'Deleting this category will remove it from all those tasks. '
                'Do you still want to proceed?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: darkGray,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: mediumBlue,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text(
                    'Delete',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }
List<String> subtasksToAdd = [];

Widget _buildSubtaskSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (subtasks.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Text(
            'Subtasks',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: darkGray,
            ),
          ),
        ),
      ...subtasks.map((subtask) {
        final TextEditingController subtaskEditingController =
            TextEditingController(text: subtask);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
          child: Slidable(
            key: ValueKey(subtask),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                CustomSlidableAction(
                  onPressed: (_) {
                    setState(() {
                      subtasks.remove(subtask);
                      _showTopNotification("✅ Subtask deleted successfully!");
                      subtaskReminders.remove(subtask);
                    });
                  },
                  backgroundColor: const Color(0xFFC2C2C2),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            child: Container( 
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                title: TextField(
                  controller: subtaskEditingController,
                  onChanged: (newValue) {
                    setState(() {
                      final index = subtasks.indexOf(subtask);
                      if (index != -1) {
                        subtasks[index] = newValue;
                      }
                    });
                  },
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: darkGray,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.notifications,
                    color: subtaskReminders[subtask] != null
                        ? mediumBlue
                        : Colors.grey,
                  ),
                  onPressed: () async {
                    _pickSubtaskReminderTime(subtask);
                  },
                ),
              ),
            ),
          ),
        );
      }).toList(),

    
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: TextField(
          controller: subtaskController,
          decoration: InputDecoration(
            labelText: 'Add sub tasks',
            labelStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: darkBlue,
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: darkBlue, width: 2.0),
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.add, color: Color.fromARGB(255, 79, 79, 79)),
              onPressed: () {
                if (subtasks.length >= 10) {
                  _showTopNotification('🚫 You can only add up to 10 subtasks.');
                  return;
                }

                if (subtaskController.text.isNotEmpty) {
                  setState(() {
                    subtasks.add(subtaskController.text);
                    subtaskReminders[subtaskController.text] = null;
                    subtaskController.clear();
                  });
                }
              },
            ),
          ),
        ),
      ),
    ],
  );
}
Widget _buildCategorySection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 0),
        child: Row(
          children: [
            Text(
              '🏷️ Category:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.edit, color: Color(0xFF3B7292)),
              onPressed: () {
                _showCategoryEditDialog(); 
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Wrap(
          spacing: 6.0,
          runSpacing: 6.0,
          children: categories.map((category) {
            return ChoiceChip(
              label: Text(
                category,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 10),
              selected: selectedCategory == category,
              selectedColor: const Color(0xFF2C678E),
              backgroundColor: Colors.grey[200],
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              onSelected: (bool selected) {
                setState(() {
                  selectedCategory = selected ? category : ''; 
                });
              },
            );
          }).toList(),
        ),
      ),
    ],
  );
}


  Map<String, Map<String, dynamic>?> subtaskReminders = {};

  bool isReminderOn = false;
  List<Map<String, dynamic>> reminderOptions = [
    {"label": "1 day before", "duration": Duration(days: 1)},
    {"label": "3 hours before", "duration": Duration(hours: 3)},
    {"label": "1 hour before", "duration": Duration(hours: 1)},
    {"label": "30 minutes before", "duration": Duration(minutes: 30)},
    {"label": "10 minutes before", "duration": Duration(minutes: 10)},
    {"label": "Custom Time", "duration": null},
  ];
  Map<String, dynamic>? selectedReminderOption;
  DateTime? customReminderDateTime;
  void _pickSubtaskReminderTime(String subtask) async {
    bool isReminderOn = subtaskReminders[subtask] != null;
    Map<String, dynamic>? selectedOption = subtaskReminders[subtask];

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            // Filter options to prevent duplicate "Custom Time"
            List<Map<String, dynamic>> filteredOptions = reminderOptions
                .where((option) => option['label'] != "Custom Time")
                .toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              backgroundColor: lightGray,
              title: Row(
                children: [
                  Icon(Icons.notifications, color: mediumBlue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Set Reminder for "$subtask"',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: darkGray,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Toggle switch for reminder On/Off
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Reminder On/Off",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: darkGray,
                          ),
                        ),
                        Switch(
                          value: isReminderOn,
                          onChanged: (value) {
                            setState(() {
                              isReminderOn = value;
                              if (!isReminderOn) {
                                selectedOption =
                                    null; // Clear reminder settings
                              }
                            });
                          },
                          activeColor: mediumBlue,
                          activeTrackColor: lightBlue,
                          inactiveThumbColor: Colors.grey,
                          inactiveTrackColor: Colors.grey[350],
                        ),
                      ],
                    ),
                    // Show predefined options if reminder is on
                    if (isReminderOn)
                      ...filteredOptions.map((option) {
                        bool isSelected = selectedOption != null &&
                            selectedOption?['duration'] == option['duration'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedOption = {
                                'duration': option['duration'],
                                'customDateTime': null,
                              };
                            });
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 8),
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? mediumBlue.withOpacity(0.2)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, color: mediumBlue),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    option['label'],
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: darkGray,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    // قسم التايم يعامل يشكل منفصب
                    if (isReminderOn)
                      GestureDetector(
                        onTap: () async {
                          final customTime =
                              await _pickCustomSubtaskReminderTime(subtask);
                          if (customTime != null) {
                            setState(() {
                              selectedOption = {
                                'duration': null,
                                'customDateTime': customTime,
                              };
                            });
                          }
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: selectedOption?['customDateTime'] != null
                                ? mediumBlue.withOpacity(0.2)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: mediumBlue),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Custom Time",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: darkGray,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      subtaskReminders[subtask] =
                          isReminderOn ? selectedOption : null;
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: mediumBlue,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Future<void> _updateTaskTitleInFirestore(Map<String, dynamic> msgData) async {
  try {
    final timestamp = msgData['timestamp'];

    // هنا نحدث اسم التايل عشان نسمح بالايديت
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('ChatBot')
        .where('timestamp', isEqualTo: timestamp)
        .get();

    if (snapshot.docs.isNotEmpty) {
      // نجعل الاسم pulled 
      for (var doc in snapshot.docs) {
        await doc.reference.update({
          'title': 'pulled', 
        });
      }
      print("Task title updated successfully.");
    } else {
      print("No task found with the provided timestamp.");
    }
  } catch (e) {
    print("Error updating task in Firestore: $e");
  }
}
     String? _currentTaskTimestamp ;

Widget buildTaskInputSection(Map<String, dynamic> msgData) {
    final currentTaskTimestamp = msgData['timestamp'].toString();
      if ( _currentTaskTimestamp != msgData['timestamp'].toString() ) {
  _TaskDataInitialized = false; }

  if (msgData["title"] !='pulled') {

  // Initialize task data
  if (msgData["title"] != null) {
    taskTitleController.text = msgData["title"];
  }
  if (msgData["date"] != null) {
    taskselectedDate = DateTime.tryParse(msgData["date"]);
  }
  if (msgData["time"] != null) {
    final timeParts = msgData["time"].split(":");
    if (timeParts.length == 2) {
      selectedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }
  }
  if (msgData['subtasks'] != null) {
  subtasks = List<String>.from(msgData['subtasks'].take(10)); // فقط 10 subtasks
}
  if (msgData['note'] != null) {
  taskNoteController.text = msgData["note"];
}
  //_TaskDataInitialized = true; 
  _currentTaskTimestamp = currentTaskTimestamp;
  _updateTaskTitleInFirestore(msgData);

  // currentTaskTimestamp = msgData['timestamp'].toString();  // Track the timestamp for comparison
}
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 📝 Task Name
      const Text("📝 Task Name:", style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      TextField(
        controller: taskTitleController,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Type task title',
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: true,
          fillColor: Colors.white.withOpacity(0.85),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          setState(() {
           // تعديل i will take user input for task title and allow him/her to edit it
            // taskTitleController.text = value;
            
            taskTitleController.selection = TextSelection.fromPosition(
              TextPosition(offset: value.length),
            );
          });
        },
      ),
      const SizedBox(height: 16),

      // Date & Time الوقت والتاريخ
      const Text("📅 Date & ⏰ Time:", style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Row(
        children: [
          // Date Picker اختيار التاريخ
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C678E),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () async {
                DateTime? date = await showDatePicker(
                  context: context,
                  initialDate: taskselectedDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() {
                    taskselectedDate = date; 
                  });
                }
              },
              child: Text(
                taskselectedDate == null
                    ? '📅 Pick Date'
                    : '📅 ${DateFormat('yyyy-MM-dd').format(taskselectedDate!)}',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Time Picker اختيار الوقت
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C678E),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () async {
                TimeOfDay? time = await showTimePicker(
                  context: context,
                  initialTime: selectedTime ?? TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() {
                    selectedTime = time; 
                  });
                }
              },
              child: Text(
                selectedTime == null
                    ? '⏰ Pick Time'
                    : '⏰ ${selectedTime!.format(context)}',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ),

const SizedBox(height: 3),
TextButton.icon(
      onPressed: () {
        setState(() {
          showOptionalFields = !showOptionalFields;
          
        });
      },
      icon: Icon(
        showOptionalFields ? Icons.remove_circle_outline : Icons.add_circle_outline,
        color: const Color(0xFF2C678E),
      ),
      label: Text(
        showOptionalFields ? "Hide Optional Fields" : "Add Optional Fields",
        style: const TextStyle(
          color: Color(0xFF2C678E),
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    if (showOptionalFields) ...[
      
      const SizedBox(height: 6),

      // Subtasks قسم البتاسكس
      const Text("📌 Subtasks:", style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 0),
    _buildSubtaskSection(),
      const SizedBox(height: 16),
       _buildCategorySection(),
       const SizedBox(height: 6),
    //  Priority
    Row(
  children: [
    Icon(Icons.flag, color: priorityIconColor),
    const SizedBox(width: 8), 
    const Text(
      "Priority:",
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
  ],
),
    const SizedBox(height: 4),
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _priorityFlag('Urgent', Colors.red),
        _priorityFlag('High', Colors.orange),
        _priorityFlag('Medium', Colors.blue),
        _priorityFlag('Low', Colors.grey),
      ],
    ),
    const SizedBox(height: 12),
    _buildReminderSection(),
    const SizedBox(height: 12),
      //  Note الملاحظات
     const Text("🗒️ Note:", style: TextStyle(fontWeight: FontWeight.bold)),
Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: TextField(
          controller: taskNoteController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add a note',
            filled: true,
            fillColor: Colors.white.withOpacity(0.8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (newValue) {
            setState(() {
        
              taskNoteController.text = newValue;
            });
          },
        ),
      ), ],
    const SizedBox(height: 6),

 // Add Button
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    const SizedBox(width: 2),

    // Add Button للحفظ
    ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF79A3B7),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
onPressed: () async {
  if (taskTitleController.text.trim().isEmpty) {
    _showTopNotification("Please enter a task name ✏️");
    return;
  }

  if (taskselectedDate == null || selectedTime == null) {
    _showTopNotification("Please select both a date and time 📅⏰");
    return;
  }

  final DateTime taskDateTime = DateTime(
    taskselectedDate!.year,
    taskselectedDate!.month,
    taskselectedDate!.day,
    selectedTime!.hour,
    selectedTime!.minute,
  );

  try {
    User? currentUser = await _getCurrentUser();
    if (currentUser == null) {
      _showTopNotification("User not logged in 🔒");
      return;
    }
QuerySnapshot existingTasksSnapshot = await FirebaseFirestore.instance
          .collection('Task')
          .where('title', isEqualTo: taskTitleController.text.trim())
          .where('scheduledDate', isEqualTo: Timestamp.fromDate(taskDateTime))
          .where('userID', isEqualTo: currentUser.uid) // Optional: check for the user ID
          .get();

      if (existingTasksSnapshot.docs.isNotEmpty) {
        // If task already exists with same title, date, and time امنعها من الحفظ
        _showTopNotification("Task already exists with this title, date, and time ⚠️");
        return;
      }

    // Create new Task document
    DocumentReference taskRef = FirebaseFirestore.instance.collection('Task').doc();
    String taskId = taskRef.id;

    await taskRef.set({
      'completionStatus': 0,
      'scheduledDate': Timestamp.fromDate(taskDateTime),
      'note': taskNoteController.text.trim(),
      'priority': _getPriorityValue(),
      'reminder': null,
      'timer': '',
      'title': taskTitleController.text.trim(),
      'userID': currentUser.uid,
      'category': selectedCategory,
    });

    //Save subtasks
    for (String subtask in subtasks) {
      if (subtask.trim().isEmpty) continue;

      DocumentReference subtaskRef =
          FirebaseFirestore.instance.collection('SubTask').doc();

      await subtaskRef.set({
        'completionStatus': 0,
        'taskID': taskRef.id,
        'timer': '',
        'title': subtask.trim(),
        'reminder': null,
      });
    }

   // TASK SAVED SUCCESSFULLY

List<String> missingHints = [];
String finalHint = "";


if (_getPriorityValue() == 0) {
  missingHints.add("⚡ Try setting a **priority** next time to stay on track with what’s urgent!");
} else if (taskNoteController.text.trim().isEmpty) {
  missingHints.add("📝 A short **note** can help your future self remember the details easily.");
} else if (selectedReminderOption == null && customReminderDateTime == null) {
  missingHints.add("⏰ Adding a **reminder** is super helpful — especially when things slip your mind!");
} else {
  missingHints.add("🎯 You're all set! Great job organizing your task! 💪");
}

String successMessage = "✅ Task **\"${taskTitleController.text.trim()}\"** has been added successfully! 🎉\n"
    "You can find it anytime in your **Tasks Page** or the **Calendar** 📅.";

String finalMessage = "$successMessage\n\n💡 **Hint:**\n${missingHints.first}";

await FirebaseFirestore.instance.collection("ChatBot").add({
  "userID": currentUser.uid,
  "response": finalMessage,
  "timestamp": Timestamp.now(),
});


_showTopNotification("Task added successfully! ✅");



  } catch (e) {
     // TASK SAVED SUCCESSFULLY في الحالة الأخرى
    _showTopNotification("Failed to save task 😢: $e");
  }
},

      child: const Text(
        '                      Save                       ',
        style: TextStyle(color: Colors.white),
      ),
    ),
  ],
),
    
  ],
); }
  
  Future<DateTime?> _pickCustomSubtaskReminderTime(String subtask) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: selectedDateforSubtask,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: darkBlue,
              onPrimary: Color(0xFFF5F7F8),
              surface: Color(0xFFF5F7F8),
              onSurface: darkGray,
              secondary: lightBlue,
            ),
            dialogBackgroundColor: Color(0xFFF5F7F8),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: darkBlue,
                onPrimary: Color(0xFFF5F7F8),
                onSurface: darkGray,
                secondary: lightBlue,
              ),
              dialogBackgroundColor: Color(0xFFF5F7F8),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final DateTime customTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        if (customTime.isAfter(DateTime.now())) {
          return customTime;
        } else {
          _showTopNotification(
              "Custom reminder time must be in the future. Please select a valid time.");
        }
      }
    }
    return null;
  }
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        _removeCopyOverlay();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text(
            'Chatbot',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 226, 231, 234),
          elevation: 0.0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
            PopupMenuButton<String>(
              color: Colors.white,
              icon: const Icon(Icons.menu, color: Color(0xFF104A73)),
              onSelected: (value) {
                if (value == 'new_session') {
                  _confirmStartNewSession();
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'new_session',
                  child: Row(
                    children: [
                      Icon(Icons.restart_alt, color: Color(0xFF545454)),
                      SizedBox(width: 10),
                      Text('Start New Session'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: const Color.fromRGBO(245, 247, 248, 1),
        body: Stack(children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/chatProfile.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AttenaBot',
                          style: TextStyle(
                            color: Color.fromRGBO(32, 35, 37, 1),
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'Always active',
                              style: TextStyle(
                                color: Color.fromRGBO(114, 119, 122, 1),
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  child: const Divider(
                    color: Colors.grey,
                    thickness: 0.2,
                  ),
                ),
                if (userID != null && userID!.startsWith('guest_'))
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE0B2),
                    ),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text:
                                "⚠️ You're in guest mode. The session won't be saved until you ",
                            style: TextStyle(
                              color: Color(0xFF6A3805),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: "register",
                            style: const TextStyle(
                              color: Color(0xFF6A3805),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => WelcomePage()),
                                );
                              },
                          ),
                          const TextSpan(
                            text: ".",
                            style: TextStyle(
                              color: Color(0xFF6A3805),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection("ChatBot")
                        .where("userID", isEqualTo: userID ?? "guest_user")
                        .orderBy("timestamp", descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.active) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients &&
                              snapshot.hasData &&
                              snapshot.data!.docs.isNotEmpty &&
                              isFirstLoad) {
                            _scrollController.jumpTo(
                                _scrollController.position.maxScrollExtent);
                            isFirstLoad = false;
                          } else if (_scrollController.hasClients &&
                              snapshot.hasData &&
                              snapshot.data!.docs.isNotEmpty) {
                            _scrollToBottom();
                          }
                        });
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var messages = snapshot.data!.docs;
                      List<Widget> messageWidgets = [];
                      if (messages.isEmpty) {
                        return SingleChildScrollView(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Container(
                              width: 110,
                              height: 110,
                              child: Image.asset(
                                'assets/images/welcomeChatbot.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Hi there! How can I assist you today?",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color.fromRGBO(32, 35, 37, 1),
                              ),
                            ),
                            const SizedBox(height: 20),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 6,
                                crossAxisSpacing: 8,
                                childAspectRatio: 1.4,
                              ),
                              itemCount: suggestedQuestions.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {
                                    _sendMessage(
                                        suggestedQuestions[index]['text']);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: suggestedQuestions[index]['color'],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          suggestedQuestions[index]['image'],
                                          width: 40,
                                          height: 40,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          suggestedQuestions[index]['text'],
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ));
                      }

                      for (var msg in messages) {
                        var msgData = msg.data() as Map<String, dynamic>;
                        String? response = msgData["response"];

                        String? actionSuggestion = msgData["actionSuggestion"];

                        Timestamp? timestamp = msgData['timestamp'];
                        DateTime? messageDate = timestamp?.toDate();
                        final actionType = msgData['actionType'] as String?;

                        if (lastMessageDate == null ||
                            messageDate?.day != lastMessageDate!.day ||
                            messageDate?.month != lastMessageDate!.month ||
                            messageDate?.year != lastMessageDate!.year) {
                          if (messageDate != null) {
                            messageWidgets.add(
                              Center(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    DateFormat('E h:mm a').format(
                                        messageDate!), // Example : Wed 8:21 AM
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );

                            lastMessageDate = messageDate;
                          }
                        }

                        lastMessageDate = messageDate;
                        if (msgData["message"] != null && msgData["message"].toString().trim().isNotEmpty) {
  var doc;
  messageWidgets.add(_buildChatBubble(
    message: msgData["message"],
    isUser: true,
    screenWidth: MediaQuery.of(context).size.width,
    doc:doc,
  ));
}


                        if (response == null || response.isEmpty) {
                          var doc;
                          messageWidgets.add(
                            _buildChatBubble(
                              message: "",
                              isUser: false,
                              isLoading: true,
                              screenWidth: MediaQuery.of(context).size.width,
                              doc:doc,
                            ),
                          );
                        } else if (isValidUtf16(response)) {
                          Widget? extraContent;

                          if (actionSuggestion == "registerNow") {
                            extraContent = GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: const Color.fromARGB(
                                          255, 255, 255, 255),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16.0),
                                      ),
                                      title: const Text(
                                        'Sign In & Explore!',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      content: const Text(
                                        'Ready to view and manage your tasks? Sign in or create an account to enjoy the full experience!',
                                      ),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              side: const BorderSide(
                                                  color: Color(0xFF79A3B7)),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                          ),
                                          child: const Text(
                                            'Cancel',
                                            style: TextStyle(
                                                color: Color(0xFF79A3B7)),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      WelcomePage()),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF79A3B7),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                          ),
                                          child: const Text(
                                            'Join Now',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C678E),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "🔐 Join Now to Manage Your Tasks",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          }
if (actionSuggestion == "addition") {
    extraContent = buildTaskInputSection(msgData);
 }
                          if (actionSuggestion == "openCalendar") {
                            extraContent = GestureDetector(
                              onTap: () {
                                _pickMultipleDatesInDialog();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C678E),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "📅 Open Calendar",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          }
                          if (actionType == "Delete Task") {
                            extraContent = handleDelete(response);
                          }

                          var doc;
                          messageWidgets.add(
                            _buildChatBubble(
                              message: response,
                              isUser: false,
                              screenWidth: MediaQuery.of(context).size.width,
                              extraContent: extraContent,
                              actionType: actionType,
                              doc: doc,
                            ),
                          );
                        } else {
                          var doc;
                          messageWidgets.add(
                            _buildChatBubble(
                              message:
                                  "⚠️ Sorry, the message contains invalid characters and can't be displayed.",
                              isUser: false,
                              screenWidth: MediaQuery.of(context).size.width,
                              doc:doc,
                            ),
                          );
                        }
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(top: 12, bottom: 12),
                        itemCount: messageWidgets.length,
                        itemBuilder: (context, index) => messageWidgets[index],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    if (_isListening) {
                                      _stopListening();
                                    } else {
                                      _startListening();
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _isListening
                                          ? Colors.redAccent
                                          : Color(0xFF545454),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      _isListening ? Icons.mic : Icons.mic_none,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF545454),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: () => _sendMessage(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showScrollButton)
            Positioned(
              bottom: 90,
              right: MediaQuery.of(context).size.width / 2 - 28,
              child: FloatingActionButton(
                onPressed: () {
                  _scrollToBottom(force: true);
                },
                child: Icon(Icons.arrow_downward,
                    size: 20, color: Colors.grey[700]),
                backgroundColor: const Color.fromARGB(255, 220, 220, 220),
                mini: true,
                shape: CircleBorder(),
              ),
            ),
        ]),
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

  void _removeCopyOverlayOnScroll() {
    if (_copyOverlay != null) {
      _removeCopyOverlay();
    }
  }

  void _showCopyButton(BuildContext context, String message, GlobalKey key) {
    _removeCopyOverlay();

    final RenderBox renderBox =
        key.currentContext?.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final Offset position = renderBox.localToGlobal(Offset.zero);

    _copyOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx + size.width - 90,
        top: position.dy - 40,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: message));
              _showTopNotification("Copied to clipboard!");
              _removeCopyOverlay();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy, size: 16, color: Colors.black54),
                  SizedBox(width: 6),
                  Text(
                    "Copy",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final overlay = Overlay.of(context, rootOverlay: true);
    if (overlay != null) {
      overlay.insert(_copyOverlay!);
    }
  }

  List<InlineSpan> _parseBoldText(String text) {
    final regex = RegExp(r'\*\* ?(.*?) ?\*\*'); // يسمح بمسافات قبل/بعد النجمتين

    final spans = <InlineSpan>[];
    int start = 0;

    try {
      for (final match in regex.allMatches(text)) {
        if (match.start > start) {
          spans.add(TextSpan(text: text.substring(start, match.start)));
        }

        spans.add(
          TextSpan(
            text: match.group(1),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );

        start = match.end;
      }

      if (start < text.length) {
        spans.add(TextSpan(text: text.substring(start)));
      }
    } catch (e) {
      print("❌ Error while parsing text: $e");
      return [TextSpan(text: "")];
    }

    return spans;
  }

  String cleanText(String input) {
    return input.replaceAll(RegExp(r'[^\u0000-\uFFFF]'), '');
  }

  void _removeCopyOverlay() {
    _copyOverlay?.remove();
    _copyOverlay = null;
  }

  OverlayEntry? _copyOverlay;

  Widget _buildChatBubble({
    required String message,
    required bool isUser,
    required double screenWidth,
    bool isLoading = false,
    Widget? extraContent,
    String? actionType,
    required DocumentSnapshot doc,
  }) {
    bool isBot = !isUser && !isLoading;
    bool isTaskList = message.contains("📝 **Task Name:");
    bool isDeletePreview = message.contains("🗑️ Here are the matching tasks:");

    if (isBot && message.contains("REMINDER_ID::")) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF6FA),
            borderRadius: BorderRadius.circular(18),
          ),
          constraints: BoxConstraints(maxWidth: screenWidth * 0.9),
          child: handleReminderChecklist(message, userID ?? "unknown"),
        ),
      );
    }

    // 🔁 Handle Delete Task separately with preview and buttons
    if (isBot && actionType == "Delete Task" && isDeletePreview) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF6FA),
            borderRadius: BorderRadius.circular(18),
          ),
          constraints: BoxConstraints(maxWidth: screenWidth * 0.9),
          child: handleDelete(message),
        ),
      );
    }

    
// handle breakdown task
if (isBot && actionType == "Breakdown Task" && (doc.data() as Map<String, dynamic>?)?['show_breakdown_form'] == true) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF6FA),
        borderRadius: BorderRadius.circular(18),
      ),
      constraints: BoxConstraints(maxWidth: screenWidth * 0.9),
      child: handleBreakdownTaskInput(
        onSubmit: (taskName, estimatedTime) async {
          await doc.reference.update({
  'userMessage': {
    'task_name': taskName,
    'estimated_time': estimatedTime,
  },
  'actionType': 'Breakdown Task',
  'show_breakdown_form': false,
  'response': 'pending_submission',
  'message': "Please break down the task '${taskName}' which will take about ${estimatedTime}.", // ✅ SMART NEW MESSAGE
});

          await Future.delayed(Duration(seconds: 1));
          print("✅ Form submitted: taskName = $taskName, estimatedTime = $estimatedTime");
        },
      ),
    ),
  );
}

if (isBot) {
  final response = (doc.data() as Map<String, dynamic>?)?['response'] ?? '';

  if (response == 'pending_submission') {
    // 🚫 Don't render anything while waiting
    return const SizedBox.shrink();
  }

  // ✅ Otherwise, show the breakdown response
  return Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7FA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(response),
    ),
  );
}


    // 🔁 Handle grouped task responses (View My Schedule)
    if (isBot && isTaskList) {
      String introText = "";
      Map<String, List<String>> tasksByDate = {};
      final lines = message.trim().split('\n');

      if (lines.isNotEmpty && lines.first.trim().startsWith("🧠")) {
        introText = lines.first.trim();
      }

      List<String> sections = message.split("📅 **Tasks for ");

      for (int s = 1; s < sections.length; s++) {
        String section = sections[s];
        if (section.trim().isEmpty) continue;

        final dateEndIndex = section.indexOf("**");
        if (dateEndIndex == -1) continue;

        String date = section.substring(0, dateEndIndex).trim();
        String rest = section.substring(dateEndIndex + 2).trim();

        List<String> tasks = rest.split("📝 **Task Name:**");

        for (int i = 1; i < tasks.length; i++) {
          String block = tasks[i].trim();
          String taskName = block.split('\n').first.trim();
          String taskDetails = block.split('\n').skip(1).join('\n').trim();

          tasksByDate.putIfAbsent(date, () => []);
          tasksByDate[date]!.add("""
$taskName
$taskDetails
""");
        }
      }

      int displayLimit = 10;

      bool showAll = showAllTasksByDate['global'] ?? false;

      List<String> allTasks = tasksByDate.values.expand((x) => x).toList();

      List<String> visibleTasks =
          showAll ? allTasks : allTasks.take(displayLimit).toList();

      List<Widget> taskWidgets = [];

      tasksByDate.forEach((date, tasks) {
        var tasksForDate =
            visibleTasks.where((task) => tasks.contains(task)).toList();

        if (tasksForDate.isEmpty) return;

        taskWidgets.addAll([
          const SizedBox(height: 18),
          Divider(color: Colors.grey.withOpacity(0.3), thickness: 0.8),
          const SizedBox(height: 10),
          SelectableText(
            "📅 Tasks for $date",
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50)),
          ),
          const SizedBox(height: 10),
        ]);

        taskWidgets.addAll(tasksForDate.map((taskBlock) {
          String taskName =
              taskBlock.split('\n')[0].replaceAll("📝 Task Name:", "").trim();
          String details = taskBlock.split('\n').skip(1).join('\n');

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F8FA),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: Tooltip(
                message: '👀 Tap to show the task details',
                preferBelow: false,
                child: ExpansionTile(
                  title: Text('$taskName'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(13),
                      child: SelectableText.rich(
  TextSpan(children: _parseBoldText(cleanDetails(details))),
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF455A64)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }).toList());
      });
      String getMotivationalMessage(String message) {
        if (message.contains("🗑️ Here are the matching tasks:")) {
          return ""; // skip motivational text for delete preview
        }
        if (message.contains("It's today!")) {
          return "🔥 It's today! Let's get things done step by step 💪 Remember: Start small, stay consistent ✨";
        } else if (message.contains("Only one task")) {
          return "🧐 Only one task for this day? That's totally fine! But maybe adding another tiny goal could boost your momentum 🚀";
        } else if (message.contains("Nice and light schedule!")) {
          return "✨ Nice and light schedule! Don't forget to celebrate every small win 🏆";
        } else if (message.contains("Looking at your whole month")) {
          return "📅 Wow! Looking at your whole month? That's a great way to plan ahead and avoid surprises 🔥";
        } else {
          return "👏 You're doing amazing organizing your tasks! Keep balancing between focus and rest 💡";
        }
      }

      taskWidgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 17),
          child: SelectableText(
            getMotivationalMessage(message),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
      );
      if (tasksByDate.values.expand((x) => x).length > displayLimit &&
          !showAll) {
        taskWidgets.add(
          Column(
            children: [
              const SizedBox(height: 9),
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      showAllTasksByDate['global'] = true;
                    });
                  },
                  child: const Text(
                    "Show more ▼",
                    style: TextStyle(
                      color: Color(0xFF2C678E),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      } else if (showAll &&
          tasksByDate.values.expand((x) => x).length > displayLimit) {
        taskWidgets.add(
          Column(
            children: [
              const SizedBox(height: 9),
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      showAllTasksByDate['global'] = false;
                    });
                  },
                  child: const Text(
                    "Show less ▲",
                    style: TextStyle(
                      color: Color(0xFF2C678E),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF6FA),
            borderRadius: BorderRadius.circular(18),
          ),
          constraints: BoxConstraints(maxWidth: screenWidth * 0.9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (introText.isNotEmpty) const SizedBox(height: 10),
              SelectableText(
                introText,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF2C3E50),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (introText.isNotEmpty) const SizedBox(height: 10),
              ...taskWidgets,
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Builder(
            builder: (messageContext) {
              final GlobalKey msgKey = GlobalKey();

              return Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onLongPress: isUser
                        ? () {
                            _showCopyButton(context, message, msgKey);
                          }
                        : null,
                    child: Container(
                      key: msgKey,
                      padding: const EdgeInsets.all(14),
                      margin: EdgeInsets.only(
                        top: 14,
                        bottom: 14,
                        left: isUser ? 8 : 1,
                        right: isUser ? 8 : 1,
                      ),
                      decoration: BoxDecoration(
                        color: isUser
                            ? const Color.fromRGBO(121, 163, 183, 1)
                            : isLoading
                                ? const Color.fromARGB(255, 145, 144, 144)
                                : const Color(0xFFC7D9E1),
                        borderRadius: BorderRadius.only(
                          topLeft: isUser
                              ? const Radius.circular(24)
                              : const Radius.circular(0),
                          topRight: const Radius.circular(24),
                          bottomLeft: const Radius.circular(24),
                          bottomRight: isUser
                              ? const Radius.circular(0)
                              : const Radius.circular(24),
                        ),
                      ),
                      constraints: BoxConstraints(
                        maxWidth: screenWidth * 0.7,
                      ),
                      child: isLoading
                          ? Lottie.asset('assets/animations/loading.json',
                              height: 30)
                          : AnimatedBuilder(
                              animation: typingMessages.containsKey(message)
                                  ? ValueNotifier(typingMessages[message])
                                  : ValueNotifier(message),
                              builder: (context, _) {
                                final textToShow =
                                    typingMessages[message] ?? message;
                                if (!isValidUtf16(textToShow)) {
                                  print("❌ Skipping invalid UTF-16 message");
                                  return const SizedBox.shrink();
                                }

                                try {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SelectableText.rich(
                                        TextSpan(
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color:
                                                Color.fromRGBO(48, 52, 55, 1),
                                          ),
                                          children: _parseBoldText(
                                              sanitizeString(textToShow)),
                                        ),
                                      ),
                                      if (extraContent != null) ...[
                                        const SizedBox(height: 10),
                                        extraContent,
                                      ],
                                    ],
                                  );
                                } catch (e) {
                                  print(
                                      "⚠️ Ignored display error in _buildChatBubble: $e");
                                  return const SizedBox.shrink();
                                }
                              },
                            ),
                    ),
                  ),
                  if (isBot && !isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.translate(
                            offset: const Offset(-2, -13),
                            child: IconButton(
                              icon: Icon(Icons.copy,
                                  size: 18, color: Colors.grey[700]),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: message));
                                _showTopNotification("Copied to clipboard!");
                              },
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(-13, -13),
                            child: StatefulBuilder(
                              builder: (context, setIconState) {
                                return IconButton(
                                  icon: Icon(
                                    messageIsPlaying[message] ?? false
                                        ? Icons.stop
                                        : Icons.volume_up,
                                    size: 18,
                                    color: Colors.grey[700],
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () async {
                                    bool isCurrentlyPlaying =
                                        messageIsPlaying[message] ?? false;
                                    if (isCurrentlyPlaying) {
                                      await flutterTts.stop();
                                      messageIsPlaying[message] = false;
                                    } else {
                                      await flutterTts.speak(message);
                                      messageIsPlaying[message] = true;
                                      flutterTts.setCompletionHandler(() {
                                        setState(() {
                                          messageIsPlaying[message] = false;
                                        });
                                      });
                                    }
                                    setState(() {});
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _simulateTyping(String message) async {
    if (!isValidUtf16(message)) {
      print("⚠️ Skipping malformed message due to invalid UTF-16.");
      return;
    }

    String displayed = "";
    for (int i = 0; i < message.length; i++) {
      displayed += message[i];
      try {
        if (!mounted) return;
        typingMessages[message] = displayed;
        setState(() {});
      } catch (e) {
        print("⚠️ Ignored UTF-16 display error: $e");
        return;
      }
      await Future.delayed(const Duration(milliseconds: 30));
    }
  }

  Set<String> selectedTasks = {};
  bool selectAll = false;

  Widget handleDelete(String response) {
    List<Widget> widgets = [];

    List<String> taskSections = response.split("\ud83d\udcdd **Task Name:");

    final hasTasks = taskSections.length > 1 &&
        taskSections.skip(1).any((section) => section.trim().isNotEmpty);

    List<String> allTaskIds = [];
    List<String> taskNames = [];
    List<String> taskDetailsList = [];

    if (hasTasks) {
      widgets.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            "🗑️ Here are the matching tasks:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
      );

      for (int i = 1; i < taskSections.length; i++) {
        String block = taskSections[i].trim();
        if (block.isEmpty) continue;

        final lines = block.split('\n');
        String taskName = lines.first.trim().replaceAll("**", "");
        String taskDetails = lines
            .skip(1)
            .takeWhile((line) => !line.contains("DELETE_ID::"))
            .join('\n')
            .trim();

        final deleteMatch = RegExp(r'DELETE_ID::(.+?)$').firstMatch(block);
        String? taskId = deleteMatch?.group(1);

        if (taskId != null) {
          allTaskIds.add(taskId);
          taskNames.add(taskName);
          taskDetailsList.add(taskDetails);
        }
      }

      widgets.add(
        StatefulBuilder(
          builder: (context, setState) {
            bool isSingleTask = allTaskIds.length == 1;
            bool selectAllChecked = selectedTasks.length == allTaskIds.length &&
                allTaskIds.isNotEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < allTaskIds.length; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8FA),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2)),
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        childrenPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        title: Row(
                          children: [
                            if (!isSingleTask)
                              Checkbox(
                                value: selectedTasks.contains(allTaskIds[i]),
                                activeColor: Color(0xFF104A73),
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedTasks.add(allTaskIds[i]);
                                    } else {
                                      selectedTasks.remove(allTaskIds[i]);
                                    }
                                  });
                                },
                              ),
                            Expanded(
                              child: Text(
                                taskNames[i],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Color(0xFF2C3E50),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSingleTask)
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: Colors.white,
                                      title: const Text("Delete Task",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18)),
                                      content: const Text(
                                          "Are you sure you want to delete this task?\nThis action cannot be undone."),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      actions: [
                                        OutlinedButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(false),
                                          child: const Text("Cancel"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(true),
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red),
                                          child: const Text("Delete"),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await deleteTaskById(allTaskIds[i]);
                                    _showTopNotification("Task deleted ✅");
                                  }
                                },
                                icon: const Icon(Icons.delete,
                                    color: Colors.white),
                                label: const Text(
                                  "Delete",
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFEF5350),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                ),
                              ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(13),
                            child: SelectableText.rich(
                              TextSpan(
                                  children: _parseBoldText(taskDetailsList[i])),
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                  fontSize: 14, color: Color(0xFF455A64)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                if (!isSingleTask && allTaskIds.length > 1)
                  CheckboxListTile(
                    title: const Text("Select All",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    value: selectAllChecked,
                    activeColor: Color(0xFF104A73),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedTasks = allTaskIds.toSet();
                        } else {
                          selectedTasks.clear();
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                const SizedBox(height: 10),
                if (!isSingleTask)
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: selectedTasks.isNotEmpty
                          ? () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  title: const Text("Delete Selected Tasks",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18)),
                                  content: Text(
                                      "Are you sure you want to delete ${selectedTasks.length} selected task(s)?\nThis action cannot be undone."),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  actions: [
                                    OutlinedButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text(
                                        "Cancel",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red),
                                      child: const Text(
                                        "Delete",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                for (var id in selectedTasks) {
                                  await deleteTaskById(id);
                                }
                                _showTopNotification(
                                    "${selectedTasks.length} task(s) deleted ✅");
                              }
                            }
                          : null,
                      icon: const Icon(Icons.delete_forever),
                      label: Text("Delete Selected (${selectedTasks.length})"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFEF5350),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  
Widget handleBreakdownTaskInput({
  required Function(String taskName, String estimatedTime) onSubmit,
}) {
  final TextEditingController taskController = TextEditingController();
  final TextEditingController timeController = TextEditingController();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Let's break down a task!",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),
      const SizedBox(height: 12),

      TextField(
        controller: taskController,
        decoration: const InputDecoration(
          labelText: 'What do you want to break down?',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),

      TextField(
        controller: timeController,
        decoration: const InputDecoration(
          labelText: 'Estimated time (e.g. 2 hours)',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),

      Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          onPressed: () {
            final taskName = taskController.text.trim();
            final estimatedTime = timeController.text.trim();

            if (taskName.isNotEmpty && estimatedTime.isNotEmpty) {
              onSubmit(taskName, estimatedTime);
              taskController.clear();
              timeController.clear();
            }
          },
          child: const Text("Break Down"),
        ),
      ),
    ],
  );
}

  Future<void> deleteTaskById(String taskId) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final taskDoc = await firestore.collection("Task").doc(taskId).get();

      if (!taskDoc.exists) {
        print("⚠️ Task not found: $taskId");
        return;
      }

      final taskData = taskDoc.data()!;
      final userId = taskData["userID"];

      await NotificationHandler.cancelNotification(taskId);

      final subtaskQuery = await firestore
          .collection("SubTask")
          .where("taskID", isEqualTo: taskId)
          .get();

      for (var subDoc in subtaskQuery.docs) {
        await NotificationHandler.cancelNotification(
            subDoc.id); // cancel each subtask
        await firestore.collection("SubTask").doc(subDoc.id).delete();
      }

      await firestore.collection("Task").doc(taskId).delete();

      print("✅ Deleted task $taskId and its subtasks");
    } catch (e) {
      print("❌ Error deleting task: $e");
    }
  }

  Widget handleReminderChecklist(String response, String userId) {
    List<String> sections = response.split(RegExp(r'📝 \*\*Task Name:\*\*'));
    List<String> taskIds = [];
    List<String> taskTitles = [];
    List<String> taskDetailsList = [];
    List<String> reminderTimes = [];
    Set<String> selectedIds = {};

    for (int i = 1; i < sections.length; i++) {
      final block = sections[i].trim();
      final lines = block.split('\n');

      final idMatch = RegExp(r'REMINDER_ID::(.+?)::(.+?)$').firstMatch(block);
      if (idMatch != null) {
        String taskId = idMatch.group(1)!;
        String reminderTime = idMatch.group(2)!;
        String taskTitle = lines.first.replaceAll("**", "").trim();
        String taskDetails = lines
            .skip(1)
            .takeWhile((line) => !line.contains("REMINDER_ID::"))
            .join('\n')
            .trim();

        taskIds.add(taskId);
        taskTitles.add(taskTitle);
        taskDetailsList.add(taskDetails);
        reminderTimes.add(reminderTime);
      }
    }

    return StatefulBuilder(builder: (context, setState) {
      bool allSelected =
          selectedIds.length == taskIds.length && taskIds.isNotEmpty;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              "🔔 Please choose the task you want to set the reminder for:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          for (int i = 0; i < taskIds.length; i++)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F8FA),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2)),
                ],
              ),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  childrenPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  title: Row(
                    children: [
                      Checkbox(
                        value: selectedIds.contains(taskIds[i]),
                        activeColor: const Color(0xFF104A73),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedIds.add(taskIds[i]);
                            } else {
                              selectedIds.remove(taskIds[i]);
                            }
                          });
                        },
                      ),
                      Expanded(
                        child: Text(taskTitles[i],
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Color(0xFF2C3E50))),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(13),
                      child: SelectableText(taskDetailsList[i],
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF455A64))),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          if (taskIds.length > 1)
            CheckboxListTile(
              title: const Text("Select All",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              value: allSelected,
              activeColor: const Color(0xFF104A73),
              onChanged: (select) {
                setState(() {
                  selectedIds = select! ? taskIds.toSet() : {};
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
          const SizedBox(height: 10),
          Center(
            child: ElevatedButton.icon(
              onPressed: selectedIds.isNotEmpty
                  ? () async {
                      final now = DateTime.now();

                      for (int i = 0; i < taskIds.length; i++) {
                        if (!selectedIds.contains(taskIds[i])) continue;

                        final reminderTime = DateTime.parse(reminderTimes[i]);

                        if (reminderTime.isAfter(now)) {
                          final taskId = taskIds[i];
                          final title = taskTitles[i];

                          await FirebaseFirestore.instance
                              .collection("Task")
                              .doc(taskId)
                              .update({
                            "reminder": Timestamp.fromDate(reminderTime),
                          });

                          await NotificationHandler.scheduleReminder(
                            taskId: taskId,
                            title: title,
                            reminderTime: reminderTime,
                          );
                        }
                      }
                      _showTopNotification("✅ Reminder(s) set successfully!");
                    }
                  : null,
              icon: const Icon(Icons.alarm),
              label: Text("Set Reminder (${selectedIds.length})"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF104A73),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ],
      );
    });
  }
String cleanDetails(String details) {
  final lines = details.split('\n');
  final filteredLines = lines.where((line) =>
      !line.contains("🔥 It's today!") &&
      !line.contains("Start small, stay consistent") &&
      !line.contains("🧐 Only one task") &&
      !line.contains("✨ Nice and light schedule!") &&
      !line.contains("📅 Wow! Looking at your whole month?") &&
      !line.contains("👏 You're doing amazing organizing") &&
      !line.contains("Don't forget to celebrate") &&
      !line.contains("Keep balancing between focus and rest")
  ).toList();
  return filteredLines.join('\n');
}

  @override
  void dispose() {
    isInChatbotPage = false;
    WidgetsBinding.instance.removeObserver(this);
    flutterTts.stop();
    _removeCopyOverlay();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
