package com.leanbitlab.ltvL;

import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import java.util.*;

/** All mutations re-resolve live TV tasks and package metadata under the ADB session lock. */
final class RecentAppsControl {
    private final Context context;
    private final AdbBridge.Shell shell;
    private long deadline;
    private final Set<String> homePackages = new HashSet<>();
    RecentAppsControl(Context context, AdbBridge.Shell shell) { this.context = context; this.shell = shell; }
    private List<RecentTaskPolicy.Task> tasks() throws Exception {
        checkActive();
        return RecentTaskPolicy.parse(shell.execute("am stack list"), shell.execute("dumpsys activity recents"));
    }
    private void checkActive() throws InterruptedException {
        if (Thread.currentThread().isInterrupted() || System.nanoTime() > deadline) throw new InterruptedException("Task operation cancelled");
    }
    private boolean eligible(String pkg) {
        if (pkg.equals(context.getPackageName()) || pkg.equals("com.android.systemui") || pkg.equals("com.nes.recents")) return false;
        var pm = context.getPackageManager();
        try {
            if (!pm.getApplicationInfo(pkg, 0).enabled || pm.getLeanbackLaunchIntentForPackage(pkg) == null) return false;
            return !homePackages.contains(pkg);
        } catch (PackageManager.NameNotFoundException absent) { return false; }
    }
    private boolean userApp(String pkg) throws PackageManager.NameNotFoundException {
        return userApp(context.getPackageManager().getApplicationInfo(pkg, 0));
    }
    private boolean userApp(ApplicationInfo app) {
        int flags = app.flags;
        return (flags & (ApplicationInfo.FLAG_SYSTEM | ApplicationInfo.FLAG_UPDATED_SYSTEM_APP)) == 0;
    }
    Map<String, Object> run(String action, String pkg) throws Exception {
        deadline = System.nanoTime() + java.util.concurrent.TimeUnit.SECONDS.toNanos(20);
        if (!"2000".equals(shell.execute("id -u").trim()) || !"0".equals(shell.execute("am get-current-user").trim()))
            throw new IllegalStateException("Unsupported Android user");
        homePackages.clear();
        for (var home : context.getPackageManager().queryIntentActivities(new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME), 0))
            if (home.activityInfo != null) homePackages.add(home.activityInfo.packageName);
        List<RecentTaskPolicy.Task> live = tasks();
        boolean failed = false;
        Set<String> closing = new HashSet<>();
        if (action.equals("closeAll")) {
            Set<String> targets = new LinkedHashSet<>();
            Set<String> seen = new HashSet<>();
            for (var task : live) if (seen.add(task.pkg()) && eligible(task.pkg()) && userApp(task.pkg())) targets.add(task.pkg());
            for (String target : targets) {
                checkActive();
                try {
                    if (eligible(target) && userApp(target) && tasks().stream().anyMatch(task -> task.pkg().equals(target)))
                        { checkActive(); closing.add(target); shell.execute("am force-stop --user 0 " + target); }
                } catch (Exception error) { failed = true; }
            }
        } else if (!action.equals("list")) {
            if (pkg == null || !pkg.matches("[A-Za-z][A-Za-z0-9_]*(\\.[A-Za-z0-9_]+)+") || !eligible(pkg))
                throw new IllegalArgumentException("Invalid target");
            var selected = live.stream().filter(task -> task.pkg().equals(pkg)).collect(java.util.stream.Collectors.toList());
            if (selected.isEmpty()) return Map.of("status", "stale", "apps", list(tasks()));
            if (action.equals("switch")) {
                shell.execute("am task focus " + selected.get(0).id());
                return Map.of("status", "success");
            }
            if (!action.equals("close")) throw new IllegalArgumentException("Invalid action");
            closing.add(pkg);
            for (var task : selected) {
                // A task may disappear while the panel is open. Never operate on a reused ID.
                if (tasks().contains(task)) { checkActive(); shell.execute("am stack remove " + task.id()); }
            }
        }
        List<RecentTaskPolicy.Task> after = action.equals("list") ? live : tasks();
        // Task removal is asynchronous on some TV builds. Bound convergence to three seconds.
        for (int attempt = 0; attempt < 15 && after.stream().anyMatch(task -> closing.contains(task.pkg())); attempt++) {
            checkActive(); Thread.sleep(200); after = tasks();
        }
        if (action.equals("close") && after.stream().anyMatch(task -> task.pkg().equals(pkg))) failed = true;
        if (action.equals("closeAll"))
            for (var task : after) if (eligible(task.pkg()) && userApp(task.pkg())) failed = true;
        return Map.of("status", failed ? "partial" : "success", "apps", list(after));
    }
    private List<Map<String, Object>> list(List<RecentTaskPolicy.Task> tasks) throws Exception {
        Map<String, Map<String, Object>> rows = new LinkedHashMap<>();
        Set<String> seen = new HashSet<>();
        var pm = context.getPackageManager();
        for (var task : tasks) {
            if (!seen.add(task.pkg()) || !eligible(task.pkg())) continue;
            var app = pm.getApplicationInfo(task.pkg(), 0);
            rows.put(task.pkg(), Map.of("packageName", task.pkg(), "name", app.loadLabel(pm).toString(), "userApp", userApp(app)));
        }
        return new ArrayList<>(rows.values());
    }
}
