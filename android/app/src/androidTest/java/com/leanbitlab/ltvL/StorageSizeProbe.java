package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.Instrumentation;
import android.app.usage.StorageStats;
import android.app.usage.StorageStatsManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Process;
import java.io.File;
import org.json.JSONObject;

/** Read-only package storage measurement. Run only on the two TV emulators. */
public final class StorageSizeProbe extends Instrumentation {
    @Override public void onCreate(Bundle args) { super.onCreate(args); start(); }

    @Override public void onStart() {
        Bundle result = new Bundle();
        try {
            if (!Build.HARDWARE.contains("ranchu") && !Build.HARDWARE.contains("goldfish"))
                throw new IllegalStateException("Emulator required");
            var context = getTargetContext();
            var info = context.getApplicationInfo();
            StorageStats stats = context.getSystemService(StorageStatsManager.class)
                .queryStatsForPackage(info.storageUuid, context.getPackageName(), Process.myUserHandle());
            JSONObject data = new JSONObject()
                .put("appBytes", stats.getAppBytes())
                .put("dataBytes", stats.getDataBytes())
                .put("cacheBytes", stats.getCacheBytes())
                .put("apkBytes", new File(info.sourceDir).length())
                .put("versionCode", context.getPackageManager().getPackageInfo(context.getPackageName(), 0).getLongVersionCode())
                .put("api", Build.VERSION.SDK_INT);
            if (stats.getAppBytes() <= 0 || data.getLong("apkBytes") <= 0)
                throw new AssertionError("Empty package size");
            result.putString("result", data.toString());
            finish(Activity.RESULT_OK, result);
        } catch (Throwable error) {
            result.putString("result", "FAIL: " + error);
            finish(Activity.RESULT_CANCELED, result);
        }
    }
}
