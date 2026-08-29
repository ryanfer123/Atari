package com.atari.atari

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

/**
 * Records only *when* a notification posted and was removed — never its
 * title, text, or any other content. See [NotifLatencyTracker] and
 * README.md's collection boundary.
 *
 * Requires the user to manually grant Notification access (Settings →
 * Apps → Special access → Notification access) — no
 * `requestPermissions()` dialog path exists for it, and the system
 * manages this service's lifecycle itself (start/stop tied to that
 * grant), so it needs no registration of its own beyond the manifest
 * `<service>` entry.
 */
class AtariNotificationListenerService : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        NotifLatencyTracker.recordPosted(applicationContext, sbn.key, sbn.postTime)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        NotifLatencyTracker.recordRemoved(applicationContext, sbn.key, System.currentTimeMillis())
    }
}
