import 'package:flutter/material.dart';
import 'package:flutter_application/authentication/signup__page.dart';
import 'package:flutter_application/welcome_page.dart'; // Import the welcome page
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Function to handle the login process
// Function to handle the login process
void _handleLogin() async {
  String email = _emailController.text;
  String password = _passwordController.text;

  if (email.isEmpty || password.isEmpty) {
    // Show Snackbar if fields are empty
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please fill in both fields'),
        backgroundColor: Colors.red, // Customize the background color
      ),
    );
    return;
  }

  try {
    // Attempt to sign in the user with Firebase Authentication
    UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // If login is successful, navigate to the next page (e.g., HomePage)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => WelcomePage()), // Change this to your next page
    );

    // Optionally show a success Snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Login Successful!'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    // Handle different types of errors (e.g., wrong password, no user found)
    String errorMessage;

    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for that email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          break;
        default:
          errorMessage = 'Login failed. Please try again.';
      }
    } else {
      errorMessage = 'An unknown error occurred.';
    }

    // Show error Snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Image.asset(
            'assets/images/login.png', // Update to your actual image path
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // Back Button
          Positioned(
            top: 40, // Adjust position as needed
            left: 20,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Color(0xFF104A73), size:55), // Arrow icon
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => WelcomePage()), // Change this to your welcome page
                );
              },
            ),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40),
                // Email TextField
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    filled: true,
                    fillColor: Colors.white70,
                    // Set the enabled border color
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(
                        color: Color(0xFFE6EBEF), // Use your desired color here
                      ),
                    ),
                    // Set the focused border color
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(
                        color: Color(0xFF3b7292), // Use your desired focused color here
                      ),
                    ),
                    floatingLabelStyle: TextStyle(
                      color: Color(0xFF3b7292), // Color of label when focused, matching the border
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Password TextField
                TextField(
                  controller: _passwordController,
                  obscureText: true, // To hide the password text
                  decoration: InputDecoration(
                    labelText: 'Password',
                    filled: true,
                    fillColor: Colors.white70,
                    // Set the enabled border color
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(
                        color: Color(0xFFE6EBEF), // Use your desired color here
                      ),
                    ),
                    // Set the focused border color
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(
                        color: Color(0xFF3b7292), // Use your desired focused color here
                      ),
                    ),
                    floatingLabelStyle: TextStyle(
                      color: Color(0xFF3b7292), // Color of label when focused, matching the border
                    ),
                  ),
                ),
                SizedBox(height: 24),
                // Log In Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleLogin, // Use the login handler
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3B7292), // Button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                        padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Log In',
                      style: TextStyle(
                        color: Colors.white, // Font color
                        fontWeight: FontWeight.bold, // Bold font
                        fontSize: 20
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Sign Up prompt
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: TextStyle(color: Color(0xFF737373)), // Corrected color code
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignUpPage()),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Color(0xFF3B7292),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
