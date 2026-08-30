package com.atari.atari

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.Outline
import android.graphics.PixelFormat
import android.graphics.Rect
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewOutlineProvider
import android.view.WindowManager
import android.widget.ImageView
import androidx.core.app.NotificationCompat
import com.airbnb.lottie.LottieAnimationView
import com.airbnb.lottie.LottieDrawable
import java.io.File
import java.io.FileOutputStream
import kotlin.math.abs

/**
 * Circle-to-Search: a draggable bubble (a looping cat animation) that
 * floats over other apps, freezes the screen when tapped, and lets the
 * user circle a region to extract.
 *
 * A foreground service is what makes this work from *any* app rather
 * than only inside ATARI — it owns the `SYSTEM_ALERT_WINDOW` views and
 * holds the screen projection for the session.
 *
 * Two Android constraints shape this design and both are easy to get
 * wrong:
 *
 * 1. **The service must already be foreground with type
 *    `mediaProjection` before `getMediaProjection` is called** (API 29+),
 *    and the type must be passed to [startForeground] explicitly — the
 *    manifest attribute alone is not enough. Otherwise the projection
 *    throws a SecurityException.
 * 2. **A projection consent token is single-use from Android 14.** Once
 *    the resulting `MediaProjection` is stopped it cannot be recreated
 *    from the same token, so the projection and its `VirtualDisplay` are
 *    created **once** here and kept for the session rather than torn
 *    down after each frame. The cost is that the system's screen-capture
 *    indicator stays visible while the feature is on, which is honest:
 *    the app genuinely can read the screen until it's turned off.
 */
class CaptureOverlayService : Service() {

    private lateinit var windowManager: WindowManager
    private var bubble: View? = null
    private var overlay: CircleSelectionView? = null
    private var screenshot: Bitmap? = null

    private var projection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null

    /** Set when a capture has been asked for; the frame listener turns
     * the next available frame into a bitmap only while this is true, so
     * idle frames cost nothing. */
    @Volatile
    private var awaitingFrame = false

    private val main = Handler(Looper.getMainLooper())

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                // Foreground first, with the type — see the class comment.
                goForeground()

                val resultCode = intent.getIntExtra(EXTRA_RESULT_CODE, 0)
                val data = IntentCompat.getParcelableExtra(intent, EXTRA_RESULT_DATA)
                if (data == null || !startProjection(resultCode, data)) {
                    Log.e(TAG, "Could not start the screen projection")
                    stopEverything()
                    return START_NOT_STICKY
                }

                showBubble()
                isRunning = true
            }
            ACTION_STOP -> {
                stopEverything()
                return START_NOT_STICKY
            }
            ACTION_CAPTURE_NOW -> {
                hideBubble()
                // Let our own UI actually leave the screen first, or the
                // capture is just a picture of this app.
                main.postDelayed({ requestFrame() }, 400)
            }
        }
        // Not sticky: a restarted service would have no projection token,
        // and silently showing a bubble that can't capture is worse than
        // being off.
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        isRunning = false
        releaseProjection()
        removeOverlay()
        hideBubble()
        screenshot?.recycle()
        screenshot = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // ------------------------------------------------------------ projection

    private fun goForeground() {
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    /** Creates the projection and a persistent virtual display. */
    private fun startProjection(resultCode: Int, data: Intent): Boolean {
        return try {
            val manager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            val created = manager.getMediaProjection(resultCode, data) ?: return false

            created.registerCallback(
                object : MediaProjection.Callback() {
                    override fun onStop() {
                        // The user can revoke capture from the system UI;
                        // the bubble must not linger implying it still works.
                        main.post { stopEverything() }
                    }
                },
                main,
            )

            val metrics = resources.displayMetrics
            val width = metrics.widthPixels
            val height = metrics.heightPixels

            val reader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
            reader.setOnImageAvailableListener({ r -> onFrame(r, width, height) }, main)

            virtualDisplay =
                created.createVirtualDisplay(
                    "atari-circle-capture",
                    width,
                    height,
                    metrics.densityDpi,
                    DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                    reader.surface,
                    null,
                    null,
                )

            projection = created
            imageReader = reader
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start the projection", e)
            false
        }
    }

    private fun releaseProjection() {
        runCatching { imageReader?.setOnImageAvailableListener(null, null) }
        runCatching { virtualDisplay?.release() }
        runCatching { imageReader?.close() }
        runCatching { projection?.stop() }
        virtualDisplay = null
        imageReader = null
        projection = null
    }

    private fun requestFrame() {
        if (projection == null) {
            Log.w(TAG, "Capture requested with no active projection")
            showBubble()
            return
        }
        awaitingFrame = true
        // Frames only arrive when the screen content changes. On a static
        // screen the reader may already hold one, so try immediately
        // rather than waiting for a change that may never come.
        imageReader?.let { onFrame(it, it.width, it.height) }
    }

    private fun onFrame(reader: ImageReader, width: Int, height: Int) {
        val image = reader.acquireLatestImage() ?: return
        try {
            if (!awaitingFrame) return
            awaitingFrame = false

            val plane = image.planes[0]
            // Rows are padded to a stride, so the bitmap must be created
            // wider and then cropped back, or every row shears.
            val rowPadding = plane.rowStride - plane.pixelStride * width
            val padded =
                Bitmap.createBitmap(
                    width + rowPadding / plane.pixelStride,
                    height,
                    Bitmap.Config.ARGB_8888,
                )
            padded.copyPixelsFromBuffer(plane.buffer)
            val shot = Bitmap.createBitmap(padded, 0, 0, width, height)
            padded.recycle()

            main.post { showSelectionOverlay(shot) }
        } catch (e: Exception) {
            Log.e(TAG, "Failed reading the captured frame", e)
            awaitingFrame = false
            main.post { showBubble() }
        } finally {
            image.close()
        }
    }

    // ---------------------------------------------------------------- bubble

    private fun showBubble() {
        if (bubble != null) return

        // Square, not the animation's 4:3 canvas — a wide rectangular
        // bubble around a round character reads as dead padding.
        val density = resources.displayMetrics.density
        val bubbleSize = (BUBBLE_SIZE_DP * density).toInt()

        val view =
            LottieAnimationView(this).apply {
                setAnimation(BUBBLE_ANIMATION_ASSET)
                repeatCount = LottieDrawable.INFINITE
                // CENTER_CROP fills the square bubble instead of
                // letterboxing the animation's 4:3 canvas. The tail
                // reaches past the body, so on top of that, `scaleX`/
                // `scaleY` — an ordinary View transform, not a custom
                // Matrix on the drawable itself — zooms in around the
                // view's own center, pushing the tail mostly out of
                // frame along with the rest of the crop's edges. This
                // is the standard, always-supported way to zoom a View;
                // the previous attempt derived a Matrix from the
                // animation's own composition size instead, which
                // turned out to make the cat stop rendering entirely.
                scaleType = ImageView.ScaleType.CENTER_CROP
                scaleX = BUBBLE_ZOOM
                scaleY = BUBBLE_ZOOM
                playAnimation()
            }

        // Masked to a circle so only the body reads as the bubble, not
        // the square frame around it. A literal click-through region
        // for the corners outside the circle needs
        // ViewTreeObserver.OnComputeInternalInsetsListener, confirmed
        // earlier to be a hidden/system API unavailable to a normal
        // app — this only changes what's drawn, not the touchable area,
        // which stays the full square.
        view.outlineProvider =
            object : ViewOutlineProvider() {
                override fun getOutline(v: View, outline: Outline) {
                    outline.setOval(0, 0, v.width, v.height)
                }
            }
        view.clipToOutline = true

        val params =
            WindowManager.LayoutParams(
                bubbleSize,
                bubbleSize,
                overlayWindowType(),
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                PixelFormat.TRANSLUCENT,
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                x = 0
                y = resources.displayMetrics.heightPixels / 3
            }

        // Drag to move, tap to capture — separated by movement distance so
        // a slightly imprecise tap still triggers a capture.
        var initialX = 0
        var initialY = 0
        var touchX = 0f
        var touchY = 0f
        var dragged = false

        view.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params.x
                    initialY = params.y
                    touchX = event.rawX
                    touchY = event.rawY
                    dragged = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - touchX
                    val dy = event.rawY - touchY
                    if (abs(dx) > TAP_SLOP || abs(dy) > TAP_SLOP) dragged = true
                    // Clamped to the screen, not left free to wander
                    // off it — this is what lets a drag reach any of
                    // the four corners rather than getting the bubble
                    // stuck out of reach above the top or below the
                    // bottom.
                    val maxY = resources.displayMetrics.heightPixels - bubbleSize
                    params.x = initialX + dx.toInt()
                    params.y = (initialY + dy.toInt()).coerceIn(0, maxY)
                    runCatching { windowManager.updateViewLayout(view, params) }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (!dragged) {
                        hideBubble()
                        // Let the bubble disappear before the frame is
                        // grabbed, or it shows up in the capture.
                        main.postDelayed({ requestFrame() }, 250)
                    } else {
                        // Settle against whichever side of the screen it's
                        // nearer to, rather than left floating mid-screen.
                        val screenWidth = resources.displayMetrics.widthPixels
                        val centerX = params.x + bubbleSize / 2
                        params.x = if (centerX < screenWidth / 2) 0 else screenWidth - bubbleSize
                        runCatching { windowManager.updateViewLayout(view, params) }
                    }
                    true
                }
                else -> false
            }
        }

        try {
            windowManager.addView(view, params)
            bubble = view
        } catch (e: Exception) {
            Log.e(TAG, "Could not add the floating bubble — is overlay permission granted?", e)
        }
    }

    private fun hideBubble() {
        bubble?.let { runCatching { windowManager.removeView(it) } }
        bubble = null
    }

    // --------------------------------------------------------------- overlay

    private fun showSelectionOverlay(shot: Bitmap) {
        removeOverlay()
        screenshot?.recycle()
        screenshot = shot

        val view =
            CircleSelectionView(
                context = this,
                screenshot = shot,
                onSelection = { rect -> onRegionSelected(shot, rect) },
                onCancel = {
                    removeOverlay()
                    showBubble()
                },
            )

        val params =
            WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                overlayWindowType(),
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                PixelFormat.TRANSLUCENT,
            )

        try {
            windowManager.addView(view, params)
            overlay = view
        } catch (e: Exception) {
            Log.e(TAG, "Could not show the selection overlay", e)
            showBubble()
        }
    }

    private fun removeOverlay() {
        overlay?.let { runCatching { windowManager.removeView(it) } }
        overlay = null
    }

    private fun onRegionSelected(shot: Bitmap, rect: Rect) {
        removeOverlay()

        val cropped =
            try {
                Bitmap.createBitmap(shot, rect.left, rect.top, rect.width(), rect.height())
            } catch (e: Exception) {
                Log.e(TAG, "Crop failed for rect $rect", e)
                showBubble()
                return
            }

        val file = File(cacheDir, "circle_capture_${System.currentTimeMillis()}.png")
        try {
            FileOutputStream(file).use { out -> cropped.compress(Bitmap.CompressFormat.PNG, 100, out) }
        } catch (e: Exception) {
            Log.e(TAG, "Could not write the crop", e)
            cropped.recycle()
            showBubble()
            return
        }
        cropped.recycle()

        // Hand the crop to the app, which does OCR, review and embedding.
        startActivity(
            Intent(this, MainActivity::class.java).apply {
                action = ACTION_CAPTURED
                putExtra(EXTRA_CROP_PATH, file.absolutePath)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            },
        )
        showBubble()
    }

    // ----------------------------------------------------------------- misc

    private fun stopEverything() {
        isRunning = false
        releaseProjection()
        removeOverlay()
        hideBubble()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun overlayWindowType(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

    private fun buildNotification(): android.app.Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "Circle to capture", NotificationManager.IMPORTANCE_LOW).apply {
                    description = "Keeps the floating capture button available over other apps."
                },
            )
        }

        val stopIntent =
            PendingIntent.getService(
                this,
                0,
                Intent(this, CaptureOverlayService::class.java).setAction(ACTION_STOP),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Circle to capture is on")
            .setContentText("Tap the floating button over any app to capture and circle.")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .addAction(0, "Turn off", stopIntent)
            .build()
    }

    companion object {
        const val ACTION_START = "com.atari.atari.CAPTURE_START"
        const val ACTION_STOP = "com.atari.atari.CAPTURE_STOP"
        const val ACTION_CAPTURE_NOW = "com.atari.atari.CAPTURE_NOW"
        const val ACTION_CAPTURED = "com.atari.atari.CAPTURED"

        const val EXTRA_RESULT_CODE = "result_code"
        const val EXTRA_RESULT_DATA = "result_data"
        const val EXTRA_CROP_PATH = "crop_path"

        private const val NOTIFICATION_ID = 1002
        private const val CHANNEL_ID = "atari_circle_capture"
        private const val TAG = "CaptureOverlayService"
        private const val TAP_SLOP = 12f

        // Lives in android/app/src/main/assets/, not the Flutter asset
        // bundle — this animation renders in a raw WindowManager overlay
        // outside the Flutter engine, via the native Lottie library.
        private const val BUBBLE_ANIMATION_ASSET = "lens_cat.json"
        private const val BUBBLE_SIZE_DP = 110

        // How far the view zooms in on its own center via scaleX/scaleY
        // — enough to crop the tail mostly out of frame, keeping the
        // circle centered on the body.
        private const val BUBBLE_ZOOM = 1.6f

        @Volatile
        var isRunning: Boolean = false
            private set
    }
}

/** Small shim so the parcelable read stays type-safe on API 33+. */
private object IntentCompat {
    fun getParcelableExtra(intent: Intent, name: String): Intent? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(name, Intent::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(name)
        }
}
