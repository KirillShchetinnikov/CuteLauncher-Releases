package com.leanbitlab.ltvL;

/** Eager WorkManager initialization is disabled; recovery schedules work from IO. */
public final class LauncherApplication extends android.app.Application implements androidx.work.Configuration.Provider {
    @Override public androidx.work.Configuration getWorkManagerConfiguration() {
        return new androidx.work.Configuration.Builder().setMinimumLoggingLevel(android.util.Log.WARN).build();
    }
}
