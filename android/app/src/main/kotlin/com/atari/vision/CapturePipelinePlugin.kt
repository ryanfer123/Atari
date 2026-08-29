package com.atari.vision

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import kotlin.math.max
import kotlin.math.min

/**
 * Platform plugin for on-device capture pipeline (scribble-to-crop + OCR extraction).
 *
 * Current milestone: deterministic scribble bounding-box crop only.
 * EdgeSAM, DocScanner dewarp, and PP-OCR adapters are not connected yet.
 *
 * Channel: com.atari/capture
 * See Plans/IMPLEMENTATION.md §4.6
 */
class CapturePipelinePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "com.atari/capture")
        methodChannel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
    }

    @Suppress("UNCHECKED_CAST")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "capture" -> {
                val rawPoints = call.argument<List<Map<String, Double>>>("scribblePoints") ?: emptyList()
                val sourceImagePath = call.argument<String>("sourceImagePath") ?: ""
                val origin = call.argument<String>("origin") ?: "camera" // "camera" | "screenshot"

                try {
                    val captureResult = processCapture(sourceImagePath, rawPoints, origin)
                    result.success(captureResult)
                } catch (e: Exception) {
                    result.error("CAPTURE_ERROR", "Failed to process image capture: ${e.message}", null)
                }
            }

            else -> result.notImplemented()
        }
    }

    private fun processCapture(
        imagePath: String,
        points: List<Map<String, Double>>,
        origin: String
    ): Map<String, Any> {
        require(origin == "camera" || origin == "screenshot") {
            "Unsupported capture origin: $origin"
        }
        val imageFile = File(imagePath)
        val ocrText = ""
        val confidence = 0.0f
        var outputPath = imagePath

        require(imageFile.isFile) { "Source image does not exist: $imagePath" }
        val bitmap = BitmapFactory.decodeFile(imagePath)
            ?: throw IllegalArgumentException("Source image is not decodable: $imagePath")
        if (points.isNotEmpty()) {
            // Calculate bounding box from scribble points
            var minX = Float.MAX_VALUE
            var minY = Float.MAX_VALUE
            var maxX = Float.MIN_VALUE
            var maxY = Float.MIN_VALUE

            for (pt in points) {
                val x = (pt["dx"] ?: 0.0).toFloat()
                val y = (pt["dy"] ?: 0.0).toFloat()
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }

            // Add padding
            val padX = (maxX - minX) * 0.1f
            val padY = (maxY - minY) * 0.1f
            val cropLeft = max(0, (minX - padX).toInt())
            val cropTop = max(0, (minY - padY).toInt())
            val cropWidth = min(bitmap.width - cropLeft, max(1, (maxX - minX + 2 * padX).toInt()))
            val cropHeight = min(bitmap.height - cropTop, max(1, (maxY - minY + 2 * padY).toInt()))

            if (cropWidth > 0 && cropHeight > 0 && cropLeft + cropWidth <= bitmap.width && cropTop + cropHeight <= bitmap.height) {
                val croppedBitmap = Bitmap.createBitmap(bitmap, cropLeft, cropTop, cropWidth, cropHeight)
                val outputFile = File(context.cacheDir, "rectified_capture_${System.currentTimeMillis()}.png")
                FileOutputStream(outputFile).use { out ->
                    croppedBitmap.compress(Bitmap.CompressFormat.PNG, 95, out)
                }
                outputPath = outputFile.absolutePath
            }
        }

        return mapOf(
            "rectifiedImagePath" to outputPath,
            "ocrText" to ocrText,
            "ocrConfidence" to confidence,
            "pipelineReady" to false,
            "pipelineStatus" to "scribble_crop_only_ocr_pending"
        )
    }
}
