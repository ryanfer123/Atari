package com.atari.atari

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * Schedules OS-level alarms for user-confirmed reminders via
 * [AlarmManager], firing [ReminderReceiver] which posts the actual
 * notification.
 *
 * Nothing gets here without an explicit user tap — see
 * Plans/PIVOT_PLAN.md §2.4.
 */
object ReminderScheduler {
    const val EXTRA_ID = "reminder_id"
    const val EXTRA_TITLE = "reminder_title"
    const val EXTRA_TOOL = "reminder_tool"

    private const val TAG = "ReminderScheduler"

    /**
     * Exact alarms need explicit user permission on Android 12+. We
     * check rather than assume, and fall back to an inexact alarm if
     * it's not granted — a reminder that fires within a few minutes of
     * the requested time is far better than one that never fires or a
     * SecurityException crash.
     */
    fun canScheduleExact(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val alarmManager = context.getSystemService(AlarmManager::class.java)
        return alarmManager.canScheduleExactAlarms()
    }

    fun schedule(context: Context, id: Int, title: String, triggerAtMillis: Long, tool: String): Boolean {
        val alarmManager = context.getSystemService(AlarmManager::class.java)
        val pendingIntent = buildPendingIntent(context, id, title, tool)

        return try {
            if (tool == "setAlarm") {
                // setAlarmClock() is what registers with
                // AlarmManager.getNextAlarmClock() — immune to Doze
                // batching, and surfaced by the OS the way a real alarm
                // is (status bar icon, lock-screen next-alarm info),
                // unlike a plain exact alarm. It's also exempt from the
                // SCHEDULE_EXACT_ALARM gate below: Android reserves this
                // API for genuine alarm-clock use. ReminderReceiver still
                // posts our own notification when it fires — this only
                // changes how the OS treats the alarm beforehand.
                val showIntent = PendingIntent.getActivity(
                    context,
                    id,
                    Intent(context, MainActivity::class.java),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                alarmManager.setAlarmClock(AlarmManager.AlarmClockInfo(triggerAtMillis, showIntent), pendingIntent)
            } else if (canScheduleExact(context)) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            } else {
                // Inexact but Doze-tolerant: the OS batches it, so it can
                // land a few minutes late. Logged so the discrepancy is
                // traceable rather than silently surprising.
                Log.i(TAG, "Exact alarms not permitted; scheduling inexact alarm for reminder $id")
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            }
            true
        } catch (e: SecurityException) {
            Log.w(TAG, "Denied permission to schedule alarm for reminder $id", e)
            false
        }
    }

    fun cancel(context: Context, id: Int) {
        val alarmManager = context.getSystemService(AlarmManager::class.java)
        alarmManager.cancel(buildPendingIntent(context, id, title = "", tool = ""))
    }

    private fun buildPendingIntent(context: Context, id: Int, title: String, tool: String): PendingIntent {
        val intent =
            Intent(context, ReminderReceiver::class.java).apply {
                putExtra(EXTRA_ID, id)
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_TOOL, tool)
            }
        // FLAG_UPDATE_CURRENT so rescheduling the same reminder id
        // replaces rather than duplicates it; the id is also the request
        // code, which is what makes cancel() able to find this alarm.
        return PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
