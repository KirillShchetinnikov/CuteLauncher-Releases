package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.ActivityOptions;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.ActivityInfo;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Handler;
import android.os.Looper;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.function.BooleanSupplier;
import io.flutter.plugin.common.MethodChannel;

/** Explicit, local opt-in. Requests Activity creation behind Home, never arbitrary services. */
final class BackgroundStartup {
    private final Activity activity;
    private final SharedPreferences prefs;
    private final ExecutorService worker = Executors.newSingleThreadExecutor();
    private final Handler main = new Handler(Looper.getMainLooper());
    private final Handler launches = new Handler(Looper.getMainLooper());
    private final Map<String, String> outcomes = new java.util.HashMap<>();
    private boolean closed;
    private int generation;

    BackgroundStartup(Activity activity) {
        this.activity = activity;
        prefs = preferences(activity);
    }

    private static SharedPreferences preferences(Context context) {
        return context.getSharedPreferences("background_startup", Context.MODE_PRIVATE);
    }

    static boolean enabled(Context context) {
        return !preferences(context).getStringSet("apps", Set.of()).isEmpty();
    }

    static boolean packageName(String value, String own) {
        return value != null && value.length() <= 255 && !value.equals(own)
            && value.matches("[A-Za-z][A-Za-z0-9_]*(\\.[A-Za-z][A-Za-z0-9_]*)+");
    }

    Intent target(String app) {
        try {
            var pm = activity.getPackageManager();
            var info = pm.getApplicationInfo(app, 0);
            if (!info.enabled || (info.flags & (ApplicationInfo.FLAG_SYSTEM | ApplicationInfo.FLAG_UPDATED_SYSTEM_APP)) != 0
                    || app.equals(activity.getPackageName())) return null;
            Intent intent = pm.getLeanbackLaunchIntentForPackage(app);
            if (intent == null) intent = pm.getLaunchIntentForPackage(app);
            if (intent == null) return null;
            var resolved = pm.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY);
            if (resolved == null || resolved.activityInfo == null) return null;
            var entry = resolved.activityInfo;
            if (!entry.enabled || !entry.exported || !app.equals(entry.packageName)
                    || (entry.launchMode != ActivityInfo.LAUNCH_MULTIPLE && entry.launchMode != ActivityInfo.LAUNCH_SINGLE_TOP)
                    || entry.documentLaunchMode == ActivityInfo.DOCUMENT_LAUNCH_NEVER) return null;
            // Replace the launcher's NEW_TASK/RESET_TASK flags; task-behind requires a document task.
            return intent.setComponent(new android.content.ComponentName(entry.packageName, entry.name))
                .setFlags(Intent.FLAG_ACTIVITY_NEW_DOCUMENT | Intent.FLAG_ACTIVITY_MULTIPLE_TASK
                    | Intent.FLAG_ACTIVITY_NO_USER_ACTION);
        } catch (PackageManager.NameNotFoundException | RuntimeException error) {
            return null;
        }
    }

    boolean handle(String method, Object arguments, MethodChannel.Result result) {
        if (!method.equals("backgroundInfo") && !method.equals("backgroundSave") && !method.equals("backgroundSetApp")) return false;
        if (method.equals("backgroundSetApp")) {
            if (!(arguments instanceof Map<?, ?> config) || !(config.get("app") instanceof String app)
                    || !packageName(app, activity.getPackageName()) || !(config.get("enabled") instanceof Boolean enabled)) {
                result.success(Map.of("status", "invalid")); return true;
            }
            worker.execute(() -> {
                // Read/modify/write one package on the same worker as all other selection writes.
                var selected = new HashSet<>(prefs.getStringSet("apps", Set.of()));
                if (enabled && !selected.contains(app) && (target(app) == null || selected.size() >= 200)) {
                    main.post(() -> result.success(Map.of("status", "unavailable"))); return;
                }
                if (enabled) selected.add(app); else selected.remove(app);
                boolean saved = prefs.edit().putStringSet("apps", selected).commit();
                main.post(() -> result.success(Map.of("status", saved ? "success" : "unavailable", "selected", new ArrayList<>(selected))));
            });
        } else if (method.equals("backgroundSave")) {
            if (!(arguments instanceof List<?> apps) || apps.size() > 200) {
                result.success(Map.of("status", "invalid")); return true;
            }
            Set<String> selected = new HashSet<>();
            for (Object item : apps) {
                if (!(item instanceof String app) || !packageName(app, activity.getPackageName())) {
                    result.success(Map.of("status", "invalid")); return true;
                }
                selected.add(app);
            }
            worker.execute(() -> {
                // Existing unavailable selections may be retained or removed, never newly enabled.
                var old = prefs.getStringSet("apps", Set.of());
                boolean valid = selected.stream().allMatch(app -> old.contains(app) || target(app) != null);
                boolean saved = valid && prefs.edit().putStringSet("apps", selected).commit();
                main.post(() -> result.success(Map.of("status", saved ? "success" : "unavailable")));
            });
        } else {
            worker.execute(() -> {
                try {
                    var selected = new HashSet<>(prefs.getStringSet("apps", Set.of()));
                    List<Map<String, Object>> apps = new ArrayList<>();
                    var pm = activity.getPackageManager();
                    for (var info : pm.getInstalledApplications(0)) {
                        if ((info.flags & (ApplicationInfo.FLAG_SYSTEM | ApplicationInfo.FLAG_UPDATED_SYSTEM_APP)) != 0
                                || info.packageName.equals(activity.getPackageName())) continue;
                        if (pm.getLeanbackLaunchIntentForPackage(info.packageName) == null
                                && pm.getLaunchIntentForPackage(info.packageName) == null && !selected.contains(info.packageName)) continue;
                        apps.add(Map.of("packageName", info.packageName, "name", info.loadLabel(pm).toString(),
                            "available", target(info.packageName) != null, "selected", selected.remove(info.packageName)));
                    }
                    for (String app : selected) apps.add(Map.of("packageName", app, "name", app,
                        "available", false, "selected", true));
                    apps.sort(java.util.Comparator.comparing(app -> (String) app.get("name"), String.CASE_INSENSITIVE_ORDER));
                    main.post(() -> result.success(Map.of("apps", apps, "outcomes", new java.util.HashMap<>(outcomes))));
                } catch (RuntimeException error) {
                    main.post(() -> result.error("unavailable", "Application list unavailable", null));
                }
            });
        }
        return true;
    }

    void launch(BooleanSupplier foreground, Runnable finished) {
        int token = ++generation;
        var selected = new HashSet<>(prefs.getStringSet("apps", Set.of()));
        if (selected.isEmpty()) { finished.run(); return; }
        worker.execute(() -> {
            List<Map.Entry<String, Intent>> targets = new ArrayList<>();
            for (String app : new java.util.TreeSet<>(selected)) {
                Intent intent = target(app);
                // SimpleEntry permits null for an app removed/changed since selection.
                targets.add(new java.util.AbstractMap.SimpleEntry<>(app, intent));
            }
            launches.post(() -> launchNext(targets, 0, token, foreground, finished));
        });
    }

    private void launchNext(List<Map.Entry<String, Intent>> targets, int index, int token,
            BooleanSupplier foreground, Runnable finished) {
        if (closed || token != generation || !foreground.getAsBoolean()) return;
        if (index == targets.size()) { finished.run(); return; }
        var target = targets.get(index);
        try {
            if (target.getValue() == null) throw new IllegalStateException("Unavailable target");
            activity.startActivity(target.getValue(), ActivityOptions.makeTaskLaunchBehind().toBundle());
            outcomes.put(target.getKey(), "requested");
        } catch (RuntimeException error) {
            outcomes.put(target.getKey(), "unavailable");
        }
        launches.postDelayed(() -> launchNext(targets, index + 1, token, foreground, finished), 350);
    }

    void cancel() { generation++; launches.removeCallbacksAndMessages(null); }
    void close() { closed = true; cancel(); worker.shutdown(); }
}
