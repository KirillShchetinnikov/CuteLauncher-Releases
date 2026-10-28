package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.SharedPreferences;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import java.io.File;
import java.util.LinkedHashSet;
import java.util.Arrays;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import dadb.AdbKeyPair;
import dadb.Dadb;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;

/** Local TCP ADB prototype. No arbitrary shell or remote-host input. */
final class AdbBridge {
    interface Session<T> { T run(Shell shell) throws Exception; }
    /** Reuse existing authorization only; opening recents never generates keys or enables ADB. */
    static <T> T recentSession(android.content.Context context, Session<T> operation) throws Exception {
        synchronized (LOCK) {
            var saved = context.getSharedPreferences("adb_connection", 0);
            int port = saved.getInt("port", 5555);
            File privateKey = new File(context.getNoBackupFilesDir(), "adb/private-key");
            File publicKey = new File(context.getNoBackupFilesDir(), "adb/public-key");
            if (saved.getBoolean("tls", false) || port < 1024 || port > 65535 || !privateKey.isFile() || !publicKey.isFile())
                throw new IllegalStateException("ADB unavailable");
            try (Dadb adb = Dadb.create("127.0.0.1", port, AdbKeyPair.read(privateKey, publicKey), 5000, 10000)) {
                return operation.run(new Shell() {
                    public String execute(String command) throws Exception {
                        // Task dumps contain other apps' intents; do not copy them into diagnostics.
                        var response = adb.shell(command);
                        if (response.getExitCode() != 0) throw new IllegalStateException("Command rejected");
                        return response.getOutput();
                    }
                    public void close() { }
                });
            }
        }
    }
    static final Object LOCK = new Object();
    interface Shell extends java.io.Closeable { String execute(String command) throws Exception; }
    private static SharedPreferences tcpSettings(Activity activity) {
        SharedPreferences saved = activity.getSharedPreferences("adb_connection", Activity.MODE_PRIVATE);
        // A saved pairing port cannot be used for the TCP/RSA connection.
        if (saved.getBoolean("tls", false)) {
            saved.edit().putBoolean("tls", false).putInt("port", 5555).apply();
        }
        return saved;
    }
    private static Map<String, Object> launcherStatus(Activity activity) {
        var intent = new android.content.Intent(android.content.Intent.ACTION_MAIN).addCategory(android.content.Intent.CATEGORY_HOME);
        var resolved = activity.getPackageManager().resolveActivity(intent, android.content.pm.PackageManager.MATCH_DEFAULT_ONLY);
        if (resolved == null || resolved.activityInfo == null) return Map.of();
        return Map.of("name", resolved.loadLabel(activity.getPackageManager()).toString(),
            "isHome", resolved.activityInfo.packageName.equals(activity.getPackageName()));
    }
    static void register(Activity activity, BinaryMessenger messenger, ExecutorService executor) {
        new MethodChannel(messenger, "cutelauncher/adb").setMethodCallHandler((call, result) -> {
            if (call.method.equals("port")) {
                Integer value = call.argument("port");
                if (value == null || value < 1024 || value > 65535) { result.success(false); return; }
                result.success(tcpSettings(activity).edit().putInt("port",value).remove("connection_snapshot").commit());
                return;
            }
            if (call.method.equals("homeOverride")) {
                Boolean enabled = call.argument("enabled");
                if (enabled == null) { result.success(false); return; }
                result.success(activity.getSharedPreferences("launcher_control",0).edit().putBoolean("override_home",enabled).commit());
                return;
            }
            if (call.method.equals("info")) {
                SharedPreferences saved = tcpSettings(activity);
                result.success(Map.of("tls", false, "port", saved.getInt("port", 5555), "compatibility", AdbCapabilities.info(activity), "launcherStatus", launcherStatus(activity), "connectionSnapshot", saved.getString("connection_snapshot", ""), "homeOverride", activity.getSharedPreferences("launcher_control",0).getBoolean("override_home",true)));
                return;
            }
            if (Boolean.TRUE.equals(call.argument("tls"))) {
                result.success(Map.of("status", "unsupported")); return;
            }
            Integer port = call.argument("port");
            if (port == null || port < 1024 || port > 65535) {
                result.success(Map.of("status", "invalid")); return;
            }
            if (!call.method.equals("action")) { result.success(Map.of("status", "invalid")); return; }
            String action = call.argument("action");
            if (action == null || !Arrays.asList("appProcessStatus", "stopApp", "cleanerInventory", "cleanerSnapshot", "cleanerApply", "cleanerRestore", "cleanerManualSave", "cleanerManualDelete", "cleanerManualRestore", "cleanerManualExport", "check", "preview", "disableSystem", "enableSystem", "home", "accessibility", "disableAccessibility", "restoreAccessibility", "overlay", "notifications", "watchNext", "usage", "writeSettings", "restore").contains(action)) {
                result.success(Map.of("status", "invalid")); return;
            }
            String operation = action.equals("preview") ? call.argument("operation") : action;
            if (!action.equals("appProcessStatus") && !action.equals("stopApp") && !action.startsWith("cleaner") && !action.equals("check") && (operation == null || !AdbCapabilities.supported(activity, operation))) {
                result.success(Map.of("status", "unsupported")); return;
            }
            executor.execute(() -> {
                Map<String, Object> response;
                synchronized (LOCK) {
                    AdbOperationDiagnostics.begin();
                    try {
                        tcpSettings(activity);
                        File privateKey = new File(activity.getNoBackupFilesDir(), "adb/private-key");
                        File publicKey = new File(activity.getNoBackupFilesDir(), "adb/public-key");
                        if (!privateKey.exists() || !publicKey.exists()) AdbKeyPair.generate(privateKey, publicKey);
                        try (Dadb adb = Dadb.create("127.0.0.1", port, AdbKeyPair.read(privateKey, publicKey), 5000, 60000)) {
                            Shell shell = new Shell() {
                                public String execute(String command) throws Exception {
                                    AdbOperationDiagnostics.command(command);
                                    try {
                                        var response = NativeShellDiagnostics.execute(adb, command, "adb");
                                        AdbOperationDiagnostics.exit(response.getExitCode());
                                        AdbOperationDiagnostics.output(response.getOutput(), response.getErrorOutput());
                                        if (response.getExitCode() != 0) throw new IllegalStateException("Command rejected");
                                        return response.getOutput().trim();
                                    } catch (Exception failure) {
                                        AdbOperationDiagnostics.failure(failure);
                                        throw failure;
                                    }
                                }
                                public void close() {}
                            };
                            AdbOperationDiagnostics.stage("dispatch");
                            if (action.equals("appProcessStatus") || action.equals("stopApp")) {
                                response = AppProcessControl.run(activity, shell, action, call.argument("packages"));
                            } else if (action.startsWith("cleaner")) {
                                response = new TvCleaner(activity, shell).run(action, call.argument("packages"), call.argument("enable"), call.argument("stateId"), call.argument("stateName"), call.argument("listName"), call.argument("listScope"));
                            } else if (action.equals("check")) {
                                String status = perform(activity, shell, "check");
                                response = status.equals("ready") ? AdbLauncherControl.snapshot(activity, shell) : Map.of("status",status);
                            } else if (action.equals("preview")) {
                                response = operation == null ? Map.of("status","invalid") : AdbLauncherControl.plan(activity,shell,operation,call.argument("target"), operation.equals("disableSystem") && Boolean.TRUE.equals(call.argument("allowOwnedWifi")));
                            } else {
                                response = Map.of("status", AdbLauncherControl.apply(activity,shell,action,call.argument("target"),call.argument("commands"), action.equals("disableSystem") && Boolean.TRUE.equals(call.argument("allowOwnedWifi"))));
                            }
                        }
                        if (response.get("status").equals("ready") || response.get("status").equals("success"))
                            activity.getSharedPreferences("adb_connection", Activity.MODE_PRIVATE).edit().putBoolean("tls", false).putInt("port", port).apply();
                    } catch (dadb.AdbAuthException e) { response = Map.of("status", "authorization"); }
                    catch (Exception | LinkageError e) {
                        AdbOperationDiagnostics.failure(e);
                        android.util.Log.w("CuteLauncherADB", "ADB operation failed: " + e.getClass().getSimpleName());
                        response = Map.of("status", "unavailable");
                    }
                    var diagnostic = AdbOperationDiagnostics.finish();
                    response = new java.util.LinkedHashMap<>(response);
                    response.put("diagnostic", diagnostic);
                }
                String connectionStatus = (String) response.get("status");
                if (action.equals("check") || connectionStatus.equals("authorization") || connectionStatus.equals("unavailable")) {
                    var savedResponse = new java.util.LinkedHashMap<>(response);
                    savedResponse.remove("diagnostic"); // Technical excerpts remain session-only.
                    tcpSettings(activity).edit().putString("connection_snapshot", new org.json.JSONObject(savedResponse).toString()).apply();
                }
                final Map<String, Object> output = response;
                new Handler(Looper.getMainLooper()).post(() -> result.success(output));
            });
        });
    }

    private static String shell(Shell adb, String command) throws Exception {
        return adb.execute(command);
    }
    private static String home(Shell adb) throws Exception {
        String output = shell(adb, "cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME");
        String[] lines = output.split("\\r?\\n");
        String component = lines[lines.length - 1].trim();
        if (!component.matches("[a-zA-Z0-9_.]+/[a-zA-Z0-9_.]+")) throw new IllegalStateException("No home");
        return AdbLauncherPolicy.normalizeComponent(component);
    }
    /** Recovery screen uses only the already-authorized local connection and existing HOME journal. */
    static boolean restoreFromRecovery(Activity activity) {
        synchronized (LOCK) {
            try {
                var saved = activity.getSharedPreferences("adb_connection", Activity.MODE_PRIVATE);
                int port = saved.getInt("port", 5555);
                if (saved.getBoolean("tls", false) || port < 1 || port > 65535) return false;
                File privateKey = new File(activity.getNoBackupFilesDir(), "adb/private-key");
                File publicKey = new File(activity.getNoBackupFilesDir(), "adb/public-key");
                if (!privateKey.isFile() || !publicKey.isFile()) return false;
                try (Dadb adb = Dadb.create("127.0.0.1", port, AdbKeyPair.read(privateKey, publicKey), 5000, 10000)) {
                    Shell shell = new Shell() {
                        public String execute(String command) throws Exception {
                            var response = NativeShellDiagnostics.execute(adb, command, "adb");
                            if (response.getExitCode() != 0) throw new IllegalStateException("Command rejected");
                            return response.getOutput().trim();
                        }
                        public void close() { }
                    };
                    var plan = AdbLauncherControl.plan(activity, shell, "restore", null);
                    if (!"ready".equals(plan.get("status"))) return false;
                    return "success".equals(AdbLauncherControl.apply(activity, shell, "restore", null,
                        (java.util.List<?>)plan.get("commands")));
                }
            } catch (Exception | LinkageError unavailable) { return false; }
        }
    }

    /** Crash recovery never creates keys, changes HOME or constructs a Flutter engine. */
    static String restoreCleanerFromRecovery(Activity activity) {
        synchronized (LOCK) {
            try {
                if (!new TvCleaner(activity, null).hasBaseline()) return "noSnapshot";
                var saved = activity.getSharedPreferences("adb_connection", Activity.MODE_PRIVATE);
                int port = saved.getInt("port", 5555);
                if (saved.getBoolean("tls", false) || port < 1024 || port > 65535) return "unavailable";
                File privateKey = new File(activity.getNoBackupFilesDir(), "adb/private-key");
                File publicKey = new File(activity.getNoBackupFilesDir(), "adb/public-key");
                if (!privateKey.isFile() || !publicKey.isFile()) return "unavailable";
                try (Dadb adb = Dadb.create("127.0.0.1", port, AdbKeyPair.read(privateKey, publicKey), 5000, 10000)) {
                    Shell shell = new Shell() {
                        public String execute(String command) throws Exception {
                            var response = NativeShellDiagnostics.execute(adb, command, "adb");
                            if (response.getExitCode() != 0) throw new IllegalStateException("Command rejected");
                            return response.getOutput().trim();
                        }
                        public void close() { }
                    };
                    // Invalidate the display cache even if restoration is interrupted.
                    File cache = new File(activity.getFilesDir(), "tv-cleaner-inventory.json");
                    if (cache.exists() && !cache.delete()) return "unavailable";
                    return (String)new TvCleaner(activity, shell).run("cleanerEmergencyRestore", null, null).get("status");
                }
            } catch (Exception | LinkageError error) { return "unavailable"; }
        }
    }

    static String perform(android.content.Context activity, Shell adb, String action) throws Exception {
        if (!shell(adb, "am get-current-user").equals("0")) return "denied";
        String own = activity.getPackageName() + "/com.leanbitlab.ltvL.MainActivity";
        SharedPreferences recovery = activity.getSharedPreferences("adb_recovery", Activity.MODE_PRIVATE);
        if (action.equals("check")) return shell(adb, "id -u").equals("2000") ? "ready" : "denied";
        if (action.equals("overlay")) {
            shell(adb, "appops set --uid '" + activity.getPackageName() + "' SYSTEM_ALERT_WINDOW allow");
            shell(adb, "appops set --user 0 '" + activity.getPackageName() + "' SYSTEM_ALERT_WINDOW allow");
            return OverlayPermission.granted(activity) ? "success" : "denied";
        }
        if (action.equals("notifications")) {
            android.content.ComponentName component = new android.content.ComponentName(activity, LauncherNotificationListenerService.class);
            shell(adb, "cmd notification allow_listener '" + component.flattenToString() + "' 0");
            return activity.getSystemService(android.app.NotificationManager.class)
                .isNotificationListenerAccessGranted(component) ? "success" : "denied";
        }
        if (action.equals("watchNext")) {
            shell(adb, "pm grant --user 0 '" + activity.getPackageName()
                + "' " + AdbCapabilities.watchNextPermission(activity));
            return new WatchNextBridge(activity).checkWatchNextPermission() ? "success" : "denied";
        }
        if (action.equals("usage") || action.equals("writeSettings")) {
            String op = action.equals("usage") ? "GET_USAGE_STATS" : "WRITE_SETTINGS";
            shell(adb, "appops set --user 0 '" + activity.getPackageName() + "' " + op + " allow");
            boolean allowed = action.equals("writeSettings") ? Settings.System.canWrite(activity)
                : new NetworkStatistics(activity).checkUsageStatsPermission();
            return allowed ? "success" : "denied";
        }
        if (action.equals("restoreAccessibility") || action.equals("disableAccessibility")) {
            if (action.equals("restoreAccessibility") && !recovery.getBoolean("accessibility_saved", false)) return "noRecovery";
            String component = activity.getPackageName() + "/com.leanbitlab.ltvL.LauncherAccessibilityService";
            String current = shell(adb, "settings get secure enabled_accessibility_services");
            if (!current.equals("null") && !current.matches("[a-zA-Z0-9_./:]*")) return "denied";
            var services = new LinkedHashSet<String>();
            if (!current.equals("null") && !current.isEmpty()) services.addAll(Arrays.asList(current.split(":")));
            if (action.equals("disableAccessibility") || !recovery.getBoolean("accessibility_own_was_enabled", false)) services.remove(component);
            else services.add(component);
            String value = String.join(":", services);
            if (value.isEmpty()) shell(adb, "settings delete secure enabled_accessibility_services");
            else shell(adb, "settings put secure enabled_accessibility_services '" + value + "'");
            shell(adb, "settings put secure accessibility_enabled " + (services.isEmpty() ? (action.equals("disableAccessibility") ? 0 : recovery.getInt("accessibility_enabled", 0)) : 1));
            String restored = shell(adb, "settings get secure enabled_accessibility_services");
            if (!(value.isEmpty() ? restored.equals("null") || restored.isEmpty() : restored.equals(value))) return "denied";
            recovery.edit().remove("accessibility_saved").apply();
            return "success";
        }
        if (action.equals("accessibility")) {
            String component = activity.getPackageName() + "/com.leanbitlab.ltvL.LauncherAccessibilityService";
            String current = shell(adb, "settings get secure enabled_accessibility_services");
            if (!current.equals("null") && !current.matches("[a-zA-Z0-9_./:]*")) return "denied";
            var services = new LinkedHashSet<String>();
            if (!current.equals("null") && !current.isEmpty()) services.addAll(Arrays.asList(current.split(":")));
            if (!recovery.getBoolean("accessibility_saved", false)) {
                String previousEnabled = shell(adb, "settings get secure accessibility_enabled");
                if (!recovery.edit().putBoolean("accessibility_saved", true)
                    .putBoolean("accessibility_own_was_enabled", services.contains(component))
                    .putInt("accessibility_enabled", previousEnabled.equals("1") ? 1 : 0).commit()) return "denied";
            }
            services.add(component);
            String value = String.join(":", services);
            shell(adb, "settings put secure enabled_accessibility_services '" + value + "'");
            shell(adb, "settings put secure accessibility_enabled 1");
            return shell(adb, "settings get secure enabled_accessibility_services").equals(value) ? "success" : "denied";
        }
        if (action.equals("home")) {
            String previous = home(adb);
            if (!previous.equals(own) && !previous.startsWith(activity.getPackageName() + "/")) {
                if (!recovery.edit().putString("previous_home", previous).commit()) return "denied";
            }
            shell(adb, "cmd package set-home-activity '" + own + "'");
            return home(adb).startsWith(activity.getPackageName() + "/") ? "success" : "denied";
        }
        return "invalid";
    }
}
