package com.atari.slm

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

/**
 * Flutter Platform Plugin exposing the on-device SLM explanation layer and masked agentic
 * source selection tooling to Dart.
 *
 * Channel: com.atari/slm
 */
class SlmPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "com.atari/slm")
        methodChannel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
    }

    @Suppress("UNCHECKED_CAST")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "explain" -> {
                val fragmentationScore = call.argument<Double>("fragmentationScore") ?: 0.0
                val appSwitchZ = call.argument<Double>("appSwitchZ") ?: -1000.0
                val unlockZ = call.argument<Double>("unlockZ") ?: -1000.0
                val notifZ = call.argument<Double>("notifZ") ?: -1000.0
                val timeBucket = call.argument<String>("timeBucket") ?: "afternoon"

                val rawBullets = call.argument<List<Map<String, String>>>("contextBullets") ?: emptyList()
                val contextSources = rawBullets.map { it["source"] ?: "" }.toTypedArray()
                val contextTexts = rawBullets.map { it["text"] ?: "" }.toTypedArray()

                // The native safety contract is packaged independently from model inference.
                // Until the llama.cpp adapter is connected, always return an explicit fallback.
                val fallbackText = try {
                    SlmBridge.nativeFallbackText(
                        fragmentationScore,
                        appSwitchZ,
                        unlockZ,
                        notifZ,
                        timeBucket
                    )
                } catch (e: UnsatisfiedLinkError) {
                    generateKotlinFallback(appSwitchZ, unlockZ, notifZ, timeBucket)
                }

                // If context bullets exist, format final output
                val explanationResult = mapOf(
                    "text" to fallbackText,
                    "contextBullets" to rawBullets,
                    "usedModel" to false,
                    "fallbackReason" to "model_runtime_not_connected"
                )
                result.success(explanationResult)
            }

            "selectSources" -> {
                val triggerSignal = call.argument<String>("triggerSignal") ?: "app_switches"
                val topSignal = call.argument<String>("topSignal") ?: "app_switches"
                val allowed = call.argument<List<String>>("allowedSources") ?: listOf(
                    "notes", "todos", "health_targets", "calendar", "capture_history"
                )
                val maxCalls = call.argument<Int>("maxCalls") ?: 3

                // Masked source selection decision point (§4.8)
                val selectedSources = performMaskedSourceSelection(triggerSignal, topSignal, allowed, maxCalls)

                val response = mapOf(
                    "selectedSources" to selectedSources,
                    "reasoning" to "Deterministic source fallback for $topSignal (cap: $maxCalls); model runtime not connected",
                    "usedModel" to false
                )
                result.success(response)
            }

            "isModelReady" -> {
                result.success(false)
            }

            "getRuntimeStatus" -> {
                result.success(
                    mapOf(
                        "nativeContractReady" to SlmBridge.isNativeContractAvailable,
                        "modelRuntimeReady" to false,
                        "modelId" to null
                    )
                )
            }

            else -> result.notImplemented()
        }
    }

    /**
     * Kotlin-level deterministic fallback matching ExplanationService::fallback_text.
     */
    private fun generateKotlinFallback(
        appSwitchZ: Double,
        unlockZ: Double,
        notifZ: Double,
        timeBucket: String
    ): String {
        return when {
            appSwitchZ >= unlockZ && appSwitchZ >= notifZ && appSwitchZ > 0.0 ->
                "Your app-switching is higher than your usual $timeBucket pattern."
            unlockZ >= notifZ && unlockZ > 0.0 ->
                "You're unlocking your phone more frequently than your usual $timeBucket pattern."
            notifZ > 0.0 ->
                "You're checking notifications faster than your usual $timeBucket pattern."
            else ->
                "Your phone activity is unusually fragmented for a $timeBucket."
        }
    }

    /**
     * Constrained agentic source selector: chooses up to [maxCalls] sources from [allowedSources]
     * based on the trigger and top signals.
     */
    private fun performMaskedSourceSelection(
        triggerSignal: String,
        topSignal: String,
        allowedSources: List<String>,
        maxCalls: Int
    ): List<String> {
        val candidates = mutableListOf<String>()

        // Heuristic mapping mirroring the Qwen3 / SLM constrained grammar
        when (topSignal) {
            "app_switches" -> {
                if ("todos" in allowedSources) candidates.add("todos")
                if ("health_targets" in allowedSources) candidates.add("health_targets")
                if ("notes" in allowedSources) candidates.add("notes")
            }
            "unlocks" -> {
                if ("calendar" in allowedSources) candidates.add("calendar")
                if ("todos" in allowedSources) candidates.add("todos")
                if ("capture_history" in allowedSources) candidates.add("capture_history")
            }
            "notif_latency" -> {
                if ("todos" in allowedSources) candidates.add("todos")
                if ("notes" in allowedSources) candidates.add("notes")
            }
            else -> {
                candidates.addAll(allowedSources.take(maxCalls))
            }
        }

        val filtered = candidates.distinct().take(maxCalls)
        return if (filtered.isNotEmpty()) filtered else allowedSources.take(maxCalls)
    }
}
