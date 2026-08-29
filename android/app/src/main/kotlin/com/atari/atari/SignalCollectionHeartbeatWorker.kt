package com.atari.atari

import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.content.ContextCompat
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters

/**
 * Periodic safety net for [SignalCollectionService]: even a foreground
 * service can still be killed by an aggressive OEM background-killer.
 * WorkManager guarantees this worker runs periodically — subject to
 * Doze/battery constraints, minimum 15-minute interval — and re-requests
 * the service start. `startForegroundService` is a no-op if the service is
 * already running (its `onCreate` doesn't fire again), so this is safe to
 * call unconditionally rather than first checking
 * [SignalCollectionService.isRunning].
 *
 * Best-effort, not guaranteed: Android 12+ restricts calling
 * `startForegroundService()` from a context it doesn't trust as
 * foreground-triggering, and a periodic background worker is exactly the
 * kind of context that can be denied (`ForegroundServiceStartNotAllowedException`,
 * confirmed happening from `Application.onCreate()` in this same app, per
 * [MainActivity]'s comment). If denied, this worker logs it and returns
 * success rather than crashing or retrying — the app being reopened is
 * still what reliably restarts collection. A more complete fix would have
 * this worker promote itself via `setForegroundAsync`, which WorkManager's
 * own execution context is trusted for; left as a follow-up, not
 * implemented here.
 *
 * See Plans/IMPLEMENTATION.md §3 (Workstream: Backend — Native).
 */
class SignalCollectionHeartbeatWorker(context: Context, params: WorkerParameters) :
    CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        try {
            ContextCompat.startForegroundService(
                applicationContext,
                Intent(applicationContext, SignalCollectionService::class.java),
            )
        } catch (e: Exception) {
            Log.w(TAG, "Could not restart SignalCollectionService from a background trigger", e)
        }
        return Result.success()
    }

    companion object {
        private const val TAG = "SignalCollectionHeartbeat"
    }
}
