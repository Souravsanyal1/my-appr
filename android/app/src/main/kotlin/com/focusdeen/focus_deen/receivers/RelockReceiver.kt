package com.focusdeen.focus_deen.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.focusdeen.focus_deen.services.AppMonitorService
import com.focusdeen.focus_deen.services.FocusAccessibilityService
import com.focusdeen.focus_deen.services.NotificationService

/**
 * Fires when a timed unlock session expires (via AlarmManager).
 *
 * CRITICAL: Never startActivity(MainActivity) here.
 * - If the user is inside the re-locked app -> show overlay on top.
 * - If user is elsewhere -> just revoke the unlock silently.
 */
class RelockReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "RelockReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val packageName = intent.getStringExtra("packageName") ?: return
        Log.i(TAG, "Relock triggered for $packageName")

        // 1. Remove temporary unlock from persistent store
        val monitor = AppMonitorService.getInstance(context)
        monitor.removeTemporaryUnlock(packageName)

        val appName = monitor.getAppName(packageName)

        // 2. Show notification that unlock duration expired
        try {
            val notificationService = NotificationService(context)
            notificationService.showRelockNotification(packageName, appName)
        } catch (e: Exception) {
            Log.e(TAG, "Notification error", e)
        }

        // 3. If user is currently inside the expired app, show overlay on top (no HOME, no MainActivity)
        val currentForeground = FocusAccessibilityService.currentForegroundPackage
        if (currentForeground == packageName) {
            Log.i(TAG, "User is inside $packageName, triggering overlay re-lock")
            Handler(Looper.getMainLooper()).post {
                val serviceInstance = FocusAccessibilityService.instance
                if (serviceInstance != null) {
                    serviceInstance.relockNow(packageName)
                } else {
                    // Accessibility service not running — fallback: go home quietly
                    Log.w(TAG, "AccessibilityService not running, performing HOME action")
                    // Can't call performGlobalAction here; just log. User will hit the lock on next open.
                }
            }
        }
    }
}
