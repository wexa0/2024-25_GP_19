import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/models/BottomNavigationBar.dart';
import 'package:flutter_application/models/GuestBottomNavigationBar.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'dart:async';



class ChatbotpageWidget extends StatefulWidget {
  const ChatbotpageWidget({super.key});

  @override
  _ChatbotpageWidgetState createState() => _ChatbotpageWidgetState();
}
  bool isSpeaking = false;
  String? currentlySpokenText;

class _ChatbotpageWidgetState extends State<ChatbotpageWidget> {

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
  String _text = '';
Map<String, bool> messageIsPlaying = {};
  DateTime? lastMessageDate;
Map<String, String> typingMessages = {};


  final List<Map<String, dynamic>> suggestedQuestions = [
    {"image": "assets/images/task.png", "text": "What do I have today?", "color": Color(0xFF2C678E)},
    {"image": "assets/images/productivity.png", "text": "Give me a productivity tip!", "color": Color(0xFF78A1BA)},
    {"image": "assets/images/focus.png", "text": "How can I stay focused?", "color": Color(0xFF78A1BA)},
    {"image": "assets/images/breakdown.png", "text": "Help me to break down a big task?", "color": Color(0xFF2C678E)},
  ];



@override
void initState() {
  super.initState();
  _speech = stt.SpeechToText();
    _fetchUserID().then((_) {
    checkSessionStatus(); 
  });
  _fetchUserID();
  _scrollController.addListener(_scrollListener);
 WidgetsBinding.instance.addPostFrameCallback((_) {
  Future.delayed(const Duration(milliseconds: 300), () {
    _scrollToBottom(force: true);
  });
});

   
  setupTts();
}

Future<void> checkSessionStatus() async {

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
    DateTime firstTime = (firstMsgSnap.docs.first.data() as Map<String, dynamic>)['timestamp'].toDate();

if (currentSessionStart == null) {
  currentSessionStart = firstTime;
} else {
  print("🔄 Using already renewed session: $currentSessionStart");
}

  Duration sinceStart = DateTime.now().difference(currentSessionStart!);
  print("⏳ Time since session start: $sinceStart");


    if (sinceStart.inMinutes >= 5 ) {


      await _showSessionExpiredDialog();
      return;
    
  

      
    }
  }
}


 String prevText = ""; 


void setupTts() async {
  await flutterTts.setLanguage("en-US");
  await flutterTts.setSpeechRate(0.5);
  await flutterTts.setPitch(1.1);
  await flutterTts.setVolume(0.85);
  await flutterTts.setVoice({
    "name": "en-us-x-sfg#female_2",
    "locale": "en-US"
  });

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
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      userID = user?.uid;
    });
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
  if (_scrollController.offset < _scrollController.position.maxScrollExtent - 50) {
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
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
              child: Image.asset("assets/images/session_bot.png", fit: BoxFit.contain),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _sessionButton(
                  text: "Continue Previous Session",
                  
                onPressed: () async {
  DateTime now = DateTime.now();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('sessionStart', now.toIso8601String());

  setState(() {
    currentSessionStart = now;
    print("✅ Session renewed at: $currentSessionStart");
  });
  Navigator.of(context).pop();
  _showTopNotification("Continuing previous session");
},

                  
                ),
                 const SizedBox(width: 1),
                _sessionButton(
                  text: "    Start new session    ",
                  onPressed: () async {
                    // حذف المحادثة القديمة
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

Widget _sessionButton({required String text, required VoidCallback onPressed}) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor:  Color(0xFF79A3B7),
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
  _simulateTyping(data['response']);
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
    await prefs.setString('sessionStart', currentSessionStart!.toIso8601String());

    _showTopNotification("Started a new session");
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
  behavior: HitTestBehavior.translucent,
  onTap: () {
    _removeCopyOverlay(); // يمسح الزر إذا ضغطت برا
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
      
      body: Stack(
        children: [
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
              if (_scrollController.hasClients && snapshot.hasData && snapshot.data!.docs.isNotEmpty && isFirstLoad ) {
                _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                isFirstLoad = false;

              } else if(_scrollController.hasClients && snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 9,
            crossAxisSpacing: 9,
            childAspectRatio: 1.8,
          ),
          itemCount: suggestedQuestions.length,
          itemBuilder: (context, index) {
            return GestureDetector(
            onTap: () {
  _sendMessage(suggestedQuestions[index]['text']);
},

              child: Container(
                decoration: BoxDecoration(
                  color: suggestedQuestions[index]['color'],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      suggestedQuestions[index]['image'],
                      width: 60,
                      height: 60,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      suggestedQuestions[index]['text'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
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
    )
    );
}




      for (var msg in messages) {
       var msgData = msg.data() as Map<String, dynamic>;

  Timestamp? timestamp = msgData['timestamp'];
  DateTime? messageDate = timestamp?.toDate();


  if (lastMessageDate == null ||
      messageDate?.day != lastMessageDate!.day ||
      messageDate?.month != lastMessageDate!.month ||
      messageDate?.year != lastMessageDate!.year) {
    
   if (messageDate != null) {
  messageWidgets.add(
    Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          DateFormat('E h:mm a').format(messageDate!), // Example : Wed 8:21 AM
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
        messageWidgets.add(_buildChatBubble(
          message: msgData["message"] ?? "",

          isUser: true,
           screenWidth: MediaQuery.of(context).size.width,
        ));

        String? response = msgData["response"];

    if (response == null || response.isEmpty) {
    messageWidgets.add(
      _buildChatBubble(
        message: "",
        isUser: false,
        isLoading: true,
        screenWidth: MediaQuery.of(context).size.width,
      ),
    );
  } else {
    messageWidgets.add(
      _buildChatBubble(
        message: response,
        isUser: false,
        screenWidth: MediaQuery.of(context).size.width,
      ),
    );
  }
}



return ListView.builder(
  controller: _scrollController,
  padding: const EdgeInsets.all(16),
  itemCount: messageWidgets.length,
  itemBuilder: (context, index) => messageWidgets[index],
);


    },
  ),
  
),

   
Padding(
  padding: const EdgeInsets.only(bottom: 16.0),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      color: _isListening ? Colors.redAccent : Color(0xFF545454),
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
      child: Icon(Icons.arrow_downward, size: 20, color: Colors.grey[700]), 
      backgroundColor: const Color.fromARGB(255, 220, 220, 220),
      mini: true,
      shape: CircleBorder(),
    ),
  ),

        
        ]
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

void _showCopyButton(BuildContext context, Offset position, String message) {
  _removeCopyOverlay(); 
  _copyOverlay = OverlayEntry(
    builder: (context) => Positioned(
      left: position.dx + 100,
      top: position.dy - 45,
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
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
}) {
  bool isBot = !isUser && !isLoading;

  return Align(
    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
    
    child: Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Builder(
  builder: (messageContext) {
    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        InkWell(
          onLongPress: isUser
              ? () {
                  final RenderBox box = messageContext.findRenderObject() as RenderBox;
                  final Offset position = box.localToGlobal(Offset.zero);
                  _showCopyButton(messageContext, position, message);
                }
              : null,
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isUser
                  ? const Color.fromRGBO(121, 163, 183, 1)
                  : isLoading
                      ? const Color.fromARGB(255, 145, 144, 144)
                      : const Color(0xFFC7D9E1),
              borderRadius: BorderRadius.only(
                topLeft: isUser ? const Radius.circular(24) : const Radius.circular(0),
                topRight: const Radius.circular(24),
                bottomLeft: const Radius.circular(24),
                bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(24),
              ),
            ),
            constraints: BoxConstraints(
              maxWidth: screenWidth * 0.7,
            ),
           child: isLoading
    ? Lottie.asset('assets/animations/loading.json', height: 30)
    : AnimatedBuilder(
        animation: typingMessages.containsKey(message)
            ? ValueNotifier(typingMessages[message])
            : ValueNotifier(message),
        builder: (context, _) {
          final textToShow = typingMessages[message] ?? message;
          return Text(
            textToShow,
            style: const TextStyle(
              fontSize: 16,
              color: Color.fromRGBO(48, 52, 55, 1),
            ),
            textAlign: TextAlign.start,
          );
        },
      ),

          ),
        ),

        if (isBot && !isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  offset: const Offset(0, -12),  
                  child: IconButton(
                    icon: Icon(Icons.copy, size: 18, color: Colors.grey[700]),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: message));
                      _showTopNotification("Copied to clipboard!");
                    },
                    ),
                    ),
                    
                
                Transform.translate(
                  offset: const Offset(-10, -12),
                  child: StatefulBuilder(
                    builder: (context, setIconState) {
                      
                     return IconButton(
  icon: Icon(
    messageIsPlaying[message] ?? false ? Icons.stop : Icons.volume_up,
    size: 18,
    color: Colors.grey[700],
  ),
  padding: EdgeInsets.zero,
  constraints: const BoxConstraints(),
  onPressed: () async {
    bool isCurrentlyPlaying = messageIsPlaying[message] ?? false;
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
  String displayed = "";
  for (int i = 0; i < message.length; i++) {
    displayed += message[i];
    try {
      if (!mounted) return;

      setState(() {
        typingMessages[message] = displayed;
      });
        
    } catch (_) {
    }
    await Future.delayed(const Duration(milliseconds: 30));
  }
}



@override
void dispose() {
  flutterTts.stop(); 
   _scrollController.dispose(); 
  _messageController.dispose(); 
  super.dispose();
}

}