import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application/pages/guest_home.dart';
import 'package:flutter_application/welcome_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_application/services/notification_handler.dart';
import 'package:flutter_application/pages/task_page.dart';
import 'package:flutter_application/pages/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application/services/notification_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<TaskPageState> taskPageKey = GlobalKey<TaskPageState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await _initializeFirebase();

  // Initialize Timezone
  tz.initializeTimeZones();

  // Initialize Notifications
  await _initializeNotifications();

  
  runApp(const MyApp());
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBbLKfKyxdcxkBzsBYvnpXc_cM_TABCw3A",
        authDomain: "attensionlens-db.firebaseapp.com",
        projectId: "attensionlens-db",
        storageBucket: "attensionlens-db.appspot.com",
        messagingSenderId: "806322652007",
        appId: "1:806322652007:web:a283d85295ec4affa7a5c2",
        measurementId: "G-E8H4BE01BT",
      ),
    );
    print("Firebase initialized successfully.");
  } catch (e) {
    print("Error initializing Firebase: $e");
  }
}

Future<void> _initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (response) {
      NotificationHandler.handleNotificationResponse(response, () {
        taskPageKey.currentState?.fetchTasksFromFirestore();
      });
    },
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AttentionLens',
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  Future<void> _initializeUserNotifications() async {
    await NotificationService.scheduleDailyMotivationalNotification();
    await NotificationService.scheduleCombinedReminderForIncompleteTasks();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null && user.emailVerified) {
            _initializeUserNotifications();
            return HomePage();
          } else {
            return const WelcomePage();
          }
        } else {
          return const WelcomePage();
        }
      },
    );
  }
}
