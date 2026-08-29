package com.atari.atari

import android.app.Application
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

class AtariApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        // SignalCollectionService itself is started from MainActivity.onCreate(),
        // not here — see that file's comment on why Application.onCreate() is
        // too early a context for Android to trust a startForegroundService()
        // call from.
        WorkManager.getInstance(this)
            .enqueueUniquePeriodicWork(
                "signal-collection-heartbeat",
                ExistingPeriodicWorkPolicy.KEEP,
                PeriodicWorkRequestBuilder<SignalCollectionHeartbeatWorker>(15, TimeUnit.MINUTES).build(),
            )
    }
}
