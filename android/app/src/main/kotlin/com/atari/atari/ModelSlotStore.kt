package com.atari.atari

import android.content.Context
import java.io.File

/**
 * Per-slot storage and validation for on-device model files.
 *
 * Records and sanity-checks paths only; it does **not** load weights.
 * [PpOcrEngine] reads the `ocr` slot from here and runs it through ONNX
 * Runtime. The `slm` and `embedder` slots are validated but not yet
 * loaded — both are GGUF and need a llama.cpp build.
 */
object ModelSlotStore {
    private const val PREFS_NAME = "atari_model_slots"

    // First 4 bytes of a GGUF file are the ASCII magic "GGUF".
    private val GGUF_MAGIC = byteArrayOf('G'.code.toByte(), 'G'.code.toByte(), 'U'.code.toByte(), 'F'.code.toByte())

    /** ONNX is protobuf with no short fixed magic, so those slots fall
     * back to an extension check. */
    private val GGUF_SLOTS = setOf("slm", "embedder")

    fun setPath(context: Context, slot: String, path: String) {
        prefs(context).edit().putString(slot, path).apply()
    }

    fun clear(context: Context, slot: String) {
        prefs(context).edit().remove(slot).apply()
    }

    fun getPath(context: Context, slot: String): String? = prefs(context).getString(slot, null)

    /**
     * App-private external directory — readable by us with no permission
     * grant on every supported Android version, and reachable by
     * `adb push`, which is what the UI instructs.
     */
    fun modelsDirectory(context: Context): String? = context.getExternalFilesDir(null)?.absolutePath

    /**
     * Looks for [expectedFileName] in the models directory and records
     * it if found. Saves the user typing a long path by hand, which is
     * the most error-prone part of getting a model in place.
     *
     * Returns true if a file was found and recorded.
     */
    fun autoDetect(context: Context, slot: String, expectedFileName: String): Boolean {
        val dir = modelsDirectory(context) ?: return false
        val candidate = File(dir, expectedFileName)
        if (!candidate.exists() || !candidate.canRead()) return false
        setPath(context, slot, candidate.absolutePath)
        return true
    }

    /**
     * [companions] are files that must sit beside the main one for the
     * slot to actually work — see `ModelSpec.companionFiles`. A slot
     * missing one is reported as incomplete rather than valid, because
     * the failure would otherwise only surface as garbled output later.
     */
    fun status(context: Context, slot: String, companions: List<String>): Map<String, Any?> {
        val path = getPath(context, slot) ?: return mapOf("status" to "notConfigured")
        val file = File(path)
        if (!file.exists()) return mapOf("status" to "fileNotFound", "path" to path)
        if (!file.canRead()) return mapOf("status" to "notReadable", "path" to path)
        if (!looksRightFormat(file, slot)) return mapOf("status" to "wrongFormat", "path" to path)

        val missing = companions.filterNot { File(file.parentFile, it).exists() }
        if (missing.isNotEmpty()) {
            return mapOf("status" to "missingCompanions", "path" to path, "missing" to missing)
        }

        var totalBytes = file.length()
        for (companion in companions) {
            totalBytes += File(file.parentFile, companion).length()
        }
        return mapOf("status" to "looksValid", "path" to path, "fileSizeBytes" to totalBytes)
    }

    private fun looksRightFormat(file: File, slot: String): Boolean {
        if (slot in GGUF_SLOTS) return hasGgufMagic(file)
        return file.name.endsWith(".onnx", ignoreCase = true) ||
            file.name.endsWith(".gguf", ignoreCase = true) ||
            file.name.endsWith(".tflite", ignoreCase = true)
    }

    private fun hasGgufMagic(file: File): Boolean =
        try {
            file.inputStream().use { stream ->
                val header = ByteArray(4)
                stream.read(header) == 4 && header.contentEquals(GGUF_MAGIC)
            }
        } catch (e: Exception) {
            false
        }

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
}
