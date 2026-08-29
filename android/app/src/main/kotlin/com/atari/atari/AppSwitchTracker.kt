package com.atari.atari

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Process

/**
 * Signal collector: foreground app-switch count, via
 * `UsageStatsManager.queryEvents()`. Metadata only — event timestamps and
 * type, matching the base app's "no behavioural content" collection
 * boundary.
 *
 * Requires the user to manually grant Usage access (Settings → Apps →
 * Special access → Usage access) — there is no `requestPermissions()`
 * dialog path for this permission. See Plans/IMPLEMENTATION.md §5.
 */
object AppSwitchTracker {
    fun hasUsageAccess(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName)
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /**
     * Count of `MOVE_TO_FOREGROUND` transitions, across all apps, in
     * `[sinceMillis, now]`. Requires [hasUsageAccess]; without it,
     * `queryEvents` simply returns an empty result rather than throwing,
     * so this returns 0 rather than needing its own error path.
     */
    fun getAppSwitchCountSince(context: Context, sinceMillis: Long): Int {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val events = usageStatsManager.queryEvents(sinceMillis, System.currentTimeMillis())
        val event = UsageEvents.Event()
        var count = 0
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                count++
            }
        }
        return count
    }
}
