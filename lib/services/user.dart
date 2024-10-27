import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/welcome_page.dart'; // Import the WelcomePage
//import 'package:image_picker/image_picker.dart'; // Import the image picker

class AppUser {
  String? firstName;
  String? lastName;
  String? email;
  String? dateOfBirth;
  String? password;
  String? userID;
  String? profilePicture;

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
      DocumentSnapshot userDoc = await _firestore.collection('User').doc(currentUser.uid).get();
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

  // Future<void> updateProfilePicture(BuildContext context) async {
  //   // Allow the user to choose an image from the gallery
  //   final pickedFile = await _picker.pickImage(
  //     source: ImageSource.gallery,
  //     imageQuality: 100, // Optional: Set the quality of the image
  //   );

  //   if (pickedFile != null) {
  //     profilePicture = pickedFile.path; // Update user profile picture path
  //     User? currentUser = _auth.currentUser;

  //     if (currentUser != null) {
  //       // Update profile picture in Firestore
  //       await _firestore.collection('User').doc(currentUser.uid).update({
  //         'profilePhoto': profilePicture,
  //       });
  //     }
  //   } else {
  //     print('No image selected.');
  //   }
  // }

  Future<void> showEditDialog(BuildContext context, String field) async {
    final TextEditingController controller = TextEditingController();

    if (field == 'name') {
      controller.text = '${firstName ?? ''} ${lastName ?? ''}'; // Set current name
    } else if (field == 'email') {
      controller.text = email ?? ''; // Set current email
    } else if (field == 'dateOfBirth') {
      controller.text = dateOfBirth ?? ''; // Set current date of birth
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $field'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: field),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (field == 'name') {
                  List<String> names = controller.text.split(' ');
                  if (names.length > 1) {
                    firstName = names[0];
                    lastName = names[1];
                    await _firestore.collection('User').doc(_auth.currentUser!.uid).update({
                      'firstName': firstName,
                      'lastName': lastName,
                    });
                  }
                } else if (field == 'email') {
                  email = controller.text;
                  await _firestore.collection('User').doc(_auth.currentUser!.uid).update({'email': email});
                } else if (field == 'dateOfBirth') {
                  dateOfBirth = controller.text;
                  await _firestore.collection('User').doc(_auth.currentUser!.uid).update({'dateOfBirth': dateOfBirth});
                }
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> showChangePasswordDialog(BuildContext context) async {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                decoration: InputDecoration(labelText: 'Current Password'),
                obscureText: true,
              ),
              TextField(
                controller: newPasswordController,
                decoration: InputDecoration(labelText: 'New Password'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String currentPassword = currentPasswordController.text;
                String newPassword = newPasswordController.text;

                // Validate current password and update to new password logic here

                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Change'),
            ),
          ],
        );
      },
    );
  }

  Future<void> logout(BuildContext context) async {
    // Show a confirmation dialog before logging out
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Close the dialog and return false
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Close the dialog and return true
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _auth.signOut(); // Sign out the user
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => WelcomePage()), // Redirect to welcome page
      );
    }
  }

  Future<void> delete(BuildContext context) async {
    // Show a confirmation dialog before deleting the account
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Account'),
          content: Text('Are you sure you want to delete your account? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Close the dialog and return false
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Close the dialog and return true
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Delete user data from Firestore
        await _firestore.collection('User').doc(currentUser.uid).delete();
        // Delete user from Firebase Auth
        await currentUser.delete();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => WelcomePage()), // Redirect to welcome page
        );
      }
    }
  }
}
