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

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onDestroy() {
        super.onDestroy()
        if (instance == this) {
            instance = null
        }
    }

    override fun onInterrupt() {
        // Accessibility interrupted
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            return
        }

        val pkgCharSequence = event.packageName ?: return
        val currentPackage = pkgCharSequence.toString()

        // Ignore our own app and common Android system overlays
        if (currentPackage == packageName ||
            currentPackage == "com.android.systemui" ||
            currentPackage.contains("launcher") ||
            currentPackage.contains("inputmethod")
        ) {
            return
        }

        if (currentPackage != lastForegroundPackage) {
            lastForegroundPackage = currentPackage

            // 1. Notify listeners (for Flutter EventChannel)
            mainHandler.post {
                onForegroundAppChangedListener?.invoke(currentPackage)
            }

            // 2. Perform Limit / Block check
            val monitor = AppMonitorService.getInstance(applicationContext)
            when (val check = monitor.checkPackage(currentPackage)) {
                is AppMonitorService.CheckResult.Blocked -> {
                    // Send to Flutter event channel
                    mainHandler.post {
                        onAppBlockedListener?.invoke(
                            currentPackage,
                            check.appName,
                            check.usedMinutes,
                            check.limitMinutes
                        )
                    }

                    // Kick user out of restricted app immediately
                    performGlobalAction(GLOBAL_ACTION_HOME)

                    // Launch FocusDeen Blocked Screen
                    val blockIntent = Intent(applicationContext, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        putExtra("route", "/blocked")
                        putExtra("packageName", currentPackage)
                        putExtra("appName", check.appName)
                        putExtra("usedMinutes", check.usedMinutes)
                        putExtra("limitMinutes", check.limitMinutes)
                    }
                    startActivity(blockIntent)
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
}
