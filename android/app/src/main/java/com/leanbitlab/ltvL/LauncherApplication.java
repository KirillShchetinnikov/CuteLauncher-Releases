package com.leanbitlab.ltvL;

/** Eager WorkManager initialization is disabled; recovery schedules work from IO. */
public final class LauncherApplication extends android.app.Application implements androidx.work.Configuration.Provider {
    @Override public void onCreate() {
        super.onCreate();
        try { observeAppPermissions(); }
        catch (RuntimeException error) {
            // Recovery still runs on foreground/WorkManager if an OEM rejects observation.
            android.util.Log.w("CuteAppPermissions", "Permission observation unavailable");
        }
    }
    private void observeAppPermissions() {
        android.content.IntentFilter packages = new android.content.IntentFilter(android.content.Intent.ACTION_PACKAGE_REPLACED);
        packages.addDataScheme("package");
        if (android.os.Build.VERSION.SDK_INT >= 33)
            registerReceiver(new AppPermissionsReceiver(), packages, android.content.Context.RECEIVER_NOT_EXPORTED);
        else registerReceiver(new AppPermissionsReceiver(), packages);
        // Process-lifetime observer, no Activity reference, polling, or ADB on the main thread.
        android.os.Handler handler = new android.os.Handler(android.os.Looper.getMainLooper());
        Runnable changed = () -> PermissionRecoveryScheduler.DISPATCH.execute(() -> {
            if (AppPermissions.prefs(this).getAll().isEmpty()) return;
            try { PermissionRecoveryScheduler.enqueue(this, 30); } catch (RuntimeException ignored) { }
        });
        android.database.ContentObserver observer = new android.database.ContentObserver(handler) {
            @Override public void onChange(boolean selfChange) {
                handler.removeCallbacks(changed);
                handler.postDelayed(changed, 1000);
            }
        };
        getContentResolver().registerContentObserver(android.provider.Settings.Secure.getUriFor(
            android.provider.Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES), false, observer);
        getContentResolver().registerContentObserver(android.provider.Settings.Secure.getUriFor(
            android.provider.Settings.Secure.ACCESSIBILITY_ENABLED), false, observer);
    }
    @Override public androidx.work.Configuration getWorkManagerConfiguration() {
        return new androidx.work.Configuration.Builder().setMinimumLoggingLevel(android.util.Log.WARN)
            .setJobSchedulerJobIdRange(10000, 19999).build();
    }
}
