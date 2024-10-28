import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application/pages/addTaskForm.dart';
import 'package:flutter_application/pages/progress_page.dart';
import 'package:flutter_application/pages/profile_page.dart';
import 'package:flutter_application/pages/chatbot_page.dart';
import 'package:flutter_application/pages/task_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(home: HomePage()));
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? imageUrl; //image url
  User? _user = FirebaseAuth.instance.currentUser; // get current user
  String? fName; // first name to print
  String? lName; // last name to print
  int _currentIndex = 0; // Current index for bottom navigation bar
  var now = DateTime.now(); //current date
  var formatter = DateFormat.yMMMMd('en_US'); //format date as specified

  final List<String> imgList = [
    'assets/images/mainCrousel.png',
    'assets/images/managaTasksCrousel.png',
    'assets/images/setRemindersCrousel.png',
    'assets/images/chatCrousel.png',
  ]; //carousel list

  // List of screens for navigation
  final List<Widget> _pages = [
    HomePageContent(), // Define a separate widget for home page content
    TaskPage(),
    ChatbotpageWidget(),
    ProgressPage(),
    ProfilePage(),
  ];
// Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    if (_user != null) {
      try {
        DocumentSnapshot<Map<String, dynamic>> ds = await FirebaseFirestore
            .instance
            .collection('User')
            .doc(_user!.uid)
            .get();

        if (ds.exists) {
          var data =
              ds.data(); // No need for casting anymore with the correct type
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
    return Scaffold(
      appBar: appBar(),
      backgroundColor: const Color.fromARGB(255, 245, 247, 248),
      body: _pages[_currentIndex], // Show the current page
      bottomNavigationBar: Container(
        color: const Color.fromARGB(
            255, 226, 231, 234), // Background color of the navigation bar
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
        child: GNav(
          backgroundColor: const Color(0xFF79A3B7)
              .withOpacity(0), // Set the background color to match your old bar
          color: const Color(
              0xFF545454), // Inactive icons and text color (match the old inactive color)
          activeColor: const Color(
              0xFF104A73), // Active icon and text color (match the old active color)
          tabBackgroundColor: const Color(0xFF79A3B7).withOpacity(
              0.3), // Slightly transparent background for active tab
          gap: 8, // Gap between icon and text
          padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8), // Adjust the padding for visual consistency
          tabBorderRadius:
              15, // Optional: add rounded corners for a softer look
          selectedIndex: _currentIndex,
          iconSize: 24, // Adjust icon size to match the old bar
          onTabChange: (index) {
            setState(() {
              _currentIndex = index; // Update the index when a tab is selected
            });
          },
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
            GButton(icon: Icons.poll, text: 'Progress'),
            GButton(
              icon: Icons.person,
              text: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // Custom AppBar
  AppBar appBar() {
    return AppBar(
      title: Text(
        'Home',
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

  // Fetch user data from Firestore
  Future<void> _fetch() async {
    final User? _user = FirebaseAuth.instance.currentUser;

    if (_user != null) {
      try {
        DocumentSnapshot ds = await FirebaseFirestore.instance
            .collection('User')
            .doc(_user.uid)
            .get();

        if (ds.exists) {
          var data = ds.data() as Map<String, dynamic>?; // Cast to Map
          if (data != null &&
              data.containsKey('firstName') &&
              data.containsKey('lastName')) {
            fName = data['firstName'];
            lName = data['lastName'];
          } else {
            print('firstName and lastName field does not exist');
          }
        } else {
          print('Document does not exist');
        }
      } catch (e) {
        print('Error fetching data: $e');
      }
    } else {
      print('No user is logged in');
    }
  }
}

// This is the content for the homepage, separated from the main scaffold
class HomePageContent extends StatefulWidget {
  @override
  _HomePageContentState createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  int _carouselIndex = 0;
  var now = DateTime.now();
  var formatter = DateFormat.yMMMMd('en_US');

  final List<String> imgList = [
    'assets/images/mainCrousel.png',
    'assets/images/managaTasksCrousel.png',
    'assets/images/setRemindersCrousel.png',
    'assets/images/chatCrousel.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 30),
        _buildWelcomeHeader(),
        SizedBox(height: 15),
        _buildCarouselSlider(),
        SizedBox(height: 15),
        _buildQuickActions(),
      ],
    );
  }

  Widget _buildWelcomeHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hello,",
            style: TextStyle(
              color: Colors.black,
              fontSize: 19,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          FutureBuilder(
            future: FirebaseAuth.instance.currentUser != null
                ? FirebaseFirestore.instance
                    .collection('User')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .get()
                : Future.value(null),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                // Access the DocumentSnapshot properly
                var userData = snapshot.data!.data()
                    as Map<String, dynamic>?; // Use '!' to ensure non-null

                if (userData != null) {
                  return Text(
                    "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}", // Safely access firstName and lastName
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 29,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                } else {
                  return Text("User data not found");
                }
              } else if (snapshot.hasError) {
                return Text("Error fetching data");
              } else {
                return CircularProgressIndicator(); // Loading indicator while fetching data
              }
            },
          ),
          Text(
            formatter.format(now),
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

  Widget _buildCarouselSlider() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider(
          options: CarouselOptions(
            enlargeCenterPage: true,
            aspectRatio: 16.3 / 8.5,
            viewportFraction: 0.9,
            onPageChanged: (index, reason) {
              setState(() {
                _carouselIndex = index;
              });
            },
          ),
          items: imgList.map((item) {
            return Container(
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
            );
          }).toList(),
        ),
        Positioned(
          bottom: 10,
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

  Widget _buildQuickActions() {
    return Container(
      height: 240,
      child: Table(
        children: [
          TableRow(
            children: [
              _buildQuickAction(
                imagePath: 'assets/images/todayTask.png',
                label: "Today's Tasks",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TaskPage()),
                  );
                },
              ),
              _buildQuickAction(
                imagePath: 'assets/images/addTask.png',
                label: 'Add a Task',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => addTask()),
                  );
                },
              ),
            ],
          ),
          TableRow(
            children: [
              _buildQuickAction(
                imagePath: 'assets/images/viewProgress.png',
                label: 'View Progress',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProgressPage()),
                  );
                },
              ),
              _buildQuickAction(
                imagePath: 'assets/images/chatWithAttena.png',
                label: 'Chat with Attena',
                onTap: () {
                  
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ChatbotpageWidget()));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

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

@override

// This is the app bar used throughout the app
AppBar _buildAppBar() {
  return AppBar(
    title: Text(
      'Home',
      style: TextStyle(
          color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    backgroundColor: const Color.fromARGB(255, 226, 231, 234),
    elevation: 0.0,
    centerTitle: true,
    automaticallyImplyLeading: false,
  );
}
