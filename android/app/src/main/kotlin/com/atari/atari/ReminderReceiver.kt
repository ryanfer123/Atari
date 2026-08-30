package com.atari.atari

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * Fires when a scheduled reminder's alarm goes off and posts the
 * notification the user confirmed.
 *
 * Alarms are set by [ReminderScheduler]; this receiver only presents
 * them.
 */
class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(ReminderScheduler.EXTRA_ID, 0)
        val title = intent.getStringExtra(ReminderScheduler.EXTRA_TITLE) ?: "Reminder"
        val tool = intent.getStringExtra(ReminderScheduler.EXTRA_TOOL) ?: "setReminder"

        ensureChannel(context, tool)

        val tapIntent =
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
        val contentIntent =
            android.app.PendingIntent.getActivity(
                context,
                id,
                tapIntent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE,
            )

        val notification =
            NotificationCompat.Builder(context, channelIdFor(tool))
                .setContentTitle(if (tool == "setAlarm") "Alarm" else "Reminder")
                .setContentText(title)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setAutoCancel(true)
                .setContentIntent(contentIntent)
                // An alarm is time-critical and should break through; a
                // plain reminder deliberately should not, since the whole
                // product exists to reduce unnecessary interruption.
                .setPriority(if (tool == "setAlarm") NotificationCompat.PRIORITY_HIGH else NotificationCompat.PRIORITY_DEFAULT)
                .setCategory(if (tool == "setAlarm") NotificationCompat.CATEGORY_ALARM else NotificationCompat.CATEGORY_REMINDER)
                .build()

        // POST_NOTIFICATIONS can be revoked after an alarm was scheduled;
        // notify() would then throw. Dropping the notification is the
        // only option at that point, but it must not crash the process.
        try {
            NotificationManagerCompat.from(context).notify(id, notification)
        } catch (e: SecurityException) {
            android.util.Log.w("ReminderReceiver", "Notification permission missing when reminder $id fired", e)
        }
    }

    private fun channelIdFor(tool: String) = if (tool == "setAlarm") CHANNEL_ALARMS else CHANNEL_REMINDERS

    private fun ensureChannel(context: Context, tool: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java)
        val isAlarm = tool == "setAlarm"
        val channel =
            NotificationChannel(
                channelIdFor(tool),
                if (isAlarm) "Alarms" else "Reminders",
                if (isAlarm) NotificationManager.IMPORTANCE_HIGH else NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                description =
                    if (isAlarm) "Time-critical alarms you confirmed." else "Reminders for tasks you confirmed."
            }
        manager.createNotificationChannel(channel)
    }

    companion object {
        const val CHANNEL_REMINDERS = "atari_reminders"
        const val CHANNEL_ALARMS = "atari_alarms"
    }
}
