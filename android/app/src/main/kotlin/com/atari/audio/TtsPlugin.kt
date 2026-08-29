package com.atari.audio

import android.content.Context
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

/**
 * Platform plugin for offline Android TextToSpeech audio explanations.
 *
 * Channel: com.atari/tts
 */
@Suppress("DEPRECATION", "OVERRIDE_DEPRECATION")
class TtsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, TextToSpeech.OnInitListener {

    private lateinit var methodChannel: MethodChannel
    private lateinit var context: Context
    private var tts: TextToSpeech? = null
    private var isTtsReady = false

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "com.atari/tts")
        methodChannel.setMethodCallHandler(this)
        tts = TextToSpeech(context, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        tts?.stop()
        tts?.shutdown()
        tts = null
        isTtsReady = false
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            tts?.let { engine ->
                val result = engine.setLanguage(Locale.US)
                if (result != TextToSpeech.LANG_MISSING_DATA && result != TextToSpeech.LANG_NOT_SUPPORTED) {
                    isTtsReady = true
                    val handler = android.os.Handler(android.os.Looper.getMainLooper())
                    engine.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                        override fun onStart(utteranceId: String?) {
                            handler.post { methodChannel.invokeMethod("onSpeechStart", utteranceId) }
                        }

                        override fun onDone(utteranceId: String?) {
                            handler.post { methodChannel.invokeMethod("onSpeechDone", utteranceId) }
                        }

                        override fun onError(utteranceId: String?) {
                            handler.post { methodChannel.invokeMethod("onSpeechError", utteranceId) }
                        }
                    })
                }
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "speak" -> {
                val text = call.argument<String>("text") ?: ""
                if (!isTtsReady || tts == null) {
                    result.error("TTS_NOT_READY", "TextToSpeech engine is not initialized", null)
                    return
                }
                if (text.isBlank()) {
                    result.success(true)
                    return
                }

                val utteranceId = "atari_explanation_${System.currentTimeMillis()}"
                val speechRate = (call.argument<Double>("speechRate") ?: 1.0).toFloat().coerceIn(0.5f, 2.0f)
                val pitch = (call.argument<Double>("pitch") ?: 1.0).toFloat().coerceIn(0.5f, 2.0f)
                tts?.setSpeechRate(speechRate)
                tts?.setPitch(pitch)
                tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, utteranceId)
                result.success(true)
            }

            "stop" -> {
                tts?.stop()
                result.success(true)
            }

            "isReady" -> {
                result.success(isTtsReady)
            }

            else -> result.notImplemented()
        }
    }
}
