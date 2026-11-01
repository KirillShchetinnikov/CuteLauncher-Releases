package com.leanbitlab.ltvL;

import android.content.Context;
import android.content.pm.PackageManager;
import java.util.regex.Pattern;

/** One visible initialization on TCL, whose app-boot guard kills cold VPN receivers. */
final class VpnStartupRecovery {
    interface Shell { String execute(String command) throws Exception; }
    record Session(String app, String previous) { }
    static String foreground(String dump) {
        var match = Pattern.compile("(?m)^.*(?:topResumedActivity|mResumedActivity)=ActivityRecord\\{[^\\r\\n]*? u\\d+ ([A-Za-z][A-Za-z0-9_.]*/[A-Za-z.$][A-Za-z0-9_.$]*) [^\\r\\n]*$").matcher(dump);
        return match.find() ? match.group(1) : "";
    }
    static boolean component(String value) {
        return value != null && value.matches("[A-Za-z][A-Za-z0-9_]*(?:\\.[A-Za-z][A-Za-z0-9_]*)+/[A-Za-z.$][A-Za-z0-9_.$]*");
    }
    static Session begin(Context context, String app, java.util.function.BooleanSupplier valid) throws Exception {
        if (!VpnPolicy.requiresProfile(app)) throw new IllegalArgumentException("Unsupported startup recovery");
        var pm = context.getPackageManager();
        var intent = pm.getLeanbackLaunchIntentForPackage(app);
        if (intent == null) intent = pm.getLaunchIntentForPackage(app);
        if (intent == null) throw new IllegalStateException("Client unavailable");
        var resolved = pm.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY);
        if (resolved == null || resolved.activityInfo == null || !resolved.activityInfo.exported
                || !app.equals(resolved.activityInfo.packageName)) throw new IllegalStateException("Client unavailable");
        String target = app + "/" + resolved.activityInfo.name;
        return AdbBridge.recentSession(context, shell -> begin(shell::execute, VpnAlwaysOn.user(context), app, target, valid));
    }
    static Session begin(Shell shell, int user, String app, String target) throws Exception {
        return begin(shell, user, app, target, () -> true);
    }
    static Session begin(Shell shell, int user, String app, String target, java.util.function.BooleanSupplier valid) throws Exception {
        check(valid);
        if (!VpnPolicy.requiresProfile(app) || !component(target) || !target.startsWith(app + "/"))
            throw new IllegalArgumentException("Invalid client");
        String previous = foreground(shell.execute("dumpsys activity activities"));
        check(valid);
        if (!component(previous) || previous.startsWith(app + "/")) throw new IllegalStateException("Previous screen unavailable");
        shell.execute(start(user, target));
        return new Session(app, previous);
    }
    private static void check(java.util.function.BooleanSupplier valid) {
        if (!valid.getAsBoolean() || Thread.currentThread().isInterrupted()) throw new java.util.concurrent.CancellationException();
    }
    static void restore(Context context, Session session) throws Exception {
        AdbBridge.recentSession(context, shell -> {
            String current = foreground(shell.execute("dumpsys activity activities"));
            if (!current.startsWith(session.app() + "/")) return null;
            var previous = android.content.ComponentName.unflattenFromString(session.previous());
            if (previous != null && previous.getPackageName().equals(context.getPackageName())) {
                // The internal launcher Activity need not be exported to shell. Restore its own task.
                var manager = context.getSystemService(android.app.ActivityManager.class);
                if (manager != null) for (var task : manager.getAppTasks()) {
                    var info = task.getTaskInfo();
                    if (previous.equals(info.baseActivity) || previous.equals(info.topActivity)) {
                        task.moveToFront(); return null;
                    }
                }
                context.startActivity(new android.content.Intent().setComponent(previous).addFlags(
                    android.content.Intent.FLAG_ACTIVITY_NEW_TASK | android.content.Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                        | android.content.Intent.FLAG_ACTIVITY_SINGLE_TOP | android.content.Intent.FLAG_ACTIVITY_NO_ANIMATION));
            } else restore(shell::execute, VpnAlwaysOn.user(context), session);
            return null;
        });
    }
    static void restore(Shell shell, int user, Session session) throws Exception {
        String current = foreground(shell.execute("dumpsys activity activities"));
        // Never bring the old screen over an app the user chose in the meantime.
        if (current.startsWith(session.app() + "/") && component(session.previous()))
            shell.execute(start(user, session.previous()));
    }
    private static String start(int user, String component) {
        return "am start --user " + user + " -n '" + component
            + "' --activity-reorder-to-front --activity-single-top --activity-no-animation";
    }
}
