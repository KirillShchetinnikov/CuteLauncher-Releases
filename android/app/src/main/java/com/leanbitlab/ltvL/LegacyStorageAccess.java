package com.leanbitlab.ltvL;

import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;
import android.os.Build;
import io.flutter.plugin.common.MethodChannel;

/** Android 9 public Downloads only. Background jobs never open a permission prompt. */
final class LegacyStorageAccess {
    static final int REQUEST = 4110;
    private final Activity activity;
    private Runnable pending;
    private MethodChannel.Result pendingResult;

    LegacyStorageAccess(Activity activity) { this.activity = activity; }

    void run(boolean mayRequest, MethodChannel.Result result, Runnable operation) {
        if (Build.VERSION.SDK_INT >= 29 || granted()) { operation.run(); return; }
        if (!mayRequest) { denied(result); return; }
        if (pending != null) { result.error("document_busy", "Storage permission request in progress", null); return; }
        pending = operation;
        pendingResult = result;
        try { activity.requestPermissions(new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE}, REQUEST); }
        catch (RuntimeException error) { complete(); }
    }

    private boolean granted() {
        return activity.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED;
    }

    void complete() {
        Runnable operation = pending;
        MethodChannel.Result result = pendingResult;
        pending = null;
        pendingResult = null;
        if (result == null) return;
        if (granted()) operation.run(); else denied(result);
    }

    void close() {
        MethodChannel.Result result = pendingResult;
        pending = null;
        pendingResult = null;
        if (result != null) denied(result);
    }

    private static void denied(MethodChannel.Result result) {
        result.error("document_failed", "Storage permission required for Android 9 Downloads", null);
    }
}
