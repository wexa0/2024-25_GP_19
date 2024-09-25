import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Image.asset(
            'assets/images/success.png', // Update with your image path
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // Content Overlay
          Center(
            child: Text(
              'Welcome to the Home Page!',
              style: TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
