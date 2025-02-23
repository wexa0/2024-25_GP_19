import 'package:flutter/material.dart';
import 'package:flutter_application/pages/chatbot_page.dart';
import 'package:flutter_application/pages/guest_home.dart';
import 'package:flutter_application/pages/guest_profile_page.dart';
import 'package:flutter_application/pages/progress_page.dart';
import 'package:flutter_application/pages/task_page.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

// Nav bar for Guest user.
class GuestCustomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChange;

  const GuestCustomNavigationBar({
    Key? key,
    required this.selectedIndex,
    required this.onTabChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 226, 231, 234),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      child: GNav(
        backgroundColor: const Color(0xFF79A3B7).withOpacity(0),
        color: const Color(0xFF545454),
        activeColor: const Color(0xFF104A73),
        tabBackgroundColor: const Color(0xFF79A3B7).withOpacity(0.3),
        gap: 8,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        tabBorderRadius: 15,
        selectedIndex: selectedIndex,
        iconSize: 24,
        onTabChange: (index) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) {
              switch (index) {
                case 0:
                  return GuestHomePage();
                case 1:
                  return TaskPage();
                case 2:
                  return ChatbotpageWidget();
                case 3:
                  return ProgressPage();
                case 4:
                  return GuestProfilePage();
                default:
                  return TaskPage();
              }
            }),
          );
        },
        tabs: [
          _buildGButton(Icons.home, 'Home'),
          _buildGButton(Icons.task, 'Tasks'),
          _buildGButton(Icons.sms, 'Chatbot'),
          _buildGButton(Icons.poll, 'Progress'),
          _buildGButton(Icons.settings, 'Settings'),
        ],
      ),
    );
  }

  /// Builds a GButton with responsive text.
  GButton _buildGButton(IconData icon, String text) {
    return GButton(
      icon: icon,
      text: text,
      textStyle: const TextStyle(
        fontSize: 12,
        overflow: TextOverflow.ellipsis, // Prevent text overflow
      ),
    );
  }
}
