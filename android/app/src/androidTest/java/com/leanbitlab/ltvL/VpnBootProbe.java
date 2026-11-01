package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.Instrumentation;
import android.os.Bundle;

/** Read-only by default. Explicit connect/inspect/cold arguments opt in to device acceptance actions. */
public final class VpnBootProbe extends Instrumentation {
    private boolean connect;
    private boolean inspect;
    private boolean cold;
    private boolean disconnect;
    private boolean widgetCycle;
    @Override public void onCreate(Bundle args) {
        super.onCreate(args);
        connect = flag(args, "connect");
        inspect = flag(args, "inspect");
        cold = flag(args, "cold");
        disconnect = flag(args, "disconnect");
        widgetCycle = flag(args, "widgetCycle");
        start();
    }
    private boolean flag(Bundle args, String key) {
        return args != null && "1".equals(args.getString(key));
    }
    @Override public void onStart() {
        var result = new Bundle();
        try {
            var vpn = new VpnController(getTargetContext());
            var state = vpn.snapshot();
            String app = vpn.prefs.getString("bootApp", "");
            if (widgetCycle) {
                if (Boolean.TRUE.equals(state.get("bootEnabled")) || !Boolean.TRUE.equals(state.get("canControl")))
                    throw new AssertionError("Widget did not regain control");
                boolean original = vpn.active();
                String profile = vpn.prefs.getString("profile_" + app, "");
                try {
                    widgetChange(vpn, app, profile, !original);
                    android.os.SystemClock.sleep(5000);
                    if (vpn.active() == original) throw new AssertionError("VPN state reverted automatically");
                    widgetChange(vpn, app, profile, original);
                } finally {
                    if (vpn.active() != original) widgetChange(vpn, app, profile, original);
                }
                result.putString("command", "PASS widget cycle; original connection restored");
                state = vpn.snapshot();
            }
            if ((cold || disconnect) && app.equals("org.amnezia.awg")) {
                String profile = vpn.prefs.getString("profile_" + app, "");
                if (!VpnPolicy.profileName(profile)) throw new AssertionError("Invalid profile");
                var down = new android.content.Intent(app + ".action.SET_TUNNEL_DOWN")
                    .setClassName(app, app + ".model.TunnelManager$IntentReceiver").putExtra("tunnel", profile);
                getTargetContext().sendBroadcast(down);
                for (int i = 0; i < 20 && vpn.active(); i++) android.os.SystemClock.sleep(500);
                if (vpn.active()) throw new AssertionError("Disconnect failed");
                if (cold) {
                    AdbBridge.recentSession(getTargetContext(), shell -> shell.execute("am kill org.amnezia.awg"));
                    android.os.SystemClock.sleep(1500);
                    var up = new android.content.Intent(app + ".action.SET_TUNNEL_UP")
                        .setClassName(app, app + ".model.TunnelManager$IntentReceiver").putExtra("tunnel", profile)
                        .addFlags(android.content.Intent.FLAG_INCLUDE_STOPPED_PACKAGES | android.content.Intent.FLAG_RECEIVER_FOREGROUND);
                    getTargetContext().sendBroadcast(up);
                    for (int i = 0; i < 30 && !vpn.active(); i++) android.os.SystemClock.sleep(500);
                    result.putString("command", "cold-explicit-up:" + vpn.active());
                } else result.putString("command", "disconnected:" + !vpn.active());
                state = vpn.snapshot();
            }
            if (inspect) {
                vpn.open(app);
                android.os.SystemClock.sleep(3000);
                String profile = vpn.prefs.getString("profile_" + app, "");
                var root = getUiAutomation().getRootInActiveWindow();
                result.putString("inspection", "profileValid=" + VpnPolicy.profileName(profile)
                    + " matchesUi=" + (root != null && !root.findAccessibilityNodeInfosByText(profile).isEmpty()));
            }
            if (connect) {
                String command = vpn.command(app, vpn.prefs.getString("profile_" + app, ""), true);
                android.os.SystemClock.sleep(5000);
                result.putString("command", command);
                state = vpn.snapshot();
            }
            result.putString("stream", "\nbootApp=" + app
                + " enabled=" + state.get("bootEnabled") + " mode=" + state.get("bootMode")
                + " profilePresent=" + !vpn.prefs.getString("profile_" + app, "").isEmpty()
                + " permission=" + (getTargetContext().checkSelfPermission(VpnController.permission(app)) == 0)
                + " status=" + state.get("startupStatus") + " active=" + state.get("active")
                + " detail=" + vpn.prefs.getString("startupDetail", "")
                + " command=" + result.getString("command", "not-requested-v2")
                + " inspection=" + result.getString("inspection", "not-requested")
                + " owner=" + state.get("owner") + "\n");
            finish(Activity.RESULT_OK, result);
        } catch (Throwable error) {
            result.putString("stream", "FAIL " + error.getClass().getSimpleName());
            finish(Activity.RESULT_CANCELED, result);
        }
    }
    private void widgetChange(VpnController vpn, String app, String profile, boolean up) throws Exception {
        String command = vpn.command(app, profile, up);
        if (!java.util.Set.of("sent", "connected", "disconnected").contains(command))
            throw new AssertionError("Widget command rejected: " + command);
        for (int i = 0; i < 40; i++) {
            android.os.SystemClock.sleep(500);
            if (vpn.active() == up && (!up || app.equals(vpn.owner().app()))) return;
        }
        throw new AssertionError("Widget command not confirmed");
    }
}
