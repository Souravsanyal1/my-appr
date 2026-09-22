package com.focusdeen.focus_deen.overlay

import android.accessibilityservice.AccessibilityService
import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import com.focusdeen.focus_deen.R
import com.focusdeen.focus_deen.services.AppMonitorService
import com.focusdeen.focus_deen.services.FocusAccessibilityService

/**
 * Floating timer overlay shown on top of the unlocked app.
 *
 * Displays remaining unlock time (e.g. ⏳ 29:59) in a draggable pill badge.
 * When the countdown reaches 0, automatically removes itself, revokes unlock,
 * and triggers re-lock overlay right there.
 */
class FloatingTimerController(
    private val service: AccessibilityService,
    private val onTimerExpired: (packageName: String) -> Unit,
) {
    companion object {
        private const val TAG = "FloatingTimer"
    }

    private val wm = service.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val handler = Handler(Looper.getMainLooper())

    var isShowing: Boolean = false
        private set
    var currentPkg: String? = null
        private set
    private var activeExpiresAt: Long = 0L

    private var rootView: View? = null
    private var timeTextView: TextView? = null
    private var layoutParams: WindowManager.LayoutParams? = null

    private val ticker = object : Runnable {
        override fun run() {
            val remainingMs = activeExpiresAt - System.currentTimeMillis()
            val remainingSec = (remainingMs / 1000).toInt()
            if (remainingSec <= 0) {
                val pkg = currentPkg
                Log.i(TAG, "Floating timer expired for $pkg -> trigger relock")
                dismiss()
                if (pkg != null) {
                    val monitor = AppMonitorService.getInstance(service.applicationContext)
                    monitor.removeTemporaryUnlock(pkg)
                    onTimerExpired(pkg)
                }
                return
            }

            val mins = remainingSec / 60
            val secs = remainingSec % 60
            timeTextView?.text = String.format("%02d:%02d", mins, secs)
            handler.postDelayed(this, 1000L)
        }
    }

    @SuppressLint("ClickableViewAccessibility")
    fun show(pkg: String, appName: String, expiresAtMillis: Long) {
        if (isShowing && currentPkg == pkg) {
            activeExpiresAt = expiresAtMillis
            rootView?.visibility = View.VISIBLE
            return
        }
        if (isShowing) {
            dismiss()
        }

        currentPkg = pkg
        activeExpiresAt = expiresAtMillis

        val density = service.resources.displayMetrics.density
        val displayWidth = service.resources.displayMetrics.widthPixels

        // Container Pill
        val pill = LinearLayout(service).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            val padH = (14 * density).toInt()
            val padV = (8 * density).toInt()
            setPadding(padH, padV, padH, padV)

            val bg = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 24 * density
                setColor(Color.parseColor("#E606120E"))
                setStroke((1.5 * density).toInt(), Color.parseColor("#1FE08F"))
            }
            background = bg
            elevation = 10 * density
        }

        // Timer Icon (Native Vector Drawable, no emojis)
        val iconView = ImageView(service).apply {
            setImageResource(R.drawable.ic_timer)
            val size = (16 * density).toInt()
            layoutParams = LinearLayout.LayoutParams(size, size).apply {
                marginEnd = (6 * density).toInt()
            }
        }
        pill.addView(iconView)

        // Time text
        val tv = TextView(service).apply {
            val remainingSec = ((expiresAtMillis - System.currentTimeMillis()) / 1000).coerceAtLeast(0)
            text = String.format("%02d:%02d", remainingSec / 60, remainingSec % 60)
            setTextColor(Color.parseColor("#1FE08F"))
            textSize = 15f
            typeface = android.graphics.Typeface.DEFAULT_BOLD
        }
        timeTextView = tv
        pill.addView(tv)

        val type = if (Build.VERSION.SDK_INT >= 26 && Settings.canDrawOverlays(service)) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
        }

        val flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL

        val lp = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            type,
            flags,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = (displayWidth - (120 * density).toInt()).coerceAtLeast(20)
            y = (90 * density).toInt()
        }
        layoutParams = lp

        // Draggable touch listener
        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f
        var isDragging = false

        pill.setOnTouchListener { v, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = lp.x
                    initialY = lp.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    isDragging = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = (event.rawX - initialTouchX).toInt()
                    val dy = (event.rawY - initialTouchY).toInt()
                    if (Math.abs(dx) > 8 || Math.abs(dy) > 8) {
                        isDragging = true
                        lp.x = initialX + dx
                        lp.y = initialY + dy
                        try {
                            wm.updateViewLayout(v, lp)
                        } catch (_: Exception) {}
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (!isDragging) {
                        val remainingSec = ((activeExpiresAt - System.currentTimeMillis()) / 1000).coerceAtLeast(0)
                        val mins = remainingSec / 60
                        val secs = remainingSec % 60
                        Toast.makeText(
                            service,
                            "$appName unlocked: %02d:%02d remaining".format(mins, secs),
                            Toast.LENGTH_SHORT
                        ).show()
                    }
                    true
                }
                else -> false
            }
        }

        try {
            wm.addView(pill, lp)
            rootView = pill
            isShowing = true
            handler.removeCallbacks(ticker)
            handler.post(ticker)
            Log.i(TAG, "Floating timer overlay shown for $pkg")
        } catch (t: Throwable) {
            Log.e(TAG, "Failed to add floating timer view", t)
        }
    }

    fun onForegroundPackageChanged(newPkg: String) {
        val target = currentPkg ?: return
        if (FocusAccessibilityService.isSystemOrTransientPackage(newPkg)) return
        if (newPkg == target) {
            rootView?.visibility = View.VISIBLE
        } else {
            rootView?.visibility = View.GONE
        }
    }

    fun dismiss() {
        handler.removeCallbacks(ticker)
        val v = rootView ?: return
        try {
            wm.removeView(v)
        } catch (_: Exception) {}
        rootView = null
        timeTextView = null
        isShowing = false
        currentPkg = null
    }
}
