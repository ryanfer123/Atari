package com.atari.atari

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import java.io.File
import java.nio.FloatBuffer
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * PP-OCRv5 text extraction: detection finds text boxes, recognition
 * reads each one, and a CTC greedy decode turns recognition's class
 * indices into characters.
 *
 * Unlike [ModelSlotStore], which only validates that files exist, this
 * actually loads the weights and runs inference. Sessions are created
 * once and reused — building an [OrtSession] costs hundreds of
 * milliseconds, and the capture flow runs this on every crop.
 *
 * Everything happens on-device. No image or extracted text leaves the
 * process.
 */
object PpOcrEngine {
    /** Longest side the detector sees. PP-OCR's own default. */
    private const val DET_LIMIT_SIDE = 960

    /** Detector input dimensions must be multiples of this. */
    private const val DET_STRIDE = 32

    /** Probability above which a detector pixel counts as text. */
    private const val DET_BIN_THRESHOLD = 0.3f

    /** Mean probability a whole region must reach to be kept. */
    private const val DET_BOX_THRESHOLD = 0.5f

    /** Regions smaller than this are noise, not glyphs. */
    private const val MIN_REGION_PIXELS = 12

    /** Recognition input height is fixed by the model signature. */
    private const val REC_HEIGHT = 48

    private const val REC_MIN_WIDTH = 16
    private const val REC_MAX_WIDTH = 960

    // ImageNet normalisation, which is what PP-OCR detection was trained with.
    private val DET_MEAN = floatArrayOf(0.485f, 0.456f, 0.406f)
    private val DET_STD = floatArrayOf(0.229f, 0.224f, 0.225f)

    private var env: OrtEnvironment? = null
    private var detSession: OrtSession? = null
    private var recSession: OrtSession? = null

    /**
     * Recognition's class list. Index 0 is the CTC blank and the last
     * index is a space, with the dictionary file in between — that
     * layout is what makes the class count 18385 for an 18383-line
     * dictionary.
     */
    private var charset: List<String>? = null

    class OcrUnavailable(message: String) : Exception(message)

    data class Result(val text: String, val confidence: Float)

    @Synchronized
    fun isReady(context: Context): Boolean = try {
        resolveFiles(context)
        true
    } catch (e: Exception) {
        false
    }

    /** Frees both sessions. Called when the OCR slot is reconfigured. */
    @Synchronized
    fun release() {
        detSession?.close()
        recSession?.close()
        detSession = null
        recSession = null
        charset = null
    }

    /**
     * Runs the full pipeline over [imagePath].
     *
     * Throws [OcrUnavailable] when the slot isn't usable, so the Dart
     * side can fall back to the placeholder rather than showing an empty
     * result that looks like "this image has no text".
     */
    @Synchronized
    fun recognise(context: Context, imagePath: String): Result {
        val files = resolveFiles(context)
        ensureSessions(files)

        val source = BitmapFactory.decodeFile(imagePath)
            ?: throw OcrUnavailable("Could not decode the image at $imagePath")
        val bitmap = if (source.config == Bitmap.Config.ARGB_8888) {
            source
        } else {
            source.copy(Bitmap.Config.ARGB_8888, false)
        }

        val boxes = detect(bitmap)
        if (boxes.isEmpty()) return Result("", 0f)

        val lines = groupIntoLines(boxes)
        val builder = StringBuilder()
        var confidenceTotal = 0f
        var confidenceCount = 0

        for (line in lines) {
            val pieces = mutableListOf<String>()
            for (box in line) {
                val crop = cropFor(bitmap, box) ?: continue
                val (text, confidence) = recognise(crop)
                crop.recycle()
                if (text.isBlank()) continue
                pieces += text
                confidenceTotal += confidence
                confidenceCount++
            }
            if (pieces.isNotEmpty()) {
                if (builder.isNotEmpty()) builder.append('\n')
                builder.append(pieces.joinToString(" "))
            }
        }

        if (bitmap !== source) source.recycle()

        val confidence = if (confidenceCount == 0) 0f else confidenceTotal / confidenceCount
        return Result(builder.toString(), confidence)
    }

    // ---------------------------------------------------------------
    // Setup
    // ---------------------------------------------------------------

    private data class Files(val det: File, val rec: File, val dict: File)

    private fun resolveFiles(context: Context): Files {
        val detPath = ModelSlotStore.getPath(context, "ocr")
            ?: throw OcrUnavailable("No OCR model configured")
        val det = File(detPath)
        if (!det.exists()) throw OcrUnavailable("Detection model missing at $detPath")

        val dir = det.parentFile ?: throw OcrUnavailable("Detection model has no parent directory")
        val rec = File(dir, "PP-OCRv5_mobile_rec.onnx")
        val dict = File(dir, "ppocrv5_dict.txt")
        if (!rec.exists()) throw OcrUnavailable("Recognition model missing at ${rec.absolutePath}")
        if (!dict.exists()) throw OcrUnavailable("Charset dictionary missing at ${dict.absolutePath}")
        return Files(det, rec, dict)
    }

    private fun ensureSessions(files: Files) {
        if (detSession != null && recSession != null && charset != null) return

        val environment = env ?: OrtEnvironment.getEnvironment().also { env = it }
        val options = OrtSession.SessionOptions().apply {
            // Both models are small and the phone has cores to spare;
            // this keeps a capture from blocking for seconds.
            setIntraOpNumThreads(4)
            setOptimizationLevel(OrtSession.SessionOptions.OptLevel.ALL_OPT)
        }

        if (detSession == null) detSession = environment.createSession(files.det.absolutePath, options)
        if (recSession == null) recSession = environment.createSession(files.rec.absolutePath, options)
        if (charset == null) {
            val entries = files.dict.readLines(Charsets.UTF_8).filter { it.isNotEmpty() }
            charset = buildList {
                add("")      // CTC blank
                addAll(entries)
                add(" ")     // PP-OCR appends an explicit space class
            }
        }
    }

    // ---------------------------------------------------------------
    // Detection
    // ---------------------------------------------------------------

    /** Axis-aligned box in *source bitmap* coordinates. */
    private data class Box(val left: Int, val top: Int, val right: Int, val bottom: Int) {
        val height get() = bottom - top
        val centreY get() = (top + bottom) / 2f
    }

    private fun detect(bitmap: Bitmap): List<Box> {
        val environment = env ?: return emptyList()
        val session = detSession ?: return emptyList()

        // Scale the long side down to the detector's working size, then
        // round both dimensions to the stride the network requires.
        val longest = max(bitmap.width, bitmap.height)
        val scale = if (longest > DET_LIMIT_SIDE) DET_LIMIT_SIDE.toFloat() / longest else 1f
        val targetW = roundToStride(bitmap.width * scale)
        val targetH = roundToStride(bitmap.height * scale)

        val resized = Bitmap.createScaledBitmap(bitmap, targetW, targetH, true)
        val pixels = IntArray(targetW * targetH)
        resized.getPixels(pixels, 0, targetW, 0, 0, targetW, targetH)
        if (resized !== bitmap) resized.recycle()

        val plane = targetW * targetH
        val input = FloatArray(3 * plane)
        for (i in 0 until plane) {
            val p = pixels[i]
            val r = ((p shr 16) and 0xFF) / 255f
            val g = ((p shr 8) and 0xFF) / 255f
            val b = (p and 0xFF) / 255f
            input[i] = (r - DET_MEAN[0]) / DET_STD[0]
            input[plane + i] = (g - DET_MEAN[1]) / DET_STD[1]
            input[2 * plane + i] = (b - DET_MEAN[2]) / DET_STD[2]
        }

        val shape = longArrayOf(1, 3, targetH.toLong(), targetW.toLong())
        val probability = FloatArray(plane)
        OnnxTensor.createTensor(environment, FloatBuffer.wrap(input), shape).use { tensor ->
            session.run(mapOf(session.inputNames.first() to tensor)).use { output ->
                val buffer = (output[0] as OnnxTensor).floatBuffer
                buffer.get(probability, 0, min(probability.size, buffer.remaining()))
            }
        }

        val boxes = componentBoxes(probability, targetW, targetH)

        // Back into source coordinates.
        val sx = bitmap.width.toFloat() / targetW
        val sy = bitmap.height.toFloat() / targetH
        return boxes.map { box ->
            Box(
                left = (box.left * sx).toInt().coerceIn(0, bitmap.width - 1),
                top = (box.top * sy).toInt().coerceIn(0, bitmap.height - 1),
                right = ceil(box.right * sx).toInt().coerceIn(1, bitmap.width),
                bottom = ceil(box.bottom * sy).toInt().coerceIn(1, bitmap.height),
            )
        }.filter { it.right > it.left && it.bottom > it.top }
    }

    /**
     * Finds text regions in the probability map.
     *
     * PP-OCR normally fits *rotated* min-area rectangles here. This
     * takes axis-aligned boxes instead, which is a deliberate
     * simplification for what this app actually captures: regions
     * circled out of a phone screenshot, where text is already upright.
     * Photographed pages at an angle would need the rotated version.
     */
    private fun componentBoxes(probability: FloatArray, width: Int, height: Int): List<Box> {
        val visited = BooleanArray(width * height)
        val boxes = mutableListOf<Box>()
        val stack = ArrayDeque<Int>()

        for (start in probability.indices) {
            if (visited[start] || probability[start] < DET_BIN_THRESHOLD) continue

            var left = Int.MAX_VALUE
            var top = Int.MAX_VALUE
            var right = Int.MIN_VALUE
            var bottom = Int.MIN_VALUE
            var sum = 0f
            var count = 0

            // Iterative flood fill — a recursive one overflows the stack
            // on a large block of text.
            visited[start] = true
            stack.addLast(start)
            while (stack.isNotEmpty()) {
                val index = stack.removeLast()
                val x = index % width
                val y = index / width
                if (x < left) left = x
                if (x > right) right = x
                if (y < top) top = y
                if (y > bottom) bottom = y
                sum += probability[index]
                count++

                if (x > 0) push(stack, visited, probability, index - 1)
                if (x < width - 1) push(stack, visited, probability, index + 1)
                if (y > 0) push(stack, visited, probability, index - width)
                if (y < height - 1) push(stack, visited, probability, index + width)
            }

            if (count < MIN_REGION_PIXELS) continue
            if (sum / count < DET_BOX_THRESHOLD) continue

            boxes += unclip(Box(left, top, right + 1, bottom + 1), width, height)
        }
        return boxes
    }

    private fun push(stack: ArrayDeque<Int>, visited: BooleanArray, probability: FloatArray, index: Int) {
        if (visited[index] || probability[index] < DET_BIN_THRESHOLD) return
        visited[index] = true
        stack.addLast(index)
    }

    /**
     * Grows a box outward the way PP-OCR's Vatti offset does. The
     * detector is trained to predict a *shrunk* version of each text
     * region, so without this the first and last characters get clipped.
     */
    private fun unclip(box: Box, width: Int, height: Int): Box {
        val w = box.right - box.left
        val h = box.bottom - box.top
        val perimeter = 2f * (w + h)
        if (perimeter <= 0f) return box
        val distance = (w * h * 1.5f) / perimeter
        val d = distance.roundToInt()
        return Box(
            left = (box.left - d).coerceAtLeast(0),
            top = (box.top - d).coerceAtLeast(0),
            right = (box.right + d).coerceAtMost(width),
            bottom = (box.bottom + d).coerceAtMost(height),
        )
    }

    /**
     * Sorts boxes into reading order: rows top to bottom, and within a
     * row left to right. Two boxes share a row when their vertical
     * centres are closer than half a line height, which tolerates the
     * baseline jitter between short and tall glyphs.
     */
    private fun groupIntoLines(boxes: List<Box>): List<List<Box>> {
        val sorted = boxes.sortedBy { it.centreY }
        val lines = mutableListOf<MutableList<Box>>()
        for (box in sorted) {
            val line = lines.lastOrNull()
            val tolerance = max(box.height, line?.last()?.height ?: box.height) / 2f
            if (line != null && kotlin.math.abs(box.centreY - line.last().centreY) <= tolerance) {
                line += box
            } else {
                lines += mutableListOf(box)
            }
        }
        return lines.map { line -> line.sortedBy { it.left } }
    }

    // ---------------------------------------------------------------
    // Recognition
    // ---------------------------------------------------------------

    private fun cropFor(bitmap: Bitmap, box: Box): Bitmap? {
        val w = box.right - box.left
        val h = box.bottom - box.top
        if (w <= 0 || h <= 0) return null
        return try {
            Bitmap.createBitmap(bitmap, box.left, box.top, w, h)
        } catch (e: IllegalArgumentException) {
            null
        }
    }

    private fun recognise(crop: Bitmap): Pair<String, Float> {
        val environment = env ?: return "" to 0f
        val session = recSession ?: return "" to 0f
        val classes = charset ?: return "" to 0f

        val targetW = ((REC_HEIGHT.toFloat() * crop.width / crop.height).roundToInt())
            .coerceIn(REC_MIN_WIDTH, REC_MAX_WIDTH)
        val resized = Bitmap.createScaledBitmap(crop, targetW, REC_HEIGHT, true)
        val pixels = IntArray(targetW * REC_HEIGHT)
        resized.getPixels(pixels, 0, targetW, 0, 0, targetW, REC_HEIGHT)
        if (resized !== crop) resized.recycle()

        val plane = targetW * REC_HEIGHT
        val input = FloatArray(3 * plane)
        for (i in 0 until plane) {
            val p = pixels[i]
            // Recognition uses simple [-1, 1] scaling, not the ImageNet
            // statistics the detector wants.
            input[i] = (((p shr 16) and 0xFF) / 255f - 0.5f) / 0.5f
            input[plane + i] = (((p shr 8) and 0xFF) / 255f - 0.5f) / 0.5f
            input[2 * plane + i] = ((p and 0xFF) / 255f - 0.5f) / 0.5f
        }

        val shape = longArrayOf(1, 3, REC_HEIGHT.toLong(), targetW.toLong())
        OnnxTensor.createTensor(environment, FloatBuffer.wrap(input), shape).use { tensor ->
            session.run(mapOf(session.inputNames.first() to tensor)).use { output ->
                val result = output[0] as OnnxTensor
                val dims = result.info.shape          // [1, T, classes]
                val steps = dims[1].toInt()
                val classCount = dims[2].toInt()
                val buffer = result.floatBuffer
                val flat = FloatArray(steps * classCount)
                buffer.get(flat, 0, min(flat.size, buffer.remaining()))
                return ctcDecode(flat, steps, classCount, classes)
            }
        }
    }

    /**
     * Greedy CTC decode: take the best class per timestep, then drop
     * blanks and runs of the same class. Confidence is the mean
     * probability of the characters that survived, which is what the
     * review screen shows the user.
     */
    private fun ctcDecode(
        logits: FloatArray,
        steps: Int,
        classCount: Int,
        classes: List<String>,
    ): Pair<String, Float> {
        val builder = StringBuilder()
        var previous = -1
        var total = 0f
        var kept = 0

        for (t in 0 until steps) {
            val offset = t * classCount
            var best = 0
            var bestScore = logits[offset]
            for (c in 1 until classCount) {
                val score = logits[offset + c]
                if (score > bestScore) {
                    bestScore = score
                    best = c
                }
            }

            if (best != 0 && best != previous) {
                if (best < classes.size) builder.append(classes[best])
                total += bestScore
                kept++
            }
            previous = best
        }

        val confidence = if (kept == 0) 0f else (total / kept).coerceIn(0f, 1f)
        return builder.toString() to confidence
    }

    private fun roundToStride(value: Float): Int {
        val rounded = (ceil(value / DET_STRIDE) * DET_STRIDE).toInt()
        return max(DET_STRIDE, rounded)
    }
}
