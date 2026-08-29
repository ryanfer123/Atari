package com.atari.atari

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.content.ContextCompat

/**
 * Restarts [SignalCollectionService] after a device reboot — a running
 * service does not survive across reboots on its own, unlike a
 * WorkManager schedule (which does). Manifest-declared, not dynamically
 * registered: `BOOT_COMPLETED` is one of the implicit broadcasts Android
 * still allows a manifest receiver to declare, and is one of the
 * documented trusted contexts for `startForegroundService()` (unlike a
 * plain WorkManager trigger — see [SignalCollectionHeartbeatWorker]) —
 * still wrapped defensively since OEM behavior around this varies.
 *
 * See Plans/IMPLEMENTATION.md §3 (Workstream: Backend — Native).
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        try {
            ContextCompat.startForegroundService(context, Intent(context, SignalCollectionService::class.java))
        } catch (e: Exception) {
            Log.w("BootReceiver", "Could not start SignalCollectionService after boot", e)
        }
    }
}
