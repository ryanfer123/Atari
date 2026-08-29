package com.atari.slm

/**
 * JNI Bridge to ATARI's native C++ model contract (libatari_model_jni.so).
 */
object SlmBridge {

    val isNativeContractAvailable: Boolean

    init {
        isNativeContractAvailable = try {
            System.loadLibrary("atari_model_jni")
            true
        } catch (e: UnsatisfiedLinkError) {
            false
        }
    }

    external fun nativeBuildPrompt(
        fragmentationScore: Double,
        appSwitchZ: Double,
        unlockZ: Double,
        notifZ: Double,
        timeBucket: String,
        contextSources: Array<String>?,
        contextTexts: Array<String>?
    ): String

    external fun nativeFallbackText(
        fragmentationScore: Double,
        appSwitchZ: Double,
        unlockZ: Double,
        notifZ: Double,
        timeBucket: String
    ): String

    external fun nativeIsSafeOutput(output: String): Boolean

    external fun nativeSourceSelectionSchema(
        triggerSignal: String,
        topSignal: String,
        allowedSourceIds: IntArray?,
        maxSources: Int
    ): String

    external fun nativeParseSourceSelection(jsonResponse: String): IntArray?
}
