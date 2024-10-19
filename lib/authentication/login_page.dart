import 'package:flutter/material.dart';
import 'package:flutter_application/authentication/signup__page.dart';
import 'package:flutter_application/welcome_page.dart';
import 'package:flutter_application/succuss.dart'; 
import 'package:flutter_application/pages/home.dart'; 
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Function to handle the login process
  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      // Show Snackbar if fields are empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both fields'),
          backgroundColor: Colors.red, // Customize the background color
        ),
      );
    } else {
      try {
        // Attempt to sign in the user with email and password
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Log success to see if this part is reached
        print('User login successful, UID: ${userCredential.user!.uid}');

        // Navigate to the Welcome Page or the next screen after successful login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => addTask()), // Your next screen
        );
      } on FirebaseAuthException catch (e) {
        // Handle different error codes
        if (e.code == 'user-not-found') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No user found for that email.'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (e.code == 'wrong-password') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Wrong password provided.'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to sign in: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
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
              icon: const Icon(Icons.arrow_back, color: Color(0xFF104A73), size:55), // Arrow icon
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomePage()), // Change this to your welcome page
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
                const SizedBox(height: 40),
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
                      borderSide: const BorderSide(
                        color: Color(0xFFE6EBEF), // Use your desired color here
                      ),
                    ),
                    // Set the focused border color
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(
                        color: Color(0xFF3b7292), // Use your desired focused color here
                      ),
                    ),
                    floatingLabelStyle: const TextStyle(
                      color: Color(0xFF3b7292), // Color of label when focused, matching the border
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                      borderSide: const BorderSide(
                        color: Color(0xFFE6EBEF), // Use your desired color here
                      ),
                    ),
                    // Set the focused border color
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(
                        color: Color(0xFF3b7292), // Use your desired focused color here
                      ),
                    ),
                    floatingLabelStyle: const TextStyle(
                      color: Color(0xFF3b7292), // Color of label when focused, matching the border
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Log In Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleLogin, // Use the login handler
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B7292), // Button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        color: Colors.white, // Font color
                        fontWeight: FontWeight.bold, // Bold font
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Sign Up prompt
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
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
                      child: const Text(
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
