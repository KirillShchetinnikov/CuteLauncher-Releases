package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.Signature;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import androidx.core.content.FileProvider;
import java.io.File;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.Executor;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;

/** Only shares the updater's private APK. Android performs final APK verification. */
final class UpdateBridge {
    private static final String PLAY = "com.android.vending";
    private static String installer(Activity activity) {
        try {
            return activity.getPackageManager().getInstallSourceInfo(activity.getPackageName()).getInstallingPackageName();
        } catch (Exception error) { return null; }
    }
    private static long version(PackageInfo info) {
        return info.getLongVersionCode();
    }
    private static Signature[] signatures(PackageInfo info) {
        return info.signingInfo != null ? info.signingInfo.getApkContentsSigners() : null;
    }
    static String[] signerNames(PackageInfo info) {
        Signature[] values = signatures(info);
        if (values == null) return new String[0];
        String[] names = new String[values.length];
        for (int index = 0; index < values.length; index++) names[index] = values[index].toCharsString();
        return names;
    }
    static void register(Activity activity, BinaryMessenger messenger, Executor executor) {
        new MethodChannel(messenger, "cutelauncher/updates").setMethodCallHandler((call, result) -> {
            if (call.method.equals("environment")) {
                try {
                    PackageInfo info = activity.getPackageManager().getPackageInfo(activity.getPackageName(), 0);
                    Map<String, Object> data = new HashMap<>();
                    data.put("play", PLAY.equals(installer(activity)));
                    data.put("version", info.versionName);
                    data.put("versionCode", version(info));
                    data.put("abis", Arrays.asList(Build.SUPPORTED_ABIS));
                    data.put("directory", new File(activity.getCacheDir(), "updates").getAbsolutePath());
                    result.success(data);
                } catch (Exception error) { result.error("unavailable", "Update environment unavailable", DiagnosticErrorDetails.from(error)); }
            } else if (call.method.equals("install")) {
                executor.execute(() -> {
                    String status = "invalid";
                    try {
                        if (PLAY.equals(installer(activity))) status = "play";
                        else {
                            File apk = new File(activity.getCacheDir(), "updates/update.apk");
                            int flags = PackageManager.GET_SIGNING_CERTIFICATES;
                            PackageInfo current = activity.getPackageManager().getPackageInfo(activity.getPackageName(), flags);
                            PackageInfo candidate = activity.getPackageManager().getPackageArchiveInfo(apk.getAbsolutePath(), flags);
                            if (apk.isFile() && apk.length() <= 128L * 1024 * 1024 && candidate != null
                                && UpdatePolicy.allows(activity.getPackageName(), version(current), signerNames(current),
                                    candidate.packageName, version(candidate), signerNames(candidate))) status = "ready";
                        }
                    } catch (Exception error) { status = "invalid"; }
                    if (status.equals("ready")) UpdatePermissionRecovery.snapshot(activity);
                    final String checked = status;
                    new Handler(Looper.getMainLooper()).post(() -> {
                        if (!checked.equals("ready")) { result.success(checked); return; }
                        try {
                            if (!activity.getPackageManager().canRequestPackageInstalls()) {
                                activity.startActivity(new Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                    Uri.parse("package:" + activity.getPackageName())));
                                result.success("permission");
                                return;
                            }
                            Uri uri = FileProvider.getUriForFile(activity, activity.getPackageName() + ".updates",
                                new File(activity.getCacheDir(), "updates/update.apk"));
                            Intent intent = new Intent(Intent.ACTION_VIEW)
                                .setDataAndType(uri, "application/vnd.android.package-archive")
                                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                            activity.startActivity(intent);
                            result.success("launched");
                        } catch (Exception error) { result.success("unavailable"); }
                    });
                });
            } else result.notImplemented();
        });
    }
}
