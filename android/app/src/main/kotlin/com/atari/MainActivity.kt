package com.atari

import com.atari.audio.TtsPlugin
import com.atari.sensing.SensingPlugin
import com.atari.slm.SlmPlugin
import com.atari.vision.CapturePipelinePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * ATARI Android Main Activity.
 *
 * Configures Flutter engine and registers all native plugins for on-device sensing,
 * offline SLM explanations, offline TTS, and vision capture pipelines.
 */
class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register custom native platform plugins
        flutterEngine.plugins.add(SensingPlugin())
        flutterEngine.plugins.add(SlmPlugin())
        flutterEngine.plugins.add(TtsPlugin())
        flutterEngine.plugins.add(CapturePipelinePlugin())
    }
}
