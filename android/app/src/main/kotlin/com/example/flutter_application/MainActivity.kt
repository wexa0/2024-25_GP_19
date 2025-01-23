package com.example.flutter_application

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.content.Context
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.AppOpsManager
import android.content.Intent
import android.provider.Settings
import android.widget.Toast

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app_blocker_channel"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // إنشاء قناة الإشعارات
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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkPermission" -> {
                        result.success(checkUsageAccessPermission())
                    }
                    "requestPermission" -> {
                        requestUsageAccessPermission()
                        result.success(null)
                    }
                    "startBlocking" -> {
                        val blockedApps = call.argument<List<String>>("blockedApps") ?: emptyList()
                        startBlockingApps(blockedApps)
                        result.success("Blocking started for: $blockedApps")
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun checkUsageAccessPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

   private fun requestUsageAccessPermission() {
    if (!checkUsageAccessPermission()) {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        startActivity(intent)
        Toast.makeText(
            this,
            "Please enable Usage Access Permission for this feature.",
            Toast.LENGTH_LONG
        ).show()
    }
}


  private fun startBlockingApps(blockedApps: List<String>) {
    val sharedPreferences = getSharedPreferences("AppBlockerPrefs", Context.MODE_PRIVATE)
    val editor = sharedPreferences.edit()
    editor.putStringSet("blockedApps", blockedApps.toSet())
    editor.apply()
}

private fun requestAccessibilityPermission() {
    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
    startActivity(intent)
}


    }

