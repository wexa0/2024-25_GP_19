import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/welcome_page.dart';

class AppUser {
  String? firstName;
  String? lastName;
  String? email;
  String? dateOfBirth;
  String? password;
  String? userID;
  String? profilePicture;

  Color darkBlue = Color(0xFF104A73);
  Color mediumBlue = Color(0xFF3B7292);
  Color lightBlue = Color(0xFF79A3B7);
  Color lightestBlue = Color(0xFFC7D9E1);
  Color lightGray = Color(0xFFF5F7F8);
  Color darkGray = Color(0xFF545454);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final ImagePicker _picker = ImagePicker(); // Image picker instance

  // Unnamed constructor to initialize attributes to default values
  AppUser() {
    firstName = '';
    lastName = '';
    email = '';
    dateOfBirth = '';
    password = '';
    userID = '';
    profilePicture = '';
  }

  // Parameterized constructor
  AppUser.named({
    this.firstName,
    this.lastName,
    this.email,
    this.dateOfBirth,
    this.password,
    this.userID,
    this.profilePicture,
  });

  Future<void> loadUserData() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('User').doc(currentUser.uid).get();
      if (userDoc.exists) {
        firstName = userDoc['firstName'];
        lastName = userDoc['lastName'];
        email = userDoc['email'];
        dateOfBirth = userDoc['dateOfBirth'];
        profilePicture = null;
        userID = currentUser.uid;
      }
    }
  }

  Future<void> showEditDialog(BuildContext context, String field) async {
    final TextEditingController controller = TextEditingController();
    if (field == 'name') {
      controller.text = '${firstName ?? ''} ${lastName ?? ''}';
    } else if (field == 'email') {
      controller.text = email ?? '';
    } else if (field == 'dateOfBirth') {
      controller.text = dateOfBirth ?? '';
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Text(
            'Edit $field',
            style: TextStyle(fontWeight: FontWeight.bold, color: darkBlue),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: field,
              hintText: 'Enter new $field',
              labelStyle: TextStyle(color: mediumBlue),
            ),
          ),
          backgroundColor: lightGray,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: lightBlue),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(color: lightBlue),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Save action logic
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: lightBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                'Save',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> showChangePasswordDialog(BuildContext context) async {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Text(
            'Change Password',
            style: TextStyle(fontWeight: FontWeight.bold, color: darkBlue),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  labelStyle: TextStyle(color: mediumBlue),
                ),
                obscureText: true,
              ),
              TextField(
                controller: newPasswordController,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(color: mediumBlue),
                ),
                obscureText: true,
              ),
            ],
          ),
          backgroundColor: lightGray,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: lightBlue),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(color: lightBlue),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: lightBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                'Change',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> logout(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.bold, color: darkBlue),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: TextStyle(color: darkGray),
          ),
          backgroundColor: lightGray,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: lightBlue),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(color: lightBlue),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: lightBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                'Yes',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _auth.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => WelcomePage()),
      );
    }
  }

  Future<void> delete(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Text(
            'Delete Account',
            style: TextStyle(fontWeight: FontWeight.bold, color: darkBlue),
          ),
          content: Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
            style: TextStyle(color: darkGray),
          ),
          backgroundColor: lightGray,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: lightBlue),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(color: lightBlue),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: lightBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('User').doc(currentUser.uid).delete();
        await currentUser.delete();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => WelcomePage()),
        );
      }
    }
  }
}
