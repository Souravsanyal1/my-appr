package com.focusdeen.focus_deen.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.focusdeen.focus_deen.services.AppMonitorService

class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action == Intent.ACTION_BOOT_COMPLETED || action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            val monitor = AppMonitorService.getInstance(context)
            val activeSessions = monitor.getActiveUnlockSessions()
            val now = System.currentTimeMillis()

            for (session in activeSessions) {
                if (session.expiresAtMillis > now) {
                    RelockScheduler.scheduleRelock(
                        context,
                        session.packageName,
                        session.expiresAtMillis
                    )
                } else {
                    monitor.removeTemporaryUnlock(session.packageName)
                }
            }
        }
    }
}
