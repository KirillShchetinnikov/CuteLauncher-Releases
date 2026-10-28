package com.leanbitlab.ltvL;

import android.content.Context;
import androidx.work.Worker;
import androidx.work.WorkerParameters;

public final class PermissionRecoveryWorker extends Worker {
    public PermissionRecoveryWorker(Context context, WorkerParameters parameters) { super(context, parameters); }
    @Override public Result doWork() {
        Context context = getApplicationContext();
        try {
            UpdatePermissionRecovery.afterUpdate(context);
            long now = System.currentTimeMillis();
            UpdatePermissionRecovery.health(context, now, new PermissionRecoveryAccess(context));
            long due = UpdatePermissionRecovery.nextCheck(context);
            // WorkManager owns retries and may defer them while the TV sleeps.
            if (due > 0 && due <= now + 300_000L && getRunAttemptCount() < 20) return Result.retry();
            return Result.success();
        } catch (RuntimeException error) {
            return getRunAttemptCount() < 5 ? Result.retry() : Result.success();
        }
    }
}
