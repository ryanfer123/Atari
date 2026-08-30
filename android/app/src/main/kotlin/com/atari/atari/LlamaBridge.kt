package com.atari.atari

import android.content.Context
import android.util.Log
import java.io.File

/**
 * Thin JNI surface over llama.cpp. Handles are opaque native pointers;
 * [LlamaSessions] owns their lifetime, so nothing else should call these
 * directly.
 */
object LlamaBridge {
    init {
        System.loadLibrary("atari_llama")
    }

    external fun nativeInit()
    external fun nativeLoad(path: String, contextSize: Int, embedding: Boolean, threads: Int): Long
    external fun nativeFree(handle: Long)
    external fun nativeEmbeddingDim(handle: Long): Int
    external fun nativeGenerate(handle: Long, prompt: String, maxTokens: Int, grammar: String?): String
    external fun nativeEmbed(handle: Long, text: String): FloatArray
}

/**
 * Holds **at most one** GGUF model in memory at a time, swapping when a
 * different slot is asked for.
 *
 * This is the architectural rule from Plans/PIVOT_PLAN.md §2.2, not an
 * incidental optimisation: Qwen3-4B is ~2.5GB and EmbeddingGemma
 * ~265MB, and keeping peak footprint to "the largest single model"
 * rather than "the sum" is what makes the memory behaviour predictable
 * enough to demo. The cost is an explicit, accepted one — swapping
 * models means reloading weights, so callers should batch work for one
 * slot before switching.
 *
 * All entry points are synchronised. Two concurrent calls for different
 * slots would otherwise race to unload each other's model out from
 * under an in-flight generate.
 */
object LlamaSessions {
    private const val TAG = "LlamaSessions"

    /// Enough for the prompt plus a short constrained answer. Kept small
    /// deliberately: context size drives KV-cache size, and none of the
    /// decision points here need long context.
    private const val SLM_CONTEXT = 2048

    /// EmbeddingGemma's training context. Inputs are single notes and
    /// captures, which are far shorter.
    private const val EMBED_CONTEXT = 2048

    private var loadedSlot: String? = null
    private var handle: Long = 0
    private var initialised = false

    class ModelUnavailable(message: String) : Exception(message)

    @Synchronized
    fun isAvailable(context: Context, slot: String): Boolean = pathFor(context, slot) != null

    /**
     * Runs [block] with [slot] loaded, loading (and unloading whatever
     * else was resident) only if necessary.
     */
    @Synchronized
    private fun <T> withSlot(context: Context, slot: String, embedding: Boolean, block: (Long) -> T): T {
        val path = pathFor(context, slot)
            ?: throw ModelUnavailable("No usable model file for the '$slot' slot")

        if (loadedSlot != slot) {
            unloadLocked()
            if (!initialised) {
                LlamaBridge.nativeInit()
                initialised = true
            }
            val started = System.currentTimeMillis()
            handle = LlamaBridge.nativeLoad(path, contextFor(slot), embedding, threadCount())
            if (handle == 0L) throw ModelUnavailable("Could not load $path")
            loadedSlot = slot
            Log.i(TAG, "Loaded '$slot' in ${System.currentTimeMillis() - started}ms")
        }
        return block(handle)
    }

    fun generate(context: Context, prompt: String, maxTokens: Int, grammar: String?): String =
        withSlot(context, "slm", embedding = false) { h ->
            LlamaBridge.nativeGenerate(h, prompt, maxTokens, grammar)
        }

    fun embed(context: Context, text: String): FloatArray =
        withSlot(context, "embedder", embedding = true) { h ->
            LlamaBridge.nativeEmbed(h, text)
        }

    fun embeddingDimensions(context: Context): Int =
        withSlot(context, "embedder", embedding = true) { h ->
            LlamaBridge.nativeEmbeddingDim(h)
        }

    /** Frees whatever is resident. Safe to call when nothing is loaded. */
    @Synchronized
    fun unload() = unloadLocked()

    private fun unloadLocked() {
        if (handle != 0L) {
            LlamaBridge.nativeFree(handle)
            Log.i(TAG, "Unloaded '$loadedSlot'")
        }
        handle = 0
        loadedSlot = null
    }

    private fun contextFor(slot: String) = if (slot == "embedder") EMBED_CONTEXT else SLM_CONTEXT

    /**
     * Leaves headroom rather than claiming every core: generation runs
     * while the UI is still animating, and saturating all cores makes
     * the app itself stutter.
     */
    private fun threadCount(): Int =
        (Runtime.getRuntime().availableProcessors() - 2).coerceIn(2, 6)

    private fun pathFor(context: Context, slot: String): String? {
        val path = ModelSlotStore.getPath(context, slot) ?: return null
        val file = File(path)
        return if (file.exists() && file.canRead()) path else null
    }
}
