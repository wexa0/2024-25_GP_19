import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ChatbotpageWidget(),
    );
  }
}

class ChatbotpageWidget extends StatelessWidget {
  const ChatbotpageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the screen width
    double screenWidth = MediaQuery.of(context).size.width;

    // Figma Flutter Generator ChatbotpageWidget - FRAME
    return Scaffold(
      backgroundColor: const Color.fromRGBO(245, 247, 248, 1),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(),
                  child: const Icon(Icons.account_circle, size: 44, color: Color.fromRGBO(242, 248, 255, 1)),
                ),
                const SizedBox(width: 12),
                Column(
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
              ],
            ),
            const SizedBox(height: 8),
            // Message Time
            const Text(
              'Wed 8:21 AM',
              style: TextStyle(
                color: Color.fromRGBO(114, 119, 122, 1),
                fontFamily: 'DM Sans',
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            // Message Bubble (AtenaBot's message)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFC7D9E1), // The specified color C7D9E1
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: BoxConstraints(maxWidth: screenWidth * 0.7), // Responsive width
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
            const SizedBox(height: 12),
            // Task Message Bubble (Show me today’s tasks)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(121, 163, 183, 1),
                  borderRadius: BorderRadius.circular(24),
                ),
                constraints: BoxConstraints(maxWidth: screenWidth * 0.7), // Responsive width
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
            // User Message (User's message)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFC7D9E1), // The specified color C7D9E1
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: BoxConstraints(maxWidth: screenWidth * 0.7), // Responsive width
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
            const Spacer(), // Pushes the messages to the top
            // Input Area
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF545454), // Background color for the menu icon
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
                      // Handle menu button press
                    },
                  ),
                ),
                const SizedBox(width: 8), // Space between the menu icon and the text field
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
                const SizedBox(width: 8), // Space between the text field and the send icon
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF545454), // Background color for the send icon
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
          ],
        ),
      ),
    );
  }
}
