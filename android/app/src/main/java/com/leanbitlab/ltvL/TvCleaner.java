package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.AtomicFile;
import java.io.File;
import java.io.FileOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.*;
import org.json.JSONObject;

/** All calls run under AdbBridge.LOCK, on its worker. Never uninstalls or clears data. */
final class TvCleaner {
    private final Activity activity;
    private final AdbBridge.Shell shell;
    private final AtomicFile storage;
    private final PackageManager pm;
    TvCleaner(Activity activity, AdbBridge.Shell shell) throws Exception {
        this.activity = activity; this.shell = shell; pm = activity.getPackageManager();
        String firmwareKey = android.util.Base64.encodeToString(
            java.security.MessageDigest.getInstance("SHA-256").digest(Build.FINGERPRINT.getBytes(StandardCharsets.UTF_8)),
            android.util.Base64.URL_SAFE | android.util.Base64.NO_WRAP | android.util.Base64.NO_PADDING);
        // An OTA gets a new baseline; recovery data for the previous firmware is retained.
        storage = new AtomicFile(new File(activity.getNoBackupFilesDir(), "tv-cleaner-" + firmwareKey + ".json"));
    }
    private JSONObject read() throws Exception {
        if (!storage.getBaseFile().exists() && !new File(storage.getBaseFile() + ".bak").exists()) return null;
        byte[] bytes = storage.readFully();
        if (bytes.length > 1024 * 1024) throw new IllegalStateException("Invalid snapshot");
        JSONObject saved = new JSONObject(new String(bytes, StandardCharsets.UTF_8));
        if (saved.getInt("schemaVersion") != 1 || !Build.FINGERPRINT.equals(saved.getString("fingerprint")))
            throw new IllegalStateException("Different firmware");
        return saved;
    }
    private void write(JSONObject value) throws Exception {
        FileOutputStream stream = storage.startWrite();
        try {
            byte[] bytes = value.toString().getBytes(StandardCharsets.UTF_8);
            stream.write(bytes);
            stream.getFD().sync();
            storage.finishWrite(stream);
            if (!Arrays.equals(bytes, storage.readFully())) throw new java.io.IOException("Snapshot verification failed");
        } catch (Exception error) { storage.failWrite(stream); throw error; }
    }
    private int state(String name) throws Exception {
        String dump = shell.execute("dumpsys package '" + name + "'");
        return TvCleanerPolicy.parseState(dump);
    }
    private Set<String> protectedPackages() throws Exception {
        Set<String> names = new HashSet<>();
        names.add(activity.getPackageName());
        // Every registered HOME, even when disabled, remains a recovery route.
        for (var info : pm.queryIntentActivities(new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME),
                PackageManager.MATCH_DISABLED_COMPONENTS)) names.add(info.activityInfo.packageName);
        // The existing authorized shell can read keys hidden from targetSdk 34+ apps.
        // A failed query still aborts before any disabling; protection never fails open.
        names.addAll(TvCleanerSettingsProtection.collect(shell::execute));
        var policy = activity.getSystemService(android.app.admin.DevicePolicyManager.class);
        if (policy != null && policy.getActiveAdmins() != null)
            for (var admin : policy.getActiveAdmins()) names.add(admin.getPackageName());
        var inputs = activity.getSystemService(android.media.tv.TvInputManager.class);
        if (inputs != null) for (var input : inputs.getTvInputList()) names.add(input.getServiceInfo().packageName);
        return names;
    }
    private boolean blocked(ApplicationInfo info, Set<String> protectedNames) {
        return info.uid < 10000 || (info.flags & ApplicationInfo.FLAG_PERSISTENT) != 0
            || protectedNames.contains(info.packageName) || TvCleanerPolicy.critical(info.packageName);
    }
    private List<Map<String, Object>> inventory() throws Exception {
        Set<String> protectedNames = protectedPackages();
        var rows = new ArrayList<Map<String, Object>>();
        for (var info : pm.getInstalledPackages(PackageManager.MATCH_DISABLED_COMPONENTS)) {
            ApplicationInfo app = info.applicationInfo;
            if (app == null || !TvCleanerPolicy.packageId(info.packageName)) continue;
            var row = new LinkedHashMap<String, Object>();
            row.put("package", info.packageName); row.put("name", app.loadLabel(pm).toString());
            row.put("versionName", info.versionName == null ? "" : info.versionName);
            row.put("versionCode", info.getLongVersionCode());
            row.put("system", (app.flags & ApplicationInfo.FLAG_SYSTEM) != 0);
            row.put("enabled", app.enabled); row.put("enabledSetting", pm.getApplicationEnabledSetting(info.packageName));
            row.put("protected", blocked(app, protectedNames)); rows.add(row);
        }
        rows.sort(Comparator.comparing(row -> row.get("package").toString()));
        if (rows.isEmpty() || rows.size() > 2000) throw new IllegalStateException("Invalid inventory");
        return rows;
    }
    private JSONObject ensureSnapshot() throws Exception {
        JSONObject saved = read();
        if (saved != null) return saved;
        JSONObject states = new JSONObject();
        for (var row : inventory()) states.put(row.get("package").toString(), row.get("enabledSetting"));
        saved = new JSONObject().put("schemaVersion", 1).put("fingerprint", Build.FINGERPRINT)
            .put("capturedAt", System.currentTimeMillis()).put("states", states).put("changed", new JSONObject());
        write(saved); return saved;
    }
    Map<String, Object> run(String action, List<String> targets, Boolean enable) throws Exception {
        if (!shell.execute("am get-current-user").equals("0") || !shell.execute("id -u").equals("2000"))
            return Map.of("status", "denied");
        if (action.equals("cleanerInventory")) return report();
        if (action.equals("cleanerSnapshot")) { ensureSnapshot(); return report(); }
        if (action.equals("cleanerRestore")) return restore();
        if (!action.equals("cleanerApply") || targets == null || targets.isEmpty() || targets.size() > 500 || enable == null)
            return Map.of("status", "invalid");
        Set<String> unique = new LinkedHashSet<>(targets);
        Set<String> protectedNames = protectedPackages();
        // Validate the entire list before the first write; no commands supplied by Dart or files.
        for (String name : unique) {
            if (!TvCleanerPolicy.packageId(name)) return Map.of("status", "invalid");
            ApplicationInfo info = pm.getApplicationInfo(name, PackageManager.MATCH_DISABLED_COMPONENTS);
            if (!enable && blocked(info, protectedNames)) return Map.of("status", "protected", "package", name);
            state(name);
        }
        JSONObject saved = ensureSnapshot();
        try { TvCleanerRecovery.apply(new ArrayList<>(unique), enable ? 1 : 3, journal(saved), device()); }
        catch (Exception error) { return Map.of("status", "partial"); }
        return report();
    }
    private Map<String, Object> restore() throws Exception {
        JSONObject saved = read();
        if (saved == null) return Map.of("status", "noSnapshot");
        try { TvCleanerRecovery.restore(journal(saved), device()); }
        catch (Exception error) { return Map.of("status", "partial"); }
        return report();
    }
    private TvCleanerRecovery.Device device() {
        return new TvCleanerRecovery.Device() {
            public int state(String name) throws Exception { return TvCleaner.this.state(name); }
            public void set(String name, int value) throws Exception { shell.execute(TvCleanerPolicy.command(name, value)); }
        };
    }
    private TvCleanerRecovery.Journal journal(JSONObject saved) throws Exception {
        JSONObject changed = saved.getJSONObject("changed"), baseline = saved.getJSONObject("states");
        return new TvCleanerRecovery.Journal() {
            public Integer original(String name) throws Exception { return changed.has(name) ? changed.getInt(name) : null; }
            public void remember(String name, int fallback) throws Exception { changed.put(name, baseline.optInt(name, fallback)); }
            public Set<String> pending() { Set<String> names = new LinkedHashSet<>(); changed.keys().forEachRemaining(names::add); return names; }
            public void forget(String name) { changed.remove(name); }
            public void persist() throws Exception { write(saved); }
        };
    }
    private Map<String, Object> report() throws Exception {
        JSONObject saved = read();
        var result = new LinkedHashMap<String, Object>();
        result.put("status", "success"); result.put("schemaVersion", 1);
        result.put("reportType", "tvCleanerInventory"); result.put("capturedAt", System.currentTimeMillis());
        result.put("identity", Map.of("manufacturer", Build.MANUFACTURER, "model", Build.MODEL,
            "device", Build.DEVICE, "fingerprint", Build.FINGERPRINT));
        result.put("packages", inventory()); result.put("snapshotSaved", saved != null);
        result.put("pendingRestore", saved == null ? 0 : saved.getJSONObject("changed").length());
        result.put("snapshot", saved == null ? "" : saved.toString());
        return result;
    }
}
