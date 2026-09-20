package com.focusdeen.focus_deen.channels

import com.focusdeen.focus_deen.services.FocusAccessibilityService
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel

class FocusDeenEventChannel : EventChannel.StreamHandler {

    companion object {
        const val CHANNEL_NAME = "com.focusdeen.app/events"
    }

    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    fun register(messenger: BinaryMessenger) {
        eventChannel = EventChannel(messenger, CHANNEL_NAME)
        eventChannel?.setStreamHandler(this)
    }

    fun unregister() {
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        eventSink = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events

        // Bind Accessibility Service callbacks
        FocusAccessibilityService.onForegroundAppChangedListener = { pkg ->
            eventSink?.success(
                mapOf(
                    "type" to "foregroundAppChanged",
                    "packageName" to pkg
                )
            )
        }

        FocusAccessibilityService.onAppBlockedListener = { pkg, name, used, limit ->
            eventSink?.success(
                mapOf(
                    "type" to "appBlocked",
                    "packageName" to pkg,
                    "appName" to name,
                    "usedMinutes" to used,
                    "limitMinutes" to limit
                )
            )
        }

        FocusAccessibilityService.onLimitWarningListener = { pkg, name, minutesLeft ->
            eventSink?.success(
                mapOf(
                    "type" to "limitWarning",
                    "packageName" to pkg,
                    "appName" to name,
                    "minutesLeft" to minutesLeft
                )
            )
        }
    }

    override fun onCancel(arguments: Any?) {
        FocusAccessibilityService.onForegroundAppChangedListener = null
        FocusAccessibilityService.onAppBlockedListener = null
        FocusAccessibilityService.onLimitWarningListener = null
        eventSink = null
    }
}
