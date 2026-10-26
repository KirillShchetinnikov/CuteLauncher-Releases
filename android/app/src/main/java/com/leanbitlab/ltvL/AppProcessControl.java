package com.leanbitlab.ltvL;

import android.app.Activity;
import java.util.List;
import java.util.Map;

/** Bounded operations on one installed application in the current Android user. */
final class AppProcessControl {
    static Map<String, Object> run(Activity activity, AdbBridge.Shell shell,
            String action, List<String> packages) throws Exception {
        if (packages == null || packages.size() != 1) return Map.of("status", "invalid");
        String target = packages.get(0);
        if (target == null || target.length() > 220
                || !target.matches("[A-Za-z][A-Za-z0-9_]*(\\.[A-Za-z0-9_]+)+")
                || target.equals(activity.getPackageName())) return Map.of("status", "invalid");
        int uid = activity.getPackageManager().getApplicationInfo(target, 0).uid;
        boolean active = AppProcessPolicy.running(shell.execute("ps -A -o UID,NAME"), target, uid);
        if (action.equals("stopApp") && active) {
            shell.execute("am force-stop --user current " + target);
            active = AppProcessPolicy.running(shell.execute("ps -A -o UID,NAME"), target, uid);
        }
        return Map.of("status", action.equals("stopApp") && active ? "denied" : "success",
                "running", active);
    }
}
