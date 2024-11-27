import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_application/pages/task_page.dart';
import 'package:flutter_application/main.dart';

class NotificationHandler {
   static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> handleNotificationResponse(
      NotificationResponse response, Function refreshTasksCallback) async {
    final String? itemId = response.payload;
print('Action ID: ${response.actionId}, Payload: ${response.payload}');

    if (itemId != null) {
      switch (response.actionId) {
        case 'mark_done':
          await _markItemAsComplete(itemId);
          taskPageKey.currentState?.fetchTasksFromFirestore();      break;
        case 'snooze_5':
          await _scheduleSnoozedNotification(itemId, 5);
          break;
        default:
          print("Unknown action: ${response.actionId}");
      }
    } else {
      print("Item ID is missing from the notification payload.");
    }
  }


  static Future<void> _markItemAsComplete(String itemId) async {
    try {
      print("Marking item as complete. Item ID: $itemId");

      final DocumentSnapshot subtaskSnapshot = await FirebaseFirestore.instance
          .collection('SubTask')
          .doc(itemId)
          .get();

      if (subtaskSnapshot.exists) {
        // Mark the subtask as complete
        await subtaskSnapshot.reference.update({'completionStatus': 1});
        print("Subtask $itemId marked as complete.");
      } else {
        final DocumentSnapshot taskSnapshot = await FirebaseFirestore.instance
            .collection('Task')
            .doc(itemId)
            .get();

        if (taskSnapshot.exists) {
          // Mark the main task as complete
          await taskSnapshot.reference.update({'completionStatus': 2});
          print("Task $itemId marked as complete.");

          // Query and mark subtasks
          final QuerySnapshot subtaskSnapshot = await FirebaseFirestore.instance
              .collection('SubTask')
              .where('taskID', isEqualTo: itemId)
              .get();

          for (var subtaskDoc in subtaskSnapshot.docs) {
            await subtaskDoc.reference.update({'completionStatus': 1});
            print(
                "Subtask ${subtaskDoc.id} of Task $itemId marked as complete.");
          }
        } else {
          print("No task or subtask found with ID: $itemId");
        }
      }
    } catch (e) {
      print("Error updating completion status for $itemId: $e");
    }
  }



  static Future<void> _scheduleSnoozedNotification(
      String itemId, int minutes) async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Ensure timezone is initialized
    final scheduledTime =
        tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      itemId.hashCode,
      "Snoozed Reminder",
      "Snoozed notification for item",
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_channel',
          'Task Reminders',
          channelDescription: 'Task reminders with snooze options',
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    print("Snoozed notification scheduled for $minutes minutes later.");
  }

  static Future<void> debugPendingNotifications() async {
    final List<PendingNotificationRequest> pendingNotifications =
        await _flutterLocalNotificationsPlugin.pendingNotificationRequests();

    print("Pending Notifications:");
    for (var notification in pendingNotifications) {
      print("ID: ${notification.id}, Title: ${notification.title}");
    }
  }

static Future<void> cancelNotification(String taskId) async {
    final int notificationId = taskId.hashCode;

    try {
      await _flutterLocalNotificationsPlugin.cancel(notificationId);
      print("Notification with ID $notificationId canceled successfully.");
    } catch (e) {
      print("Failed to cancel notification with ID $notificationId: $e");
    }

    // Debug remaining notifications
    await debugPendingNotifications();
  }



  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      print("All notifications canceled.");
    } catch (e) {
      print("Failed to cancel all notifications: $e");
    }
  }
  
}
