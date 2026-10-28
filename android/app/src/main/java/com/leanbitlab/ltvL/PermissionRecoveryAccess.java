package com.leanbitlab.ltvL;

import android.content.ComponentName;
import android.content.Context;
import android.content.pm.PackageManager;
import dadb.AdbKeyPair;
import dadb.Dadb;
import java.io.File;
import java.util.Set;

/** Existing local authorization only. No key generation, pairing, UI or remote hosts. */
final class PermissionRecoveryAccess implements UpdatePermissionRecovery.Access {
    private final Context context;
    static final class Unavailable extends Exception {
        final String reason;
        Unavailable(String reason) { this.reason = reason; }
    }
    PermissionRecoveryAccess(Context context) { this.context = context; }
    public Set<String> granted() { return UpdatePermissionRecovery.granted(context); }
    public boolean accessibilityEnabled() { return UpdatePermissionRecovery.accessibility(context); }
    public boolean connected() { return LauncherAccessibilityService.connected(); }
    public boolean supported(String action) {
        return UpdatePermissionPolicy.ACTIONS.contains(action)
                && AdbCompatibilityPolicy.supportedSdk(android.os.Build.VERSION.SDK_INT)
                && context.getPackageManager().hasSystemFeature(PackageManager.FEATURE_LEANBACK)
                && (!action.equals("watchNext") || !AdbCapabilities.watchNextPermission(context).isEmpty());
    }
    public UpdatePermissionRecovery.Session open() throws Exception {
        var saved = context.getSharedPreferences("adb_connection", 0);
        int port = saved.getInt("port", 5555);
        File privateKey = new File(context.getNoBackupFilesDir(), "adb/private-key");
        File publicKey = new File(context.getNoBackupFilesDir(), "adb/public-key");
        if (saved.getBoolean("tls", false) || port < 1024 || port > 65535 || !privateKey.isFile() || !publicKey.isFile())
            throw new Unavailable("adb_not_configured");
        final Dadb adb = Dadb.create("127.0.0.1", port, AdbKeyPair.read(privateKey, publicKey), 1500, 5000);
        AdbBridge.Shell shell = new AdbBridge.Shell() {
            public String execute(String command) throws Exception {
                var response = NativeShellDiagnostics.execute(adb, command, "updatePermissions");
                if (response.getExitCode() != 0) throw new Unavailable("command_rejected");
                return response.getOutput().trim();
            }
            public void close() { }
        };
        try {
            if (!shell.execute("id -u").equals("2000") || !shell.execute("am get-current-user").equals("0"))
                throw new Unavailable("unsupported_user");
        } catch (Exception error) { adb.close(); throw error; }
        return new UpdatePermissionRecovery.Session() {
            public String restore(String action, boolean requireEnabled) throws Exception {
                if (!action.equals("accessibility")) return AdbBridge.perform(context, shell, action);
                return reconnect(context, shell, requireEnabled);
            }
            public void close() throws Exception { adb.close(); }
        };
    }
    static String reconnect(Context context, AdbBridge.Shell shell, boolean requireEnabled) throws Exception {
        ComponentName component = new ComponentName(context, LauncherAccessibilityService.class);
        String own = component.flattenToString();
        String current = shell.execute("settings get secure enabled_accessibility_services");
        String without = UpdatePermissionPolicy.serviceList(current, own, false); // Validate before any write.
        boolean listed = false;
        for (String item : current.split(":")) if (component.equals(ComponentName.unflattenFromString(item))) listed = true;
        boolean enabled = listed && shell.execute("settings get secure accessibility_enabled").equals("1");
        if (requireEnabled && !enabled) return "revoked";
        // Only update recovery carries consent to restore disabled access. On Android
        // 13+, restricted settings can block restoring a service after a sideloaded update.
        if (!requireEnabled && android.os.Build.VERSION.SDK_INT >= 33) {
            String query = "appops get --user 0 '" + context.getPackageName()
                    + "' ACCESS_RESTRICTED_SETTINGS 2>&1 || true";
            String mode = AdbAccessibilityOps.mode("ACCESS_RESTRICTED_SETTINGS", shell.execute(query));
            if (AdbAccessibilityOps.needsAllow("ACCESS_RESTRICTED_SETTINGS", mode)) {
                String command = "appops set --user 0 '" + context.getPackageName()
                        + "' ACCESS_RESTRICTED_SETTINGS allow";
                if (!AdbAccessibilityOps.apply(context.getPackageName(), shell::execute, java.util.List.of(command)))
                    throw new Unavailable("permission_rejected");
            }
        }
        try {
            if (enabled) {
                shell.execute("settings put secure enabled_accessibility_services '" + without + "'");
                Thread.sleep(250);
            }
        } finally {
            String latest = shell.execute("settings get secure enabled_accessibility_services");
            String restored = UpdatePermissionPolicy.serviceList(latest, own, true);
            shell.execute("settings put secure enabled_accessibility_services '" + restored + "'");
            shell.execute("settings put secure accessibility_enabled 1");
            if (!shell.execute("settings get secure enabled_accessibility_services").equals(restored))
                throw new Unavailable("permission_rejected");
        }
        return "success";
    }
}
