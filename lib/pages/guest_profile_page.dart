import 'package:flutter/material.dart';
import 'package:flutter_application/authentication/login_page.dart';
import 'package:flutter_application/authentication/signup__page.dart';
import 'package:flutter_application/models/BottomNavigationBar.dart';
import 'package:flutter_application/welcome_page.dart';
//import 'package:image_picker/image_picker.dart';
import 'dart:io'; // For File type
import 'dart:html' as html; // Import for web detection
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_application/services/user.dart'; // Import the AppUser class

class ProfileWidget extends StatelessWidget {
  final String? imagePath; // String? to allow null values
  final VoidCallback onClicked;

  const ProfileWidget({
    Key? key,
    required this.imagePath,
    required this.onClicked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          buildImage(),
        ],
      ),
    );
  }

  Widget buildImage() {
    ImageProvider<Object> image;

    // Check if running on the web and handle image loading accordingly
    if (imagePath == null || imagePath!.isEmpty) {
      // Use network image as default
      image = NetworkImage(
          'https://cdn.pixabay.com/photo/2017/03/02/19/18/mystery-man-973460_960_720.png'); // Default online image
    } else if (html.window.navigator.userAgent.contains('Chrome')) {
      // For web, use AssetImage
      image = AssetImage(imagePath!);
    } else {
      // For mobile, use FileImage
      image = FileImage(File(imagePath!));
    }

    return ClipOval(
      child: Material(
        color: Colors.transparent,
        child: Ink.image(
          image: image,
          fit: BoxFit.cover,
          width: 128,
          height: 128,
          child: const SizedBox(),
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(home: GuestProfilePage()));
}

class GuestProfilePage extends StatefulWidget {
  @override
  _GuestProfilePageState createState() => _GuestProfilePageState();
}

class _GuestProfilePageState extends State<GuestProfilePage> {
  AppUser user = AppUser(); // Instance of AppUser
  bool isLoading = true;
  File? _image; // Variable to store the selected image
  //final ImagePicker _picker = ImagePicker(); // Image picker instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    await user.loadUserData(); // Load user data using AppUser method
    setState(() {
      isLoading = false;
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
              color: Colors.black,
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

    overlayState?.insert(overlayEntry);
    Future.delayed(Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  // Future<void> _changeProfilePicture() async {
  //   // Allow the user to choose an image from the gallery
  //   final pickedFile = await _picker.pickImage(
  //     source: ImageSource.gallery,
  //     imageQuality: 100, // Optional: Set the quality of the image
  //   );

  //   if (pickedFile != null) {
  //     setState(() {
  //       _image = File(pickedFile.path); // Set the selected image
  //       user.profilePicture =
  //           pickedFile.path; // Update user profile picture path
  //       user.updateProfilePicture(pickedFile.path
  //           as BuildContext); // Update profile picture in Firestore
  //     });
  //   } else {
  //     print('No image selected.');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    double coverHeight = 150; // Set the height for the cover image
    double profileHeight = 128; // Set the height for the profile image
    final top = coverHeight - (profileHeight - 35);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color.fromRGBO(121, 163, 183, 1),
        elevation: 0.0,
        centerTitle: true,
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(),
      backgroundColor:
          Color(0xFFF5F7F8), // Set the background color for the entire page
      body: SafeArea(
        child: isLoading
            ? const Center(
                child:
                    CircularProgressIndicator()) // Show loading indicator while fetching data
            : SingleChildScrollView(
                // Makes the page scrollable
                child: Stack(
                  clipBehavior:
                      Clip.none, // Prevents clipping of the profile image
                  children: [
                    Column(
                      children: [
                        // Profile Header Section with Profile Picture and Camera Icon
                        Container(
                          width: double.infinity,
                          height: coverHeight,
                          color: Color.fromRGBO(121, 163, 183,
                              1), // Background color for the header
                        ),
                        SizedBox(height: 50),
                        // Profile Information Section Title
                        Container(
                          width: double.infinity,
                          color: Colors.grey[300],
                          padding: EdgeInsets.all(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Profile Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // Sign Up Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        SignUpPage()), // Redirects to sign_up_page.dart
                              );
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Color.fromRGBO(199, 217, 225, 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: Size(
                                MediaQuery.of(context).size.width * 0.9,
                                52,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Sign up', // Change title to "Sign up"
                                style: TextStyle(
                                  color: Color.fromRGBO(54, 54, 54, 1),
                                  fontSize: 18,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        // Login Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        LoginPage()), // Redirects to login_page.dart
                              );
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Color.fromRGBO(121, 163, 183, 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: Size(
                                MediaQuery.of(context).size.width * 0.9,
                                52,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Login', // Change title to "Login"
                                style: TextStyle(
                                  color: Color.fromRGBO(54, 54, 54, 1),
                                  fontSize: 18,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),

                        //Others Section Title
                        Container(
                          width: double.infinity,
                          color: Colors.grey[300],
                          padding: EdgeInsets.all(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Others',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // Contact us Row
                        Material(
                          color: Colors.white,
                          child: InkWell(
                            onTap: () {
                              // Use the mailto link to open the email app
                              final Uri emailLaunchUri = Uri(
                                scheme: 'mailto',
                                path: 'AttentionLens@gmail.com',
                                query: 'subject=Contact%20AttentionLens',
                              );
                              launch(emailLaunchUri.toString());
                            },
                            child: ListTile(
                              title: Text('Contact us'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Send us an email'),
                                  SizedBox(width: 8),
                                  Icon(
                                      Icons.arrow_forward_ios), // Trailing icon
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Positioned(
                    //   top: top,
                    //   left: MediaQuery.of(context).size.width / 2 -
                    //       profileHeight / 2,
                    //   child: ProfileWidget(
                    //     imagePath: _image?.path ??
                    //         user.profilePicture, // Use selected image or default
                    //     onClicked: _changeProfilePicture,
                    //   ),
                    // ),
                  ],
                ),
              ),
      ),
    );
  }
}
