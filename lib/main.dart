import 'package:flutter/material.dart';
import 'package:flutter_application/task_page';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application/welcome_page.dart'; // Import your WelcomePage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WelcomePage(), // Set the initial page to WelcomePage
    );
  }
}
