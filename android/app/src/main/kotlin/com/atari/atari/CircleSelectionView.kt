package com.atari.atari

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.Rect
import android.graphics.RectF
import android.view.MotionEvent
import android.view.View

/**
 * Full-screen overlay showing the frozen screenshot, on which the user
 * draws a circle/scribble around what they want.
 *
 * Everything outside the stroke's bounding box is dimmed, so the
 * selection reads as "this is what will be read" rather than as
 * decoration. The crop is that bounding box, not a segmented cutout —
 * EdgeSAM is stretch-only in the pivot (Plans/PIVOT_PLAN.md §2.5) and a
 * box is enough to read text out of.
 */
@SuppressLint("ViewConstructor")
class CircleSelectionView(
    context: Context,
    private val screenshot: Bitmap,
    private val onSelection: (Rect) -> Unit,
    private val onCancel: () -> Unit,
) : View(context) {

    private val path = Path()
    private var minX = Float.MAX_VALUE
    private var minY = Float.MAX_VALUE
    private var maxX = Float.MIN_VALUE
    private var maxY = Float.MIN_VALUE
    private var hasStroke = false

    private val strokePaint =
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            style = Paint.Style.STROKE
            strokeWidth = 10f
            strokeCap = Paint.Cap.ROUND
            strokeJoin = Paint.Join.ROUND
        }

    private val dimPaint = Paint().apply { color = Color.argb(150, 0, 0, 0) }
    private val clearPaint = Paint().apply { xfermode = PorterDuffXfermode(PorterDuff.Mode.CLEAR) }
    private val boxPaint =
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            style = Paint.Style.STROKE
            strokeWidth = 4f
        }
    private val hintPaint =
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            textSize = 40f
            textAlign = Paint.Align.CENTER
        }

    /** A stray tap isn't a selection; requiring real area avoids
     * "cropping" to a few pixels and blaming OCR for the result. */
    private val minSelectionPx = 60

    private val selection: Rect?
        get() {
            if (!hasStroke) return null
            val rect = Rect(minX.toInt(), minY.toInt(), maxX.toInt(), maxY.toInt())
            if (rect.width() < minSelectionPx || rect.height() < minSelectionPx) return null
            // Clamp into the screenshot; fingers overshoot the edges.
            rect.left = rect.left.coerceIn(0, screenshot.width - 1)
            rect.top = rect.top.coerceIn(0, screenshot.height - 1)
            rect.right = rect.right.coerceIn(rect.left + 1, screenshot.width)
            rect.bottom = rect.bottom.coerceIn(rect.top + 1, screenshot.height)
            return rect
        }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        canvas.drawBitmap(screenshot, null, Rect(0, 0, width, height), null)

        val rect = selection
        val layer = canvas.saveLayer(0f, 0f, width.toFloat(), height.toFloat(), null)
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), dimPaint)
        if (rect != null) {
            canvas.drawRoundRect(RectF(rect), 24f, 24f, clearPaint)
        }
        canvas.restoreToCount(layer)

        if (rect != null) {
            canvas.drawRoundRect(RectF(rect), 24f, 24f, boxPaint)
        }
        if (hasStroke) {
            canvas.drawPath(path, strokePaint)
        } else {
            canvas.drawText("Circle what you want to read", width / 2f, height * 0.9f, hintPaint)
            canvas.drawText("Tap outside to cancel", width / 2f, height * 0.9f + 52f, hintPaint)
        }
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        when (event.action) {
            MotionEvent.ACTION_DOWN -> {
                path.reset()
                path.moveTo(event.x, event.y)
                minX = event.x
                maxX = event.x
                minY = event.y
                maxY = event.y
                hasStroke = true
                invalidate()
            }
            MotionEvent.ACTION_MOVE -> {
                path.lineTo(event.x, event.y)
                minX = minOf(minX, event.x)
                maxX = maxOf(maxX, event.x)
                minY = minOf(minY, event.y)
                maxY = maxOf(maxY, event.y)
                invalidate()
            }
            MotionEvent.ACTION_UP -> {
                val rect = selection
                if (rect != null) {
                    onSelection(rect)
                } else {
                    // Too small to be a deliberate selection — treat it as
                    // "tap outside to dismiss" rather than cropping noise.
                    onCancel()
                }
            }
        }
        return true
    }
}
