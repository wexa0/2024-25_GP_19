//need more updating and i still have an error beacuse i don't hve access to firebase
//need to add picture field

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  DateTime? _selectedDate;
  final _formKey = GlobalKey<FormState>(); // Key for form validation

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch user data when initializing the page
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('User')
          .doc(user.uid)
          .get();

      // Populate the fields with existing user data
      _firstNameController.text = userData['firstName'] ?? '';
      _lastNameController.text = userData['lastName'] ?? '';
      _emailController.text = userData['email'] ?? '';
      _dobController.text = userData['dateOfBirth'] ?? '';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color(0xFF3b7292), // Header color
            colorScheme: ColorScheme.light(
                primary: Color(0xFF3b7292)), // Selected date color
            buttonTheme: ButtonThemeData(
                textTheme: ButtonTextTheme.primary), // Button text color
          ),
          child: child ?? Container(),
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text =
            "${picked.day}/${picked.month}/${picked.year}"; // Format as DD/MM/YYYY
      });
    }
  }

  // Function to handle profile updates
  void _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        User? user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          // Update user email if changed
          if (_emailController.text.trim() != user.email) {
            await user.updateEmail(_emailController.text.trim());
          }

          // Update user details in Firestore
          await FirebaseFirestore.instance
              .collection('User')
              .doc(user.uid)
              .update({
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'email': _emailController.text.trim(),
            'dateOfBirth': _dobController.text.trim(),
          });

          // Notify success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated successfully!')),
          );

          // Navigate back to the previous page
          Navigator.pop(context);
        }
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Image.asset(
            'assets/images/signup.png', // Update to your actual image path
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // Back Button
          Positioned(
            top: 40, // Adjust position as needed
            left: 20,
            child: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: Color(0xFF104A73), size: 55), // Arrow icon
              onPressed: () {
                Navigator.pop(context); // Go back to the previous page
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey, // Assign the form key
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Edit Profile',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  // First Name and Last Name Fields
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            labelText: 'First Name *',
                            filled: true,
                            fillColor: Color(0xFFE6EBEF), // Background color
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(
                                color: Color(0xFFE6EBEF),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(
                                color: Color(0xFF3b7292),
                              ),
                            ),
                            floatingLabelStyle: TextStyle(
                              color: Color(0xFF3b7292),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'First Name is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            labelText: 'Last Name *',
                            filled: true,
                            fillColor: Color(0xFFE6EBEF), // Background color
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(
                                color: Color(0xFFE6EBEF),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(
                                color: Color(0xFF3b7292),
                              ),
                            ),
                            floatingLabelStyle: TextStyle(
                              color: Color(0xFF3b7292),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Last Name is required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email *',
                      filled: true,
                      fillColor: Color(0xFFE6EBEF),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(
                          color: Color(0xFFE6EBEF),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(
                          color: Color(0xFF3b7292),
                        ),
                      ),
                      floatingLabelStyle: TextStyle(
                        color: Color(0xFF3b7292),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                          .hasMatch(value)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  // Date of Birth Field
                  TextFormField(
                    controller: _dobController,
                    readOnly: true, // Prevent keyboard from appearing
                    onTap: () => _selectDate(context),
                    decoration: InputDecoration(
                      labelText: 'Date of Birth *',
                      filled: true,
                      fillColor: Color(0xFFE6EBEF),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(
                          color: Color(0xFFE6EBEF),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(
                          color: Color(0xFF3b7292),
                        ),
                      ),
                      floatingLabelStyle: TextStyle(
                        color: Color(0xFF3b7292),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Date of Birth is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24),
                  // Update Profile Button
                  ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3b7292), // Button color
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child:
                        Text('Update Profile', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}