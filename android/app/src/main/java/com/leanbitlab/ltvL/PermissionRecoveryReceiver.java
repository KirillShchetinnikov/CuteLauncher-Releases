package com.leanbitlab.ltvL;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

public final class PermissionRecoveryReceiver extends BroadcastReceiver {
    @Override public void onReceive(Context context, Intent intent) {
        if (!Intent.ACTION_MY_PACKAGE_REPLACED.equals(intent.getAction()) && !Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())) return;
        PendingResult pending = goAsync();
        Context app = context.getApplicationContext();
        PermissionRecoveryScheduler.DISPATCH.execute(() -> {
            try { PermissionRecoveryScheduler.enqueue(app, 3); }
            catch (RuntimeException error) { android.util.Log.w("CuteLauncherUpdate", "Unable to schedule update recovery"); }
            finally { pending.finish(); }
        });
    }
}
