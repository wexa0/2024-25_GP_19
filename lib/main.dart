import 'package:flutter/material.dart';
import 'package:flutter_application/task_page';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application/welcome_page.dart'; // Import your WelcomePage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const firebaseOptions = FirebaseOptions(
    apiKey: "<API-KEY>",
    authDomain: "attensionlens-db.firebaseapp.com",
    projectId: "attensionlens-db",
    storageBucket: "attensionlens-db.appspot.com",
    messagingSenderId: "806322652007",
    appId: "<APP-ID>",
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
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WelcomePage(), // Set the initial page to WelcomePage
      debugShowCheckedModeBanner: false, // Disable the debug banner
    );
  }
}
