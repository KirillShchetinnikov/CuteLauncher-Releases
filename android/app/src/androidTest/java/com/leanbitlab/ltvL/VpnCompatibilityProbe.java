package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.Instrumentation;
import android.content.SharedPreferences;
import android.os.Bundle;
import java.util.Map;

/** Opt-in, bounded device test. Restores the original VPN and all widget preferences. */
public final class VpnCompatibilityProbe extends Instrumentation {
    private boolean mantarayOnly;
    private boolean confirmationOnly;
    @Override public void onCreate(Bundle args) {
        super.onCreate(args);
        mantarayOnly = args != null && "mantaray".equals(args.getString("client"));
        confirmationOnly = args != null && "mantarayConfirmation".equals(args.getString("client"));
        start();
    }
    @Override public void onStart() {
        var report = new Bundle();
        var vpn = new VpnController(getTargetContext());
        var saved = vpn.prefs.getAll();
        var original = vpn.owner();
        boolean wasActive = vpn.active();
        var log = new StringBuilder();
        log.append("Initial VPN active: ").append(wasActive).append('\n');
        Throwable problem = null;
        try {
            if (wasActive && !VpnPolicy.supported(original.app())) throw new AssertionError("Original VPN cannot be restored");
            if (wasActive && VpnPolicy.requiresProfile(original.app()) && original.profile().isEmpty())
                throw new AssertionError("Original VPN profile unavailable");
            var system = VpnAlwaysOn.refresh(getTargetContext());
            if (system.lockdown() || !system.app().isEmpty()) throw new AssertionError("Existing system VPN: control test skipped");
            try {
                for (String app : new String[]{"com.happproxy", "com.mantaray.vpn"}) {
                    if (!VpnAlwaysOn.configure(getTargetContext(), app)) throw new AssertionError("System selection rejected");
                    if (!VpnAlwaysOn.refresh(getTargetContext()).app().equals(app)) throw new AssertionError("System selection readback failed");
                }
            } finally {
                if (!VpnAlwaysOn.configure(getTargetContext(), "")) throw new AssertionError("System restore failed");
                var restored = VpnAlwaysOn.refresh(getTargetContext());
                if (!restored.equals(system)) throw new AssertionError("System settings changed");
                vpn.prefs.edit().putBoolean("restartRequired", false).commit();
            }
            log.append("PASS: both system selections persisted, original restored, lockdown unchanged; no reboot\n");
            if (confirmationOnly) {
                if (wasActive) throw new AssertionError("Confirmation-only scenario requires no active VPN");
                if (!"sent".equals(vpn.command("com.mantaray.vpn", "", true))) throw new AssertionError("MantaRay action rejected");
                boolean shown = false;
                for (int i = 0; i < 20 && !shown; i++) {
                    Thread.sleep(500);
                    shown = AdbBridge.recentSession(getTargetContext(), shell ->
                        java.util.regex.Pattern.compile("(?m)^.*(?:topResumedActivity|mResumedActivity)=.*com\\.mantaray\\.vpn/(?:com\\.mantaray\\.vpn\\.)?\\.?VpnActionActivity.*$")
                            .matcher(shell.execute("dumpsys activity activities")).find());
                }
                if (!shown) throw new AssertionError("MantaRay confirmation activity not foreground");
                sendKeyDownUpSync(android.view.KeyEvent.KEYCODE_BACK);
                if (vpn.active()) throw new AssertionError("Canceled confirmation connected VPN");
                log.append("PASS: public MantaRay confirmation opened and canceled; VPN command not approved\n");
            } else {
            if (wasActive) change(vpn, original.app(), original.profile(), false);
            String[] clients = mantarayOnly ? new String[]{"com.mantaray.vpn"}
                : new String[]{"com.happproxy", "com.mantaray.vpn"};
            for (String app : clients) {
                change(vpn, app, "", true);
                log.append("PASS: ").append(app).append(" connected, owner confirmed\n");
                change(vpn, app, "", false);
                log.append("PASS: ").append(app).append(" disconnected\n");
            }
            }
        } catch (Throwable error) { problem = error; }
        finally {
            try {
                var current = vpn.owner();
                if (vpn.active() && (!wasActive || !current.app().equals(original.app())))
                    change(vpn, current.app(), current.profile(), false);
                if (wasActive && !vpn.active()) change(vpn, original.app(), original.profile(), true);
                log.append("PASS: original connection state restored\n");
            } catch (Throwable restore) { problem = restore; }
            restore(vpn.prefs, saved);
        }
        report.putString("stream", "\n" + log + (problem == null ? "PASS\n" : "FAIL: " + problem.getMessage() + "\n"));
        finish(problem == null ? Activity.RESULT_OK : Activity.RESULT_CANCELED, report);
    }
    private void change(VpnController vpn, String app, String profile, boolean up) throws Exception {
        String result = vpn.command(app, profile, up);
        if (!java.util.Set.of("sent", "connected", "disconnected").contains(result))
            throw new AssertionError(app + " command rejected: " + result);
        long until = android.os.SystemClock.elapsedRealtime() + 20000;
        do {
            Thread.sleep(500);
            if (!up && !vpn.active()) return;
            if (up && vpn.active() && app.equals(vpn.owner().app())) return;
        } while (android.os.SystemClock.elapsedRealtime() < until);
        throw new AssertionError(app + (up ? " connect" : " disconnect") + " not confirmed");
    }
    @SuppressWarnings("unchecked")
    private void restore(SharedPreferences prefs, Map<String, ?> values) {
        var edit = prefs.edit().clear();
        for (var entry : values.entrySet()) {
            Object value = entry.getValue(); String key = entry.getKey();
            if (value instanceof String s) edit.putString(key, s);
            else if (value instanceof Boolean b) edit.putBoolean(key, b);
            else if (value instanceof Integer n) edit.putInt(key, n);
            else if (value instanceof Long n) edit.putLong(key, n);
            else if (value instanceof Float n) edit.putFloat(key, n);
            else if (value instanceof java.util.Set<?>) edit.putStringSet(key, (java.util.Set<String>)value);
        }
        if (!edit.commit()) throw new AssertionError("Widget preferences restore failed");
    }
}
