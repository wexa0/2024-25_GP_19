import 'package:flutter/material.dart';
import 'package:flutter_application/pages/guest_home.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class GuestCustomBottomNavigationBar extends StatefulWidget {
  const GuestCustomBottomNavigationBar({Key? key}) : super(key: key);

  @override
  _CustomBottomNavigationBarState createState() =>
      _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<GuestCustomBottomNavigationBar> {
  final ValueNotifier<int> _selectedIndex = ValueNotifier<int>(0);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5.0, left: 2, right: 2),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8.0,
            spreadRadius: 7.0,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25.0),
        child: BottomAppBar(
          color: const Color.fromARGB(255, 226, 231, 234),
          child: ValueListenableBuilder<int>(
            valueListenable: _selectedIndex,
            builder: (context, selectedIndex, _) {
              return GNav(
                color: const Color.fromARGB(255, 0, 0, 0),
                activeColor: const Color.fromARGB(255, 94, 129, 145),
                iconSize: 26.0,
                selectedIndex: selectedIndex,
                onTabChange: (index) {
                  _selectedIndex.value = index;
                  // Handle navigation logic based on selected index
                  switch (index) {
                    case 0:
                       Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => GuestHomePage()),
                      );
                      break;
                    case 1:
                      // Navigate to Tasks
                      break;
                    case 2:
                      // Navigate to Chatbot
                      break;
                    case 3:
                      // Navigate to Progress
                      break;
                    case 4:
                      // Navigate to ProfilePage
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => ProfilePage(),
                      //   ),
                      // );
                      break;
                  }
                },
                tabs: const [
                  GButton(icon: Icons.home, text: 'Home'),
                  GButton(icon: Icons.task, text: 'Tasks'),
                  GButton(icon: Icons.sms, text: 'Chatbot'),
                  GButton(icon: Icons.poll, text: 'Progress'),
                  GButton(icon: Icons.person, text: 'Profile'),
                ],
                padding: const EdgeInsets.only(left: 4, right: 4),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _selectedIndex.dispose();
    super.dispose();
  }
}
