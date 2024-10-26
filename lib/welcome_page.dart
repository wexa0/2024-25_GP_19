import 'package:flutter/material.dart';
import 'package:flutter_application/authentication/signup__page.dart';
import 'package:flutter_application/authentication/login_page.dart';
import 'package:flutter_application/pages/guest_home.dart'; 

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              'assets/images/welcome_page.png', // Add your background image path
              fit: BoxFit.cover,
            ),
          ),

          // SafeArea to prevent content from being obscured by system UI
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32.0, 0, 32.0, 20.0), // Adjusted bottom padding
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Keeps the column as small as possible
                  children: [
                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to sign-up page
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignUpPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3b7292), // Custom button color
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white), // White text color
                        ),
                      ),
                    ),
                    const SizedBox(height: 12), // Space between buttons

                    // Log In Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          // Navigate to log-in page
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()), // Navigate to LoginPage
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(
                            color: Color(0xFF3b7292), // Custom border color
                            width: 3,
                          ),
                        ),
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3b7292), // Custom text color
                          ),
                        ),
                      ),
                    ),
                     const SizedBox(height: 12), // Space between buttons

                    // Log In Button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          // Navigate to attentionlens
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => GuestHomePage()), // Navigate to LoginPage
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 17,
                            decoration: TextDecoration.underline,
                            color: Color.fromARGB(255, 85, 93, 97),
                          ),
                          children: [
                            const TextSpan(text: 'Navigate AttentionLens as '),
                            TextSpan(
                              text: 'Guest', 
                              style: const TextStyle(color: Color(0xFF3b7292),
                               decoration: TextDecoration.underline,
                                decorationColor: Color(0xFF3b7292),
                              ),
                             
                            ),
                          ],
                        ),
                      ),)
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: WelcomePage(),
  ));
}
