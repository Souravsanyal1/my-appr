package com.focusdeen.focus_deen.services

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent
import com.focusdeen.focus_deen.MainActivity

class FocusAccessibilityService : AccessibilityService() {

    companion object {
        @Volatile
        var instance: FocusAccessibilityService? = null
            private set

        @Volatile
        var currentForegroundPackage: String? = null

        var onForegroundAppChangedListener: ((String) -> Unit)? = null
        var onAppBlockedListener: ((packageName: String, appName: String, usedMinutes: Int, limitMinutes: Int) -> Unit)? = null
        var onLimitWarningListener: ((packageName: String, appName: String, minutesLeft: Int) -> Unit)? = null

        fun isRunning(): Boolean = instance != null

        fun closeCurrentApp(): Boolean {
            return instance?.performGlobalAction(GLOBAL_ACTION_HOME) ?: false
        }
    }

    private var lastForegroundPackage: String? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var isEnforcingBlock = false

    // Periodic ticker to check if the active app's temporary unlock session has expired
    private val autoLockTicker = object : Runnable {
        override fun run() {
            try {
                val currentPkg = currentForegroundPackage
                if (currentPkg != null && !isSystemOrOwnPackage(currentPkg)) {
                    val monitor = AppMonitorService.getInstance(applicationContext)
                    val check = monitor.checkPackage(currentPkg)
                    if (check is AppMonitorService.CheckResult.Blocked) {
                        enforceBlock(currentPkg, check)
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
            mainHandler.postDelayed(this, 1500L)
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        mainHandler.removeCallbacks(autoLockTicker)
        mainHandler.postDelayed(autoLockTicker, 1500L)
    }

    override fun onDestroy() {
        mainHandler.removeCallbacks(autoLockTicker)
        super.onDestroy()
        if (instance == this) {
            instance = null
            currentForegroundPackage = null
            lastForegroundPackage = null
        }
    }

    override fun onInterrupt() {
        // Accessibility interrupted
    }

    private fun isSystemOrOwnPackage(pkg: String): Boolean {
        val lower = pkg.lowercase()
        return pkg == packageName ||
            lower == "com.android.systemui" ||
            lower.contains("launcher") ||
            lower.contains("inputmethod") ||
            lower.contains("systemui") ||
            lower == "android"
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            return
        }

        val pkgCharSequence = event.packageName ?: return
        val currentPackage = pkgCharSequence.toString()

        // If user is at launcher, lock screen, keyboard, or inside FocusDeen:
        // Reset tracked packages so opening the app again triggers detection
        if (isSystemOrOwnPackage(currentPackage)) {
            currentForegroundPackage = null
            lastForegroundPackage = null
            return
        }

        if (currentPackage != lastForegroundPackage) {
            lastForegroundPackage = currentPackage
            currentForegroundPackage = currentPackage

            // 1. Notify listeners (for Flutter EventChannel)
            mainHandler.post {
                onForegroundAppChangedListener?.invoke(currentPackage)
            }

            // 2. Perform Limit / Block check
            val monitor = AppMonitorService.getInstance(applicationContext)
            when (val check = monitor.checkPackage(currentPackage)) {
                is AppMonitorService.CheckResult.Blocked -> {
                    enforceBlock(currentPackage, check)
                }
                is AppMonitorService.CheckResult.Warning -> {
                    mainHandler.post {
                        onLimitWarningListener?.invoke(
                            currentPackage,
                            check.appName,
                            check.minutesLeft
                        )
                    }
                }
                AppMonitorService.CheckResult.Allowed -> {
                    // App allowed
                }
            }
        }
    }

    private fun enforceBlock(currentPackage: String, check: AppMonitorService.CheckResult.Blocked) {
        if (isEnforcingBlock) return
        isEnforcingBlock = true

        // 1. Kick user out of restricted app immediately
        performGlobalAction(GLOBAL_ACTION_HOME)
        currentForegroundPackage = null
        lastForegroundPackage = null

        // 2. Notify Flutter event channel
        mainHandler.post {
            onAppBlockedListener?.invoke(
                currentPackage,
                check.appName,
                check.usedMinutes,
                check.limitMinutes
            )
        }

        // 3. Show lock notification
        try {
            val notificationService = NotificationService(applicationContext)
            notificationService.showLockNotification(currentPackage, check.appName)
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // 4. Launch FocusDeen Blocked Screen
        try {
            val blockIntent = Intent(applicationContext, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("route", "/blocked")
                putExtra("packageName", currentPackage)
                putExtra("appName", check.appName)
                putExtra("usedMinutes", check.usedMinutes)
                putExtra("limitMinutes", check.limitMinutes)
            }
            startActivity(blockIntent)
        } catch (e: Exception) {
            e.printStackTrace()
        }

        mainHandler.postDelayed({
            isEnforcingBlock = false
        }, 1200L)
    }
}
