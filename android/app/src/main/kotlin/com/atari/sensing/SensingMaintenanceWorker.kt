package com.atari.sensing

import android.content.Context
import androidx.work.Worker
import androidx.work.WorkerParameters

/** Periodically bounds and re-persists metadata-only sensing history. */
class SensingMaintenanceWorker(
    appContext: Context,
    workerParams: WorkerParameters
) : Worker(appContext, workerParams) {
    override fun doWork(): Result {
        UnlockTracker.init(applicationContext)
        UnlockTracker.pruneAndPersist(applicationContext)
        return Result.success()
    }
}
