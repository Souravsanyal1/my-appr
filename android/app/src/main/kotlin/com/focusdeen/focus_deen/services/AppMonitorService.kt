package com.focusdeen.focus_deen.services

import android.content.Context
import java.util.concurrent.ConcurrentHashMap

data class LimitConfig(
    val packageName: String,
    val appName: String,
    val dailyLimitMinutes: Int,
    val warningThresholdMinutes: Int,
    val mode: String, // "block" or "warning"
    val isEnabled: Boolean
)

data class UnlockSession(
    val packageName: String,
    val expiresAtMillis: Long,
    val durationMinutes: Int
)

class AppMonitorService private constructor(private val context: Context) {

    private val usageStatsService = UsageStatsService(context)
    private val notificationService = NotificationService(context)

    // In-memory cache for active limits
    val limitsMap = ConcurrentHashMap<String, LimitConfig>()
    // In-memory cache for active temporary unlock sessions
    val unlockSessionsMap = ConcurrentHashMap<String, UnlockSession>()
    // Track warnings sent today so we don't spam notifications
    private val warningsSentToday = ConcurrentHashMap<String, Long>()

    companion object {
        @Volatile
        private var INSTANCE: AppMonitorService? = null

        fun getInstance(context: Context): AppMonitorService {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: AppMonitorService(context.applicationContext).also { INSTANCE = it }
            }
        }
    }

    fun syncLimits(limits: List<LimitConfig>) {
        limitsMap.clear()
        for (limit in limits) {
            if (limit.isEnabled) {
                limitsMap[limit.packageName] = limit
            }
        }
    }

    fun setTemporaryUnlock(packageName: String, durationMinutes: Int) {
        val expiresAt = System.currentTimeMillis() + (durationMinutes * 60 * 1000L)
        unlockSessionsMap[packageName] = UnlockSession(packageName, expiresAt, durationMinutes)
    }

    fun removeTemporaryUnlock(packageName: String) {
        unlockSessionsMap.remove(packageName)
    }

    fun isTemporarilyUnlocked(packageName: String): Boolean {
        val session = unlockSessionsMap[packageName] ?: return false
        if (System.currentTimeMillis() < session.expiresAtMillis) {
            return true
        } else {
            // Expired, remove it
            unlockSessionsMap.remove(packageName)
            return false
        }
    }

    fun getActiveUnlockSessions(): List<UnlockSession> {
        val now = System.currentTimeMillis()
        val active = mutableListOf<UnlockSession>()
        val iterator = unlockSessionsMap.entries.iterator()
        while (iterator.hasNext()) {
            val entry = iterator.next()
            if (entry.value.expiresAtMillis > now) {
                active.add(entry.value)
            } else {
                iterator.remove()
            }
        }
        return active
    }

    sealed class CheckResult {
        object Allowed : CheckResult()
        data class Warning(val appName: String, val minutesLeft: Int) : CheckResult()
        data class Blocked(val appName: String, val usedMinutes: Int, val limitMinutes: Int) : CheckResult()
    }

    fun checkPackage(packageName: String): CheckResult {
        val limit = limitsMap[packageName] ?: return CheckResult.Allowed

        // If currently temporarily unlocked, allow!
        if (isTemporarilyUnlocked(packageName)) {
            return CheckResult.Allowed
        }

        val usedMinutes = usageStatsService.getTodayUsageMinutes(packageName).toInt()

        // Check if limit exceeded
        if (usedMinutes >= limit.dailyLimitMinutes) {
            return CheckResult.Blocked(limit.appName, usedMinutes, limit.dailyLimitMinutes)
        }

        // Check if within warning threshold
        val minutesLeft = limit.dailyLimitMinutes - usedMinutes
        if (minutesLeft <= limit.warningThresholdMinutes && minutesLeft > 0) {
            // Check if warning already sent in the last 15 minutes
            val lastSent = warningsSentToday[packageName] ?: 0L
            val now = System.currentTimeMillis()
            if (now - lastSent > 15 * 60 * 1000L) {
                warningsSentToday[packageName] = now
                notificationService.showLimitWarning(packageName, limit.appName, minutesLeft)
            }
            return CheckResult.Warning(limit.appName, minutesLeft)
        }

        return CheckResult.Allowed
    }
}
