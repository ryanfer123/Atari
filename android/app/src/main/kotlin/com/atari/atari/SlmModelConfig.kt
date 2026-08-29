package com.atari.atari

import android.content.Context
import java.io.File

/**
 * On-device configuration for which GGUF model file the (not-yet-built)
 * on-device SLM runtime should load.
 *
 * This is deliberately just path configuration plus a cheap existence/
 * format sanity check — it does not load model weights or run inference,
 * and it is not wired to the C++ `ModelRuntime::load(ModelConfig)`
 * contract (`native/model/include/atari/model/explanation_service.h`)
 * yet, since there is no JNI bridge to that native layer. A real Android
 * runtime adapter implementing that contract, and connecting it to
 * whatever path is configured here, is a follow-up — see
 * native/model/README.md.
 *
 * The app can already read its own external files directory
 * (`getExternalFilesDir(null)`) on every Android version with no
 * permission grant, so that's the recommended place to push a model
 * file to, e.g.:
 * `adb push model.gguf /sdcard/Android/data/com.atari.atari/files/`
 */
object SlmModelConfig {
    private const val PREFS_NAME = "atari_slm_model_config"
    private const val KEY_MODEL_PATH = "model_path"

    // First 4 bytes of a GGUF file are the ASCII magic "GGUF" — see
    // https://github.com/ggml-org/ggml/blob/master/docs/gguf.md.
    private val GGUF_MAGIC = byteArrayOf('G'.code.toByte(), 'G'.code.toByte(), 'U'.code.toByte(), 'F'.code.toByte())

    fun setModelPath(context: Context, path: String) {
        prefs(context).edit().putString(KEY_MODEL_PATH, path).apply()
    }

    fun getModelPath(context: Context): String? = prefs(context).getString(KEY_MODEL_PATH, null)

    /**
     * Status of the currently configured path: file existence, then a
     * cheap GGUF-magic-byte sniff. This is *not* full format or weight
     * validation — that's the future inference engine's job once it
     * actually parses the file.
     */
    fun status(context: Context): ModelPathStatus {
        val path = getModelPath(context) ?: return ModelPathStatus.NotConfigured
        val file = File(path)
        if (!file.exists()) return ModelPathStatus.FileNotFound
        if (!file.canRead()) return ModelPathStatus.NotReadable
        return if (looksLikeGguf(file)) ModelPathStatus.LooksValid(file.length()) else ModelPathStatus.NotGguf
    }

    private fun looksLikeGguf(file: File): Boolean {
        return try {
            file.inputStream().use { stream ->
                val header = ByteArray(4)
                val bytesRead = stream.read(header)
                bytesRead == 4 && header.contentEquals(GGUF_MAGIC)
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
}

sealed class ModelPathStatus {
    data object NotConfigured : ModelPathStatus()
    data object FileNotFound : ModelPathStatus()
    data object NotReadable : ModelPathStatus()
    data object NotGguf : ModelPathStatus()
    data class LooksValid(val fileSizeBytes: Long) : ModelPathStatus()
}
