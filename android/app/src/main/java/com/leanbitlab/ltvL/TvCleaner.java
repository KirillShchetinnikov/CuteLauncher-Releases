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
    private final TvCleanerStateStore states;
    TvCleaner(Activity activity, AdbBridge.Shell shell) throws Exception {
        this.activity = activity; this.shell = shell; pm = activity.getPackageManager();
        String firmwareKey = android.util.Base64.encodeToString(
            java.security.MessageDigest.getInstance("SHA-256").digest(Build.FINGERPRINT.getBytes(StandardCharsets.UTF_8)),
            android.util.Base64.URL_SAFE | android.util.Base64.NO_WRAP | android.util.Base64.NO_PADDING);
        states = new TvCleanerStateStore(activity.getNoBackupFilesDir(), Build.FINGERPRINT, firmwareKey);
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
    private Map<String, Object> identity() {
        return Map.of("manufacturer", Build.MANUFACTURER, "model", Build.MODEL,
            "device", Build.DEVICE, "fingerprint", Build.FINGERPRINT,
            "androidVersion", Build.VERSION.RELEASE, "sdkInt", Build.VERSION.SDK_INT);
    }
    private JSONObject currentState() throws Exception {
        JSONObject values = new JSONObject();
        for (var row : inventory()) values.put(row.get("package").toString(), row.get("enabledSetting"));
        return new JSONObject().put("schemaVersion", 1).put("fingerprint", Build.FINGERPRINT)
            .put("identity", new JSONObject(identity())).put("capturedAt", System.currentTimeMillis())
            .put("states", values).put("changed", new JSONObject());
    }
    private JSONObject ensureSnapshot() throws Exception {
        JSONObject saved = read();
        if (saved != null) {
            states.ensureBaseline(saved); // Preserve the original date and states of older installations.
            return saved;
        }
        JSONObject baseline = states.baseline();
        if (baseline == null) baseline = states.ensureBaseline(currentState());
        saved = new JSONObject(baseline.toString()).put("changed", new JSONObject());
        write(saved); return saved;
    }
    boolean hasBaseline() throws Exception { return states.baseline() != null || read() != null; }
    Map<String, Object> run(String action, List<String> targets, Boolean enable) throws Exception {
        return run(action, targets, enable, null, null);
    }
    Map<String, Object> run(String action, List<String> targets, Boolean enable, String stateId, String stateName) throws Exception {
        return run(action, targets, enable, stateId, stateName, null, null);
    }
    Map<String, Object> run(String action, List<String> targets, Boolean enable, String stateId, String stateName,
            String listName, String listScope) throws Exception {
        if (!shell.execute("am get-current-user").equals("0") || !shell.execute("id -u").equals("2000"))
            return Map.of("status", "denied");
        if (action.equals("cleanerInventory")) { ensureSnapshot(); return report(); }
        if (action.equals("cleanerSnapshot")) { ensureSnapshot(); return report(); }
        if (action.equals("cleanerRestore") || action.equals("cleanerEmergencyRestore")) {
            JSONObject baseline = states.baseline();
            if (baseline == null) {
                // Older versions stored the original state in the journal. Never capture a new baseline here.
                JSONObject legacy = read();
                if (legacy == null) return Map.of("status", "noSnapshot");
                baseline = states.ensureBaseline(legacy);
            }
            return restoreState(baseline);
        }
        if (action.equals("cleanerManualSave")) {
            ensureSnapshot(); states.saveManual(currentState(), stateName); return report();
        }
        if (action.equals("cleanerManualDelete")) { states.deleteManual(stateId); return report(); }
        if (action.equals("cleanerManualExport"))
            return Map.of("status", "success", "manualSnapshot", states.manual(stateId).toString());
        if (action.equals("cleanerManualRestore")) return restoreState(states.manual(stateId));
        if (!action.equals("cleanerApply") || enable == null) return Map.of("status", "invalid");
        JSONObject descriptions = null;
        if (listScope != null) {
            try (var input = activity.getAssets().open("flutter_assets/catalog/app_descriptions.json")) {
                var bytes = new java.io.ByteArrayOutputStream(); byte[] buffer = new byte[8192]; int count;
                while ((count = input.read(buffer)) != -1) {
                    if (bytes.size() + count > 1024 * 1024) throw new IllegalStateException("Catalog too large");
                    bytes.write(buffer, 0, count);
                }
                descriptions = new JSONObject(new String(bytes.toByteArray(), StandardCharsets.UTF_8)).getJSONObject("packages");
            }
        }
        var installed = new LinkedHashMap<String, TvCleanerListPolicy.App>();
        for (var row : inventory()) {
            String name = row.get("package").toString();
            JSONObject metadata = descriptions == null ? null : descriptions.optJSONObject(name);
            boolean system = Boolean.TRUE.equals(row.get("system"));
            boolean preinstalled = system && metadata != null && "preinstalled".equals(metadata.optString("category"));
            installed.put(name, new TvCleanerListPolicy.App(system, preinstalled,
                Boolean.TRUE.equals(row.get("enabled")), Boolean.TRUE.equals(row.get("protected"))));
        }
        List<String> selected = TvCleanerListPolicy.select(targets, installed, listScope, enable);
        JSONObject before = new JSONObject();
        for (String name : selected) {
            int mode = state(name);
            if (!enable && mode >= 2) continue;
            before.put(name, mode);
        }
        selected.removeIf(name -> !before.has(name));
        if (selected.isEmpty()) return report();
        JSONObject saved = ensureSnapshot();
        if (!enable && listName != null) {
            JSONObject subset = new JSONObject().put("schemaVersion",1).put("fingerprint",Build.FINGERPRINT)
                .put("identity",new JSONObject(identity())).put("capturedAt",System.currentTimeMillis()).put("states",before);
            try { states.saveBeforeList(subset, listName); }
            catch (Exception failedCopy) { return Map.of("status", "snapshotFailed"); }
        }
        try { TvCleanerRecovery.apply(selected, enable ? 1 : 3, journal(saved), device()); }
        catch (Exception error) { return Map.of("status", "partial"); }
        return report();
    }
    private Map<String, Object> restoreState(JSONObject source) throws Exception {
        Map<String, Integer> desired = TvCleanerStateStore.states(source);
        JSONObject saved = ensureSnapshot();
        Set<String> installed = new HashSet<>(), protectedNames = new HashSet<>();
        var needed = new LinkedHashMap<String, Integer>();
        var actual = new HashMap<String, Integer>();
        for (var row : inventory()) {
            String name = row.get("package").toString(); installed.add(name);
            actual.put(name, ((Number)row.get("enabledSetting")).intValue());
            if (Boolean.TRUE.equals(row.get("protected"))) protectedNames.add(name);
        }
        TvCleanerRecovery.Journal journal = journal(saved);
        for (var entry : desired.entrySet()) {
            if (!Objects.equals(actual.get(entry.getKey()), entry.getValue())) needed.put(entry.getKey(), entry.getValue());
            else if (Objects.equals(journal.original(entry.getKey()), entry.getValue())) journal.forget(entry.getKey());
        }
        journal.persist();
        int skipped;
        try { skipped = TvCleanerRecovery.restoreStates(needed, installed, protectedNames, journal, device()); }
        catch (Exception error) { return Map.of("status", "partial"); }
        var result = report();
        if (skipped > 0) { result.put("status", "partial"); result.put("skippedRestore", skipped); }
        return result;
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
        result.put("identity", identity());
        result.put("packages", inventory()); result.put("snapshotSaved", saved != null);
        result.put("pendingRestore", saved == null ? 0 : saved.getJSONObject("changed").length());
        JSONObject baseline = states.baseline();
        result.put("baselineCreatedAt", baseline == null ? 0 : baseline.getLong("capturedAt"));
        result.put("manualStates", states.manualStates());
        result.put("snapshot", saved == null ? "" : saved.toString());
        return result;
    }
}
