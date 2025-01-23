package com.example.flutter_application

import android.accessibilityservice.AccessibilityService // تحديد المسار الكامل لـ AccessibilityService
import android.view.accessibility.AccessibilityEvent // تحديد المسار الكامل لـ AccessibilityEvent
import android.widget.Toast // تحديد المسار الكامل لـ Toast
import android.content.Context

class AppBlockerService : AccessibilityService() {

private val sharedPreferences by lazy {
    getSharedPreferences("AppBlockerPrefs", Context.MODE_PRIVATE)
}

override fun onAccessibilityEvent(event: AccessibilityEvent?) {
    if (event == null) return

    val packageName = event.packageName?.toString() ?: return
    val blockedApps = sharedPreferences.getStringSet("blockedApps", emptySet()) ?: emptySet()

    if (blockedApps.contains(packageName)) {
        Toast.makeText(
            this,
            "The app $packageName is blocked!",
            Toast.LENGTH_SHORT
        ).show()
        performGlobalAction(GLOBAL_ACTION_HOME)
    }
}



    override fun onInterrupt() {
        // يمكن تركه فارغًا أو إضافة منطق مخصص إذا لزم الأمر
    }
}
