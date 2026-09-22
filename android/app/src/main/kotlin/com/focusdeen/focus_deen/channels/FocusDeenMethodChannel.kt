package com.focusdeen.focus_deen.channels

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
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
import java.util.Locale
import java.util.concurrent.Executors

class FocusDeenMethodChannel(private val context: Context) : MethodChannel.MethodCallHandler, TextToSpeech.OnInitListener {

    companion object {
        const val CHANNEL_NAME = "com.focusdeen.app/methods"
    }

    private var channel: MethodChannel? = null
    private val usageStatsService = UsageStatsService(context)
    private val appMonitorService = AppMonitorService.getInstance(context)
    private val backgroundExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    private var mediaPlayer: MediaPlayer? = null
    private var tts: TextToSpeech? = null
    private var isTtsInitialized = false
    private var pendingSpeakText: String? = null
    private var pendingLanguage: String? = null
    private var pendingRate: Float = 0.85f
    private var pendingFallback: String = ""

    init {
        try {
            tts = TextToSpeech(context.applicationContext, this)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            isTtsInitialized = true
            tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) {
                    mainHandler.post {
                        channel?.invokeMethod("onAudioStart", mapOf("utteranceId" to (utteranceId ?: "")))
                    }
                }

                override fun onDone(utteranceId: String?) {
                    mainHandler.post {
                        channel?.invokeMethod("onAudioDone", mapOf("utteranceId" to (utteranceId ?: "")))
                    }
                }

                @Deprecated("Deprecated in Java")
                override fun onError(utteranceId: String?) {
                    mainHandler.post {
                        channel?.invokeMethod("onAudioError", mapOf("utteranceId" to (utteranceId ?: "")))
                    }
                }
            })

            pendingSpeakText?.let { text ->
                speakText(text, pendingLanguage ?: "ar", pendingRate, pendingFallback)
                pendingSpeakText = null
                pendingLanguage = null
                pendingFallback = ""
            }
        }
    }

    fun playAudio(url: String, fallbackText: String, language: String): Boolean {
        stopAudio()

        if (url.isEmpty()) {
            return speakText(fallbackText, language, 0.85f, fallbackText)
        }

        return try {
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .build()
                )
                setDataSource(url)
                setOnPreparedListener { mp ->
                    mp.start()
                    mainHandler.post {
                        channel?.invokeMethod("onAudioStart", mapOf("url" to url))
                    }
                }
                setOnCompletionListener {
                    stopAudio()
                    mainHandler.post {
                        channel?.invokeMethod("onAudioDone", mapOf("url" to url))
                    }
                }
                setOnErrorListener { _, what, extra ->
                    stopAudio()
                    speakText(fallbackText, language, 0.85f, fallbackText)
                    true
                }
                prepareAsync()
            }
            true
        } catch (e: Exception) {
            e.printStackTrace()
            speakText(fallbackText, language, 0.85f, fallbackText)
        }
    }

    fun speakText(text: String, language: String, rate: Float, fallbackPhonetic: String = ""): Boolean {
        stopAudioOnly()
        if (!isTtsInitialized || tts == null) {
            pendingSpeakText = text
            pendingLanguage = language
            pendingRate = rate
            pendingFallback = fallbackPhonetic
            return false
        }

        try {
            val targetLocale = when (language.lowercase()) {
                "ar" -> Locale("ar")
                "bn" -> Locale("bn", "BD")
                else -> Locale("en", "US")
            }

            var textToSpeak = text
            val avail = tts?.isLanguageAvailable(targetLocale) ?: TextToSpeech.LANG_NOT_SUPPORTED
            if (avail != TextToSpeech.LANG_NOT_SUPPORTED && avail != TextToSpeech.LANG_MISSING_DATA) {
                tts?.language = targetLocale
            } else {
                // Arabic voice data is missing on many phones (e.g. Infinix / Xiaomi).
                // If text is in Arabic script and Arabic TTS voice is not installed,
                // the English/Default TTS engine will silently skip Arabic characters.
                // In that case, we MUST speak the phonetic fallback (Bengali or English transliteration)!
                if (fallbackPhonetic.isNotEmpty()) {
                    textToSpeak = fallbackPhonetic
                }

                val bnLocale = Locale("bn", "BD")
                val bnAvail = tts?.isLanguageAvailable(bnLocale) ?: TextToSpeech.LANG_NOT_SUPPORTED
                if (bnAvail != TextToSpeech.LANG_NOT_SUPPORTED && bnAvail != TextToSpeech.LANG_MISSING_DATA) {
                    tts?.language = bnLocale
                } else {
                    tts?.language = Locale.US
                }
            }

            tts?.setSpeechRate(rate)
            tts?.setPitch(1.0f)

            val params = android.os.Bundle().apply {
                putInt(TextToSpeech.Engine.KEY_PARAM_STREAM, AudioManager.STREAM_MUSIC)
                putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, 1.0f)
            }

            val utteranceId = "deenflow_${System.currentTimeMillis()}"
            val result = tts?.speak(textToSpeak, TextToSpeech.QUEUE_FLUSH, params, utteranceId)
            return result == TextToSpeech.SUCCESS
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    private fun stopAudioOnly() {
        try {
            if (mediaPlayer != null) {
                if (mediaPlayer?.isPlaying == true) {
                    mediaPlayer?.stop()
                }
                mediaPlayer?.release()
                mediaPlayer = null
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun stopAudio() {
        stopAudioOnly()
        try {
            tts?.stop()
        } catch (e: Exception) {
            e.printStackTrace()
        }
        mainHandler.post {
            channel?.invokeMethod("onAudioDone", null)
        }
    }

    fun register(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL_NAME)
        channel?.setMethodCallHandler(this)
    }

    fun unregister() {
        channel?.setMethodCallHandler(null)
        channel = null
        stopAudio()
        try {
            tts?.shutdown()
        } catch (e: Exception) {
            e.printStackTrace()
        }
        tts = null
        isTtsInitialized = false
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getInstalledApps" -> {
                backgroundExecutor.execute {
                    try {
                        val apps = getInstalledAppsList()
                        mainHandler.post {
                            result.success(apps)
                        }
                    } catch (e: Exception) {
                        mainHandler.post {
                            result.error("APPS_ERROR", e.localizedMessage, null)
                        }
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
                        mainHandler.post {
                            result.success(usageMap)
                        }
                    } catch (e: Exception) {
                        mainHandler.post {
                            result.error("USAGE_ERROR", e.localizedMessage, null)
                        }
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

            "syncMonitoredPackages" -> {
                val packages = call.argument<List<String>>("packages") ?: emptyList()
                appMonitorService.syncMonitoredPackages(packages)
                result.success(true)
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

            "syncSettings" -> {
                // Persist overlay settings (min score, unlock duration) so the accessibility
                // service can read them from SharedPreferences without needing a Flutter engine.
                val minScore = call.argument<Int>("minScore") ?: 80
                val unlockDurationMinutes = call.argument<Int>("unlockDurationMinutes") ?: 30
                val prefs = context.getSharedPreferences("focusdeen_monitor_prefs", android.content.Context.MODE_PRIVATE)
                prefs.edit()
                    .putInt("min_score", minScore)
                    .putInt("unlock_duration_minutes", unlockDurationMinutes)
                    .apply()
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

            "launchApp" -> {
                val packageName = call.argument<String>("packageName") ?: ""
                try {
                    val launchIntent = context.packageManager.getLaunchIntentForPackage(packageName)
                    if (launchIntent != null) {
                        launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        context.startActivity(launchIntent)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                } catch (e: Exception) {
                    result.error("LAUNCH_ERROR", e.localizedMessage, null)
                }
            }

            "isBatteryOptimizationIgnored" -> {
                val powerManager = context.getSystemService(Context.POWER_SERVICE) as? android.os.PowerManager
                val isIgnored = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    powerManager?.isIgnoringBatteryOptimizations(context.packageName) ?: false
                } else {
                    true
                }
                result.success(isIgnored)
            }

            "requestIgnoreBatteryOptimizations" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    try {
                        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                            data = Uri.parse("package:${context.packageName}")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        context.startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        val fallbackIntent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        context.startActivity(fallbackIntent)
                        result.success(true)
                    }
                } else {
                    result.success(true)
                }
            }

            "playAudio" -> {
                val url = call.argument<String>("url") ?: ""
                val fallbackText = call.argument<String>("fallbackText") ?: ""
                val language = call.argument<String>("language") ?: "ar"
                val success = playAudio(url, fallbackText, language)
                result.success(success)
            }

            "speak" -> {
                val text = call.argument<String>("text") ?: ""
                val language = call.argument<String>("language") ?: "ar"
                val rate = (call.argument<Double>("rate") ?: 0.85).toFloat()
                val fallbackPhonetic = call.argument<String>("fallbackPhonetic") ?: ""
                val success = speakText(text, language, rate, fallbackPhonetic)
                result.success(success)
            }

            "stopSpeaking", "stopAudio" -> {
                stopAudio()
                result.success(true)
            }

            "isSpeaking" -> {
                result.success(mediaPlayer?.isPlaying == true || tts?.isSpeaking == true)
            }

            else -> result.notImplemented()
        }
    }

    private fun getInstalledAppsList(): List<Map<String, Any?>> {
        val pm = context.packageManager
        val appList = mutableListOf<Map<String, Any?>>()
        val seenPackages = mutableSetOf<String>()

        // 1. Primary: Query all launcher activities
        val mainIntent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }

        val resolveInfos = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                pm.queryIntentActivities(mainIntent, PackageManager.ResolveInfoFlags.of(0L))
            } else {
                @Suppress("DEPRECATION")
                pm.queryIntentActivities(mainIntent, 0)
            }
        } catch (e: Exception) {
            emptyList()
        }

        for (resolveInfo in resolveInfos) {
            val activityInfo = resolveInfo.activityInfo ?: continue
            val pkg = activityInfo.packageName ?: continue
            if (pkg == context.packageName || seenPackages.contains(pkg)) {
                continue
            }
            seenPackages.add(pkg)

            val appName = try {
                resolveInfo.loadLabel(pm).toString()
            } catch (e: Exception) {
                pkg
            }

            val appInfo = activityInfo.applicationInfo
            val isSystemApp = if (appInfo != null) {
                (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            } else {
                false
            }

            val category = inferAppCategory(pkg, appName, appInfo)

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
                    "category" to category,
                    "iconBase64" to iconBase64
                )
            )
        }

        // 2. Secondary fallback: Query all installed applications to catch any launchable user apps
        try {
            val installedApps = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                pm.getInstalledApplications(PackageManager.ApplicationInfoFlags.of(0L))
            } else {
                @Suppress("DEPRECATION")
                pm.getInstalledApplications(0)
            }

            for (appInfo in installedApps) {
                val pkg = appInfo.packageName ?: continue
                if (pkg == context.packageName || seenPackages.contains(pkg)) {
                    continue
                }

                // Check if user launchable
                val launchIntent = pm.getLaunchIntentForPackage(pkg)
                if (launchIntent != null) {
                    seenPackages.add(pkg)
                    val appName = try {
                        pm.getApplicationLabel(appInfo).toString()
                    } catch (e: Exception) {
                        pkg
                    }
                    val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                    val category = inferAppCategory(pkg, appName, appInfo)
                    val iconBase64 = try {
                        val drawable = pm.getApplicationIcon(appInfo)
                        drawableToBase64(drawable)
                    } catch (e: Exception) {
                        null
                    }

                    appList.add(
                        mapOf(
                            "packageName" to pkg,
                            "appName" to appName,
                            "isSystemApp" to isSystemApp,
                            "category" to category,
                            "iconBase64" to iconBase64
                        )
                    )
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // Sort alphabetically by appName
        return appList.sortedBy { (it["appName"] as? String)?.lowercase() ?: "" }
    }

    private fun inferAppCategory(pkg: String, name: String, appInfo: ApplicationInfo?): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && appInfo != null) {
            when (appInfo.category) {
                ApplicationInfo.CATEGORY_GAME -> return "Gaming"
                ApplicationInfo.CATEGORY_AUDIO -> return "Music & Audio"
                ApplicationInfo.CATEGORY_VIDEO -> return "Video & Entertainment"
                ApplicationInfo.CATEGORY_IMAGE -> return "Photo & Video"
                ApplicationInfo.CATEGORY_SOCIAL -> return "Social media"
                ApplicationInfo.CATEGORY_NEWS -> return "News"
                ApplicationInfo.CATEGORY_MAPS -> return "Navigation"
                ApplicationInfo.CATEGORY_PRODUCTIVITY -> return "Productivity"
            }
        }

        val lower = "${pkg.lowercase()} ${name.lowercase()}"
        return when {
            lower.contains("game") || lower.contains("play") || lower.contains("clash") ||
                lower.contains("craft") || lower.contains("subway") || lower.contains("candy") ||
                lower.contains("pubg") || lower.contains("freefire") || lower.contains("roblox") -> "Gaming"
            lower.contains("social") || lower.contains("facebook") || lower.contains("insta") ||
                lower.contains("tiktok") || lower.contains("musically") || lower.contains("snap") ||
                lower.contains("reddit") || lower.contains("tweet") || lower.contains("twitter") ||
                lower.contains("x") || lower.contains("threads") || lower.contains("pin") -> "Social media"
            lower.contains("chat") || lower.contains("messag") || lower.contains("what") ||
                lower.contains("tele") || lower.contains("discord") || lower.contains("viber") ||
                lower.contains("imo") || lower.contains("signal") -> "Messaging"
            lower.contains("tube") || lower.contains("video") || lower.contains("stream") ||
                lower.contains("netfl") || lower.contains("prime") || lower.contains("movie") ||
                lower.contains("tv") || lower.contains("twitch") || lower.contains("disney") -> "Video & Entertainment"
            lower.contains("music") || lower.contains("audio") || lower.contains("spot") ||
                lower.contains("sound") -> "Music & Audio"
            lower.contains("shop") || lower.contains("amazon") || lower.contains("daraz") ||
                lower.contains("store") || lower.contains("shopee") || lower.contains("ali") -> "Shopping"
            lower.contains("chrome") || lower.contains("browser") || lower.contains("fire") ||
                lower.contains("opera") || lower.contains("edge") -> "Browser"
            else -> "Social media"
        }
    }

    private fun drawableToBase64(drawable: Drawable): String? {
        return try {
            val bitmap = if (drawable is BitmapDrawable && drawable.bitmap != null && !drawable.bitmap.isRecycled) {
                drawable.bitmap
            } else {
                val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 64
                val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 64
                val b = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(b)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
                b
            }

            // Scale to 56x56 for high-DPI clarity while keeping payload under 1.5KB
            val scaled = if (bitmap.width == 56 && bitmap.height == 56) {
                bitmap
            } else {
                Bitmap.createScaledBitmap(bitmap, 56, 56, true)
            }
            val stream = ByteArrayOutputStream()
            scaled.compress(Bitmap.CompressFormat.PNG, 85, stream)
            val byteArray = stream.toByteArray()
            Base64.encodeToString(byteArray, Base64.NO_WRAP)
        } catch (e: Exception) {
            null
        }
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
            "appSettings" -> Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:${context.packageName}")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            else -> null
        }

        if (intent != null) {
            context.startActivity(intent)
        }
    }
}
