package com.focusdeen.focus_deen.services

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.focusdeen.focus_deen.MainActivity

class NotificationService(private val context: Context) {
    companion object {
        const val CHANNEL_ID = "focus_deen_warnings"
        const val CHANNEL_NAME = "FocusDeen Limit Alerts"
        private const val NOTIFICATION_ID_BASE = 7000
    }

    init {
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifies when daily screen time limits are approaching"
                enableVibration(true)
            }
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    fun showLimitWarning(packageName: String, appName: String, minutesLeft: Int) {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/limits")
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            packageName.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("FocusDeen Alert: $appName")
            .setContentText("You have $minutesLeft minute${if (minutesLeft > 1) "s" else ""} left before your limit is reached.")
            .setStyle(NotificationCompat.BigTextStyle().bigText(
                "You have $minutesLeft minute${if (minutesLeft > 1) "s" else ""} left before $appName reaches its daily limit. Remember your intention and guard your time."
            ))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(packageName.hashCode(), notification)
    }

    fun showLockNotification(packageName: String, appName: String) {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/blocked")
            putExtra("packageName", packageName)
            putExtra("appName", appName)
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            packageName.hashCode() + 1,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentTitle("FocusDeen: $appName Locked")
            .setContentText("Time is up! $appName is locked. Recite an Islamic deed to unlock.")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(packageName.hashCode() + 100, notification)
    }
}
