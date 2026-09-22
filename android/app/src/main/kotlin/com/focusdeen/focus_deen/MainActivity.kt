package com.focusdeen.focus_deen

import android.content.Intent
import android.os.Bundle
import com.focusdeen.focus_deen.channels.FocusDeenEventChannel
import com.focusdeen.focus_deen.channels.FocusDeenMethodChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private var methodChannel: FocusDeenMethodChannel? = null
    private var eventChannel: FocusDeenEventChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = FocusDeenMethodChannel(this).apply {
            register(flutterEngine.dartExecutor.binaryMessenger)
        }

        eventChannel = FocusDeenEventChannel().apply {
            register(flutterEngine.dartExecutor.binaryMessenger)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        methodChannel?.unregister()
        eventChannel?.unregister()
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleRouteIntent(intent)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleRouteIntent(intent)
    }

    private fun handleRouteIntent(intent: Intent?) {
        val route = intent?.getStringExtra("route")
        val blockedPkg = intent?.getStringExtra("blocked_pkg") ?: intent?.getStringExtra("packageName") ?: ""
        if (route == "/blocked" || (blockedPkg.isNotEmpty() && intent?.hasExtra("blocked_pkg") == true)) {
            val appName = intent?.getStringExtra("appName") ?: ""
            val usedMinutes = intent?.getIntExtra("usedMinutes", 0) ?: 0
            val limitMinutes = intent?.getIntExtra("limitMinutes", 0) ?: 0

            flutterEngine?.navigationChannel?.pushRoute(
                "/blocked?package=$blockedPkg&appName=$appName&used=$usedMinutes&limit=$limitMinutes"
            )
        }
    }
}
