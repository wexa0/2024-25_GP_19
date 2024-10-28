import 'package:flutter/material.dart';
import 'package:flutter_application/models/BottomNavigationBar.dart';

class ChatbotpageWidget extends StatelessWidget {
  const ChatbotpageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the screen width
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
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
      ),
      backgroundColor: const Color.fromRGBO(245, 247, 248, 1),

      // استخدام Stack لعرض محتوى الصفحة مع طبقة "Coming Soon"
      body: Stack(
        children: [
          // محتوى الصفحة الأصلي
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/chatProfile.png', // Use your PNG asset here
                          width: 30,
                          height: 30,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      color: const Color(0xFFF5F7F8), // Background color F5F7F8
                      padding: const EdgeInsets.all(8.0), // Optional: Add padding for better spacing
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'AtenaBot',
                            style: TextStyle(
                              color: Color.fromRGBO(32, 35, 37, 1),
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Always active',
                            style: TextStyle(
                              color: Color.fromRGBO(114, 119, 122, 1),
                              fontFamily: 'DM Sans',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Message Time (Centered)
                Center(
                  child: const Text(
                    'Wed 8:21 AM',
                    style: TextStyle(
                      color: Color.fromRGBO(114, 119, 122, 1),
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Message Bubble (AtenaBot's message with profile picture)
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/chatProfile.png', // Use your PNG asset here
                          width: 30,
                          height: 30,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC7D9E1), // The specified color C7D9E1
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(0), // Square top left
                            topRight: Radius.circular(24), // Rounded top right
                            bottomLeft: Radius.circular(24), // Rounded bottom left
                            bottomRight: Radius.circular(24), // Rounded bottom right
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: BoxConstraints(
                            maxWidth: screenWidth * 0.7), // Responsive width
                        child: const Text(
                          'Hello, I’m Atena! 👋 I’m your personal ADHD time management assistant. How can I help you?',
                          style: TextStyle(
                            color: Color.fromRGBO(48, 52, 55, 1),
                            fontFamily: 'DM Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Task Message Bubble (Show me today’s tasks) - Aligned to the right
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(121, 163, 183, 1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24), // Square top left
                        topRight: Radius.circular(24), // Rounded top right
                        bottomLeft: Radius.circular(24), // Rounded bottom left
                        bottomRight: Radius.circular(0), // Rounded bottom right
                      ),
                    ),
                    constraints: BoxConstraints(
                        maxWidth: screenWidth * 0.7), // Responsive width
                    child: const Text(
                      'Show me today’s tasks',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'DM Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // User Message (User's message with profile picture)
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/chatProfile.png', // Use your PNG asset here
                          width: 30,
                          height: 30,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC7D9E1), // The specified color C7D9E1
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(0), // Square top left
                            topRight: Radius.circular(24), // Rounded top right
                            bottomLeft: Radius.circular(24), // Rounded bottom left
                            bottomRight: Radius.circular(24), // Rounded bottom right
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: BoxConstraints(
                            maxWidth: screenWidth * 0.7), // Responsive width
                        child: const Text(
                          'You only have “going to gym” task at 5pm',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Color.fromRGBO(48, 52, 55, 1),
                            fontFamily: 'DM Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(), // Pushes the messages to the top
                // Input Area (This will not overlap with the bottom navigation bar)
                Container(
                  padding: const EdgeInsets.only(bottom: 16.0), // Add padding to avoid overlap
                  child: Row(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF545454), // Background color for the menu icon
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: () {
                            // Handle menu button press
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
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
                          child: const TextField(
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF545454), // Background color for the send icon
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: () {
                            // Handle send button press
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // طبقة "Coming Soon"
          Positioned.fill(
            child: Container(
              color: Colors.grey.withOpacity(0.8), // خلفية شفافة
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.hourglass_empty, size: 80, color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'Coming Soon',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'This feature is not available yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
