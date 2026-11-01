package com.leanbitlab.ltvL;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Process;

/** Persist Android's own boot configuration. Never change lockdown or impersonate a device owner. */
final class VpnAlwaysOn {
    interface Shell { String execute(String command) throws Exception; }
    record State(String app, boolean lockdown) { }
    static int user(Context context) { return Process.myUid() / 100000; }
    static State read(Shell shell, int user) throws Exception {
        String prefix = "settings --user " + user + " get secure ";
        String app = shell.execute(prefix + "always_on_vpn_app").trim();
        String lockdown = shell.execute(prefix + "always_on_vpn_lockdown").trim();
        if (app.equals("null")) app = "";
        if (!app.isEmpty() && !VpnPolicy.packageName(app)) throw new IllegalStateException("VPN setting unavailable");
        if (!java.util.Set.of("null", "0", "1").contains(lockdown)) throw new IllegalStateException("VPN setting unavailable");
        return new State(app, lockdown.equals("1"));
    }
    static State refresh(Context context) throws Exception {
        var state = AdbBridge.recentSession(context, shell -> read(shell::execute, user(context)));
        context.getSharedPreferences(VpnController.PREFS, 0).edit().putString("systemApp", state.app()).apply();
        return state;
    }
    static boolean configure(Context context, String app) throws Exception {
        return AdbBridge.recentSession(context, shell -> configure(
            context.getSharedPreferences(VpnController.PREFS, 0), shell::execute, user(context), app));
    }
    static boolean configure(SharedPreferences prefs, Shell shell, int user, String app) throws Exception {
        if (!app.isEmpty() && !VpnPolicy.packageName(app)) return false;
        State before = read(shell, user);
        String owned = prefs.getString("ownedAlwaysOn", "");
        if (!owned.isEmpty() && !owned.equals(before.app())) {
            if (!app.isEmpty()) return false;
            // Leaving our mode must remain possible after an external system change.
            prefs.edit().remove("ownedAlwaysOn").remove("previousAlwaysOn").putString("systemApp", before.app()).apply();
            return true;
        }
        if (app.isEmpty() && owned.isEmpty()) return true; // Do not clear someone else's setting.
        String target = app.isEmpty() ? prefs.getString("previousAlwaysOn", "") : app;
        if (!target.isEmpty() && !VpnPolicy.packageName(target)) return false;
        if (target.equals(before.app())) {
            if (app.isEmpty()) prefs.edit().remove("ownedAlwaysOn").remove("previousAlwaysOn").apply();
            return true;
        }
        if (before.lockdown()) return false; // Preserve existing traffic protection and allowlist verbatim.
        String savedPrevious = prefs.getString("previousAlwaysOn", "");
        String previous = owned.isEmpty() ? before.app() : savedPrevious;
        // Journal before the external write; a crash must not lose the previous system configuration.
        // During release retain ownership until the external write is confirmed.
        if (!prefs.edit().putString("previousAlwaysOn", previous)
                .putString("ownedAlwaysOn", app.isEmpty() ? owned : target).commit()) return false;
        try {
            write(shell, user, target);
            if (!read(shell, user).app().equals(target)) throw new IllegalStateException("VPN setting rejected");
        } catch (Exception failure) {
            // Restore only if no external actor changed the value after our write.
            try { if (read(shell, user).app().equals(target)) write(shell, user, before.app()); }
            catch (Exception ignored) { throw failure; }
            prefs.edit().putString("ownedAlwaysOn", owned).putString("previousAlwaysOn", savedPrevious).apply();
            throw failure;
        }
        var edit = prefs.edit().putString("systemApp", target).putBoolean("restartRequired", true);
        if (app.isEmpty()) edit.remove("ownedAlwaysOn").remove("previousAlwaysOn");
        edit.apply();
        return true;
    }
    private static void write(Shell shell, int user, String app) throws Exception {
        String prefix = "settings --user " + user;
        shell.execute(app.isEmpty() ? prefix + " delete secure always_on_vpn_app"
            : prefix + " put secure always_on_vpn_app '" + app + "'");
    }
    static void boot(Context context) {
        context.getSharedPreferences(VpnController.PREFS, 0).edit().putBoolean("restartRequired", false).apply();
    }
}
