package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.NotificationManager;
import android.content.ComponentName;
import android.content.SharedPreferences;
import android.provider.Settings;
import dadb.AdbKeyPair;
import dadb.Dadb;
import java.io.File;
import java.util.HashSet;
import java.util.Set;

/** One bounded recovery on the first foreground launch after replacing the APK. */
final class UpdatePermissionRecovery {
    private static SharedPreferences saved(Activity activity) {
        return activity.getSharedPreferences("update_permissions", 0);
    }

    private static long installation(Activity activity) throws Exception {
        return activity.getPackageManager().getPackageInfo(activity.getPackageName(), 0).lastUpdateTime;
    }

    private static boolean accessibility(Activity activity) {
        if (Settings.Secure.getInt(activity.getContentResolver(), Settings.Secure.ACCESSIBILITY_ENABLED, 0) != 1)
            return false;
        String value = Settings.Secure.getString(activity.getContentResolver(), Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES);
        ComponentName own = new ComponentName(activity, LauncherAccessibilityService.class);
        if (value != null) for (String item : value.split(":"))
            if (own.equals(ComponentName.unflattenFromString(item))) return true;
        return false;
    }

    private static Set<String> granted(Activity activity) {
        Set<String> result = new HashSet<>();
        if (accessibility(activity)) result.add("accessibility");
        if (activity.getSystemService(NotificationManager.class).isNotificationListenerAccessGranted(
            new ComponentName(activity, LauncherNotificationListenerService.class))) result.add("notifications");
        if (OverlayPermission.granted(activity)) result.add("overlay");
        if (new NetworkStatistics(activity).checkUsageStatsPermission()) result.add("usage");
        if (Settings.System.canWrite(activity)) result.add("writeSettings");
        if (new WatchNextBridge(activity).checkWatchNextPermission()) result.add("watchNext");
        return result;
    }

    // Called on the IO worker, including immediately before opening the package installer.
    static void snapshot(Activity activity) {
        synchronized (AdbBridge.LOCK) {
            try {
                long current = installation(activity);
                if (UpdatePermissionPolicy.replaced(saved(activity).getLong("installation", 0), current)) return;
                saved(activity).edit().putLong("installation", current).putStringSet("granted", granted(activity)).commit();
            } catch (Exception error) { android.util.Log.w("CuteLauncherUpdate", "Permission snapshot unavailable", error); }
        }
    }

    static void afterUpdate(Activity activity) {
        synchronized (AdbBridge.LOCK) {
            try {
                var state = saved(activity);
                long current = installation(activity);
                if (!UpdatePermissionPolicy.replaced(state.getLong("installation", 0), current)) {
                    snapshot(activity);
                    return;
                }
                Set<String> previous = new HashSet<>(state.getStringSet("granted", Set.of()));
                Set<String> actual = granted(activity);
                // Consume before opening ADB. Never resurrect old grants on later resumes or after a crash.
                if (!state.edit().putLong("installation", current).putStringSet("granted", actual).commit()) return;
                if (previous.contains("notifications") && actual.contains("notifications"))
                    android.service.notification.NotificationListenerService.requestRebind(
                        new ComponentName(activity, LauncherNotificationListenerService.class));
                var missing = UpdatePermissionPolicy.missing(previous, actual, LauncherAccessibilityService.connected());
                if (missing.isEmpty()) return;
                var connection = activity.getSharedPreferences("adb_connection", 0);
                int port = connection.getInt("port", 5555);
                File privateKey = new File(activity.getNoBackupFilesDir(), "adb/private-key");
                File publicKey = new File(activity.getNoBackupFilesDir(), "adb/public-key");
                if (connection.getBoolean("tls", false) || port < 1024 || port > 65535
                    || !privateKey.isFile() || !publicKey.isFile()) return;
                try (Dadb adb = Dadb.create("127.0.0.1", port, AdbKeyPair.read(privateKey, publicKey), 1500, 5000)) {
                    AdbBridge.Shell shell = new AdbBridge.Shell() {
                        public String execute(String command) throws Exception {
                            var response = NativeShellDiagnostics.execute(adb, command, "updatePermissions");
                            if (response.getExitCode() != 0) throw new IllegalStateException("Permission recovery rejected");
                            return response.getOutput().trim();
                        }
                        public void close() {}
                    };
                    if (!shell.execute("id -u").equals("2000") || !shell.execute("am get-current-user").equals("0")) return;
                    for (String action : missing) {
                        try {
                            if (!AdbCapabilities.supported(activity, action)) continue;
                            // Recheck immediately: Android may have connected the service during ADB setup.
                            if (action.equals("accessibility") && accessibility(activity)
                                && LauncherAccessibilityService.connected()) continue;
                            if (action.equals("accessibility")) {
                                restoreAccessibility(activity, shell);
                                continue;
                            }
                            String status = AdbBridge.perform(activity, shell, action);
                            android.util.Log.i("CuteLauncherUpdate", action + " recovery: " + status);
                        } catch (Exception error) {
                            android.util.Log.w("CuteLauncherUpdate", action + " recovery failed", error);
                        }
                    }
                } finally { snapshot(activity); }
            } catch (Exception | LinkageError error) {
                android.util.Log.w("CuteLauncherUpdate", "Automatic permission recovery unavailable", error);
            }
        }
    }

    private static void restoreAccessibility(Activity activity, AdbBridge.Shell shell) throws Exception {
        String own = new ComponentName(activity, LauncherAccessibilityService.class).flattenToString();
        String current = shell.execute("settings get secure enabled_accessibility_services");
        try {
            if (accessibility(activity)) {
                shell.execute("settings put secure enabled_accessibility_services '"
                    + UpdatePermissionPolicy.serviceList(current, own, false) + "'");
                Thread.sleep(250);
            }
        } finally {
            // Read again to preserve other services changed during reconnect; keep the user's ADB recovery journal.
            String latest = shell.execute("settings get secure enabled_accessibility_services");
            String restored = UpdatePermissionPolicy.serviceList(latest, own, true);
            shell.execute("settings put secure enabled_accessibility_services '" + restored + "'");
            shell.execute("settings put secure accessibility_enabled 1");
            if (!shell.execute("settings get secure enabled_accessibility_services").equals(restored))
                throw new IllegalStateException("Accessibility recovery rejected");
        }
    }
}
