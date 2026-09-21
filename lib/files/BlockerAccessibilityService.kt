package com.example.deenflow.blocker // TODO: apnar package name din

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.util.Log
import android.view.accessibility.AccessibilityEvent

/**
 * Example wiring. Apnar existing service thakle seta e ei logic merge korun (notun service banaben na).
 *
 * BlockerStore e ei method gulo lagbe (apnar existing store e thakle naam mila nin):
 *   isProtected(pkg): Boolean
 *   isUnlocked(pkg): Boolean            // now < unlockedUntil (elapsedRealtime check shoho)
 *   minScore(): Int                     // Settings theke, hardcoded na
 *   durationMinutes(): Int              // Settings theke
 *   unlock(pkg, minutes): Long          // unlockedUntil return kore
 */
class BlockerAccessibilityService : AccessibilityService(), OverlayController.Callbacks {

    companion object {
        private const val TAG = "BlockerService"

        /** RelockReceiver ei instance ke bolbe: "ei package e overlay dekhao". */
        @Volatile
        var instance: BlockerAccessibilityService? = null
            private set

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

    private lateinit var store: BlockerStore
    private lateinit var overlay: OverlayController
    private var launcherPkgs: Set<String> = emptySet()

    private val screenOffReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            overlay.dismiss()
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        store = BlockerStore(this)
        overlay = OverlayController(this, this).also { it.prewarm() }
        launcherPkgs = resolveLauncherPackages()
        registerReceiver(screenOffReceiver, IntentFilter(Intent.ACTION_SCREEN_OFF))
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return

        // Nijer overlay window er event ignore (nahole overlay nijeke dismiss kore felbe)
        if (pkg == packageName) return
        if (pkg in IGNORED) return

        // Launcher e gele overlay soriye dao
        if (pkg in launcherPkgs) {
            overlay.dismiss()
            return
        }

        overlay.onForegroundPackageChanged(pkg)

        if (!store.isProtected(pkg) || store.isUnlocked(pkg)) return

        overlay.show(
            pkg = pkg,
            appLabel = labelOf(pkg),
            minScore = store.minScore(),
            durationMinutes = store.durationMinutes(),
        )
    }

    /** Unlock time sesh hole RelockReceiver eta call korbe. HOME + DeenFlow open korbe NA. */
    fun relockNow(pkg: String) {
        if (store.isProtected(pkg) && !store.isUnlocked(pkg)) {
            overlay.show(pkg, labelOf(pkg), store.minScore(), store.durationMinutes())
        }
    }

    // ---------------------------------------------- OverlayController.Callbacks

    override fun onUnlock(pkg: String, scorePercent: Int) {
        val until = store.unlock(pkg, store.durationMinutes())
        RelockScheduler.schedule(this, pkg, until) // exact alarm (setExactAndAllowWhileIdle)
        // TODO: EventChannel e "unlocked" event pathan + local log e likhun
        Log.i(TAG, "Unlocked $pkg score=$scorePercent")
        // Protected app already niche e ache, tai kono startActivity lagbe na.
    }

    override fun onCancel(pkg: String) {
        Log.i(TAG, "Cancelled for $pkg -> HOME")
        // TODO: local event log
    }

    override fun onOverlayFailed(pkg: String, reason: String) {
        Log.w(TAG, "Overlay failed for $pkg: $reason")
        // Fallback chain: 1) LockActivity (alada task, MainActivity na)  2) HOME + notification
        // TODO: LockActivity ekhane launch korun, ta na hole:
        performGlobalAction(GLOBAL_ACTION_HOME)
    }

    // ------------------------------------------------------------------ misc

    override fun onInterrupt() {
        overlay.dismiss()
    }

    override fun onDestroy() {
        instance = null
        try { unregisterReceiver(screenOffReceiver) } catch (_: IllegalArgumentException) {}
        if (::overlay.isInitialized) overlay.release()
        super.onDestroy()
    }

    private fun labelOf(pkg: String): String = try {
        packageManager.getApplicationLabel(packageManager.getApplicationInfo(pkg, 0)).toString()
    } catch (_: PackageManager.NameNotFoundException) {
        pkg
    }

    private fun resolveLauncherPackages(): Set<String> {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        return packageManager.queryIntentActivities(intent, 0)
            .map { it.activityInfo.packageName }
            .toSet()
    }
}
