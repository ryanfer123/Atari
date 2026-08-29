package com.atari.sensing

import android.content.ComponentName
import android.content.Context
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CopyOnWriteArrayList

/**
 * Tracks notification timing metadata and response latencies.
 *
 * CRITICAL PRIVACY INVARIANT:
 * Strictly records timestamps only. Never reads or stores notification titles,
 * text contents, sender details, or package contents.
 *
 * See Plans/IMPLEMENTATION.md §1 / §3.
 */
class NotifLatencyTracker : NotificationListenerService() {

    companion object {
        private const val MAX_LATENCY_HISTORY = 100

        // Maps non-identifying notification hash -> postTimeMillis
        private val activePostTimes = ConcurrentHashMap<Int, Long>()

        // Recorded response latencies in milliseconds
        private val latencyHistory = CopyOnWriteArrayList<Long>()

        fun isPermissionGranted(context: Context): Boolean {
            val flat = Settings.Secure.getString(
                context.contentResolver,
                "enabled_notification_listeners"
            ) ?: return false
            val cn = ComponentName(context, NotifLatencyTracker::class.java)
            return flat.contains(cn.flattenToString())
        }

        fun recordNotificationPost(notifId: Int, postTime: Long) {
            activePostTimes[notifId] = postTime
        }

        fun recordNotificationDismissal(notifId: Int, dismissTime: Long) {
            val postTime = activePostTimes.remove(notifId) ?: return
            val latencyMs = (dismissTime - postTime).coerceAtLeast(0L)
            latencyHistory.add(latencyMs)
            while (latencyHistory.size > MAX_LATENCY_HISTORY) {
                latencyHistory.removeAt(0)
            }
        }

        /**
         * Returns the average notification response latency in milliseconds.
         * Returns 0.0 if no latency data has been recorded.
         */
        fun getAverageLatencyMs(): Double {
            if (latencyHistory.isEmpty()) return 0.0
            return latencyHistory.average()
        }

        fun clearHistory() {
            activePostTimes.clear()
            latencyHistory.clear()
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        // Use non-reversible hash of key for timing reference only
        val notifKeyHash = sbn.key?.hashCode() ?: sbn.id
        recordNotificationPost(notifKeyHash, sbn.postTime)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        if (sbn == null) return
        val notifKeyHash = sbn.key?.hashCode() ?: sbn.id
        recordNotificationDismissal(notifKeyHash, System.currentTimeMillis())
    }
}
