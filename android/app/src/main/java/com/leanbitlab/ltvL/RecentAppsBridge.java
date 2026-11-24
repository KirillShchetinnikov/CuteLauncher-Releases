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
import java.util.concurrent.Executor;
import java.util.concurrent.ExecutorService;
import java.util.function.BooleanSupplier;
import java.util.function.Consumer;

final class RecentAppsBridge implements AutoCloseable {
    enum OpenResult { OPENED, UNAVAILABLE, ADB_REQUIRED, ACCESSIBILITY_REQUIRED, CANCELLED }

    static final String PREFS = "recent_apps";
    private static final ComponentName OEM = new ComponentName("com.nes.recents", "com.nes.recents.RecentsActivity");
    private final MethodChannel channel;
    private volatile boolean closed;
    private volatile long memoryGeneration;
    private int openGeneration;
    static Intent systemIntent() {
        return new Intent("com.android.systemui.recents.TOGGLE_RECENTS").setComponent(OEM).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
    }
    static boolean systemAvailable(Context context) {
        var info = context.getPackageManager().resolveActivity(systemIntent(), 0);
        return info != null && info.activityInfo != null && info.activityInfo.exported && info.activityInfo.enabled
            && info.activityInfo.applicationInfo.enabled;
    }
    static String mode(Context context) { return context.getSharedPreferences(PREFS, 0).getString("mode", "auto"); }
    private static boolean adbAvailable(Context context) {
        try {
            return AdbBridge.recentSession(context,
                shell -> AdbShellIdentity.supported(shell.execute("id -u").trim()));
        } catch (Exception | LinkageError unavailable) {
            return false;
        }
    }
    static Map<String, Object> access(Context context) {
        return Map.of("adb", adbAvailable(context), "accessibility", LauncherAccessibilityService.connected());
    }
    static boolean setup(Context context, String destination) {
        String extra;
        if ("adb".equals(destination)) extra = LauncherActivity.OPEN_ADB_SETTINGS;
        else if ("accessibility".equals(destination)) extra = LauncherActivity.OPEN_ACCESSIBILITY_SETTINGS;
        else return false;
        Intent intent = new Intent(context, MainActivity.class)
            .setAction(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
            .putExtra(extra, true)
            .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        try { context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)); return true; }
        catch (RuntimeException unavailable) { return false; }
    }
    private static boolean openSystem(Context context) {
        if (!systemAvailable(context)) return false;
        try {
            context.startActivity(systemIntent());
            return true;
        } catch (RuntimeException denied) {
            return false;
        }
    }
    static void open(Context context, Executor worker, Handler main,
                     BooleanSupplier current, Consumer<OpenResult> complete) {
        String mode = mode(context);
        if (!mode.equals("custom") && openSystem(context)) {
            if (context instanceof LauncherAccessibilityService service) service.dismissPanel();
            complete.accept(OpenResult.OPENED);
        } else if (mode.equals("system")) {
            complete.accept(OpenResult.UNAVAILABLE);
        } else if (LauncherAccessibilityService.closeRecentsIfOpen()) {
            complete.accept(OpenResult.OPENED);
        } else if (!LauncherAccessibilityService.connected()) {
            complete.accept(OpenResult.ACCESSIBILITY_REQUIRED);
        } else {
            worker.execute(() -> {
                boolean adb = adbAvailable(context);
                main.post(() -> {
                    if (!current.getAsBoolean()) complete.accept(OpenResult.CANCELLED);
                    else if (!LauncherAccessibilityService.connected()) complete.accept(OpenResult.ACCESSIBILITY_REQUIRED);
                    else if (!adb) complete.accept(OpenResult.ADB_REQUIRED);
                    else complete.accept(LauncherAccessibilityService.showRecents()
                        ? OpenResult.OPENED : OpenResult.UNAVAILABLE);
                });
            });
        }
    }
    RecentAppsBridge(Context context, BinaryMessenger messenger, ExecutorService worker, Runnable dismiss) {
        channel = new MethodChannel(messenger, "cutelauncher/recent_apps");
        Handler main = new Handler(Looper.getMainLooper());
        channel.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "cancelMemory" -> { memoryGeneration++; result.success(null); }
                case "ram" -> worker.execute(() -> {
                    var response = SystemStatusController.ramSnapshot(context);
                    main.post(() -> { if (!closed) result.success(response); });
                });
                case "memory" -> {
                    String pkg = call.argument("packageName");
                    long generation = memoryGeneration;
                    worker.execute(() -> {
                        Map<String, Object> memory = RecentAppsMemory.UNAVAILABLE;
                        try {
                            if (!closed && generation == memoryGeneration)
                                memory = AdbBridge.recentSession(context, shell -> RecentAppsMemory.read(shell, pkg,
                                    () -> closed || generation != memoryGeneration || Thread.currentThread().isInterrupted()));
                        } catch (Exception unavailable) { /* Optional measurement; keep the task usable. */ }
                        Map<String, Object> response = memory;
                        main.post(() -> { if (!closed) result.success(generation == memoryGeneration ? response : RecentAppsMemory.UNAVAILABLE); });
                    });
                }
                case "info" -> result.success(Map.of("mode", mode(context), "systemAvailable", systemAvailable(context),
                    "accessibility", LauncherAccessibilityService.connected()));
                case "access" -> worker.execute(() -> {
                    var response = access(context);
                    main.post(() -> { if (!closed) result.success(response); });
                });
                case "setup" -> {
                    boolean opened = setup(context, call.argument("destination"));
                    result.success(opened);
                    if (opened) dismiss.run();
                }
                case "mode" -> {
                    if (!(call.arguments() instanceof String mode) || !Set.of("auto", "custom", "system").contains(mode)) {
                        result.error("invalid", "Invalid mode", null); return;
                    }
                    worker.execute(() -> {
                        boolean ok = context.getSharedPreferences(PREFS, 0).edit().putString("mode", mode).commit();
                        if (ok) NativeSyncBridge.changed("native_config_recent_apps");
                        main.post(() -> { if (!closed) result.success(ok); });
                    });
                }
                case "open" -> {
                    int generation = ++openGeneration;
                    open(context, worker, main, () -> !closed && generation == openGeneration, response -> {
                        if (closed) return;
                        switch (response) {
                            case ADB_REQUIRED -> result.error("recent_adb_required", "Local ADB unavailable", null);
                            case ACCESSIBILITY_REQUIRED -> result.error("recent_accessibility_required",
                                "Accessibility service unavailable", null);
                            default -> result.success(response == OpenResult.OPENED);
                        }
                    });
                }
                case "cancelOpen" -> { openGeneration++; result.success(null); }
                case "list", "switch", "close", "closeAll", "icon" -> {
                    if (!call.method.equals("icon")) memoryGeneration++;
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
                            main.post(() -> { if (!closed) result.error("unavailable", "Open apps unavailable", DiagnosticErrorDetails.from(unavailable)); });
                        }
                    });
                }
                default -> result.notImplemented();
            }
        });
    }
    @Override public void close() { closed = true; memoryGeneration++; channel.setMethodCallHandler(null); }
}
