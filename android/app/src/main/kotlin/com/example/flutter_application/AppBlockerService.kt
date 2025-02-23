package com.example.flutter_application

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.widget.Toast
import android.content.Context
import android.util.Log
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.provider.Settings
import android.view.LayoutInflater
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import androidx.core.app.NotificationCompat
import android.content.Intent
import android.content.pm.PackageManager

class AppBlockerService : AccessibilityService() {

  
    private val sharedPreferences by lazy {
        getSharedPreferences("AppBlockerPrefs", Context.MODE_PRIVATE)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || event.packageName == null) return

        val packageName = event.packageName.toString()
        val blockedApps = sharedPreferences.getStringSet("blockedApps", emptySet()) ?: emptySet()
        
         if (blockedApps.contains(packageName) && !isDialogVisible) {
        showBlockedAppDialog(packageName)
    }
        // الحصول على اسم التطبيق
       // الحصول على اسم التطبيق
        val appName = try {
        packageManager.getApplicationLabel(
                packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
            ).toString()
        } catch (e: PackageManager.NameNotFoundException) {
            Log.e("AppBlockerService", "Application not found for package: $packageName")
            packageName // Fallback to package name if the app name cannot be retrieved
        }


        // إذا كانت الحزمة موجودة ضمن التطبيقات المحظورة
        if (blockedApps.contains(packageName)) {
            Log.d("AppBlocker", "Blocked app detected: $appName")
            if (hasOverlayPermission()) {
                showBlockedAppDialog(appName)
            } else {
                Log.e("AppBlocker", "Overlay permission not granted!")
                performGlobalAction(GLOBAL_ACTION_HOME)
                Toast.makeText(this, "The app $appName is blocked!", Toast.LENGTH_SHORT).show()
            }
        }
    }
private var isDialogVisible = false

    // عرض نافذة مخصصة لتطبيق محظور
    private fun showBlockedAppDialog(appName: String) {

          if (isDialogVisible) return // لا تعرض النافذة إذا كانت مرئية بالفعل
    isDialogVisible = true

    val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
    val params = WindowManager.LayoutParams(
        WindowManager.LayoutParams.MATCH_PARENT,
        WindowManager.LayoutParams.MATCH_PARENT,
        WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
        android.graphics.PixelFormat.TRANSLUCENT
    )

    val view = LayoutInflater.from(this).inflate(R.layout.blocked_app_dialog, null)

    // إعداد النصوص داخل النافذة
    view.findViewById<TextView>(R.id.dialog_title).text = "Blocked App Detected"
    view.findViewById<TextView>(R.id.dialog_message).text =
        "The app $appName is currently blocked. Please focus on your task."
    view.findViewById<ImageView>(R.id.dialog_icon).setImageResource(R.drawable.ic_launcher_foreground)

    // إعداد زر OK
    view.findViewById<Button>(R.id.dialog_button).setOnClickListener {
        performGlobalAction(GLOBAL_ACTION_HOME) 
        windowManager.removeView(view) 
        isDialogVisible = false 
    }

    // عرض النافذة
    windowManager.addView(view, params)
}



    // التحقق من أذونات الـ Overlay
    private fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    // إنشاء قناة الإشعارات
   private fun createNotificationChannel() {
    try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "AppBlockerChannel",
                "App Blocker Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Running App Blocker Service"
            }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager?.createNotificationChannel(channel)
        }
    } catch (e: Exception) {
        Log.e("AppBlocker", "Error creating notification channel: ${e.message}")
    }
}

    // بدء تشغيل الخدمة في الوضع الأمامي مع إشعار
    private fun startForegroundService() {
    try {
        val notification = NotificationCompat.Builder(this, "AppBlockerChannel")
            .setContentTitle("App Blocker is Running")
            .setContentText("Blocking distracting apps")
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setOngoing(true)
            .build()

        startForeground(1, notification)
    } catch (e: Exception) {
        Log.e("AppBlocker", "Error starting foreground service: ${e.message}")
    }
}
private fun checkAccessibilityPermission(): Boolean {
    val accessibilityEnabled = Settings.Secure.getInt(
        contentResolver,
        Settings.Secure.ACCESSIBILITY_ENABLED,
        0
    )
    return accessibilityEnabled == 1
}
private fun requestAccessibilityPermission() {
    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
    startActivity(intent)
    Toast.makeText(
        this,
        "Please enable Accessibility Permission for this feature.",
        Toast.LENGTH_LONG
    ).show()
}


    override fun onServiceConnected() {
    super.onServiceConnected()

    // تحقق من إذن Overlay
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
        val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
        Toast.makeText(
            this,
            "Overlay permission is required. Please enable it in settings.",
            Toast.LENGTH_LONG
        ).show()

        stopSelf() // أوقف الخدمة إذا لم يتم منح الإذن
        return
    }

    // إذا كانت الأذونات موجودة، أكمل العملية
    createNotificationChannel()
    startForegroundService()
}


    // عند إيقاف الخدمة
    override fun onInterrupt() {
        Log.d("AppBlocker", "Service interrupted")
    }

    // بدء حظر التطبيقات
    fun startBlocking(blockedApps: Set<String>) {
        val editor = sharedPreferences.edit()
        editor.putStringSet("blockedApps", blockedApps)
        editor.apply()
        Log.d("AppBlocker", "Blocking started for apps: $blockedApps")
    }

    // إيقاف حظر التطبيقات
    fun stopBlocking() {
        val editor = sharedPreferences.edit()
        editor.remove("blockedApps")
        editor.apply()
        Log.d("AppBlocker", "Blocking stopped, all apps are unblocked")
    }

    private fun checkAllPermissions(): Boolean {
    val hasAccessibilityPermission = checkAccessibilityPermission()
    val hasOverlayPermission = hasOverlayPermission()

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

}
