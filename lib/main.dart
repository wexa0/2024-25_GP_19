import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
<<<<<<< HEAD
import 'package:flutter_application/welcome_page.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure Firebase is initialized before your app runs.
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDmLYRShTksz7xniQH8Qks8TxhBQKhzFSk",
        authDomain: "attensionlens-db.firebaseapp.com",
        projectId: "attensionlens-db",
        storageBucket: "attensionlens-db.appspot.com",
        messagingSenderId: "806322652007",
        appId: "1:806322652007:web:a283d85295ec4affa7a5c2",
      ),
    );
=======
import 'package:flutter_application/welcome_page.dart';

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
>>>>>>> 40c024b6aa0f3812a741458929487d182c99554a
    print("Firebase initialized successfully");
  } catch (e) {
    print("Firebase initialization error: $e");
  }
<<<<<<< HEAD
  
=======

>>>>>>> 40c024b6aa0f3812a741458929487d182c99554a
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

<<<<<<< HEAD
 @override
Widget build(BuildContext context) {
      return MaterialApp(
        title: 'Your App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const WelcomePage(), // Your initial page
      );
}
=======
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WelcomePage(), 
      debugShowCheckedModeBanner: false,
      // Your initial page
    );
  }
>>>>>>> 40c024b6aa0f3812a741458929487d182c99554a
}
