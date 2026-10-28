package com.leanbitlab.ltvL;

import android.content.Context;
import androidx.work.*;
import java.util.concurrent.TimeUnit;

/** OS-owned deferrable work; no foreground service, exact alarm or polling loop. */
final class PermissionRecoveryScheduler {
    static final java.util.concurrent.ExecutorService DISPATCH = java.util.concurrent.Executors.newSingleThreadExecutor();
    private static boolean scheduled;
    private static void persisted(Operation operation) {
        try { operation.getResult().get(3, TimeUnit.SECONDS); }
        catch (Exception error) { throw new IllegalStateException("Unable to persist recovery work", error); }
    }
    static synchronized void ensure(Context context) {
        if (scheduled) return;
        persisted(WorkManager.getInstance(context).enqueueUniquePeriodicWork("cute-permission-health", ExistingPeriodicWorkPolicy.KEEP,
                new PeriodicWorkRequest.Builder(PermissionRecoveryWorker.class, 15, TimeUnit.MINUTES)
                        .setInitialDelay(15, TimeUnit.MINUTES).setBackoffCriteria(BackoffPolicy.LINEAR, 30, TimeUnit.SECONDS).build()));
        scheduled = true;
    }
    static void enqueue(Context context, long delaySeconds) {
        ensure(context);
        persisted(WorkManager.getInstance(context).enqueueUniqueWork("cute-permission-check", ExistingWorkPolicy.KEEP,
                new OneTimeWorkRequest.Builder(PermissionRecoveryWorker.class).setInitialDelay(delaySeconds, TimeUnit.SECONDS)
                        .setBackoffCriteria(BackoffPolicy.LINEAR, 30, TimeUnit.SECONDS).build()));
    }
    static void foreground(Context context) {
        try {
            UpdatePermissionRecovery.afterUpdate(context);
            UpdatePermissionRecovery.health(context, System.currentTimeMillis(), new PermissionRecoveryAccess(context));
            ensure(context);
            if (UpdatePermissionRecovery.nextCheck(context) > 0) enqueue(context, 15);
        } catch (RuntimeException | LinkageError error) { android.util.Log.w("CuteLauncherUpdate", "Foreground recovery check unavailable"); }
    }
    static void serviceConnected(Context context) {
        Context app = context.getApplicationContext();
        DISPATCH.execute(() -> { try { enqueue(app, 3); } catch (RuntimeException error) {
            android.util.Log.w("CuteLauncherUpdate", "Unable to schedule connection check");
        } });
    }
}
