package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.Instrumentation;
import android.content.Intent;
import android.os.Bundle;
import java.io.File;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import dadb.AdbKeyPair;
import dadb.Dadb;

/** Real embedded TCP/RSA and native confirmed plan; restores settings and AppOps. */
public final class AdbAccessibilityProbe extends Instrumentation {
    private volatile Activity activity;
    private boolean traceCommands;
    @Override public void callActivityOnCreate(Activity value, Bundle state) {
        activity = value;
        super.callActivityOnCreate(value, state);
    }
    @Override public void onCreate(Bundle args) {
        super.onCreate(args); traceCommands = args != null && "true".equals(args.getString("trace")); start();
    }
    @Override public void onStart() {
        Bundle report = new Bundle();
        try {
            runOnMainSync(() -> getTargetContext().startActivity(new Intent(getTargetContext(), MainActivity.class)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)));
            long deadline = android.os.SystemClock.elapsedRealtime() + 10000;
            while (activity == null && android.os.SystemClock.elapsedRealtime() < deadline) android.os.SystemClock.sleep(100);
            require(activity != null, "Launcher not started");
            String own = activity.getPackageName();
            File root = new File(activity.getNoBackupFilesDir(), "adb");
            var key = AdbKeyPair.read(new File(root, "private-key"), new File(root, "public-key"));
            int port = activity.getSharedPreferences("adb_connection", 0).getInt("port", 5555);
            try (var connection = Dadb.create("127.0.0.1", port, key, 5000, 60000)) {
                AdbBridge.Shell shell = new AdbBridge.Shell() {
                    public String execute(String command) throws Exception {
                        var response = connection.shell(command);
                        if (traceCommands && (command.startsWith("appops") || command.startsWith("settings"))) {
                            Bundle trace = new Bundle();
                            trace.putString("stream", "\n" + command + " => " + response.getAllOutput().trim() + "\n");
                            sendStatus(1, trace);
                        }
                        if (response.getExitCode() != 0) throw new IllegalStateException("Rejected: " + command);
                        return response.getOutput().trim();
                    }
                    public void close() {}
                };
                String originalServices = shell.execute("settings get secure enabled_accessibility_services");
                String originalEnabled = shell.execute("settings get secure accessibility_enabled");
                var recovery = activity.getSharedPreferences("adb_recovery", 0);
                Map<String, ?> originalRecovery = new HashMap<>(recovery.getAll());
                Map<String, String> originalOps = new HashMap<>();
                for (String op : AdbAccessibilityOps.OPERATIONS) originalOps.put(op, AdbAccessibilityOps.mode(op,
                    shell.execute("appops get --user 0 '" + own + "' " + op + " 2>&1 || true")));
                try {
                    // Force the regression even on an emulator whose default permits sideloaded apps.
                    for (String op : List.of("ACCESS_RESTRICTED_SETTINGS", "BIND_ACCESSIBILITY_SERVICE", "RUN_ANY_IN_BACKGROUND"))
                        if (!originalOps.get(op).equals("unsupported"))
                            shell.execute("appops set --user 0 '" + own + "' " + op + " deny");
                    var preview = AdbLauncherControl.plan(activity, shell, "accessibility", null);
                    require(preview.get("status").equals("ready"), "Preview rejected");
                    List<?> commands = (List<?>)preview.get("commands");
                    require(commands.stream().anyMatch(command -> command.toString().contains("BIND_ACCESSIBILITY_SERVICE allow")), "Missing denied operation");
                    // Changing an AppOp after confirmation must invalidate the entire plan.
                    shell.execute("appops set --user 0 '" + own + "' RUN_ANY_IN_BACKGROUND allow");
                    require(AdbLauncherControl.apply(activity, shell, "accessibility", null, commands).equals("changed"), "Stale confirmation accepted");
                    shell.execute("appops set --user 0 '" + own + "' RUN_ANY_IN_BACKGROUND deny");
                    preview = AdbLauncherControl.plan(activity, shell, "accessibility", null);
                    commands = (List<?>)preview.get("commands");
                    String result = AdbLauncherControl.apply(activity, shell, "accessibility", null, commands);
                    require(result.equals("success"), "Apply: " + result);
                    android.os.SystemClock.sleep(1500);
                    require(shell.execute("settings get secure enabled_accessibility_services").contains(own + "/"), "Service removed by system");
                    require(shell.execute("settings get secure accessibility_enabled").equals("1"), "Accessibility off");
                    require(AdbAccessibilityOps.plan(own, shell::execute).isEmpty(), "Allowed operations still in plan");
                    String manager = shell.execute("dumpsys accessibility");
                    require(manager.contains("Bound services:{Service[label=CuteLauncher"), "Service not bound");
                    report.putString("result", "PASS: uid=" + android.os.Process.myUid() + ", SDK=" + android.os.Build.VERSION.SDK_INT
                        + ", original=" + originalOps + ", plan=" + commands + ", stale confirmation rejected, service bound");
                } finally {
                    for (var entry : originalOps.entrySet()) if (!entry.getValue().equals("unsupported"))
                        shell.execute("appops set --user 0 '" + own + "' " + entry.getKey() + " " + entry.getValue());
                    shell.execute(originalServices.equals("null") ? "settings delete secure enabled_accessibility_services"
                        : "settings put secure enabled_accessibility_services '" + originalServices + "'");
                    shell.execute(originalEnabled.equals("null") ? "settings delete secure accessibility_enabled"
                        : "settings put secure accessibility_enabled " + originalEnabled);
                    var editor = recovery.edit().clear();
                    for (var entry : originalRecovery.entrySet()) {
                        Object value = entry.getValue();
                        if (value instanceof String) editor.putString(entry.getKey(), (String)value);
                        else if (value instanceof Boolean) editor.putBoolean(entry.getKey(), (Boolean)value);
                        else if (value instanceof Integer) editor.putInt(entry.getKey(), (Integer)value);
                        else throw new AssertionError("Unexpected recovery type");
                    }
                    require(editor.commit(), "Recovery not restored");
                    require(shell.execute("settings get secure enabled_accessibility_services").equals(originalServices), "Services not restored");
                    require(shell.execute("settings get secure accessibility_enabled").equals(originalEnabled), "Accessibility not restored");
                }
            }
            finish(Activity.RESULT_OK, report);
        } catch (Throwable error) {
            report.putString("result", "FAIL: " + error);
            finish(Activity.RESULT_CANCELED, report);
        }
    }
    private static void require(boolean value, String message) { if (!value) throw new AssertionError(message); }
}
