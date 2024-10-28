import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/welcome_page.dart';
import 'package:intl/intl.dart';

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

  Future<void> showEditDialog(BuildContext context, String field, VoidCallback onUpdate) async {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController fieldController = TextEditingController();
  
  DateTime selectedDate = DateTime.now();
  String formattedDate = '';

  ValueNotifier<bool> isFirstNameEmpty = ValueNotifier<bool>(true);
  ValueNotifier<bool> isLastNameEmpty = ValueNotifier<bool>(true);
  ValueNotifier<bool> isFieldEmpty = ValueNotifier<bool>(true);

  if (field == 'name') {
    firstNameController.text = '';
    lastNameController.text = '';
  } else if (field == 'dateOfBirth') {
    formattedDate = dateOfBirth ?? 'Select your birth date';
  } else {
    fieldController.text = '';
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1990),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color(0xFF104A73), // darkBlue
            colorScheme: ColorScheme.light(
              primary: Color(0xFF104A73), // darkBlue
              onPrimary: Color(0xFFF5F7F8), // lightGray
              surface: Color(0xFFF5F7F8), // lightGray
              onSurface: Color(0xFF545454), // darkGray
              secondary: Color(0xFF79A3B7), // lightBlue
            ),
            dialogBackgroundColor: Color(0xFFF5F7F8), // Background color
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      selectedDate = pickedDate;
      formattedDate = DateFormat('MMM dd, yyyy').format(selectedDate);
      isFieldEmpty.value = false;
    }
  }

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: Text(
          'Edit $field',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: field == 'name'
              ? [
                  TextField(
                    controller: firstNameController,
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      hintText: firstName ?? 'Enter your first name',
                    ),
                    onChanged: (value) {
                      isFirstNameEmpty.value = value.isEmpty;
                    },
                  ),
                  TextField(
                    controller: lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      hintText: lastName ?? 'Enter your last name',
                    ),
                    onChanged: (value) {
                      isLastNameEmpty.value = value.isEmpty;
                    },
                  ),
                ]
              : field == 'dateOfBirth'
                  ? [
                      GestureDetector(
                        onTap: () => _pickDate(context),
                        child: AbsorbPointer(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Date of Birth',
                              hintText: formattedDate,
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ]
                  : [
                      TextField(
                        controller: fieldController,
                        decoration: InputDecoration(
                          labelText: field,
                          hintText: email ?? 'Enter your $field',
                        ),
                        onChanged: (value) {
                          isFieldEmpty.value = value.isEmpty;
                        },
                      ),
                    ],
        ),
        backgroundColor: Colors.white,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Color(0xFF79A3B7)),
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF79A3B7)),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: isFirstNameEmpty,
            builder: (context, firstNameValue, child) {
              return ValueListenableBuilder<bool>(
                valueListenable: isLastNameEmpty,
                builder: (context, lastNameValue, child) {
                  return ElevatedButton(
                    onPressed: (field == 'name' &&
                                firstNameController.text.isEmpty &&
                                lastNameController.text.isEmpty) ||
                            (field != 'name' && isFieldEmpty.value)
                        ? null
                        : () async {
                            Map<String, dynamic> updateData = {};

                            if (field == 'name') {
                              if (firstNameController.text.isNotEmpty) {
                                updateData['firstName'] = firstNameController.text;
                              }
                              if (lastNameController.text.isNotEmpty) {
                                updateData['lastName'] = lastNameController.text;
                              }
                            } else if (field == 'dateOfBirth') {
                              updateData['dateOfBirth'] = DateFormat('MMM dd, yyyy').format(selectedDate);
                            } else {
                              updateData[field] = fieldController.text;
                            }

                            if (updateData.isNotEmpty) {
                              await _firestore
                                  .collection('User')
                                  .doc(_auth.currentUser!.uid)
                                  .update(updateData);
                              await loadUserData(); // Reload user data after update
                              onUpdate(); // Trigger UI refresh callback
                            }

                            // Show notification and close dialog
                            _showTopNotification(context, '$field updated successfully!');
                            Navigator.of(context).pop(); // Close the dialog
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF79A3B7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
              );
            },
          ),
        ],
      );
    },
  );
}



  Future<void> showChangePasswordDialog(BuildContext context) async {
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Text(
          'Change Password',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Current Password',
              ),
              obscureText: true,
            ),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
              ),
              obscureText: true,
            ),
          ],
        ),
        backgroundColor: Colors.white,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Color(0xFF79A3B7)),
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF79A3B7)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                User? currentUser = _auth.currentUser;
                if (currentUser == null) throw Exception('No user is signed in.');

                // Authenticate the current password
                final credential = EmailAuthProvider.credential(
                  email: currentUser.email!,
                  password: currentPasswordController.text,
                );

                await currentUser.reauthenticateWithCredential(credential);

                // Validate the new password
                String newPassword = newPasswordController.text;
                String? validationResult = _validatePassword(newPassword);
                if (validationResult != null) {
                  _showTopNotification(context, validationResult);
                  return;
                }

                // Update the password in Firebase Authentication
                await currentUser.updatePassword(newPassword);

                // Close the dialog and show confirmation
                Navigator.of(context).pop();
                _showTopNotification(context, 'Password changed successfully!');
              } catch (e) {
                _showTopNotification(context, 'Error: ${e.toString()}');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF79A3B7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text(
              'Change',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );
}


// Password validation method
  String? _validatePassword(String value) {
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    } else if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#]).{8,}$')
        .hasMatch(value)) {
      return 'Password must contain upper, lower, number, and symbol';
    }
    return null;
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
          'Sign out',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
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

    // Clear user attributes
    firstName = null;
    lastName = null;
    email = null;
    dateOfBirth = null;
    password = null;
    userID = null;
    profilePicture = null;

    await loadUserData(); // Reload to ensure all data is reset

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
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
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

      // Clear user attributes
      firstName = null;
      lastName = null;
      email = null;
      dateOfBirth = null;
      password = null;
      userID = null;
      profilePicture = null;

      await loadUserData(); // Reload to confirm data reset

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => WelcomePage()),
      );
    }
  }
}


  void _showTopNotification(BuildContext context, String message) {
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
}