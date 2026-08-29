package com.atari.atari

import android.content.Context
import android.content.SharedPreferences

/**
 * Persists notification-timing metadata recorded by
 * [AtariNotificationListenerService] and computes latency against either
 * dismissal or the next unlock, whichever comes first.
 *
 * Only ever stores a notification's `key` (an opaque system identifier —
 * package/id/tag/uid, not user-authored content) and two timestamps.
 * Title, text, and every other piece of notification content are never
 * read, matching the base app's collection boundary (README.md).
 *
 * See Plans/IMPLEMENTATION.md §3/§4.1 (`notif_latency_ms`).
 */
object NotifLatencyTracker {
    private const val PREFS_NAME = "atari_notif_latency_tracker"
    private const val KEY_EVENTS = "notif_events"
    private const val MAX_STORED_EVENTS = 500

    // Unit/record separator control characters (U+001F, U+001E) — not
    // valid inside a notification key, used purely as field/record
    // delimiters. They render invisibly in editors; that's expected, not
    // an accidental empty string. Avoids ambiguity from keys that may
    // themselves contain ':' or other "normal" punctuation.
    private const val FIELD_SEP = ""
    private const val RECORD_SEP = ""

    data class NotifEvent(val key: String, val postedAt: Long, val removedAt: Long?)

    fun recordPosted(context: Context, key: String, postedAt: Long) {
        val prefs = prefs(context)
        val events = readEvents(prefs).toMutableList()
        events.removeAll { it.key == key } // replace any stale unresolved entry for the same key
        events.add(NotifEvent(key, postedAt, null))
        writeEvents(prefs, events.takeLast(MAX_STORED_EVENTS))
    }

    fun recordRemoved(context: Context, key: String, removedAt: Long) {
        val prefs = prefs(context)
        val events = readEvents(prefs).toMutableList()
        val index = events.indexOfLast { it.key == key && it.removedAt == null }
        if (index < 0) return // removal for a posted event we never saw (e.g. pre-process-start) — nothing to update
        events[index] = events[index].copy(removedAt = removedAt)
        writeEvents(prefs, events)
    }

    /**
     * Latency in milliseconds for each notification posted at or after
     * [sinceMillis]: time until it was removed, or time until the next
     * unlock after it posted, whichever is earlier. A notification that
     * is neither removed nor followed by a recorded unlock yet is
     * excluded — it's still "open", not zero-latency.
     */
    fun getLatenciesSince(context: Context, sinceMillis: Long): List<Long> {
        val events = readEvents(prefs(context)).filter { it.postedAt >= sinceMillis }
        val unlockTimestamps = UnlockTracker.getUnlockTimestamps(context)
        return events.mapNotNull { event ->
            val nextUnlock = unlockTimestamps.filter { it >= event.postedAt }.minOrNull()
            listOfNotNull(event.removedAt, nextUnlock).minOrNull()?.let { it - event.postedAt }
        }
    }

    private fun readEvents(prefs: SharedPreferences): List<NotifEvent> {
        val raw = prefs.getString(KEY_EVENTS, null)
        if (raw.isNullOrBlank()) return emptyList()
        return raw.split(RECORD_SEP).mapNotNull { record ->
            val parts = record.split(FIELD_SEP)
            if (parts.size != 3) return@mapNotNull null
            val postedAt = parts[1].toLongOrNull() ?: return@mapNotNull null
            val removedAt = if (parts[2].isEmpty()) null else parts[2].toLongOrNull()
            NotifEvent(key = parts[0], postedAt = postedAt, removedAt = removedAt)
        }
    }

    private fun writeEvents(prefs: SharedPreferences, events: List<NotifEvent>) {
        val serialized =
            events.joinToString(RECORD_SEP) { e -> listOf(e.key, e.postedAt, e.removedAt ?: "").joinToString(FIELD_SEP) }
        prefs.edit().putString(KEY_EVENTS, serialized).apply()
    }

    private fun prefs(context: Context): SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
}
