package com.focusdeen.focus_deen.services

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Build
import android.os.Process
import java.util.Calendar

class UsageStatsService(private val context: Context) {

    private val usageStatsManager: UsageStatsManager? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
        } else {
            null
        }

    fun hasUsagePermission(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager ?: return false
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun getStartOfDayMillis(): Long {
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        return calendar.timeInMillis
    }

    /**
     * Aggregates usage time for all packages from midnight today until now.
     */
    fun getTodayUsageForPackages(packages: List<String>): Map<String, Long> {
        val startOfDay = getStartOfDayMillis()
        val now = System.currentTimeMillis()
        return getUsageBetween(startOfDay, now, packages)
    }

    /**
     * Gets usage in milliseconds for packages between given timestamps.
     * Uses queryUsageStats and falls back to usageEvents if needed.
     */
    fun getUsageBetween(startTime: Long, endTime: Long, packages: List<String>? = null): Map<String, Long> {
        val resultMap = mutableMapOf<String, Long>()
        if (usageStatsManager == null || !hasUsagePermission()) {
            return resultMap
        }

        try {
            val statsList: List<UsageStats> = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            ) ?: emptyList()

            for (stat in statsList) {
                val pkg = stat.packageName
                if (packages == null || packages.contains(pkg)) {
                    val totalTime = stat.totalTimeInForeground
                    val existing = resultMap[pkg] ?: 0L
                    if (totalTime > existing) {
                        resultMap[pkg] = totalTime
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        return resultMap
    }

    /**
     * Returns foreground usage in minutes for a specific package today.
     */
    fun getTodayUsageMinutes(packageName: String): Long {
        val usageMap = getTodayUsageForPackages(listOf(packageName))
        val millis = usageMap[packageName] ?: 0L
        return millis / (1000 * 60)
    }
}
