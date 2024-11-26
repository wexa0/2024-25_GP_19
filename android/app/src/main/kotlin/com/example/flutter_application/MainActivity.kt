package com.example.flutter_application

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.content.Context
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "task_channel",  // Channel ID
                "Task Reminders", // Channel Name
                NotificationManager.IMPORTANCE_HIGH // Importance
            ).apply {
                description = "Task reminders with customizable intervals"
            }
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
