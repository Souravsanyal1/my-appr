package com.focusdeen.focus_deen.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import com.focusdeen.focus_deen.MainActivity
import com.focusdeen.focus_deen.services.AppMonitorService
import com.focusdeen.focus_deen.services.FocusAccessibilityService
import com.focusdeen.focus_deen.services.NotificationService

class RelockReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val packageName = intent.getStringExtra("packageName") ?: return

        // 1. Remove temporary unlock from persistent store
        val monitor = AppMonitorService.getInstance(context)
        monitor.removeTemporaryUnlock(packageName)

        // 2. Check if the app is currently in the foreground
        val currentForeground = FocusAccessibilityService.currentForegroundPackage
        val appName = monitor.getAppName(packageName)

        // 3. Show notification that unlock duration expired
        try {
            val notificationService = NotificationService(context)
            notificationService.showLockNotification(packageName, appName)
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // 4. If user is currently inside the expired app, immediately kick to home and show DeenFlow
        if (currentForeground == packageName) {
            FocusAccessibilityService.closeCurrentApp()

            Handler(Looper.getMainLooper()).postDelayed({
                try {
                    val blockIntent = Intent(context, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP
                        putExtra("route", "/blocked")
                        putExtra("packageName", packageName)
                        putExtra("blocked_pkg", packageName)
                        putExtra("appName", appName)
                    }
                    context.startActivity(blockIntent)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }, 300L)
        }
    }
}
