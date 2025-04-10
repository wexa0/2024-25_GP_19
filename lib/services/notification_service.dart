import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  
  static Future<void> scheduleDailyMotivationalNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('motivation_enabled') ?? true;

    if (!isEnabled) {
      print("Motivational notifications are turned off.");
      return;
    }

    const List<String> motivationalMessages = [
      "Check your tasks and crush your goals today!",
      "Stay focused! A small step today brings big results tomorrow.",
      "Your tasks are waiting. Organize your day and make it count!",
      "Little wins every day add up to big successes. Start now!",
      "You've got this! Your productive day starts here.",
      "Keep it simple: Plan, focus, and achieve. Let's go!",
      "It's task time! Take control and make your day productive.",
      "Big journeys begin with small steps. Start with your tasks now!",
      "Your day is waiting! Check your tasks, stay focused, and take a step toward completing your goals. Let’s make today productive!",
    ];

    final random = Random();
    final String chosenMessage =
        motivationalMessages[random.nextInt(motivationalMessages.length)];

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'daily_motivation_channel',
      'Daily Motivation',
      channelDescription: 'Daily motivational reminders for ADHD users',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    final tz.TZDateTime scheduledTime =
        await _getUserScheduledMotivationalTime();

    print("Scheduled motivational notification for: $scheduledTime");

    flutterLocalNotificationsPlugin
        .zonedSchedule(
      0,
      'Start Your Day Right!',
      chosenMessage,
      scheduledTime,
      platformChannelSpecifics,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    )
        .then((_) {
      print("Motivational notification scheduled.");
    }).catchError((error) {
      print("Error scheduling motivational notification: $error");
    });
  }

  static Future<void> scheduleCombinedReminderForIncompleteTasks() async {
  final prefs = await SharedPreferences.getInstance();
  final isEnabled = prefs.getBool('task_reminder_enabled') ?? true;

  if (!isEnabled) {
    print("Task reminder notifications are turned off.");
    return;
  }

  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final startOfTomorrow = startOfToday.add(Duration(days: 1));

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('userID', isEqualTo: userId)
        .where('completionStatus', isNotEqualTo: 2)
        .get();

    // 🔍 Filter for tasks scheduled today
    final todayTasks = snapshot.docs.where((doc) {
      final timestamp = doc['scheduledDate'];
      if (timestamp is! Timestamp) return false;
      final scheduled = timestamp.toDate();
      return scheduled.isAfter(startOfToday) && scheduled.isBefore(startOfTomorrow);
    }).toList();

    if (todayTasks.isNotEmpty) {
      final taskTitles =
          todayTasks.map((doc) => doc['title'] as String).toList();

      final message = taskTitles.length > 3
          ? 'You have ${taskTitles.length} unfinished tasks today: ${taskTitles.sublist(0, 3).join(', ')}, and more.'
          : 'Today\'s unfinished tasks: ${taskTitles.join(', ')}. You can do it!';

      final scheduledTime = await _getUserScheduledMissedTaskTime();
      _scheduleCombinedNotification(scheduledTime, message);
    } else {
      print("No unfinished tasks for today.");
    }
  } catch (error) {
    print("Error fetching today's incomplete tasks: $error");
  }
}


  static Future<void> _scheduleCombinedNotification(
      DateTime notificationTime, String message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'overdue_tasks_channel',
      'Overdue Tasks',
      channelDescription: 'Reminders for overdue tasks',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      'Task Reminder',
      message,
      tz.TZDateTime.from(notificationTime, tz.local),
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<tz.TZDateTime> _getUserScheduledMotivationalTime() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTime = prefs.getString('motivational_time') ?? '8:0';
    final parts = savedTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(Duration(days: 1));
    }
    return scheduled;
  }

  static Future<tz.TZDateTime> _getUserScheduledMissedTaskTime() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTime = prefs.getString('task_reminder_time') ?? '21:0';
    final parts = savedTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(Duration(days: 1));
    }
    return scheduled;
  }
  static Future<void> cancelMotivationalNotification() async {
  try {
    await flutterLocalNotificationsPlugin.cancel(0); // 0 is the ID used for motivation
    print("Motivational notification cancelled.");
  } catch (e) {
    print("Error cancelling motivational notification: $e");
  }
}

static Future<void> cancelTaskReminderNotification() async {
  try {
    await flutterLocalNotificationsPlugin.cancel(1); // 1 is the ID used for task reminder
    print("Task reminder notification cancelled.");
  } catch (e) {
    print("Error cancelling task reminder notification: $e");
  }
}

}
