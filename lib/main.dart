import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'package:flutter_application/welcome_page.dart'; // Import your WelcomePage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const firebaseOptions = FirebaseOptions(
    apiKey: "AIzaSyDmLYRShTksz7xniQH8Qks8TxhBQKhzFSk",
    authDomain: "attensionlens-db.firebaseapp.com",
    projectId: "attensionlens-db",
    storageBucket: "attensionlens-db.appspot.com",
    messagingSenderId: "806322652007",
    appId: "1:806322652007:web:d899f944a96a5da5a7a5c2",
    measurementId: "G-5JNN0NVSSB",
  );

  try {
    await Firebase.initializeApp(options: firebaseOptions);
    print("Firebase initialized successfully");
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WelcomePage(), // Set the initial page to WelcomePage
      debugShowCheckedModeBanner: false, // Disable the debug banner
    );
  }
}
