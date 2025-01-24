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

    // تحقق من إذن Overlay عند بدء التطبيق
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
        val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
        Toast.makeText(
            this,
            "Please grant overlay permission for the app to function properly.",
            Toast.LENGTH_LONG
        ).show()
    }

    createNotificationChannel()
}

    private fun checkAndRequestPermissions(): Boolean {
    val hasAccessibilityPermission = checkAccessibilityPermission()
    val hasOverlayPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        Settings.canDrawOverlays(this)
    } else true

    if (!hasAccessibilityPermission) {
        requestAccessibilityPermission()
        Toast.makeText(
            this,
            "Accessibility permission is required for app blocking.",
            Toast.LENGTH_LONG
        ).show()
        return false
    }

    if (!hasOverlayPermission) {
        val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
        startActivity(intent)
        Toast.makeText(
            this,
            "Overlay permission is required for app blocking.",
            Toast.LENGTH_LONG
        ).show()
        return false
    }

    return true
}
private fun checkAccessibilityPermission(): Boolean {
    val accessibilityEnabled = Settings.Secure.getInt(
        contentResolver,
        Settings.Secure.ACCESSIBILITY_ENABLED,
        0
    )
    return accessibilityEnabled == 1
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
                    "stopBlocking" -> {
                        stopBlockingApps()
                        result.success("Blocking stopped successfully.")
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun createNotificationChannel() {
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

    private fun stopBlockingApps() {
        val sharedPreferences = getSharedPreferences("AppBlockerPrefs", Context.MODE_PRIVATE)
        val editor = sharedPreferences.edit()
        editor.remove("blockedApps")
        editor.apply()

        Toast.makeText(
            this,
            "Blocking has been stopped. All apps are now accessible.",
            Toast.LENGTH_SHORT
        ).show()
    }

    private fun requestAccessibilityPermission() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        startActivity(intent)
        Toast.makeText(
            this,
            "Please enable Accessibility Permission for this feature.",
            Toast.LENGTH_LONG
        ).show()
    }
}
