package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.Instrumentation;
import android.content.Intent;
import android.os.Bundle;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import org.json.JSONObject;

/** Emulator-only target-UID detector and HOME cycle, restoring package state and recovery data. */
public final class AdbCompatibilityProbe extends Instrumentation {
    private volatile Activity launchedActivity;
    @Override public void callActivityOnCreate(Activity activity, Bundle state) {
        launchedActivity = activity;
        super.callActivityOnCreate(activity, state);
    }
    @Override public void onCreate(Bundle args) { super.onCreate(args); start(); }
    @Override public void onStart() {
        Bundle report = new Bundle();
        Activity activity = null;
        try {
            if (!android.os.Build.HARDWARE.contains("ranchu") && !android.os.Build.HARDWARE.contains("goldfish"))
                throw new AssertionError("Emulator required");
            // When the target is already HOME, Android may create it before onStart.
            // startActivitySync would wait forever for another singleTask instance.
            runOnMainSync(() -> getTargetContext().startActivity(new Intent(getTargetContext(), MainActivity.class)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)));
            long deadline = android.os.SystemClock.elapsedRealtime() + 10000;
            while (launchedActivity == null && android.os.SystemClock.elapsedRealtime() < deadline)
                android.os.SystemClock.sleep(100);
            activity = launchedActivity;
            if (activity == null) throw new AssertionError("Launcher did not start within 10 seconds");
            android.os.SystemClock.sleep(1500);
            if (android.os.Process.myUid() != getTargetContext().getApplicationInfo().uid)
                throw new AssertionError("Not target UID");
            var info = AdbCapabilities.info(activity);
            var actions = (Map<?, ?>) info.get("actions");
            try (AdbBridge.Shell shell = new AdbBridge.Shell() {
                public String execute(String command) throws Exception {
                    // UiAutomation tokenizes commands without shell quote handling. A real sh
                    // is needed for the same quoted fixed plans that the embedded ADB runs.
                    var pipes = getUiAutomation().executeShellCommandRw("sh");
                    try (var input = new android.os.ParcelFileDescriptor.AutoCloseInputStream(pipes[0])) {
                        try (var outputPipe = new android.os.ParcelFileDescriptor.AutoCloseOutputStream(pipes[1])) {
                            outputPipe.write((command + " 2>&1\nexit\n").getBytes(StandardCharsets.UTF_8));
                        }
                        String output = new String(input.readAllBytes(), StandardCharsets.UTF_8).trim();
                        Bundle trace = new Bundle();
                        trace.putString("stream", "\n" + command + " => " + output + "\n");
                        sendStatus(1, trace);
                        return output;
                    }
                }
                public void close() {}
            }) {
                for (String action : new String[]{"home", "overlay", "notifications", "watchNext", "usage", "writeSettings", "accessibility"}) {
                    var plan = AdbLauncherControl.plan(activity, shell, action, null);
                    String expected = Boolean.TRUE.equals(actions.get(action)) ? "ready" : "unsupported";
                    if (!expected.equals(plan.get("status")))
                        throw new AssertionError(action + ": " + plan);
                }
                JSONObject data = new JSONObject(info);
                data.put("uid", android.os.Process.myUid());
                data.put("version", getTargetContext().getPackageManager()
                    .getPackageInfo(getTargetContext().getPackageName(), 0).versionName);
                data.put("home", shell.execute("cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME"));
                data.put("watchNextPermission", AdbCapabilities.watchNextPermission(activity));
                String stock = info.get("system").equals("Google TV")
                    ? "com.google.android.apps.tv.launcherx" : "com.google.android.tvlauncher";
                boolean originallyDisabled = shell.execute("pm list packages -d --user 0")
                    .lines().anyMatch(line -> line.equals("package:" + stock));
                String originalHome = shell.execute("cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME")
                    .lines().reduce((a, b) -> b).orElseThrow();
                var recovery = activity.getSharedPreferences("adb_recovery", 0);
                Map<String, ?> originalRecovery = new java.util.HashMap<>(recovery.getAll());
                try {
                    apply(activity, shell, "enableSystem", stock);
                    if (AdbCapabilities.canHome(activity)) throw new AssertionError("Pinned HOME must block direct selection");
                    apply(activity, shell, "disableSystem", stock);
                    if (!shell.execute("cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME")
                        .contains(activity.getPackageName() + "/")) throw new AssertionError("Replacement HOME not selected");
                    apply(activity, shell, "restore", null);
                    if (!shell.execute("cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME")
                        .contains(stock + "/")) throw new AssertionError("Stock HOME not restored");
                    data.put("homeCycle", "PASS: enable, blocked direct HOME, disable, actual resolve, restore");
                } finally {
                    shell.execute((originallyDisabled ? "pm disable-user" : "pm enable") + " --user 0 '" + stock + "'");
                    String restoredHome = shell.execute("cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME")
                        .lines().reduce((a, b) -> b).orElseThrow();
                    if (!restoredHome.equals(originalHome))
                        shell.execute("cmd package set-home-activity '" + originalHome + "'");
                    var editor = recovery.edit().clear();
                    for (var entry : originalRecovery.entrySet()) {
                        Object value = entry.getValue();
                        if (value instanceof String) editor.putString(entry.getKey(), (String)value);
                        else if (value instanceof Boolean) editor.putBoolean(entry.getKey(), (Boolean)value);
                        else if (value instanceof Integer) editor.putInt(entry.getKey(), (Integer)value);
                        else throw new AssertionError("Unexpected recovery value");
                    }
                    if (!editor.commit()) throw new AssertionError("Recovery preferences not restored");
                }
                report.putString("result", "PASS: " + data);
            }
            finish(Activity.RESULT_OK, report);
        } catch (Throwable error) {
            report.putString("result", "FAIL: " + error);
            finish(Activity.RESULT_CANCELED, report);
        } finally {
            if (activity != null) { Activity launched = activity; runOnMainSync(launched::finish); }
        }
    }
    private static void apply(Activity activity, AdbBridge.Shell shell, String action, String target) throws Exception {
        var plan = AdbLauncherControl.plan(activity, shell, action, target);
        if (!"ready".equals(plan.get("status"))) throw new AssertionError(action + " plan: " + plan);
        String status = AdbLauncherControl.apply(activity, shell, action, target, (java.util.List<?>)plan.get("commands"));
        if (!"success".equals(status)) throw new AssertionError(action + ": " + status);
    }
}
