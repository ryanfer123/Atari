package com.atari.sensing

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Process

/**
 * Collects app switching / foreground transition metadata.
 *
 * Uses [UsageStatsManager.queryEvents] to count rapid application switching.
 * Never inspects in-app contents or screens — only counts package transition events.
 *
 * See Plans/IMPLEMENTATION.md §1 / §3.
 */
class AppSwitchTracker(private val context: Context) {

    private val usageStatsManager: UsageStatsManager? =
        context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager

    /**
     * Checks if the user has granted Special App Access -> Usage Access.
     */
    fun hasPermission(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager ?: return false
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            context.packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /**
     * Queries foreground transition events in the given time window and returns the total
     * count of application switches.
     */
    fun getAppSwitchCount(windowStartMs: Long, windowEndMs: Long): Int {
        if (!hasPermission() || usageStatsManager == null) {
            return 0
        }

        val events = usageStatsManager.queryEvents(windowStartMs, windowEndMs) ?: return 0
        val event = UsageEvents.Event()
        var switchCount = 0
        var lastPackage: String? = null

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            // ACTIVITY_RESUMED (1) or MOVE_TO_FOREGROUND (1)
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED ||
                event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND
            ) {
                val currentPackage = event.packageName
                if (currentPackage != null && currentPackage != lastPackage) {
                    switchCount++
                    lastPackage = currentPackage
                }
            }
        }
        return switchCount
    }

    /**
     * Computes the application switching rate (switches per minute) in the specified window.
     */
    fun getAppSwitchRatePerMinute(windowStartMs: Long, windowEndMs: Long): Double {
        val count = getAppSwitchCount(windowStartMs, windowEndMs)
        val durationMinutes = ((windowEndMs - windowStartMs) / 60000.0).coerceAtLeast(1.0)
        return count / durationMinutes
    }
}
