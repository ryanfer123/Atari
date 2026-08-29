package com.atari.atari

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * Foreground service that owns every signal collector's live registration
 * (currently [UnlockTracker]; `AppSwitchTracker`/`NotifLatencyTracker` join
 * it as they're added).
 *
 * A dynamically-registered `BroadcastReceiver`, or any plain background
 * process, can be killed by Android at any time once the app isn't the
 * foreground activity — and on this device, OriginOS's own background
 * killer is more aggressive than stock Android on top of that. Running as
 * a foreground service with a persistent notification is what actually
 * keeps collection running when the app is closed, by telling the system
 * this process is doing ongoing, user-visible work.
 *
 * This is not a complete fix by itself: it still needs (1) a boot receiver
 * ([BootReceiver]) since services don't survive a reboot, and (2), on this
 * hardware, the user manually setting battery usage to "No restrictions"
 * and enabling Autostart for this app in OriginOS's own settings — there
 * is no standard Android API that reliably overrides an OEM's own
 * background-killer. See docs/development.md.
 */
class SignalCollectionService : Service() {
    override fun onCreate() {
        super.onCreate()
        isRunning = true
        startForeground(NOTIFICATION_ID, buildNotification())
        UnlockTracker.ensureRegistered(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Sticky: if Android reclaims this service's process outright
        // (distinct from just backgrounding the app UI), ask the system to
        // recreate it — this is the "wake up in isolation" case
        // [SignalCollectionHeartbeatWorker] otherwise handles on a delay.
        return START_STICKY
    }

    override fun onDestroy() {
        isRunning = false
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun buildNotification(): Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            val channel =
                NotificationChannel(CHANNEL_ID, "Signal collection", NotificationManager.IMPORTANCE_LOW).apply {
                    description = "ATARI is recording on-device usage signals (unlocks, app switches)."
                }
            manager.createNotificationChannel(channel)
        }
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("ATARI is monitoring your phone activity")
            .setContentText("On-device only — nothing leaves your phone.")
            // TODO(frontend): replace with a real status-bar icon once app
            // assets exist; the launcher icon is a placeholder.
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    companion object {
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "atari_signal_collection"

        @Volatile
        var isRunning: Boolean = false
            private set
    }
}
