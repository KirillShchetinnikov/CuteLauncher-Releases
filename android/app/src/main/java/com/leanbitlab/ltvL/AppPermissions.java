package com.leanbitlab.ltvL;

import android.accessibilityservice.AccessibilityServiceInfo;
import android.content.ComponentName;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import android.view.accessibility.AccessibilityManager;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ExecutorService;
import org.json.JSONObject;

/** Local opt-in consent, shared by settings and the existing recovery worker. */
final class AppPermissions {
    private final Context context;
    private final AdbBridge.Shell testShell;
    private Plan pending;
    private record Target(String component, String pkg, String name, String service, String signature) { }
    private record Plan(String token, Target target, List<String> ops, long expires) { }
    AppPermissions(Context context) { this(context, null); }
    AppPermissions(Context context, AdbBridge.Shell testShell) {
        this.context = context.getApplicationContext(); this.testShell = testShell;
    }
    private <T> T session(AdbBridge.Session<T> action) throws Exception {
        return testShell == null ? AdbBridge.recentSession(context, action) : action.run(testShell);
    }
    static SharedPreferences prefs(Context c) { return c.getSharedPreferences("app_permissions", 0); }
    private JSONObject state(String component) throws Exception {
        return new JSONObject(prefs(context).getString(component, "{}"));
    }
    private void save(String component, JSONObject state) {
        if (!prefs(context).edit().putString(component, state.toString()).commit())
            throw new IllegalStateException("save_failed");
    }
    private String signature(String pkg) throws Exception {
        var info = context.getPackageManager().getPackageInfo(pkg, PackageManager.GET_SIGNING_CERTIFICATES);
        if (info.signingInfo == null) throw new IllegalStateException("missing_signature");
        List<String> signatures = new ArrayList<>();
        for (var cert : info.signingInfo.getApkContentsSigners())
            signatures.add(android.util.Base64.encodeToString(MessageDigest.getInstance("SHA-256")
                .digest(cert.toByteArray()), android.util.Base64.NO_WRAP));
        if (signatures.isEmpty()) throw new IllegalStateException("missing_signature");
        Collections.sort(signatures);
        // An uninstall/reinstall with the same signer must also require new consent,
        // even when the removal broadcast was missed while the launcher was stopped.
        return String.join(":", signatures) + ":" + info.firstInstallTime;
    }
    private List<Target> targets() throws Exception {
        if (android.os.Process.myUid() / 100000 != 0)
            throw new IllegalStateException("unsupported_user");
        var manager = (AccessibilityManager) context.getSystemService(Context.ACCESSIBILITY_SERVICE);
        if (manager == null) throw new IllegalStateException("unsupported");
        List<Target> result = new ArrayList<>();
        for (AccessibilityServiceInfo info : manager.getInstalledAccessibilityServiceList()) {
            var resolve = info.getResolveInfo();
            var service = resolve.serviceInfo;
            if (service == null || service.packageName.equals(context.getPackageName())
                    || !"android.permission.BIND_ACCESSIBILITY_SERVICE".equals(service.permission)
                    || !service.enabled || !service.applicationInfo.enabled) continue;
            var name = new ComponentName(service.packageName, service.name).flattenToString();
            // Validate shell arguments and list format before ever exposing an actionable target.
            try {
                // Read current package flags, not cached AccessibilityServiceInfo metadata.
                var app = context.getPackageManager().getApplicationInfo(service.packageName, 0);
                if ((app.flags & (ApplicationInfo.FLAG_SYSTEM | ApplicationInfo.FLAG_UPDATED_SYSTEM_APP)) != 0) {
                    // Retire consent created by earlier builds without changing system permissions.
                    packageRemoved(context, service.packageName);
                    continue;
                }
                if (!app.enabled) continue;
                UpdatePermissionPolicy.serviceList("", name, true);
                result.add(new Target(name, service.packageName,
                    service.applicationInfo.loadLabel(context.getPackageManager()).toString(),
                    resolve.loadLabel(context.getPackageManager()).toString(), signature(service.packageName)));
            } catch (PackageManager.NameNotFoundException | IllegalArgumentException ignored) { /* Removed or invalid component. */ }
        }
        result.sort(java.util.Comparator.comparing(Target::name).thenComparing(Target::component));
        return result;
    }
    private Target target(String component) throws Exception {
        for (Target target : targets()) if (target.component.equals(component)) return target;
        throw new IllegalStateException("target_missing");
    }
    private JSONObject checkedState(Target target) throws Exception {
        JSONObject s = state(target.component);
        if (s.has("signature") && !target.signature.equals(s.getString("signature"))) {
            // Never inherit consent across a reinstall with a different signing identity.
            s = new JSONObject().put("restore", false).put("result", "identity_changed");
            save(target.component, s);
        }
        return s;
    }
    private Map<String, Object> snapshot(Target target) throws Exception {
        var s = checkedState(target);
        var row = new LinkedHashMap<String, Object>();
        row.put("component", target.component); row.put("package", target.pkg);
        row.put("name", target.name); row.put("service", target.service);
        row.put("restore", s.optBoolean("restore", true)); row.put("managed", s.optBoolean("managed"));
        String list = Settings.Secure.getString(context.getContentResolver(), Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES);
        row.put("enabled", list != null && AppPermissionOps.contains(list, target.component)
            && Settings.Secure.getInt(context.getContentResolver(), Settings.Secure.ACCESSIBILITY_ENABLED, 0) == 1);
        row.put("result", s.optString("result", "not_managed"));
        row.put("checkedAt", s.optLong("checkedAt"));
        Map<String, String> modes = new LinkedHashMap<>();
        JSONObject stored = s.optJSONObject("modes");
        for (String op : AdbAccessibilityOps.OPERATIONS) modes.put(op, stored == null ? "unknown" : stored.optString(op, "unknown"));
        row.put("modes", modes);
        return row;
    }
    private Map<String, Object> list() throws Exception {
        List<Map<String, Object>> result = new ArrayList<>();
        for (Target target : targets()) result.add(snapshot(target));
        return Map.of("status", "success", "services", result);
    }
    private void rememberModes(Target target, Map<String, String> modes, String result) throws Exception {
        JSONObject s = checkedState(target).put("modes", new JSONObject(modes))
            .put("checkedAt", System.currentTimeMillis()).put("result", result);
        save(target.component, s);
    }
    Map<String, Object> run(String method, String component, Boolean restore, String token) throws Exception {
        synchronized (AdbBridge.LOCK) {
            if (method.equals("list")) return list();
            Target target = target(component);
            JSONObject s = checkedState(target);
            if (method.equals("configure")) {
                if (restore == null) throw new IllegalArgumentException("Missing restore setting");
                save(component, s.put("restore", restore).put("attempts", 0).put("next", 0)
                    .put("result", s.optBoolean("managed") ? (restore ? "watching" : "paused") : "not_managed"));
                return Map.of("status", "success", "service", snapshot(target));
            }
            if (!List.of("inspect", "preview", "apply", "disable", "reconnect").contains(method))
                throw new IllegalArgumentException("Invalid action");
            // Cancel recovery before trying ADB, including when ADB is unavailable.
            if (method.equals("disable")) save(component, s.put("restore", false).put("managed", false)
                .put("result", "paused").put("attempts", 0).put("next", 0));
            return session(shell -> {
                AppPermissionOps.checkUser(shell);
                // Recheck identity after connecting and before mutations.
                if (!target.signature.equals(target(component).signature)) throw new IllegalStateException("identity_changed");
                if (method.equals("disable") || method.equals("reconnect")) {
                    if (method.equals("disable")) AppPermissionOps.setEnabled(shell, component, false);
                    else AppPermissionOps.reconnect(shell, component);
                    save(component, checkedState(target).put("result", method.equals("disable") ? "paused" : "success"));
                    return Map.of("status", "success", "service", snapshot(target));
                }
                Map<String, String> modes = AppPermissionOps.modes(target.pkg, shell);
                List<String> ops = AppPermissionOps.plan(target.pkg, modes);
                if (method.equals("preview")) {
                    pending = new Plan(UUID.randomUUID().toString(), target, ops, System.currentTimeMillis() + 300_000);
                    rememberModes(target, modes, "checked");
                    List<String> commands = new ArrayList<>(ops);
                    String list = UpdatePermissionPolicy.serviceList(
                        shell.execute("settings get secure enabled_accessibility_services").trim(), component, true);
                    commands.add("settings put secure enabled_accessibility_services '" + list + "'");
                    commands.add("settings put secure accessibility_enabled 1");
                    return Map.of("status", "success", "token", pending.token, "commands", commands,
                        "service", snapshot(target));
                }
                if (method.equals("apply")) {
                    Plan plan = pending; pending = null;
                    if (plan == null || !plan.token.equals(token) || !plan.target.equals(target)
                            || plan.expires < System.currentTimeMillis() || !plan.ops.containsAll(ops))
                        throw new IllegalStateException("stale_plan");
                    // Persist explicit consent before writes, so partial failures remain recoverable.
                    save(component, checkedState(target).put("managed", true).put("signature", target.signature)
                        .put("result", "pending").put("attempts", 0).put("next", 0));
                    if (!AdbAccessibilityOps.apply(target.pkg, shell::execute, ops)) throw new IllegalStateException("permission_rejected");
                    AppPermissionOps.setEnabled(shell, component, true);
                }
                modes = AppPermissionOps.modes(target.pkg, shell);
                if (method.equals("apply") && (!AppPermissionOps.plan(target.pkg, modes).isEmpty()
                        || !AppPermissionOps.enabled(shell, component)))
                    throw new IllegalStateException("permission_rejected");
                rememberModes(target, modes, method.equals("inspect")
                    ? checkedState(target).optString("result", "checked") : "success");
                return Map.of("status", "success", "service", snapshot(target));
            });
        }
    }
    static long delay(int attempts) { return attempts >= 3 ? 3_600_000L : attempts == 2 ? 60_000L : 15_000L; }
    static void health(Context context) {
        new AppPermissions(context).recover(System.currentTimeMillis());
    }
    void recover(long now) {
        synchronized (AdbBridge.LOCK) {
            if (prefs(context).getAll().isEmpty()) return;
            AppPermissions manager = this;
            try {
                List<Target> targets = manager.targets();
                for (Target target : targets) {
                    JSONObject s = manager.checkedState(target);
                    if (!s.optBoolean("managed") || !s.optBoolean("restore", true) || s.optLong("next") > now) continue;
                    try {
                        manager.session(shell -> {
                            AppPermissionOps.checkUser(shell);
                            if (!target.signature.equals(manager.target(target.component).signature)) throw new IllegalStateException("identity_changed");
                            Map<String, String> modes = AppPermissionOps.modes(target.pkg, shell);
                            List<String> ops = AppPermissionOps.plan(target.pkg, modes);
                            boolean enabled = AppPermissionOps.enabled(shell, target.component);
                            if (!AdbAccessibilityOps.apply(target.pkg, shell::execute, ops)) throw new IllegalStateException("permission_rejected");
                            if (!AppPermissionOps.enabled(shell, target.component)) AppPermissionOps.setEnabled(shell, target.component, true);
                            Map<String, String> finalModes = AppPermissionOps.modes(target.pkg, shell);
                            if (!AppPermissionOps.plan(target.pkg, finalModes).isEmpty()
                                    || !AppPermissionOps.enabled(shell, target.component)) throw new IllegalStateException("permission_rejected");
                            manager.rememberModes(target, finalModes,
                                !enabled || !ops.isEmpty() ? "restored" : "watching");
                            return null;
                        });
                        manager.save(target.component, manager.state(target.component).put("attempts", 0).put("next", now + 30_000));
                    } catch (Exception error) {
                        int attempts = s.optInt("attempts") + 1;
                        manager.save(target.component, manager.state(target.component).put("attempts", Math.min(attempts, 3))
                            .put("next", now + delay(attempts)).put("result", "retry"));
                    }
                }
            } catch (Exception error) { android.util.Log.w("CuteAppPermissions", "Recovery unavailable"); }
        }
    }
    static long nextCheck(Context c) {
        synchronized (AdbBridge.LOCK) {
            long due = Long.MAX_VALUE;
            for (Object value : prefs(c).getAll().values()) try {
                JSONObject s = new JSONObject((String) value);
                if (s.optBoolean("managed") && s.optBoolean("restore", true) && s.optString("result").equals("retry"))
                    due = Math.min(due, s.optLong("next"));
            } catch (Exception ignored) { }
            return due == Long.MAX_VALUE ? 0 : due;
        }
    }
    static void packageRemoved(Context c, String pkg) {
        synchronized (AdbBridge.LOCK) {
            var edit = prefs(c).edit();
            boolean changed = false;
            for (String component : prefs(c).getAll().keySet()) if (component.startsWith(pkg + "/")) {
                edit.remove(component); changed = true;
            }
            if (changed && !edit.commit()) throw new IllegalStateException("save_failed");
        }
    }
    static void register(Context context, BinaryMessenger messenger, ExecutorService executor) {
        AppPermissions manager = new AppPermissions(context);
        Handler main = new Handler(Looper.getMainLooper());
        new MethodChannel(messenger, "cutelauncher/app_permissions").setMethodCallHandler((call, result) -> {
            String component = call.argument("component"); Boolean restore = call.argument("restore"); String token = call.argument("token");
            executor.execute(() -> {
                Map<String, Object> response;
                try { response = manager.run(call.method, component, restore, token); }
                catch (Exception | LinkageError error) { response = Map.of("status", "error"); }
                Map<String, Object> completed = response;
                main.post(() -> result.success(completed));
                if (!call.method.equals("list") && !call.method.equals("inspect") && !call.method.equals("preview"))
                    try { PermissionRecoveryScheduler.enqueue(manager.context, 30); } catch (RuntimeException ignored) { }
            });
        });
    }
}
