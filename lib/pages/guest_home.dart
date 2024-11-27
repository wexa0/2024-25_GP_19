import 'package:flutter/material.dart';
import 'package:flutter_application/models/GuestBottomNavigationBar.dart';
import 'package:flutter_application/pages/task_page.dart';
import 'package:flutter_application/pages/progress_page.dart';
import 'package:flutter_application/pages/guest_profile_page.dart';
import 'package:flutter_application/pages/chatbot_page.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application/welcome_page.dart';

void main() async {
  runApp(MaterialApp(home: GuestHomePage()));
}

class GuestHomePage extends StatefulWidget {
  const GuestHomePage({super.key});
  @override
  GuestHomePageState createState() => GuestHomePageState();
}

class GuestHomePageState extends State<GuestHomePage> {
  int _currentIndex = 0;

  // List of screens for navigation
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      GuestHomePageContent(onTabChange: onTabChange), // Pass the callback here
      TaskPage(),
      ChatbotpageWidget(),
      ProgressPage(),
      GuestHomePage(),
    ]);
  }

  void onTabChange(int index) {
    setState(() {
      _currentIndex = index; // Update the index when a tab is selected
    });
  }

  @override
  Widget build(BuildContext context) {
    var selectedIndex = 0;
    return Scaffold(
      appBar: _currentIndex == 0 ? _buildAppBar() : null,
      backgroundColor: const Color.fromARGB(255, 245, 247, 248),
      body: _pages[_currentIndex],
      bottomNavigationBar: GuestCustomNavigationBar(
        selectedIndex: selectedIndex,
        onTabChange: (index) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) {
              switch (index) {
                case 0:
                  return GuestHomePage();
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
      ),
    );
  }

  // Custom AppBar for GuestHomePage
  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'Guest Home',
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
    );
  }
}

// This is the content for the Guest HomePage
class GuestHomePageContent extends StatefulWidget {
  final Function(int) onTabChange; // Callback to change tabs

  GuestHomePageContent({required this.onTabChange});

  @override
  GuestHomePageContentState createState() => GuestHomePageContentState();
}

class GuestHomePageContentState extends State<GuestHomePageContent> {
  String? fName; // first name to print
  String? lName; // last name to print
  int _carouselIndex = 0; // Current index for carousel
  var now = DateTime.now(); // current date
  var formatter = DateFormat.yMMMMd('en_US'); // format date as specified
  final List<String> imgList = [
    'assets/images/signUpForFeatures.png',
    'assets/images/managaTasksCrousel.png',
    'assets/images/setRemindersCrousel.png',
    'assets/images/chatCrousel.png',
  ]; // carousel list

  // Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser; // get current user
    if (user != null) {
      try {
        DocumentSnapshot<Map<String, dynamic>> ds = await FirebaseFirestore
            .instance
            .collection('User')
            .doc(user.uid)
            .get();

        if (ds.exists) {
          var data = ds.data();
          if (data != null) {
            setState(() {
              fName = data['firstName'] ?? ''; // Ensure fName is never null
              lName = data['lastName'] ?? ''; // Ensure lName is never null
            });
          }
        } else {
          print('Document does not exist.');
        }
      } catch (e) {
        print('Error fetching data: $e');
      }
    } else {
      print('No user is logged in.');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch user data when the widget is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 36),
        _buildWelcomeHeader(),
        SizedBox(height: 18),
        _buildCarouselSlider(),
        SizedBox(height: 15),
        buildQuickActions(),
      ],
    );
  }

  // Builds the welcome message and date
  Widget _buildWelcomeHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome to,",
            style: TextStyle(
              color: Colors.black,
              fontSize: 19,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "AttentionLens!",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 29,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Text(
            formatter.format(now), // Display the formatted date
            style: TextStyle(
              color: const Color.fromARGB(255, 144, 147, 147),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // Builds the carousel slider with images
  Widget _buildCarouselSlider() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider(
          options: CarouselOptions(
            enlargeCenterPage: true,
            aspectRatio: 16 / 8.5,
            viewportFraction: 0.9,
            onPageChanged: (index, reason) {
              setState(() {
                _carouselIndex = index; // Update current index
              });
            },
          ),
          items: imgList.map((item) {
            return GestureDetector(
              onTap: () {
                if (_carouselIndex == 0) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => WelcomePage()),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.only(top: 2, bottom: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(25, 203, 203, 203)
                          .withOpacity(0.9),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(item, fit: BoxFit.cover),
                ),
              ),
            );
          }).toList(),
        ),
        Positioned(
          bottom: 10, // Position it at the bottom of the image
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: imgList.asMap().entries.map((entry) {
              int index = entry.key;
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 3.0),
                width: _carouselIndex == index ? 25 : 8.0,
                height: 4.5,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(2),
                  color: _carouselIndex == index
                      ? const Color.fromARGB(255, 238, 238, 238)
                      : Colors.grey,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Builds the quick action buttons
  Widget buildQuickActions() {
    return Column(
      children: [
        SizedBox(
          height: 240,
          child: Table(children: [
            TableRow(
              children: <Widget>[
                Padding(
                    padding: const EdgeInsets.only(left: 17, top: 10, right: 6),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskPage(),
                          ),
                        ); // Navigate to TaskPage
                      },
                      child: Container(
                        height: 110,
                        width: 100,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(95, 203, 203, 203)
                                  .withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 0),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(10),
                          color: const Color.fromARGB(255, 255, 255, 255),
                        ),
                        child: Table(
                          columnWidths: const {
                            0: const FractionColumnWidth(0.3)
                          },
                          children: [
                            TableRow(
                              children: [
                                Container(
                                  margin:
                                      const EdgeInsets.only(top: 3, left: 3),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/todayTask.png',
                                        height: 45,
                                        width: 45,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(right: 40),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(height: 30),
                                      Text(
                                        "Today's Tasks",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    )),
                Padding(
                    padding: const EdgeInsets.only(left: 6, top: 10, right: 17),
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: const Color(0xFFF5F7F8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              title: const Text(
                                'Login & Explor!',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              content: const Text(
                                'Ready to add tasks? Sign in or create an account to access all features.',
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
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: Color(0xFF79A3B7)),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => WelcomePage()),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF79A3B7),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  child: const Text(
                                    'Join Now',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Container(
                        height: 110,
                        width: 100,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(95, 203, 203, 203)
                                  .withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 0),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(10),
                          color: const Color.fromARGB(255, 255, 255, 255),
                        ),
                        child: Table(
                          columnWidths: const {
                            0: const FractionColumnWidth(0.3)
                          },
                          children: [
                            TableRow(
                              children: [
                                Container(
                                  margin:
                                      const EdgeInsets.only(top: 3, left: 3),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/addTask.png',
                                        height: 45,
                                        width: 45,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(right: 40),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(height: 30),
                                      Text(
                                        "Add a Task",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
            TableRow(
              children: <Widget>[
                Padding(
                    padding: const EdgeInsets.only(left: 17, top: 10, right: 6),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProgressPage(),
                          ),
                        );
                      },
                      child: Container(
                        height: 110,
                        width: 100,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(95, 203, 203, 203)
                                  .withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 0),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(10),
                          color: const Color.fromARGB(255, 255, 255, 255),
                        ),
                        child: Table(
                          columnWidths: const {
                            0: const FractionColumnWidth(0.3)
                          },
                          children: [
                            TableRow(
                              children: [
                                Container(
                                  margin:
                                      const EdgeInsets.only(top: 3, left: 3),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/viewProgress.png',
                                        height: 45,
                                        width: 45,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(right: 30),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(height: 28),
                                      Text(
                                        "View Progress",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    )),
                Padding(
                    padding: const EdgeInsets.only(left: 6, top: 10, right: 17),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatbotpageWidget(),
                          ),
                        );
                      },
                      child: Container(
                        height: 110,
                        width: 100,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(95, 203, 203, 203)
                                  .withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 0),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(10),
                          color: const Color.fromARGB(255, 255, 255, 255),
                        ),
                        child: Table(
                          columnWidths: const {
                            0: const FractionColumnWidth(0.3)
                          },
                          children: [
                            TableRow(
                              children: [
                                Container(
                                  margin:
                                      const EdgeInsets.only(top: 3, left: 3),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/chatWithAttena.png',
                                        height: 45,
                                        width: 45,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(right: 24),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(height: 28),
                                      Text(
                                        "Chat with Attena",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
          ]),
        ),
      ],
    );
  }

  // Helper function to build each quick action button
  Widget _buildQuickAction({
    required String imagePath,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 17),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(95, 203, 203, 203).withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 3,
                offset: Offset(0, 0),
              ),
            ],
            borderRadius: BorderRadius.circular(10),
            color: const Color.fromARGB(255, 255, 255, 255),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Image.asset(imagePath, height: 45, width: 45),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
