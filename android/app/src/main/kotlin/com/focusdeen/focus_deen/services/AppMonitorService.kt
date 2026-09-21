package com.focusdeen.focus_deen.services

import android.content.Context
import android.content.SharedPreferences
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
    private val prefs: SharedPreferences =
        context.getSharedPreferences("focusdeen_monitor_prefs", Context.MODE_PRIVATE)

    // Set of package names that should be protected/locked by default
    val monitoredPackagesSet: MutableSet<String> = ConcurrentHashMap.newKeySet<String>()

    // In-memory cache for active limits
    val limitsMap = ConcurrentHashMap<String, LimitConfig>()
    // In-memory cache for active temporary unlock sessions
    val unlockSessionsMap = ConcurrentHashMap<String, UnlockSession>()
    // Track warnings sent today so we don't spam notifications
    private val warningsSentToday = ConcurrentHashMap<String, Long>()

    init {
        // Load persisted monitored packages from SharedPreferences
        val savedPackages = prefs.getStringSet("monitored_packages", null)
        if (savedPackages != null && savedPackages.isNotEmpty()) {
            monitoredPackagesSet.addAll(savedPackages)
        } else {
            // Default common distracting apps
            val defaults = listOf(
                "com.zhiliaoapp.musically",
                "com.ss.android.ugc.trill",
                "com.instagram.android",
                "com.facebook.katana",
                "com.google.android.youtube",
                "com.snapchat.android"
            )
            monitoredPackagesSet.addAll(defaults)
            prefs.edit().putStringSet("monitored_packages", defaults.toSet()).apply()
        }
    }

    companion object {
        @Volatile
        private var INSTANCE: AppMonitorService? = null

        fun getInstance(context: Context): AppMonitorService {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: AppMonitorService(context.applicationContext).also { INSTANCE = it }
            }
        }
    }

    fun syncMonitoredPackages(packages: List<String>) {
        monitoredPackagesSet.clear()
        monitoredPackagesSet.addAll(packages)
        prefs.edit().putStringSet("monitored_packages", packages.toSet()).apply()
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
        prefs.edit().putLong("unlock_$packageName", expiresAt).apply()
    }

    fun removeTemporaryUnlock(packageName: String) {
        unlockSessionsMap.remove(packageName)
        prefs.edit().remove("unlock_$packageName").apply()
    }

    fun isTemporarilyUnlocked(packageName: String): Boolean {
        val now = System.currentTimeMillis()

        // 1. Check in-memory session
        val memorySession = unlockSessionsMap[packageName]
        if (memorySession != null) {
            if (now < memorySession.expiresAtMillis) {
                return true
            } else {
                unlockSessionsMap.remove(packageName)
                prefs.edit().remove("unlock_$packageName").apply()
                return false
            }
        }

        // 2. Check persistent SharedPreferences (in case process restarted)
        val savedExpiry = prefs.getLong("unlock_$packageName", 0L)
        if (savedExpiry > 0L) {
            if (now < savedExpiry) {
                val remainingMinutes = (((savedExpiry - now) / 60000L).toInt()).coerceAtLeast(1)
                unlockSessionsMap[packageName] = UnlockSession(packageName, savedExpiry, remainingMinutes)
                return true
            } else {
                prefs.edit().remove("unlock_$packageName").apply()
                return false
            }
        }

        return false
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
                prefs.edit().remove("unlock_${entry.key}").apply()
                iterator.remove()
            }
        }
        return active
    }

    fun getAppName(packageName: String): String {
        return try {
            val pm = context.packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (e: Exception) {
            when (packageName) {
                "com.zhiliaoapp.musically", "com.ss.android.ugc.trill" -> "TikTok"
                "com.instagram.android" -> "Instagram"
                "com.facebook.katana" -> "Facebook"
                "com.google.android.youtube" -> "YouTube"
                "com.snapchat.android" -> "Snapchat"
                else -> packageName.substringAfterLast('.')
            }
        }
    }

    sealed class CheckResult {
        object Allowed : CheckResult()
        data class Warning(val appName: String, val minutesLeft: Int) : CheckResult()
        data class Blocked(val appName: String, val usedMinutes: Int, val limitMinutes: Int) : CheckResult()
    }

    fun checkPackage(packageName: String): CheckResult {
        val isMonitored = monitoredPackagesSet.contains(packageName)
        val limit = limitsMap[packageName]

        // If not monitored and no limit configured, allow
        if (!isMonitored && limit == null) {
            return CheckResult.Allowed
        }

        val appName = limit?.appName ?: getAppName(packageName)
        val dailyLimit = limit?.dailyLimitMinutes ?: 30
        val usedMinutes = usageStatsService.getTodayUsageMinutes(packageName).toInt()

        // 1. Monitored packages are LOCKED BY DEFAULT until an Islamic deed earns an unlock pass
        if (isMonitored) {
            if (isTemporarilyUnlocked(packageName)) {
                // If unlocked pass is active, check daily limit if configured
                if (limit != null && usedMinutes >= limit.dailyLimitMinutes) {
                    return CheckResult.Blocked(appName, usedMinutes, dailyLimit)
                }
                return CheckResult.Allowed
            } else {
                // Monitored app is currently locked: BLOCK!
                return CheckResult.Blocked(appName, usedMinutes, dailyLimit)
            }
        }

        // 2. Not monitored, but in limitsMap: check daily limit
        if (limit != null) {
            if (isTemporarilyUnlocked(packageName)) {
                return CheckResult.Allowed
            }

            if (usedMinutes >= limit.dailyLimitMinutes) {
                return CheckResult.Blocked(appName, usedMinutes, limit.dailyLimitMinutes)
            }

            // Check warning threshold
            val minutesLeft = limit.dailyLimitMinutes - usedMinutes
            if (minutesLeft <= limit.warningThresholdMinutes && minutesLeft > 0) {
                val lastSent = warningsSentToday[packageName] ?: 0L
                val now = System.currentTimeMillis()
                if (now - lastSent > 15 * 60 * 1000L) {
                    warningsSentToday[packageName] = now
                    notificationService.showLimitWarning(packageName, limit.appName, minutesLeft)
                }
                return CheckResult.Warning(limit.appName, minutesLeft)
            }
        }

        return CheckResult.Allowed
    }
}
