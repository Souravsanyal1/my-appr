package com.focusdeen.focus_deen.channels

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Base64
import androidx.core.app.NotificationManagerCompat
import com.focusdeen.focus_deen.services.AppMonitorService
import com.focusdeen.focus_deen.services.FocusAccessibilityService
import com.focusdeen.focus_deen.services.LimitConfig
import com.focusdeen.focus_deen.services.UsageStatsService
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

class FocusDeenMethodChannel(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "com.focusdeen.app/methods"
    }

    private var channel: MethodChannel? = null
    private val usageStatsService = UsageStatsService(context)
    private val appMonitorService = AppMonitorService.getInstance(context)
    private val backgroundExecutor = Executors.newSingleThreadExecutor()

    fun register(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL_NAME)
        channel?.setMethodCallHandler(this)
    }

    fun unregister() {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getInstalledApps" -> {
                backgroundExecutor.execute {
                    try {
                        val apps = getInstalledAppsList()
                        result.success(apps)
                    } catch (e: Exception) {
                        result.error("APPS_ERROR", e.localizedMessage, null)
                    }
                }
            }

            "getAppUsage" -> {
                val packages = call.argument<List<String>>("packages") ?: emptyList()
                val startTime = call.argument<Long>("startTime")
                val endTime = call.argument<Long>("endTime") ?: System.currentTimeMillis()

                backgroundExecutor.execute {
                    try {
                        val usageMap: Map<String, Long> = if (startTime != null) {
                            usageStatsService.getUsageBetween(startTime, endTime, packages)
                        } else {
                            usageStatsService.getTodayUsageForPackages(packages)
                        }
                        result.success(usageMap)
                    } catch (e: Exception) {
                        result.error("USAGE_ERROR", e.localizedMessage, null)
                    }
                }
            }

            "checkPermissions" -> {
                val status = mapOf(
                    "usageStats" to usageStatsService.hasUsagePermission(),
                    "accessibility" to FocusAccessibilityService.isRunning(),
                    "overlay" to (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) Settings.canDrawOverlays(context) else true),
                    "notifications" to NotificationManagerCompat.from(context).areNotificationsEnabled()
                )
                result.success(status)
            }

            "requestPermission" -> {
                val permissionType = call.argument<String>("permissionType")
                try {
                    openPermissionSettings(permissionType)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("PERMISSION_ERROR", e.localizedMessage, null)
                }
            }

            "syncLimits" -> {
                val limitsList = call.argument<List<Map<String, Any>>>("limits") ?: emptyList()
                val configs = limitsList.map {
                    LimitConfig(
                        packageName = it["packageName"] as? String ?: "",
                        appName = it["appName"] as? String ?: "",
                        dailyLimitMinutes = (it["dailyLimitMinutes"] as? Number)?.toInt() ?: 30,
                        warningThresholdMinutes = (it["warningThresholdMinutes"] as? Number)?.toInt() ?: 5,
                        mode = it["mode"] as? String ?: "block",
                        isEnabled = it["isEnabled"] as? Boolean ?: true
                    )
                }
                appMonitorService.syncLimits(configs)
                result.success(true)
            }

            "setTemporaryUnlock" -> {
                val packageName = call.argument<String>("packageName") ?: ""
                val durationMinutes = call.argument<Int>("durationMinutes") ?: 5
                appMonitorService.setTemporaryUnlock(packageName, durationMinutes)
                result.success(true)
            }

            "removeTemporaryUnlock" -> {
                val packageName = call.argument<String>("packageName") ?: ""
                appMonitorService.removeTemporaryUnlock(packageName)
                result.success(true)
            }

            "getUnlockSessions" -> {
                val sessions = appMonitorService.getActiveUnlockSessions().map {
                    mapOf(
                        "packageName" to it.packageName,
                        "expiresAtMillis" to it.expiresAtMillis,
                        "durationMinutes" to it.durationMinutes
                    )
                }
                result.success(sessions)
            }

            "closeForegroundApp" -> {
                val success = FocusAccessibilityService.closeCurrentApp()
                result.success(success)
            }

            else -> result.notImplemented()
        }
    }

    private fun getInstalledAppsList(): List<Map<String, Any?>> {
        val pm = context.packageManager
        val mainIntent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }

        val resolveInfos = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(mainIntent, PackageManager.ResolveInfoFlags.of(0L))
        } else {
            @Suppress("DEPRECATION")
            pm.queryIntentActivities(mainIntent, 0)
        }

        val appList = mutableListOf<Map<String, Any?>>()
        val seenPackages = mutableSetOf<String>()

        for (resolveInfo in resolveInfos) {
            val pkg = resolveInfo.activityInfo.packageName
            if (pkg == context.packageName || seenPackages.contains(pkg)) {
                continue
            }
            seenPackages.add(pkg)

            val appName = resolveInfo.loadLabel(pm).toString()
            val isSystemApp = (resolveInfo.activityInfo.applicationInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            val iconBase64 = try {
                val drawable = resolveInfo.loadIcon(pm)
                drawableToBase64(drawable)
            } catch (e: Exception) {
                null
            }

            appList.add(
                mapOf(
                    "packageName" to pkg,
                    "appName" to appName,
                    "isSystemApp" to isSystemApp,
                    "iconBase64" to iconBase64
                )
            )
        }

        // Sort alphabetically by appName
        return appList.sortedBy { (it["appName"] as? String)?.lowercase() ?: "" }
    }

    private fun drawableToBase64(drawable: Drawable): String {
        val bitmap = if (drawable is BitmapDrawable && drawable.bitmap != null) {
            drawable.bitmap
        } else {
            val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 96
            val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 96
            val b = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(b)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            b
        }

        // Scale down to max 96x96 to keep memory & transmission fast
        val scaled = Bitmap.createScaledBitmap(bitmap, 96, 96, true)
        val stream = ByteArrayOutputStream()
        scaled.compress(Bitmap.CompressFormat.PNG, 85, stream)
        val byteArray = stream.toByteArray()
        return Base64.encodeToString(byteArray, Base64.NO_WRAP)
    }

    private fun openPermissionSettings(type: String?) {
        val intent = when (type) {
            "usageStats" -> Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            "accessibility" -> Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            "overlay" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:${context.packageName}")
                ).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK }
            } else null

            "notifications" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                    putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
            } else {
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:${context.packageName}")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
            }
            else -> null
        }

        if (intent != null) {
            context.startActivity(intent)
        }
    }
}
