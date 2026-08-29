package com.atari.sensing

import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
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
        private const val PREFS_NAME = "atari_notification_latency"
        private const val KEY_ACTIVE_POSTS = "active_posts"
        private const val KEY_LATENCIES = "latencies"
        private const val MAX_ACTIVE_AGE_MS = 24 * 60 * 60 * 1000L

        // Maps non-identifying notification hash -> postTimeMillis
        private val activePostTimes = ConcurrentHashMap<Int, Long>()

        // Recorded response latencies in milliseconds
        private val latencyHistory = CopyOnWriteArrayList<Long>()

        @Volatile
        private var isInitialized = false

        fun init(context: Context) {
            if (isInitialized) return
            synchronized(this) {
                if (isInitialized) return
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                restoreFromPrefs(prefs)
                isInitialized = true
            }
        }

        fun isPermissionGranted(context: Context): Boolean {
            val flat = Settings.Secure.getString(
                context.contentResolver,
                "enabled_notification_listeners"
            ) ?: return false
            val cn = ComponentName(context, NotifLatencyTracker::class.java)
            return flat.contains(cn.flattenToString())
        }

        @Synchronized
        fun recordNotificationPost(context: Context, notifId: Int, postTime: Long) {
            init(context)
            activePostTimes[notifId] = postTime
            saveToPrefs(context)
        }

        @Synchronized
        fun recordNotificationDismissal(context: Context, notifId: Int, dismissTime: Long) {
            init(context)
            val postTime = activePostTimes.remove(notifId) ?: return
            addLatency((dismissTime - postTime).coerceAtLeast(0L))
            saveToPrefs(context)
        }

        /** Records post-to-unlock latency for every notification still active at this unlock. */
        @Synchronized
        fun recordNextUnlock(context: Context, unlockTime: Long) {
            init(context)
            val completed = activePostTimes.entries.filter { it.value <= unlockTime }
            if (completed.isEmpty()) return
            completed.forEach { entry ->
                if (activePostTimes.remove(entry.key, entry.value)) {
                    addLatency((unlockTime - entry.value).coerceAtLeast(0L))
                }
            }
            saveToPrefs(context)
        }

        /**
         * Returns the average notification response latency in milliseconds.
         * Returns 0.0 if no latency data has been recorded.
         */
        fun getAverageLatencyMs(): Double {
            if (latencyHistory.isEmpty()) return 0.0
            return latencyHistory.average()
        }

        @Synchronized
        fun clearHistory(context: Context? = null) {
            activePostTimes.clear()
            latencyHistory.clear()
            context?.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)?.edit()?.clear()?.apply()
        }

        @Synchronized
        internal fun pruneAndPersist(context: Context, nowMs: Long) {
            init(context)
            activePostTimes.entries.removeAll { nowMs - it.value > MAX_ACTIVE_AGE_MS }
            while (latencyHistory.size > MAX_LATENCY_HISTORY) latencyHistory.removeAt(0)
            saveToPrefs(context)
        }

        private fun addLatency(latencyMs: Long) {
            latencyHistory.add(latencyMs)
            while (latencyHistory.size > MAX_LATENCY_HISTORY) latencyHistory.removeAt(0)
        }

        private fun restoreFromPrefs(prefs: SharedPreferences) {
            activePostTimes.clear()
            prefs.getString(KEY_ACTIVE_POSTS, "").orEmpty().split(',').forEach { encoded ->
                val parts = encoded.split(':', limit = 2)
                val key = parts.getOrNull(0)?.toIntOrNull()
                val time = parts.getOrNull(1)?.toLongOrNull()
                if (key != null && time != null) activePostTimes[key] = time
            }
            latencyHistory.clear()
            latencyHistory.addAll(
                prefs.getString(KEY_LATENCIES, "").orEmpty().split(',').mapNotNull(String::toLongOrNull)
            )
        }

        private fun saveToPrefs(context: Context) {
            val active = activePostTimes.entries.joinToString(",") { "${it.key}:${it.value}" }
            val latencies = latencyHistory.takeLast(MAX_LATENCY_HISTORY).joinToString(",")
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit()
                .putString(KEY_ACTIVE_POSTS, active)
                .putString(KEY_LATENCIES, latencies)
                .apply()
        }
    }

    private var unlockReceiver: UnlockTracker? = null

    override fun onCreate() {
        super.onCreate()
        init(applicationContext)
        unlockReceiver = UnlockTracker.registerRuntimeReceiver(applicationContext)
    }

    override fun onDestroy() {
        UnlockTracker.unregisterRuntimeReceiver(applicationContext, unlockReceiver)
        unlockReceiver = null
        super.onDestroy()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        // Use non-reversible hash of key for timing reference only
        val notifKeyHash = sbn.key?.hashCode() ?: sbn.id
        recordNotificationPost(applicationContext, notifKeyHash, sbn.postTime)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        if (sbn == null) return
        val notifKeyHash = sbn.key?.hashCode() ?: sbn.id
        recordNotificationDismissal(applicationContext, notifKeyHash, System.currentTimeMillis())
    }
}
