package com.atari.sensing

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import java.util.concurrent.CopyOnWriteArrayList

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

        // In-memory cache of recent unlock timestamps (epoch ms)
        private val inMemoryUnlocks = CopyOnWriteArrayList<Long>()

        @Volatile
        private var isInitialized = false

        fun init(context: Context) {
            if (!isInitialized) {
                synchronized(this) {
                    if (!isInitialized) {
                        loadFromPrefs(context)
                        isInitialized = true
                    }
                }
            }
        }

        fun recordUnlock(context: Context, timestampMs: Long = System.currentTimeMillis()) {
            inMemoryUnlocks.add(timestampMs)
            // Trim old events if exceeding limit
            while (inMemoryUnlocks.size > MAX_STORED_EVENTS) {
                inMemoryUnlocks.removeAt(0)
            }
            saveToPrefs(context)
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
            }
        }
    }
}
