package com.atari.slm

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File

/**
 * Flutter Platform Plugin exposing the on-device SLM explanation layer and masked agentic
 * source selection tooling to Dart.
 *
 * When a GGUF model file is loaded via `initAndLoad`, all `explain` and `selectSources` calls
 * route through the llama.cpp C++ runtime (via [SlmBridge] JNI). If the runtime is unready or
 * generates an invalid response, the system falls back deterministically without user disruption.
 *
 * Channel: com.atari/slm
 */
class SlmPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var context: Context

    private var runtimeInitialized = false
    private var modelReady = false

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
            "initRuntime" -> {
                result.success(initRuntime())
            }

            "loadModel" -> {
                val modelPath = call.argument<String>("modelPath") ?: ""
                val contextTokens = call.argument<Int>("contextTokens") ?: 1024
                result.success(loadModel(modelPath, contextTokens))
            }

            "unloadModel" -> {
                unloadModel()
                result.success(true)
            }

            "explain" -> {
                val fragmentationScore = call.argument<Double>("fragmentationScore") ?: 0.0
                val appSwitchZ = call.argument<Double>("appSwitchZ") ?: -1000.0
                val unlockZ = call.argument<Double>("unlockZ") ?: -1000.0
                val notifZ = call.argument<Double>("notifZ") ?: -1000.0
                val timeBucket = call.argument<String>("timeBucket") ?: "afternoon"

                val rawBullets = call.argument<List<Map<String, String>>>("contextBullets") ?: emptyList()
                val contextSources = rawBullets.map { it["source"] ?: "" }.toTypedArray()
                val contextTexts = rawBullets.map { it["text"] ?: "" }.toTypedArray()

                val explanationResult = generateExplanation(
                    fragmentationScore, appSwitchZ, unlockZ, notifZ, timeBucket,
                    contextSources, contextTexts, rawBullets
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

                val response = selectSources(triggerSignal, topSignal, allowed, maxCalls)
                result.success(response)
            }

            "isModelReady" -> {
                result.success(modelReady)
            }

            "getRuntimeStatus" -> {
                val metrics = getRuntimeMetrics()
                result.success(metrics)
            }

            else -> result.notImplemented()
        }
    }

    // ── Runtime lifecycle ──────────────────────────────────────────

    private fun initRuntime(): Map<String, Any> {
        if (runtimeInitialized) {
            return mapOf("success" to true, "message" to "Already initialized")
        }
        return try {
            if (!SlmBridge.isNativeContractAvailable) {
                return mapOf("success" to false, "message" to "Native library not available")
            }
            val nativeLibDir = context.applicationInfo.nativeLibraryDir
            val code = SlmBridge.nativeRuntimeInit(nativeLibDir)
            runtimeInitialized = code == 0
            mapOf(
                "success" to (code == 0),
                "message" to if (code == 0) "GGML backends loaded from $nativeLibDir" else "Init failed ($code)"
            )
        } catch (e: Exception) {
            Log.e(TAG, "Runtime init failed", e)
            mapOf("success" to false, "message" to "Exception: ${e.message}")
        }
    }

    private fun loadModel(modelPath: String, contextTokens: Int): Map<String, Any> {
        if (!runtimeInitialized) {
            val init = initRuntime()
            if (init["success"] != true) return init
        }
        return try {
            val file = File(modelPath)
            if (!file.isFile) {
                return mapOf("success" to false, "message" to "Model file not found: $modelPath")
            }
            val code = SlmBridge.nativeLoadModel(modelPath, contextTokens)
            modelReady = code == 0
            mapOf(
                "success" to (code == 0),
                "message" to when (code) {
                    0 -> "Model loaded (ctx=$contextTokens)"
                    1 -> "Backend not initialized"
                    2 -> "Failed to load GGUF file"
                    3 -> "Failed to create context"
                    else -> "Unknown error ($code)"
                }
            )
        } catch (e: Exception) {
            Log.e(TAG, "Model load failed", e)
            modelReady = false
            mapOf("success" to false, "message" to "Exception: ${e.message}")
        }
    }

    private fun unloadModel() {
        try {
            SlmBridge.nativeUnloadModel()
        } catch (_: Exception) { }
        modelReady = false
    }

    // ── Explanation generation ─────────────────────────────────────

    /**
     * If the model is loaded, build a grounded prompt, generate via llama.cpp,
     * validate with the native safety contract, and return. Otherwise, fall
     * back deterministically.
     */
    private fun generateExplanation(
        fragmentationScore: Double,
        appSwitchZ: Double,
        unlockZ: Double,
        notifZ: Double,
        timeBucket: String,
        contextSources: Array<String>,
        contextTexts: Array<String>,
        rawBullets: List<Map<String, String>>
    ): Map<String, Any?> {
        // Attempt model-based generation.
        if (modelReady) {
            try {
                // Build the grounded prompt via C++ native contract.
                val prompt = SlmBridge.nativeBuildPrompt(
                    fragmentationScore, appSwitchZ, unlockZ, notifZ, timeBucket,
                    contextSources, contextTexts
                )

                // Generate via llama.cpp (bounded to 128 tokens for 1-sentence output).
                val rawOutput = SlmBridge.nativeGenerate(prompt, 128)

                // Validate output safety via C++ contract.
                if (rawOutput.isNotEmpty() && SlmBridge.nativeIsSafeOutput(rawOutput)) {
                    return mapOf(
                        "text" to rawOutput.trim(),
                        "contextBullets" to rawBullets,
                        "usedModel" to true,
                        "fallbackReason" to null
                    )
                }

                // Model output failed validation — fall through to deterministic.
                Log.w(TAG, "Model output rejected by safety contract: ${rawOutput.take(80)}...")
            } catch (e: Exception) {
                Log.w(TAG, "Model generation failed, using fallback", e)
            }
        }

        // Deterministic fallback.
        val fallbackText = try {
            SlmBridge.nativeFallbackText(
                fragmentationScore, appSwitchZ, unlockZ, notifZ, timeBucket
            )
        } catch (e: UnsatisfiedLinkError) {
            generateKotlinFallback(appSwitchZ, unlockZ, notifZ, timeBucket)
        }

        return mapOf(
            "text" to fallbackText,
            "contextBullets" to rawBullets,
            "usedModel" to false,
            "fallbackReason" to if (modelReady) "output_rejected" else "model_runtime_not_loaded"
        )
    }

    // ── Masked source selection ───────────────────────────────────

    /**
     * If the model is loaded, query it with a JSON grammar constraint for the
     * masked source subset. Validate and cap at [maxCalls]. Fall back to
     * deterministic heuristic if unavailable or invalid.
     */
    private fun selectSources(
        triggerSignal: String,
        topSignal: String,
        allowedSources: List<String>,
        maxCalls: Int
    ): Map<String, Any> {
        if (modelReady) {
            try {
                // Build the constrained prompt / schema for source selection.
                val allowedIds = allowedSources.mapNotNull { sourceNameToId(it) }.toIntArray()
                val selectionPrompt = SlmBridge.nativeSourceSelectionSchema(
                    triggerSignal, topSignal, allowedIds, maxCalls
                )

                // Generate via llama.cpp.
                val rawOutput = SlmBridge.nativeGenerate(selectionPrompt, 64)

                // Parse and validate the model's selection.
                val selectedIds = SlmBridge.nativeParseSourceSelection(rawOutput)
                if (selectedIds != null && selectedIds.isNotEmpty()) {
                    val selected = selectedIds.toList()
                        .mapNotNull { sourceIdToName(it) }
                        .filter { it in allowedSources }
                        .distinct()
                        .take(maxCalls)

                    if (selected.isNotEmpty()) {
                        return mapOf(
                            "selectedSources" to selected,
                            "reasoning" to "Model-selected sources for $topSignal (cap: $maxCalls)",
                            "usedModel" to true
                        )
                    }
                }
                Log.w(TAG, "Model source selection invalid, using heuristic")
            } catch (e: Exception) {
                Log.w(TAG, "Model source selection failed, using heuristic", e)
            }
        }

        // Deterministic fallback.
        val selectedSources = performHeuristicSourceSelection(triggerSignal, topSignal, allowedSources, maxCalls)
        return mapOf(
            "selectedSources" to selectedSources,
            "reasoning" to "Deterministic source heuristic for $topSignal (cap: $maxCalls); model ${if (modelReady) "output invalid" else "not loaded"}",
            "usedModel" to false
        )
    }

    // ── Runtime metrics ───────────────────────────────────────────

    private fun getRuntimeMetrics(): Map<String, Any?> {
        val base = mutableMapOf<String, Any?>(
            "nativeContractReady" to SlmBridge.isNativeContractAvailable,
            "modelRuntimeReady" to modelReady,
            "runtimeInitialized" to runtimeInitialized
        )
        if (modelReady) {
            try {
                val metricsJson = SlmBridge.nativeRuntimeMetrics()
                val json = JSONObject(metricsJson)
                base["modelLoaded"] = json.optBoolean("modelLoaded", false)
                base["contextTokens"] = json.optInt("contextTokens", 0)
                base["loadMs"] = json.optLong("loadMs", 0)
                base["generationMs"] = json.optLong("generationMs", 0)
                base["ttftMs"] = json.optLong("ttftMs", 0)
                base["generatedTokens"] = json.optInt("generatedTokens", 0)
            } catch (_: Exception) { }
        }
        return base
    }

    // ── Helpers ────────────────────────────────────────────────────

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

    private fun performHeuristicSourceSelection(
        triggerSignal: String,
        topSignal: String,
        allowedSources: List<String>,
        maxCalls: Int
    ): List<String> {
        val candidates = mutableListOf<String>()
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
            "notif_latency_ms" -> {
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

    private fun sourceNameToId(name: String): Int? = when (name) {
        "notes" -> 0
        "todos" -> 1
        "health_targets" -> 2
        "calendar" -> 3
        "capture_history" -> 4
        else -> null
    }

    private fun sourceIdToName(id: Int): String? = when (id) {
        0 -> "notes"
        1 -> "todos"
        2 -> "health_targets"
        3 -> "calendar"
        4 -> "capture_history"
        else -> null
    }

    companion object {
        private const val TAG = "SlmPlugin"
    }
}
