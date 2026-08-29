package com.atari.sensing

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter Platform Plugin exposing Android sensing metrics to Dart.
 *
 * Channel: com.atari/sensing
 * EventChannel: com.atari/sensing_stream
 */
class SensingPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler, ActivityAware {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context
    private var activity: Activity? = null

    private lateinit var appSwitchTracker: AppSwitchTracker
    private var eventSink: EventChannel.EventSink? = null
    private val handler = Handler(Looper.getMainLooper())
    private var periodicRunnable: Runnable? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        UnlockTracker.init(context)
        appSwitchTracker = AppSwitchTracker(context)

        methodChannel = MethodChannel(binding.binaryMessenger, "com.atari/sensing")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, "com.atari/sensing_stream")
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        stopPeriodicUpdates()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getCurrentSnapshot" -> {
                val windowMinutes = call.argument<Int>("windowMinutes") ?: 15
                val now = System.currentTimeMillis()
                val windowStart = now - (windowMinutes * 60 * 1000L)

                val unlockCount = UnlockTracker.getUnlockCount(windowStart, now)
                val switchCount = appSwitchTracker.getAppSwitchCount(windowStart, now)
                val notifLatency = NotifLatencyTracker.getAverageLatencyMs()

                val snapshot = mapOf(
                    "unlockCount" to unlockCount,
                    "appSwitchCount" to switchCount,
                    "avgNotifLatencyMs" to notifLatency,
                    "windowStartMs" to windowStart,
                    "windowEndMs" to now
                )
                result.success(snapshot)
            }

            "checkPermissions" -> {
                val hasUsage = appSwitchTracker.hasPermission()
                val hasNotif = NotifLatencyTracker.isPermissionGranted(context)
                val permissions = mapOf(
                    "usageAccess" to hasUsage,
                    "notificationAccess" to hasNotif
                )
                result.success(permissions)
            }

            "requestUsagePermission" -> {
                val currentActivity = activity
                if (currentActivity != null) {
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    context.startActivity(intent)
                    result.success(true)
                } else {
                    result.error("NO_ACTIVITY", "Cannot open settings without an active Activity", null)
                }
            }

            "requestNotificationPermission" -> {
                val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                context.startActivity(intent)
                result.success(true)
            }

            "recordSimulatedUnlock" -> {
                UnlockTracker.recordUnlock(context)
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        startPeriodicUpdates()
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        stopPeriodicUpdates()
    }

    private fun startPeriodicUpdates() {
        stopPeriodicUpdates()
        periodicRunnable = object : Runnable {
            override fun run() {
                val now = System.currentTimeMillis()
                val windowStart = now - (15 * 60 * 1000L)
                val unlockCount = UnlockTracker.getUnlockCount(windowStart, now)
                val switchCount = appSwitchTracker.getAppSwitchCount(windowStart, now)
                val notifLatency = NotifLatencyTracker.getAverageLatencyMs()

                val snapshot = mapOf(
                    "unlockCount" to unlockCount,
                    "appSwitchCount" to switchCount,
                    "avgNotifLatencyMs" to notifLatency,
                    "windowStartMs" to windowStart,
                    "windowEndMs" to now
                )
                eventSink?.success(snapshot)
                handler.postDelayed(this, 10000L) // update every 10s
            }
        }
        handler.post(periodicRunnable!!)
    }

    private fun stopPeriodicUpdates() {
        periodicRunnable?.let { handler.removeCallbacks(it) }
        periodicRunnable = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
