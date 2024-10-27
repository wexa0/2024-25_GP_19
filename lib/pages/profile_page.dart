import 'package:flutter/material.dart';
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
import 'guest_profile_page.dart';

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
          Positioned(
            bottom: 10,
            right: 0.5,
            child: buildEditIcon(),
          ),
        ],
      ),
    );
  }

  Widget buildImage() {
    ImageProvider<Object> image;

    // Check if running on the web and handle image loading accordingly
    if (imagePath == null || imagePath!.isEmpty) {
      image = NetworkImage(
          'https://cdn.pixabay.com/photo/2017/03/02/19/18/mystery-man-973460_960_720.png'); // Default online image
    } else if (html.window.navigator.userAgent.contains('Chrome')) {
      image = AssetImage(imagePath!);
    } else {
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

  Widget buildEditIcon() {
    return InkWell(
      onTap: onClicked,
      child: Container(
        padding: EdgeInsets.all(8),
        child: Icon(
          Icons.camera_alt,
          color: Color(0xFF525252),
          size: 32,
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(home: ProfilePage()));
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AppUser user = AppUser(); // Instance of AppUser
  bool isLoading = true;
  File? _image; // Variable to store the selected image
  //final ImagePicker _picker = ImagePicker(); // Image picker instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkUserEmail(); // Check if the user has an email
  }

  void _checkUserEmail() async {
    await user.loadUserData();
    if (user.email == null || user.email!.isEmpty) {
      // Redirect to guest profile page if no email is found
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => GuestProfilePage()),
      );
    } else {
      setState(() {
        isLoading = false; // Proceed if email exists
      });
    }
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
  //   final pickedFile = await _picker.pickImage(
  //     source: ImageSource.gallery,
  //     imageQuality: 100,
  //   );

  //   if (pickedFile != null) {
  //     setState(() {
  //       _image = File(pickedFile.path);
  //       user.profilePicture = pickedFile.path;
  //       user.updateProfilePicture(pickedFile.path as BuildContext);
  //     });
  //   } else {
  //     print('No image selected.');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    double coverHeight = 150;
    double profileHeight = 128;
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
      backgroundColor: Color(0xFFF5F7F8),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: coverHeight,
                          color: Color.fromRGBO(121, 163, 183, 1),
                        ),
                        SizedBox(height: 50),
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
                        Material(
                          color: Colors.white,
                          child: InkWell(
                            onTap: () => user.showEditDialog(context, 'name'),
                            child: ListTile(
                              title: Text('Name'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('${user.firstName ?? ''} ${user.lastName ?? ''}'.trim()),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.white,
                          child: InkWell(
                            onTap: () => user.showEditDialog(context, 'email'),
                            child: ListTile(
                              title: Text('Email'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(user.email ?? 'Loading...'),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.white,
                          child: InkWell(
                            onTap: () => user.showEditDialog(context, 'dateOfBirth'),
                            child: ListTile(
                              title: Text('Date of Birth'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(user.dateOfBirth ?? 'Loading...'),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.white,
                          child: InkWell(
                            onTap: () => user.showChangePasswordDialog(context),
                            child: ListTile(
                              title: Text('Change Password'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('••••••••'),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                            ),
                          ),
                        ),
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
                        Material(
                          color: Colors.white,
                          child: InkWell(
                            onTap: () {
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
                                  Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TextButton(
                            onPressed: () => user.logout(context),
                            style: TextButton.styleFrom(
                              backgroundColor: Color.fromRGBO(199, 217, 225, 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: Size(
                                  MediaQuery.of(context).size.width * 0.9, 52),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.logout, color: Color.fromRGBO(54, 54, 54, 1)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      'Logout',
                                      style: TextStyle(
                                        color: Color.fromRGBO(54, 54, 54, 1),
                                        fontSize: 18,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TextButton(
                            onPressed: () => user.delete(context),
                            style: TextButton.styleFrom(
                              backgroundColor: Color.fromRGBO(121, 163, 183, 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: Size(
                                  MediaQuery.of(context).size.width * 0.9, 52),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.close, color: Color.fromRGBO(54, 54, 54, 1)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      'Delete Account',
                                      style: TextStyle(
                                        color: Color.fromRGBO(54, 54, 54, 1),
                                        fontSize: 18,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Positioned(
                    //   top: top,
                    //   left: MediaQuery.of(context).size.width / 2 - profileHeight / 2,
                    //   child: ProfileWidget(
                    //     imagePath: _image?.path ?? user.profilePicture,
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
