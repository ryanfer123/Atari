package com.atari.atari

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences

/**
 * Signal collector: device-unlock timestamps, via a BroadcastReceiver on
 * `ACTION_USER_PRESENT`. Metadata only (a timestamp), matching the base
 * app's "no behavioural content" collection boundary.
 *
 * See Plans/IMPLEMENTATION.md §3 (Workstream: Backend — Native).
 */
object UnlockTracker {
    private const val PREFS_NAME = "atari_unlock_tracker"
    private const val KEY_TIMESTAMPS = "unlock_timestamps"

    /** Bounds unbounded on-device storage growth; recent history is what
     * the baseline/classifier actually need. */
    private const val MAX_STORED_TIMESTAMPS = 1000

    private var receiver: BroadcastReceiver? = null

    /**
     * Registers the receiver if it isn't already. Called from
     * [SignalCollectionService.onCreate] — a dynamically-registered
     * receiver only survives while its owning process is alive, so
     * running that registration inside the foreground service (rather
     * than, say, [AtariApplication.onCreate] directly) is what keeps it
     * alive when the app itself is closed. See
     * [SignalCollectionService]'s kdoc for the full picture.
     */
    fun ensureRegistered(context: Context) {
        if (receiver != null) return
        val newReceiver =
            object : BroadcastReceiver() {
                override fun onReceive(context: Context, intent: Intent) {
                    if (intent.action == Intent.ACTION_USER_PRESENT) {
                        recordUnlock(context, System.currentTimeMillis())
                    }
                }
            }
        context.applicationContext.registerReceiver(newReceiver, IntentFilter(Intent.ACTION_USER_PRESENT))
        receiver = newReceiver
    }

    fun getUnlockTimestamps(context: Context): List<Long> = readTimestamps(prefs(context))

    fun getUnlockCountSince(context: Context, sinceMillis: Long): Int =
        readTimestamps(prefs(context)).count { it >= sinceMillis }

    private fun recordUnlock(context: Context, atMillis: Long) {
        val prefs = prefs(context)
        val updated = (readTimestamps(prefs) + atMillis).takeLast(MAX_STORED_TIMESTAMPS)
        prefs.edit().putString(KEY_TIMESTAMPS, updated.joinToString(",")).apply()
    }

    private fun readTimestamps(prefs: SharedPreferences): List<Long> {
        val raw = prefs.getString(KEY_TIMESTAMPS, null)
        if (raw.isNullOrBlank()) return emptyList()
        return raw.split(",").mapNotNull { it.toLongOrNull() }
    }

    private fun prefs(context: Context): SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
}
