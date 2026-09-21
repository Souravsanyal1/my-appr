package com.focusdeen.focus_deen.services

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import com.focusdeen.focus_deen.overlay.OverlayController
import com.focusdeen.focus_deen.receivers.RelockScheduler

class FocusAccessibilityService : AccessibilityService(), OverlayController.Callbacks {

    companion object {
        private const val TAG = "FocusAccessibility"

        @Volatile
        var instance: FocusAccessibilityService? = null
            private set

        @Volatile
        var currentForegroundPackage: String? = null

        // Kept for backwards compatibility with FocusDeenEventChannel listeners
        var onForegroundAppChangedListener: ((String) -> Unit)? = null
        var onLimitWarningListener: ((packageName: String, appName: String, minutesLeft: Int) -> Unit)? = null
        var onAppBlockedListener: ((packageName: String, appName: String, usedMinutes: Int, limitMinutes: Int) -> Unit)? = null

        fun isRunning(): Boolean = instance != null

        fun closeCurrentApp(): Boolean {
            return instance?.performGlobalAction(GLOBAL_ACTION_HOME) ?: false
        }

        // System UI, keyboard, permission dialog: eder upor overlay dekhano jabe na.
        private val IGNORED = setOf(
            "com.android.systemui",
            "com.google.android.permissioncontroller",
            "com.android.permissioncontroller",
            "com.google.android.inputmethod.latin",
            "com.samsung.android.honeyboard",
            "com.touchtype.swiftkey",
        )
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private lateinit var overlay: OverlayController
    private var launcherPkgs: Set<String> = emptySet()

    private var lastForegroundPackage: String? = null

    private val screenOffReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (::overlay.isInitialized) overlay.dismiss()
        }
    }

    // Periodic ticker to check if the active app's temporary unlock session has expired
    private val autoLockTicker = object : Runnable {
        override fun run() {
            try {
                val currentPkg = currentForegroundPackage
                if (currentPkg != null && !isSystemOrOwnPackage(currentPkg)) {
                    val monitor = AppMonitorService.getInstance(applicationContext)
                    val check = monitor.checkPackage(currentPkg)
                    if (check is AppMonitorService.CheckResult.Blocked) {
                        if (::overlay.isInitialized && !overlay.isShowingFor(currentPkg)) {
                            showOverlayFor(currentPkg, check)
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "autoLockTicker error", e)
            }
            mainHandler.postDelayed(this, 1500L)
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        overlay = OverlayController(this, this).also { it.prewarm() }
        launcherPkgs = resolveLauncherPackages()
        registerReceiver(screenOffReceiver, IntentFilter(Intent.ACTION_SCREEN_OFF))
        mainHandler.removeCallbacks(autoLockTicker)
        mainHandler.postDelayed(autoLockTicker, 1500L)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return

        // Nijer overlay window er event ignore (nahole overlay nijeke dismiss kore felbe)
        if (pkg == packageName) return
        if (pkg in IGNORED) return

        // Launcher e gele overlay soriye dao
        if (pkg in launcherPkgs) {
            currentForegroundPackage = null
            lastForegroundPackage = null
            if (::overlay.isInitialized) overlay.dismiss()
            return
        }

        if (pkg != lastForegroundPackage) {
            lastForegroundPackage = pkg
            currentForegroundPackage = pkg

            // Notify Flutter EventChannel listeners
            mainHandler.post {
                onForegroundAppChangedListener?.invoke(pkg)
            }

            // Notify overlay to dismiss if user changed apps
            if (::overlay.isInitialized) overlay.onForegroundPackageChanged(pkg)

            // Check if blocked
            val monitor = AppMonitorService.getInstance(applicationContext)
            when (val check = monitor.checkPackage(pkg)) {
                is AppMonitorService.CheckResult.Blocked -> {
                    showOverlayFor(pkg, check)
                }
                is AppMonitorService.CheckResult.Warning -> {
                    mainHandler.post {
                        onLimitWarningListener?.invoke(pkg, check.appName, check.minutesLeft)
                    }
                }
                AppMonitorService.CheckResult.Allowed -> {
                    // App allowed
                }
            }
        }
    }

    /** Unlock time sesh hole RelockReceiver eta call korbe. HOME + DeenFlow open korbe NA. */
    fun relockNow(pkg: String) {
        val monitor = AppMonitorService.getInstance(applicationContext)
        val appName = monitor.getAppName(pkg)
        val minScore = getMinScore()
        val durationMinutes = getDurationMinutes()

        if (::overlay.isInitialized && !overlay.isShowingFor(pkg)) {
            overlay.show(pkg, appName, minScore, durationMinutes)
        }
    }

    // ---------------------------------------------------------------- overlay helpers

    private fun showOverlayFor(pkg: String, check: AppMonitorService.CheckResult.Blocked) {
        val minScore = getMinScore()
        val durationMinutes = getDurationMinutes()

        // Notify event channel
        mainHandler.post {
            onAppBlockedListener?.invoke(pkg, check.appName, check.usedMinutes, check.limitMinutes)
        }

        // Show notifications (non-blocking info only)
        try {
            val notificationService = NotificationService(applicationContext)
            notificationService.showLockNotification(pkg, check.appName)
        } catch (e: Exception) {
            Log.e(TAG, "Notification error", e)
        }

        if (::overlay.isInitialized) {
            overlay.show(pkg, check.appName, minScore, durationMinutes)
        }
    }

    private fun getMinScore(): Int {
        // Read from SharedPreferences set by Flutter settings
        val prefs = applicationContext.getSharedPreferences("focusdeen_monitor_prefs", Context.MODE_PRIVATE)
        return prefs.getInt("min_score", 80)
    }

    private fun getDurationMinutes(): Int {
        val prefs = applicationContext.getSharedPreferences("focusdeen_monitor_prefs", Context.MODE_PRIVATE)
        return prefs.getInt("unlock_duration_minutes", 30)
    }

    // ---------------------------------------------- OverlayController.Callbacks

    override fun onUnlock(pkg: String, scorePercent: Int) {
        // Score passed: set temporary unlock in native store and schedule relock
        val monitor = AppMonitorService.getInstance(applicationContext)
        val durationMinutes = getDurationMinutes()
        monitor.setTemporaryUnlock(pkg, durationMinutes)
        Log.i(TAG, "Unlocked $pkg score=$scorePercent for ${durationMinutes}min")
        // Protected app is already in the background (beneath our overlay which is now gone)
        // No startActivity needed. The app becomes accessible naturally.
    }

    override fun onCancel(pkg: String) {
        Log.i(TAG, "Cancelled for $pkg -> HOME")
        currentForegroundPackage = null
        lastForegroundPackage = null
    }

    override fun onOverlayFailed(pkg: String, reason: String) {
        Log.w(TAG, "Overlay failed for $pkg: $reason -> HOME fallback")
        // Fallback: just go home. Never launch MainActivity.
        performGlobalAction(GLOBAL_ACTION_HOME)
        currentForegroundPackage = null
        lastForegroundPackage = null
    }

    // ------------------------------------------------------------------ misc

    override fun onInterrupt() {
        if (::overlay.isInitialized) overlay.dismiss()
    }

    override fun onDestroy() {
        mainHandler.removeCallbacks(autoLockTicker)
        instance = null
        currentForegroundPackage = null
        lastForegroundPackage = null
        try { unregisterReceiver(screenOffReceiver) } catch (_: IllegalArgumentException) {}
        if (::overlay.isInitialized) overlay.release()
        super.onDestroy()
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

    private fun resolveLauncherPackages(): Set<String> {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        return packageManager.queryIntentActivities(intent, 0)
            .map { it.activityInfo.packageName }
            .toSet()
    }

    @Suppress("unused")
    private fun labelOf(pkg: String): String = try {
        packageManager.getApplicationLabel(packageManager.getApplicationInfo(pkg, 0)).toString()
    } catch (_: PackageManager.NameNotFoundException) {
        pkg
    }
}
