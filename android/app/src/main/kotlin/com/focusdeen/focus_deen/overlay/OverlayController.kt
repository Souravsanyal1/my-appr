package com.focusdeen.focus_deen.overlay

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.KeyEvent
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.TextView
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterTextureView
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

/**
 * Protected app er UPORE full-screen Flutter lock/deed UI dekhay.
 * MainActivity kokhono launch kore na.
 *
 * Lifecycle: prewarm() -> show(pkg) -> (pass | cancel | package change) -> dismiss() -> release()
 * Sob kichu main thread e chalate hobe (AccessibilityService callbacks already main thread).
 */
class OverlayController(
    private val service: AccessibilityService,
    private val callbacks: Callbacks,
) {
    interface Callbacks {
        /** Score >= minScore hole. Store + alarm + event ekhane korben. */
        fun onUnlock(pkg: String, scorePercent: Int)

        /** Fail / back / cancel. Overlay already remove hoyeche ar HOME pathano hoyeche. */
        fun onCancel(pkg: String)

        /** Overlay boshano ba Flutter render korte parlo na. LockActivity / HOME fallback e jan. */
        fun onOverlayFailed(pkg: String, reason: String)
    }

    companion object {
        private const val TAG = "OverlayController"
        const val CHANNEL = "deenflow/lock_overlay"
        const val ENGINE_ID = "deenflow_lock_overlay_engine"
        private const val DART_ENTRYPOINT = "lockOverlayMain"
        private const val FIRST_FRAME_TIMEOUT_MS = 3000L
        private const val COVER_COLOR = "#E606120E"
    }

    private val main = Handler(Looper.getMainLooper())
    private val wm = service.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val audio = service.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    private var engine: FlutterEngine? = null
    private var channel: MethodChannel? = null
    private var dartReady = false
    private var pendingShowArgs: Map<String, Any?>? = null

    private var root: KeyFrameLayout? = null
    private var cover: View? = null
    private var flutterView: FlutterView? = null

    private var currentPkg: String? = null
    private var currentMinScore: Int = 80
    private var focusRequest: AudioFocusRequest? = null

    private val watchdog = Runnable {
        val pkg = currentPkg ?: return@Runnable
        Log.w(TAG, "Flutter first frame delayed for $pkg — revealing content, never auto-backing")
        // Never dismiss to home! Keep overlay displayed over the app.
        cover?.visibility = View.GONE
    }

    val isShowing: Boolean get() = root != null
    fun isShowingFor(pkg: String): Boolean = root != null && currentPkg == pkg

    // ---------------------------------------------------------------- engine

    /** Service connect hole ekbar call korun, tahole overlay tatkhonik khole. */
    fun prewarm() {
        if (engine != null) return
        val loader = FlutterInjector.instance().flutterLoader()
        if (!loader.initialized()) {
            loader.startInitialization(service.applicationContext)
        }
        loader.ensureInitializationComplete(service.applicationContext, null)

        val e = FlutterEngine(service.applicationContext)
        val bundle = loader.findAppBundlePath()
        e.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint(bundle, DART_ENTRYPOINT))
        // NOTE: Activity-dependent plugin (permission_handler request, etc.) service e kaj korbe na.
        GeneratedPluginRegistrant.registerWith(e)

        channel = MethodChannel(e.dartExecutor.binaryMessenger, CHANNEL).also {
            it.setMethodCallHandler(::onDartCall)
        }
        // LockActivity fallback ei engine ta reuse korte pare.
        FlutterEngineCache.getInstance().put(ENGINE_ID, e)
        engine = e
    }

    // ------------------------------------------------------------------ show

    fun show(pkg: String, appLabel: String, minScore: Int, durationMinutes: Int) {
        if (isShowingFor(pkg)) return // ekhoni ei app er jonno dekhano hocche, flicker korbe na
        if (isShowing) removeWindowOnly() // onno protected app e switch korle

        prewarm()
        val e = engine ?: return callbacks.onOverlayFailed(pkg, "no_engine")

        currentPkg = pkg
        currentMinScore = minScore

        val container = KeyFrameLayout(service) { onBackPressed() }.apply {
            setBackgroundColor(Color.parseColor(COVER_COLOR))
            isFocusable = true
            isFocusableInTouchMode = true
            setOnTouchListener { _, _ -> true } // pichone kono tap jabe na
        }

        val fv = FlutterView(service, FlutterTextureView(service))
        container.addView(
            fv,
            FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT),
        )

        // Flutter frame ready howar age native branded cover (protected app er content jeno na dekha jay)
        val coverView = FrameLayout(service).apply {
            setBackgroundColor(Color.parseColor(COVER_COLOR))
            addView(
                TextView(service).apply {
                    text = "DeenFlow"
                    setTextColor(Color.parseColor("#1FE08F"))
                    textSize = 28f
                    gravity = Gravity.CENTER
                },
                FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                    Gravity.CENTER,
                ),
            )
        }
        container.addView(
            coverView,
            FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT),
        )

        if (!addWindow(container)) {
            currentPkg = null
            callbacks.onOverlayFailed(pkg, "add_view_failed")
            return
        }

        root = container
        cover = coverView
        flutterView = fv
        fv.attachToFlutterEngine(e)
        e.lifecycleChannel.appIsResumed()
        container.requestFocus()
        requestAudioFocus()

        val args = mapOf(
            "package" to pkg,
            "label" to appLabel,
            "minScore" to minScore,
            "durationMinutes" to durationMinutes,
        )
        if (dartReady) channel?.invokeMethod("onShow", args) else pendingShowArgs = args

        main.removeCallbacks(watchdog)
        main.postDelayed(watchdog, FIRST_FRAME_TIMEOUT_MS)
    }

    // --------------------------------------------------------------- dismiss

    fun dismiss() {
        main.removeCallbacks(watchdog)
        removeWindowOnly()
        currentPkg = null
        pendingShowArgs = null
        abandonAudioFocus()
    }

    /** Foreground package badle gele service eta call korbe. */
    fun onForegroundPackageChanged(newPkg: String) {
        val showing = currentPkg ?: return
        if (newPkg != showing) dismiss()
    }

    fun release() {
        dismiss()
        channel?.setMethodCallHandler(null)
        channel = null
        engine?.destroy()
        engine = null
        dartReady = false
        FlutterEngineCache.getInstance().remove(ENGINE_ID)
    }

    private fun removeWindowOnly() {
        val r = root ?: return
        try {
            flutterView?.detachFromFlutterEngine()
            engine?.lifecycleChannel?.appIsPaused()
        } catch (t: Throwable) {
            Log.w(TAG, "detach failed", t)
        }
        try {
            wm.removeView(r)
        } catch (_: IllegalArgumentException) {
            // view already removed
        } finally {
            root = null
            cover = null
            flutterView = null
        }
    }

    // --------------------------------------------------------- Dart -> native

    private fun onDartCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "engineReady" -> {
                dartReady = true
                pendingShowArgs?.let { channel?.invokeMethod("onShow", it) }
                pendingShowArgs = null
                result.success(null)
            }
            "shown" -> { // Flutter er prothom real frame draw hoyeche
                main.removeCallbacks(watchdog)
                cover?.visibility = View.GONE
                result.success(null)
            }
            "unlockAndDismiss" -> {
                val pkg = currentPkg
                val score = call.argument<Int>("score") ?: 0
                // Capture minScore before dismiss clears it
                val minScoreSnapshot = currentMinScore
                dismiss()
                if (pkg != null) {
                    if (score >= minScoreSnapshot) callbacks.onUnlock(pkg, score) else goHome(pkg)
                }
                result.success(null)
            }
            "cancelAndGoHome" -> {
                goHome(currentPkg)
                result.success(null)
            }
            "dismiss" -> {
                dismiss()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun onBackPressed() {
        // Back = cancel = HOME (user kokhono atke thakbe na)
        goHome(currentPkg)
    }

    private fun goHome(pkg: String?) {
        dismiss()
        service.performGlobalAction(AccessibilityService.GLOBAL_ACTION_HOME)
        if (pkg != null) callbacks.onCancel(pkg)
    }

    // ---------------------------------------------------------------- window

    private fun addWindow(view: View): Boolean {
        val types = mutableListOf<Int>()
        if (Build.VERSION.SDK_INT >= 26 && Settings.canDrawOverlays(service)) {
            types += WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        }
        if (Build.VERSION.SDK_INT >= 22) {
            types += WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
        }
        for (type in types) {
            try {
                wm.addView(view, layoutParams(type))
                Log.i(TAG, "Successfully attached overlay with type=$type")
                return true
            } catch (t: Throwable) {
                Log.w(TAG, "addView failed for type=$type", t)
            }
        }
        return false
    }

    private fun layoutParams(type: Int): WindowManager.LayoutParams {
        // FLAG_NOT_FOCUSABLE deliberately NEI: Back key ar keyboard lagbe.
        val flags = WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON

        return WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            type,
            flags,
            PixelFormat.TRANSLUCENT,
        ).apply {
            softInputMode = WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE
            if (Build.VERSION.SDK_INT >= 30) {
                layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
            } else if (Build.VERSION.SDK_INT >= 28) {
                layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            }
        }
    }

    // ----------------------------------------------------------- audio focus

    /** Pichoner TikTok/YouTube er sound/video pause korte chay (kichu app ignore korte pare). */
    private fun requestAudioFocus() {
        if (Build.VERSION.SDK_INT >= 26) {
            val req = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build(),
                )
                .setOnAudioFocusChangeListener { }
                .build()
            audio.requestAudioFocus(req)
            focusRequest = req
        } else {
            @Suppress("DEPRECATION")
            audio.requestAudioFocus(null, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN)
        }
    }

    private fun abandonAudioFocus() {
        if (Build.VERSION.SDK_INT >= 26) {
            focusRequest?.let { audio.abandonAudioFocusRequest(it) }
            focusRequest = null
        } else {
            @Suppress("DEPRECATION")
            audio.abandonAudioFocus(null)
        }
    }

    /** Back key intercept korar jonno. */
    private class KeyFrameLayout(
        context: Context,
        private val onBack: () -> Unit,
    ) : FrameLayout(context) {
        override fun dispatchKeyEvent(event: KeyEvent): Boolean {
            if (event.keyCode == KeyEvent.KEYCODE_BACK) {
                if (event.action == KeyEvent.ACTION_UP) onBack()
                return true
            }
            return super.dispatchKeyEvent(event)
        }
    }
}
