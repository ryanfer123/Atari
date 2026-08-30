package com.atari.atari

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import java.util.concurrent.Executors
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

private const val PROJECTION_REQUEST_CODE = 2001

/**
 * Platform-channel boundary for signal collectors — the Dart-side client
 * lives in `lib/core/services`. See Plans/IMPLEMENTATION.md §3 (Workstream:
 * Backend — Native): "Expose every capability above through the
 * `lib/core/services` platform-channel contract."
 */
class MainActivity : FlutterActivity() {
    private val signalsChannelName = "atari.dev/signals"
    private val modelsChannelName = "atari.dev/models"
    private val remindersChannelName = "atari.dev/reminders"
    private val captureChannelName = "atari.dev/capture"

    /// Held so the async permission dialog result can be reported back
    /// to the Dart caller that started it.
    private var pendingCapturePermission: MethodChannel.Result? = null

    /// Kept so the overlay service can push a crop into Dart when it
    /// relaunches this activity.
    private var captureChannel: MethodChannel? = null

    /// OCR loads ~21MB of weights and runs two networks, which is far
    /// too slow for the platform thread — a capture would visibly jank
    /// the UI. Single-threaded because PpOcrEngine holds one pair of
    /// sessions and serialises on them anyway.
    private val ocrExecutor = Executors.newSingleThreadExecutor()

    /// Separate from [ocrExecutor] so a slow generation can't queue
    /// behind a capture's OCR, but still single-threaded: LlamaSessions
    /// holds one model at a time and serialises on it, so extra threads
    /// would only contend.
    private val llamaExecutor = Executors.newSingleThreadExecutor()

    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Deliberately here, not in AtariApplication.onCreate(): Android
        // 12+ only allows startForegroundService() from a context it
        // trusts as foreground-triggering, and Application.onCreate() runs
        // too early in the process lifecycle to reliably count — it threw
        // ForegroundServiceStartNotAllowedException in testing on this
        // device. An Activity's onCreate() is a context Android does
        // trust.
        ContextCompat.startForegroundService(this, Intent(this, SignalCollectionService::class.java))
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, signalsChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getUnlockTimestamps" -> {
                        result.success(UnlockTracker.getUnlockTimestamps(applicationContext))
                    }
                    "getUnlockCountSince" -> {
                        val sinceMillis = (call.argument<Number>("sinceMillis"))?.toLong()
                        if (sinceMillis == null) {
                            result.error("missing_argument", "sinceMillis is required", null)
                        } else {
                            result.success(UnlockTracker.getUnlockCountSince(applicationContext, sinceMillis))
                        }
                    }
                    "isCollectionServiceRunning" -> {
                        result.success(SignalCollectionService.isRunning)
                    }
                    "hasUsageAccess" -> {
                        result.success(AppSwitchTracker.hasUsageAccess(applicationContext))
                    }
                    "getAppSwitchCountSince" -> {
                        val sinceMillis = (call.argument<Number>("sinceMillis"))?.toLong()
                        if (sinceMillis == null) {
                            result.error("missing_argument", "sinceMillis is required", null)
                        } else {
                            result.success(AppSwitchTracker.getAppSwitchCountSince(applicationContext, sinceMillis))
                        }
                    }
                    "openUsageAccessSettings" -> {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(null)
                    }
                    "hasNotificationAccess" -> {
                        val enabled = NotificationManagerCompat.getEnabledListenerPackages(applicationContext)
                        result.success(enabled.contains(applicationContext.packageName))
                    }
                    "getNotifLatenciesSince" -> {
                        val sinceMillis = (call.argument<Number>("sinceMillis"))?.toLong()
                        if (sinceMillis == null) {
                            result.error("missing_argument", "sinceMillis is required", null)
                        } else {
                            result.success(NotifLatencyTracker.getLatenciesSince(applicationContext, sinceMillis))
                        }
                    }
                    "openNotificationAccessSettings" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, modelsChannelName)
            .setMethodCallHandler { call, result ->
                val slot = call.argument<String>("slot")
                when (call.method) {
                    "setModelPath" -> {
                        val path = call.argument<String>("path")
                        if (slot == null || path == null) {
                            result.error("missing_argument", "slot and path are required", null)
                        } else {
                            ModelSlotStore.setPath(applicationContext, slot, path)
                            result.success(null)
                        }
                    }
                    "clearModelPath" -> {
                        if (slot == null) {
                            result.error("missing_argument", "slot is required", null)
                        } else {
                            ModelSlotStore.clear(applicationContext, slot)
                            result.success(null)
                        }
                    }
                    "getModelStatus" -> {
                        val companions = call.argument<List<String>>("companions") ?: emptyList()
                        if (slot == null) {
                            result.error("missing_argument", "slot is required", null)
                        } else {
                            result.success(ModelSlotStore.status(applicationContext, slot, companions))
                        }
                    }
                    "autoDetect" -> {
                        val fileName = call.argument<String>("fileName")
                        if (slot == null || fileName == null) {
                            result.error("missing_argument", "slot and fileName are required", null)
                        } else {
                            result.success(ModelSlotStore.autoDetect(applicationContext, slot, fileName))
                        }
                    }
                    "getModelsDirectory" -> {
                        result.success(ModelSlotStore.modelsDirectory(applicationContext))
                    }
                    "isOcrReady" -> {
                        result.success(PpOcrEngine.isReady(applicationContext))
                    }
                    "runOcr" -> {
                        val path = call.argument<String>("imagePath")
                        if (path == null) {
                            result.error("missing_argument", "imagePath is required", null)
                        } else {
                            runOcrAsync(path, result)
                        }
                    }
                    "isSlmReady" -> {
                        result.success(LlamaSessions.isAvailable(applicationContext, "slm"))
                    }
                    "isEmbedderReady" -> {
                        result.success(LlamaSessions.isAvailable(applicationContext, "embedder"))
                    }
                    "slmGenerate" -> {
                        val prompt = call.argument<String>("prompt")
                        if (prompt == null) {
                            result.error("missing_argument", "prompt is required", null)
                        } else {
                            val maxTokens = call.argument<Int>("maxTokens") ?: 64
                            val grammar = call.argument<String>("grammar")
                            onLlamaThread(result) {
                                LlamaSessions.generate(applicationContext, prompt, maxTokens, grammar)
                            }
                        }
                    }
                    "embedText" -> {
                        val text = call.argument<String>("text")
                        if (text == null) {
                            result.error("missing_argument", "text is required", null)
                        } else {
                            onLlamaThread(result) {
                                // Sent as doubles because that is what
                                // the Dart contract stores and compares.
                                LlamaSessions.embed(applicationContext, text)
                                    .map { it.toDouble() }
                            }
                        }
                    }
                    "embeddingDimensions" -> {
                        onLlamaThread(result) {
                            LlamaSessions.embeddingDimensions(applicationContext)
                        }
                    }
                    "unloadModels" -> {
                        onLlamaThread(result) {
                            LlamaSessions.unload()
                            null
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        captureChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, captureChannelName)
        captureChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isEnabled" -> result.success(CaptureOverlayService.isRunning)
                "canDrawOverlays" -> result.success(Settings.canDrawOverlays(this))
                "requestOverlayPermission" -> {
                    // No runtime dialog exists for this one — the only
                    // path is the settings screen.
                    startActivity(
                        Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName"),
                        ),
                    )
                    result.success(null)
                }
                "enable" -> {
                    // Projection consent is answered in onActivityResult;
                    // the service is only started once it's granted.
                    pendingCapturePermission = result
                    val manager =
                        getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                    startActivityForResult(manager.createScreenCaptureIntent(), PROJECTION_REQUEST_CODE)
                }
                "disable" -> {
                    startService(
                        Intent(this, CaptureOverlayService::class.java)
                            .setAction(CaptureOverlayService.ACTION_STOP),
                    )
                    result.success(null)
                }
                "captureNow" -> {
                    if (!CaptureOverlayService.isRunning) {
                        result.error("not_enabled", "Turn on circle-to-capture first", null)
                    } else {
                        moveTaskToBack(true)
                        startService(
                            Intent(this, CaptureOverlayService::class.java)
                                .setAction(CaptureOverlayService.ACTION_CAPTURE_NOW),
                        )
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // A crop can arrive before Dart is listening (the service launches
        // this activity), so replay whatever the launch intent carried.
        deliverPendingCrop(intent)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, remindersChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasPermissions" -> {
                        result.success(hasNotificationPermission() && ReminderScheduler.canScheduleExact(this))
                    }
                    "requestPermissions" -> {
                        requestReminderPermissions()
                        // Reports current state, not post-grant state: the
                        // notification dialog and the exact-alarm settings
                        // screen are both async, so the UI re-checks with
                        // hasPermissions() when it regains focus.
                        result.success(hasNotificationPermission() && ReminderScheduler.canScheduleExact(this))
                    }
                    "schedule" -> {
                        val id = call.argument<Number>("id")?.toInt()
                        val title = call.argument<String>("title")
                        val whenMillis = call.argument<Number>("scheduledForMillis")?.toLong()
                        val tool = call.argument<String>("tool") ?: "setReminder"
                        if (id == null || title == null || whenMillis == null) {
                            result.error("missing_argument", "id, title and scheduledForMillis are required", null)
                        } else {
                            result.success(ReminderScheduler.schedule(applicationContext, id, title, whenMillis, tool))
                        }
                    }
                    "cancel" -> {
                        val id = call.argument<Number>("id")?.toInt()
                        if (id == null) {
                            result.error("missing_argument", "id is required", null)
                        } else {
                            ReminderScheduler.cancel(applicationContext, id)
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PROJECTION_REQUEST_CODE) return

        val granted = resultCode == Activity.RESULT_OK && data != null
        if (granted) {
            // Android 14+ needs the service in the foreground with type
            // mediaProjection before the projection can be built, so the
            // consent is handed to the service rather than used here.
            ContextCompat.startForegroundService(
                this,
                Intent(this, CaptureOverlayService::class.java).apply {
                    action = CaptureOverlayService.ACTION_START
                    putExtra(CaptureOverlayService.EXTRA_RESULT_CODE, resultCode)
                    putExtra(CaptureOverlayService.EXTRA_RESULT_DATA, data)
                },
            )
        }
        pendingCapturePermission?.success(granted)
        pendingCapturePermission = null
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        deliverPendingCrop(intent)
    }

    /** Forwards a crop produced by the overlay service into Dart. */
    private fun deliverPendingCrop(intent: Intent?) {
        if (intent?.action != CaptureOverlayService.ACTION_CAPTURED) return
        val path = intent.getStringExtra(CaptureOverlayService.EXTRA_CROP_PATH) ?: return
        // Clear it so a configuration change doesn't replay the same crop.
        intent.removeExtra(CaptureOverlayService.EXTRA_CROP_PATH)
        captureChannel?.invokeMethod("onCaptureReady", mapOf("path" to path))
    }

    /**
     * Runs PP-OCR off the platform thread and reports back on it, which
     * is where MethodChannel results must be delivered.
     *
     * A failure is reported as an error rather than empty text so the
     * Dart side can fall back to the placeholder — returning "" would be
     * indistinguishable from an image that genuinely has no text in it.
     */
    /**
     * Runs [work] on the llama thread and delivers its value on the
     * platform thread, where MethodChannel results are required.
     *
     * Failures come back as channel errors, never as a plausible-looking
     * default: the Dart side decides what to fall back to, and it can
     * only do that if it can tell a failure from a real answer.
     */
    private fun onLlamaThread(result: MethodChannel.Result, work: () -> Any?) {
        llamaExecutor.execute {
            try {
                val value = work()
                mainHandler.post { result.success(value) }
            } catch (e: Throwable) {
                mainHandler.post {
                    result.error("llama_failed", e.message ?: e.toString(), null)
                }
            }
        }
    }

    private fun runOcrAsync(imagePath: String, result: MethodChannel.Result) {
        ocrExecutor.execute {
            try {
                val ocr = PpOcrEngine.recognise(applicationContext, imagePath)
                mainHandler.post {
                    result.success(
                        mapOf("text" to ocr.text, "confidence" to ocr.confidence.toDouble()),
                    )
                }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error("ocr_failed", e.message ?: e.toString(), null)
                }
            }
        }
    }

    private fun hasNotificationPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun requestReminderPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !hasNotificationPermission()) {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1001)
        }
        if (!ReminderScheduler.canScheduleExact(this)) {
            // No runtime dialog exists for exact alarms — the only path is
            // this settings screen (Android 12+).
            startActivity(
                Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:$packageName")),
            )
        }
    }
}
