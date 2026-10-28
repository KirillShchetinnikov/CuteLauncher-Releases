package com.leanbitlab.ltvL;

import android.content.Context;
import android.content.Intent;
import android.content.ComponentName;
import android.os.Handler;
import android.os.Looper;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ExecutorService;

final class RecentAppsBridge implements AutoCloseable {
    static final String PREFS = "recent_apps";
    private static final ComponentName OEM = new ComponentName("com.nes.recents", "com.nes.recents.RecentsActivity");
    private final MethodChannel channel;
    private volatile boolean closed;
    static Intent systemIntent() {
        return new Intent("com.android.systemui.recents.TOGGLE_RECENTS").setComponent(OEM).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
    }
    static boolean systemAvailable(Context context) {
        var info = context.getPackageManager().resolveActivity(systemIntent(), 0);
        return info != null && info.activityInfo != null && info.activityInfo.exported && info.activityInfo.enabled
            && info.activityInfo.applicationInfo.enabled;
    }
    static String mode(Context context) { return context.getSharedPreferences(PREFS, 0).getString("mode", "auto"); }
    static boolean open(Context context) {
        String mode = mode(context);
        if (!mode.equals("custom") && systemAvailable(context)) {
            try { context.startActivity(systemIntent()); return true; }
            catch (RuntimeException denied) { if (mode.equals("system")) return false; }
        }
        return !mode.equals("system") && LauncherAccessibilityService.showRecents();
    }
    RecentAppsBridge(Context context, BinaryMessenger messenger, ExecutorService worker, Runnable dismiss) {
        channel = new MethodChannel(messenger, "cutelauncher/recent_apps");
        Handler main = new Handler(Looper.getMainLooper());
        channel.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "info" -> result.success(Map.of("mode", mode(context), "systemAvailable", systemAvailable(context),
                    "accessibility", LauncherAccessibilityService.connected()));
                case "mode" -> {
                    if (!(call.arguments() instanceof String mode) || !Set.of("auto", "custom", "system").contains(mode)) {
                        result.error("invalid", "Invalid mode", null); return;
                    }
                    worker.execute(() -> {
                        boolean ok = context.getSharedPreferences(PREFS, 0).edit().putString("mode", mode).commit();
                        main.post(() -> { if (!closed) result.success(ok); });
                    });
                }
                case "open" -> result.success(open(context));
                case "list", "switch", "close", "closeAll", "icon" -> {
                    String pkg = call.argument("packageName");
                    worker.execute(() -> {
                        try {
                            Object response = call.method.equals("icon")
                                ? new ApplicationCatalog(context).getApplicationIcon(pkg, 128)
                                : AdbBridge.recentSession(context, shell -> new RecentAppsControl(context, shell).run(call.method, pkg));
                            main.post(() -> {
                                if (closed) return;
                                result.success(response);
                                if (call.method.equals("switch") && response instanceof Map<?, ?> map && "success".equals(map.get("status"))) dismiss.run();
                            });
                        } catch (Exception unavailable) {
                            main.post(() -> { if (!closed) result.error("unavailable", "Open apps unavailable", null); });
                        }
                    });
                }
                default -> result.notImplemented();
            }
        });
    }
    @Override public void close() { closed = true; channel.setMethodCallHandler(null); }
}
