package com.atari.sensing

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.TimeUnit

/**
 * Tracks device unlock events and screen state changes.
 *
 * Listens for [Intent.ACTION_USER_PRESENT] to measure user presence and fragmentation.
 * Persists timestamps in SharedPreferences for cold-start and background durability.
 *
 * See Plans/IMPLEMENTATION.md §1 / §3.
 */
class UnlockTracker : BroadcastReceiver() {

    companion object {
        private const val PREFS_NAME = "atari_unlock_tracker"
        private const val KEY_UNLOCK_TIMESTAMPS = "unlock_timestamps"
        private const val MAX_STORED_EVENTS = 500
        private const val DUPLICATE_WINDOW_MS = 2_000L
        private const val MAINTENANCE_WORK_NAME = "atari-sensing-maintenance"

        // In-memory cache of recent unlock timestamps (epoch ms)
        private val inMemoryUnlocks = CopyOnWriteArrayList<Long>()

        @Volatile
        private var isInitialized = false

        fun init(context: Context) {
            if (!isInitialized) {
                synchronized(this) {
                    if (!isInitialized) {
                        loadFromPrefs(context)
                        scheduleMaintenance(context)
                        isInitialized = true
                    }
                }
            }
        }

        @Synchronized
        fun recordUnlock(context: Context, timestampMs: Long = System.currentTimeMillis()) {
            if (inMemoryUnlocks.lastOrNull()?.let {
                    timestampMs >= it && timestampMs - it < DUPLICATE_WINDOW_MS
                } == true) {
                return
            }
            inMemoryUnlocks.add(timestampMs)
            // Trim old events if exceeding limit
            while (inMemoryUnlocks.size > MAX_STORED_EVENTS) {
                inMemoryUnlocks.removeAt(0)
            }
            saveToPrefs(context)
            NotifLatencyTracker.recordNextUnlock(context, timestampMs)
        }

        /** Registers the modern runtime receiver required for USER_PRESENT on API 26+. */
        fun registerRuntimeReceiver(context: Context): UnlockTracker {
            init(context.applicationContext)
            val receiver = UnlockTracker()
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_USER_PRESENT)
                addAction(Intent.ACTION_SCREEN_OFF)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                @Suppress("DEPRECATION")
                context.registerReceiver(receiver, filter)
            }
            return receiver
        }

        fun unregisterRuntimeReceiver(context: Context, receiver: UnlockTracker?) {
            if (receiver == null) return
            runCatching { context.unregisterReceiver(receiver) }
        }

        @Synchronized
        internal fun pruneAndPersist(context: Context, nowMs: Long = System.currentTimeMillis()) {
            val retentionStartMs = nowMs - TimeUnit.DAYS.toMillis(8)
            inMemoryUnlocks.removeAll { it < retentionStartMs }
            while (inMemoryUnlocks.size > MAX_STORED_EVENTS) {
                inMemoryUnlocks.removeAt(0)
            }
            saveToPrefs(context)
            NotifLatencyTracker.pruneAndPersist(context, nowMs)
        }

        private fun scheduleMaintenance(context: Context) {
            val request = PeriodicWorkRequestBuilder<SensingMaintenanceWorker>(
                15,
                TimeUnit.MINUTES
            ).build()
            WorkManager.getInstance(context.applicationContext).enqueueUniquePeriodicWork(
                MAINTENANCE_WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                request
            )
        }

        /**
         * Returns the number of unlocks that occurred within the specified time window.
         */
        fun getUnlockCount(windowStartMs: Long, windowEndMs: Long): Int {
            return inMemoryUnlocks.count { it in windowStartMs..windowEndMs }
        }

        /**
         * Returns all unlock timestamps within the window.
         */
        fun getUnlocks(windowStartMs: Long, windowEndMs: Long): List<Long> {
            return inMemoryUnlocks.filter { it in windowStartMs..windowEndMs }
        }

        private fun loadFromPrefs(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val savedString = prefs.getString(KEY_UNLOCK_TIMESTAMPS, "") ?: ""
            if (savedString.isNotEmpty()) {
                val timestamps = savedString.split(",")
                    .mapNotNull { it.trim().toLongOrNull() }
                inMemoryUnlocks.clear()
                inMemoryUnlocks.addAll(timestamps)
            }
        }

        private fun saveToPrefs(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val joined = inMemoryUnlocks.takeLast(MAX_STORED_EVENTS).joinToString(",")
            prefs.edit().putString(KEY_UNLOCK_TIMESTAMPS, joined).apply()
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        init(context)
        when (intent.action) {
            Intent.ACTION_USER_PRESENT -> {
                recordUnlock(context, System.currentTimeMillis())
            }
            Intent.ACTION_SCREEN_OFF -> {
                // Screen off signals session end
            }
            Intent.ACTION_BOOT_COMPLETED -> {
                loadFromPrefs(context)
                scheduleMaintenance(context)
            }
        }
    }
}
