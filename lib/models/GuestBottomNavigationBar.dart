import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter_application/pages/chatbot_page.dart';
import 'package:flutter_application/pages/guest_home.dart';
import 'package:flutter_application/pages/guest_profile_page.dart';
import 'package:flutter_application/pages/task_page.dart';
import 'package:flutter_application/pages/progress_page.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  // List of pages for navigation
  final List<Widget> _pages = [
    GuestHomePage(), // Home page widget
    TaskPage(), // Task page widget
    Chatbotpage(),
    ProgressPage(), // Progress page widget
    GuestProfilePage(), // Profile page widget
  ];

  // Update the index when a user taps a BottomNavigationBarItem
  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, // Track the current index
        onTap: onTabTapped, // Handle tapping on a navigation item
        type: BottomNavigationBarType.fixed, // Fixed navigation bar
        selectedItemColor: Color(0xFF104A73), // Change this to match your theme
        unselectedItemColor: Colors.grey, // Unselected icon color
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task),
            label: 'Task',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
