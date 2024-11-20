import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChange;

  const BottomNavigationBarWidget({
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
        color: const Color(0xFF545454), // اللون الافتراضي للأيقونات
        activeColor: const Color(0xFF104A73), // لون الأيقونات النشطة
        tabBackgroundColor: const Color(0xFF79A3B7).withOpacity(0.3),
        gap: 8,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        tabBorderRadius: 15,
        selectedIndex: selectedIndex,
        iconSize: 24,
        onTabChange: onTabChange,
        tabs: const [
          GButton(
            icon: Icons.home,
            text: 'Home',
          ),
          GButton(
            icon: Icons.task,
            text: 'Tasks',
          ),
          GButton(
            icon: Icons.sms,
            text: 'Chatbot',
          ),
          GButton(
            icon: Icons.poll,
            text: 'Progress',
          ),
          GButton(
            icon: Icons.person,
            text: 'Profile',
          ),
        ],
      ),
    );
  }
}
