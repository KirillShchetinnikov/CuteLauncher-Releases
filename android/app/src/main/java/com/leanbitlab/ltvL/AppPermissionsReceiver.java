package com.leanbitlab.ltvL;

/** Package changes never grant consent. Uninstall immediately forgets it. */
public final class AppPermissionsReceiver extends android.content.BroadcastReceiver {
    @Override public void onReceive(android.content.Context context, android.content.Intent intent) {
        if (intent.getData() == null) return;
        String pkg = intent.getData().getSchemeSpecificPart();
        if (pkg == null) return;
        PendingResult pending = goAsync();
        PermissionRecoveryScheduler.DISPATCH.execute(() -> {
            try {
                if ((android.content.Intent.ACTION_PACKAGE_REMOVED.equals(intent.getAction())
                        || android.content.Intent.ACTION_PACKAGE_FULLY_REMOVED.equals(intent.getAction()))
                        && !intent.getBooleanExtra(android.content.Intent.EXTRA_REPLACING, false))
                    AppPermissions.packageRemoved(context, pkg);
                PermissionRecoveryScheduler.enqueue(context, 30);
            } catch (RuntimeException ignored) { }
            finally { pending.finish(); }
        });
    }
}
