package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.Instrumentation;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import java.io.File;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.*;
import org.json.JSONObject;
import dadb.AdbKeyPair;
import dadb.Dadb;

/** Emulator-only integration fixture. Never deletes/replaces the real protected baseline. */
public final class TvCleanerRecoveryProbe extends Instrumentation {
    private static final String APP = "io.cutelauncher.fixture.documents";
    private String phase;
    @Override public void onCreate(Bundle args) { super.onCreate(args); phase = args.getString("phase", "prepare"); start(); }
    private void check(boolean value, String message) { if (!value) throw new AssertionError(message); }
    private File marker(Context context) { return new File(context.getNoBackupFilesDir(), "tv-cleaner-probe.json"); }
    private JSONObject prefs(Context context, String name) {
        return new JSONObject(context.getSharedPreferences(name, 0).getAll());
    }
    private void restorePrefs(Context context, String name, JSONObject values) throws Exception {
        var editor = context.getSharedPreferences(name, 0).edit().clear();
        for (var keys = values.keys(); keys.hasNext();) {
            String key = keys.next(); Object value = values.get(key);
            if (value instanceof Boolean) editor.putBoolean(key, (Boolean)value);
            else if (value instanceof Number) {
                if (key.equals("port") || key.equals("dart_pid")) editor.putInt(key, ((Number)value).intValue());
                else editor.putLong(key, ((Number)value).longValue());
            } else editor.putString(key, value.toString());
        }
        check(editor.commit(), "Preference restoration failed");
    }
    private String shell(String command) throws Exception {
        try (var input = new android.os.ParcelFileDescriptor.AutoCloseInputStream(getUiAutomation().executeShellCommand(command))) {
            return new String(input.readAllBytes(), StandardCharsets.UTF_8).trim();
        }
    }
    private static String readText(File file) throws Exception { return new String(Files.readAllBytes(file.toPath()), StandardCharsets.UTF_8); }
    private static void writeText(File file, String text) throws Exception { Files.write(file.toPath(), text.getBytes(StandardCharsets.UTF_8)); }
    private android.view.accessibility.AccessibilityNodeInfo findText(android.view.accessibility.AccessibilityNodeInfo node, String text) {
        if (node == null) return null;
        if (node.getText() != null && text.equalsIgnoreCase(node.getText().toString())) return node;
        for (int i=0; i<node.getChildCount(); i++) {
            var found = findText(node.getChild(i), text); if (found != null) return found;
        }
        return null;
    }
    private void authorize(Context context) throws Exception {
        var service = getUiAutomation().getServiceInfo();
        service.flags |= android.accessibilityservice.AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS;
        getUiAutomation().setServiceInfo(service);
        File dir = new File(context.getNoBackupFilesDir(), "adb");
        var executor = java.util.concurrent.Executors.newSingleThreadExecutor();
        var connected = executor.submit(() -> {
            int accepted = 0;
            for (int i=0;i<20;i++) {
                try (Dadb adb = Dadb.create("127.0.0.1",5555,
                        AdbKeyPair.read(new File(dir,"private-key"),new File(dir,"public-key")),2000,3000)) {
                    if (adb.shell("id -u").getOutput().trim().equals("2000") && ++accepted == 2) return true;
                } catch (Exception unavailable) { Thread.sleep(300); }
            }
            return false;
        });
        try {
            for (int i=0;i<180 && !connected.isDone();i++) {
                var root = getUiAutomation().getRootInActiveWindow();
                if (root != null && "com.android.systemui".contentEquals(root.getPackageName())) {
                    checkPermissions(root);
                    Thread.sleep(200);
                    for (String label : List.of("Allow", "OK", "Разрешить")) {
                        var button = findText(root,label);
                        if (button != null) { button.performAction(android.view.accessibility.AccessibilityNodeInfo.ACTION_CLICK); break; }
                    }
                }
                Thread.sleep(200);
            }
            check(connected.get(5, java.util.concurrent.TimeUnit.SECONDS), "Local ADB authorization failed");
        } finally { executor.shutdownNow(); }
    }
    private void checkPermissions(android.view.accessibility.AccessibilityNodeInfo node) {
        if (node == null) return;
        if (node.isCheckable()) {
            android.util.Log.i("CleanerProbe", "authorization checkbox: " + node.getViewIdResourceName() + " checked=" + node.isChecked());
            if (!node.isChecked()) node.performAction(android.view.accessibility.AccessibilityNodeInfo.ACTION_CLICK);
        }
        for (int i=0;i<node.getChildCount();i++) checkPermissions(node.getChild(i));
    }
    @Override public void onStart() {
        Bundle result = new Bundle();
        try {
            check(Build.HARDWARE.contains("ranchu") || Build.HARDWARE.contains("goldfish"), "Emulator required");
            Context context = getTargetContext();
            if (phase.equals("keys")) {
                File dir = new File(context.getNoBackupFilesDir(), "adb"); dir.mkdirs();
                File privateKey = new File(dir, "private-key"), publicKey = new File(dir, "public-key");
                if (!privateKey.exists() || !publicKey.exists()) AdbKeyPair.generate(privateKey, publicKey);
            } else if (phase.equals("authorize")) {
                authorize(context);
            } else if (phase.equals("prepare")) {
                check(!marker(context).exists(), "Fixture already prepared");
                JSONObject original = new JSONObject().put("crash", prefs(context, "crash_loop"))
                    .put("adb", prefs(context, "adb_connection"));
                writeText(marker(context), original.toString());
                CrashLoopGuard.retry(context);
                context.getSharedPreferences("adb_connection", 0).edit().putInt("port", 5555).putBoolean("tls", false).commit();
                var monitor = addMonitor(LauncherActivity.class.getName(), null, false);
                context.startActivity(new Intent(context, LauncherActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
                Activity activity = monitor.waitForActivityWithTimeout(15000);
                removeMonitor(monitor);
                check(activity != null, "Launcher did not resume");
                File adbDir = new File(context.getNoBackupFilesDir(), "adb");
                try (Dadb transport = Dadb.create("127.0.0.1",5555,
                        AdbKeyPair.read(new File(adbDir,"private-key"),new File(adbDir,"public-key")),5000,10000)) {
                AdbBridge.Shell device = new AdbBridge.Shell() {
                    public String execute(String command) throws Exception {
                        var response = transport.shell(command);
                        if (response.getExitCode() != 0) throw new IllegalStateException("ADB command rejected");
                        return response.getOutput().trim();
                    }
                    public void close() { }
                };
                TvCleaner cleaner = new TvCleaner(activity, device);
                synchronized (AdbBridge.LOCK) {
                    Map<String, Object> first = cleaner.run("cleanerInventory", null, null);
                    check("success".equals(first.get("status")), "First inventory failed");
                    check(((Number)first.get("baselineCreatedAt")).longValue() > 0, "No baseline date");
                    JSONObject snapshot = new JSONObject((String)first.get("snapshot"));
                    check(snapshot.getJSONObject("states").has(APP), "Install fixture before first baseline creation");
                    File[] bases = context.getNoBackupFilesDir().listFiles((dir, name) -> name.startsWith("tv-cleaner-baseline-") && name.endsWith(".json"));
                    check(bases != null && bases.length == 1, "Expected one firmware baseline");
                    original.put("baseline", bases[0].getName()).put("baselineBytes", readText(bases[0]));
                    writeText(marker(context), original.toString());
                    long date = ((Number)first.get("baselineCreatedAt")).longValue();
                    for (var row : (List<Map<String,Object>>)first.get("manualStates"))
                        if ("emulator-state-probe".equals(row.get("name"))) cleaner.run("cleanerManualDelete",null,null,row.get("id").toString(),null);
                    cleaner.run("cleanerManualSave", null, null, null, "emulator-state-probe");
                    Map<String, Object> afterSave = cleaner.run("cleanerInventory", null, null);
                    var copies = (List<Map<String, Object>>)afterSave.get("manualStates");
                    String id = copies.stream().filter(row -> "emulator-state-probe".equals(row.get("name"))).findFirst().orElseThrow().get("id").toString();
                    for (String scope : List.of("system","preinstalled")) {
                        cleaner.run("cleanerApply",List.of(APP),false,null,null,"Before applying list: wrong scope",scope);
                        check(context.getPackageManager().getApplicationEnabledSetting(APP)==0, "User app escaped scope filter");
                    }
                    Map<String,Object> appliedList = cleaner.run("cleanerApply",List.of(APP,"org.example.missing"),false,null,null,
                        "Before applying list: emulator-list-probe",null);
                    check("success".equals(appliedList.get("status")), "Disable list failed");
                    var listCopies = (List<Map<String,Object>>)appliedList.get("manualStates");
                    String listCopy = listCopies.stream().filter(row -> "Before applying list: emulator-list-probe".equals(row.get("description")))
                        .findFirst().orElseThrow().get("id").toString();
                    JSONObject selectedCopy = new JSONObject((String)cleaner.run("cleanerManualExport",null,null,listCopy,null).get("manualSnapshot"));
                    check(selectedCopy.getJSONObject("states").length()==1 && selectedCopy.getJSONObject("states").getInt(APP)==0,
                        "Automatic copy must contain only the actually disabled package");
                    check("selectedApplications".equals(selectedCopy.getString("scope")), "Automatic copy scope missing");
                    cleaner.run("cleanerManualRestore",null,null,listCopy,null);
                    check(context.getPackageManager().getApplicationEnabledSetting(APP)==0,"Subset copy did not restore original state");
                    cleaner.run("cleanerManualDelete",null,null,listCopy,null);
                    check("success".equals(cleaner.run("cleanerManualRestore", null, null, id, null).get("status")), "Manual restore failed");
                    check(context.getPackageManager().getApplicationEnabledSetting(APP) == 0, "Manual state not restored");
                    check("success".equals(cleaner.run("cleanerManualExport", null, null, id, null).get("status")), "Manual export failed");
                    cleaner.run("cleanerManualDelete", null, null, id, null);
                    check("success".equals(cleaner.run("cleanerApply", List.of(APP), false).get("status")), "Second disable failed");
                    check("success".equals(AdbBridge.restoreCleanerFromRecovery(activity)), "Real local ADB recovery failed");
                    check(context.getPackageManager().getApplicationEnabledSetting(APP) == 0, "Real ADB did not restore fixture");
                    cleaner.run("cleanerApply", List.of(APP), false);
                    check(context.getPackageManager().getApplicationEnabledSetting(APP) == 3, "Crash fixture is not disabled");
                    Map<String, Object> last = cleaner.run("cleanerInventory", null, null);
                    check(((Number)last.get("baselineCreatedAt")).longValue() == date, "Baseline overwritten");
                    writeText(new File(context.getFilesDir(), "tv-cleaner-inventory.json"), new JSONObject(last).toString());
                }
                }
            } else {
                JSONObject original = new JSONObject(readText(marker(context)));
                if (phase.equals("verify")) {
                    check("success".equals(CrashLoopGuard.cleanerRestoreStatus(context)), "Crash-loop recovery did not succeed");
                    check(context.getPackageManager().getApplicationEnabledSetting(APP) == 0, "Crash-loop did not restore fixture");
                    check(!new File(context.getFilesDir(), "tv-cleaner-inventory.json").exists(), "Stale cache retained");
                    check(readText(new File(context.getNoBackupFilesDir(), original.getString("baseline")))
                        .equals(original.getString("baselineBytes")), "Protected baseline changed");
                } else if (phase.equals("cleanup")) {
                    shell(TvCleanerPolicy.command(APP, 0).replace("'", ""));
                    if (original.has("baseline")) {
                        String key = original.getString("baseline").replace("tv-cleaner-baseline-", "").replace(".json", "");
                        var store = new TvCleanerStateStore(context.getNoBackupFilesDir(), Build.FINGERPRINT, key);
                        for (var row : store.manualStates()) if ("emulator-state-probe".equals(row.get("name")) || "Before applying list: emulator-list-probe".equals(row.get("description"))) store.deleteManual(row.get("id").toString());
                    }
                    CrashLoopGuard.retry(context);
                    restorePrefs(context, "crash_loop", original.getJSONObject("crash"));
                    // Synthetic historical crashes must not be counted again on the next cold entry.
                    context.getSharedPreferences("crash_loop", 0).edit().putLong("seen", System.currentTimeMillis()).commit();
                    restorePrefs(context, "adb_connection", original.getJSONObject("adb"));
                    Files.delete(marker(context).toPath());
                } else throw new IllegalArgumentException("Unknown phase");
            }
            result.putString("stream", "\nPASS cleaner recovery " + phase + "\n"); finish(Activity.RESULT_OK, result);
        } catch (Throwable error) {
            java.io.StringWriter trace = new java.io.StringWriter(); error.printStackTrace(new java.io.PrintWriter(trace));
            result.putString("stream", "\nFAIL cleaner recovery " + phase + ": " + trace + "\n"); finish(Activity.RESULT_CANCELED, result);
        }
    }
}
