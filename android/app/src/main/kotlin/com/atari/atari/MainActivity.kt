package com.atari.atari

import android.content.Intent
import android.os.Bundle
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Platform-channel boundary for signal collectors — the Dart-side client
 * lives in `lib/core/services`. See Plans/IMPLEMENTATION.md §3 (Workstream:
 * Backend — Native): "Expose every capability above through the
 * `lib/core/services` platform-channel contract."
 */
class MainActivity : FlutterActivity() {
    private val signalsChannelName = "atari.dev/signals"

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
                    else -> result.notImplemented()
                }
            }
    }
}
