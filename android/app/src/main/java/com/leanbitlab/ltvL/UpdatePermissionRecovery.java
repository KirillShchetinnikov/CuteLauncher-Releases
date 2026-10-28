package com.leanbitlab.ltvL;

import android.app.NotificationManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.SharedPreferences;
import android.provider.Settings;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

/** Durable, bounded recovery; a failed transport never consumes earlier consent. */
final class UpdatePermissionRecovery {
    private static long checkedInstallation = -1;
    interface Session extends AutoCloseable {
        String restore(String action, boolean requireEnabled) throws Exception;
        @Override void close() throws Exception;
    }
    interface Access {
        Set<String> granted();
        boolean accessibilityEnabled();
        boolean connected();
        boolean supported(String action);
        Session open() throws Exception;
    }
    static SharedPreferences saved(Context c) { return c.getSharedPreferences("update_permissions", 0); }
    private static long installation(Context c) throws Exception {
        return c.getPackageManager().getPackageInfo(c.getPackageName(), 0).lastUpdateTime;
    }
    static boolean accessibility(Context c) {
        if (Settings.Secure.getInt(c.getContentResolver(), Settings.Secure.ACCESSIBILITY_ENABLED, 0) != 1) return false;
        String value = Settings.Secure.getString(c.getContentResolver(), Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES);
        ComponentName own = new ComponentName(c, LauncherAccessibilityService.class);
        if (value != null) for (String item : value.split(":"))
            if (own.equals(ComponentName.unflattenFromString(item))) return true;
        return false;
    }
    static Set<String> granted(Context c) {
        Set<String> result = new HashSet<>();
        if (accessibility(c)) result.add("accessibility");
        if (c.getSystemService(NotificationManager.class).isNotificationListenerAccessGranted(new ComponentName(c, LauncherNotificationListenerService.class))) result.add("notifications");
        if (OverlayPermission.granted(c)) result.add("overlay");
        if (new NetworkStatistics(c).checkUsageStatsPermission()) result.add("usage");
        if (Settings.System.canWrite(c)) result.add("writeSettings");
        if (new WatchNextBridge(c).checkWatchNextPermission()) result.add("watchNext");
        return result;
    }
    private static Set<String> read(SharedPreferences p, String key) { return new HashSet<>(p.getStringSet(key, Set.of())); }
    private static void status(SharedPreferences p, String key, String value, long now) {
        boolean changed = !value.equals(p.getString(key, ""));
        p.edit().putString(key, value).putLong("last_checked", now).commit();
        if (changed) android.util.Log.i("CuteLauncherUpdate", key + ": " + value);
    }
    private static String failure(Throwable error) {
        if (error instanceof PermissionRecoveryAccess.Unavailable unavailable) return unavailable.reason;
        if (error instanceof dadb.AdbAuthException) return "adb_authorization";
        return "adb_unavailable";
    }
    private static boolean complete(String action, Set<String> actual, Access access) {
        return actual.contains(action) && (!action.equals("accessibility") || access.connected());
    }
    private static void reconcile(SharedPreferences p, Set<String> pending, Set<String> actual, Access access) {
        Set<String> observed = read(p, "observed_grants");
        pending.removeIf(action -> observed.contains(action) && !actual.contains(action) || complete(action, actual, access));
        observed.addAll(actual); observed.retainAll(pending);
        p.edit().putStringSet("pending", pending).putStringSet("observed_grants", observed).putStringSet("granted", actual).commit();
    }
    // Never overwrite the old version's baseline or discard an outstanding retry.
    static void snapshot(Context c) {
        synchronized (AdbBridge.LOCK) {
            try {
                var p = saved(c); long current = installation(c);
                if (UpdatePermissionPolicy.replaced(p.getLong("installation", 0), current)) return;
                Access access = new PermissionRecoveryAccess(c);
                reconcile(p, read(p, "pending"), access.granted(), access);
                p.edit().putLong("installation", current).commit();
            } catch (Exception error) { android.util.Log.w("CuteLauncherUpdate", "Snapshot failed: " + error.getClass().getSimpleName()); }
        }
    }
    static void afterUpdate(Context c) {
        synchronized (AdbBridge.LOCK) {
            try {
                long current = installation(c); var p = saved(c);
                if (checkedInstallation == current && read(p, "pending").isEmpty()) return;
                if (UpdatePermissionPolicy.replaced(p.getLong("installation", 0), current)
                        && read(p, "granted").contains("notifications") && granted(c).contains("notifications")) {
                    android.service.notification.NotificationListenerService.requestRebind(new ComponentName(c, LauncherNotificationListenerService.class));
                }
                recover(c, current, System.currentTimeMillis(), new PermissionRecoveryAccess(c));
                checkedInstallation = current;
            } catch (Exception | LinkageError error) { status(saved(c), "status", "check_unavailable", System.currentTimeMillis()); }
        }
    }
    static void recover(Context c, long current, long now, Access access) {
        synchronized (AdbBridge.LOCK) {
            var p = saved(c); long previous = p.getLong("installation", 0);
            Set<String> actual = access.granted(), pending = read(p, "pending");
            if (previous != current) {
                Set<String> baseline = read(p, "granted");
                if (p.getLong("deadline", 0) > now) {
                    Set<String> inherited = new HashSet<>(pending);
                    Set<String> observed = read(p, "observed_grants");
                    for (String action : observed) if (!actual.contains(action)) inherited.remove(action);
                    baseline.addAll(inherited);
                }
                pending = previous > 0 ? UpdatePermissionPolicy.missing(baseline, actual, access.connected()) : new HashSet<>();
                if (!p.edit().putLong("installation", current).putStringSet("pending", pending).putStringSet("observed_grants", Set.of())
                        .putStringSet("granted", actual).putInt("attempts", 0).putLong("deadline", now + UpdatePermissionPolicy.RECOVERY_WINDOW_MS).putLong("retry_at", now).commit()) return;
            }
            if (pending.isEmpty()) { p.edit().putStringSet("granted", actual).commit(); status(p, "status", "healthy", now); return; }
            reconcile(p, pending, actual, access);
            if (pending.isEmpty()) { status(p, "status", "resolved_or_revoked", now); return; }
            int attempts = p.getInt("attempts", 0);
            if (now >= p.getLong("deadline", 0) || attempts >= UpdatePermissionPolicy.MAX_ATTEMPTS) {
                p.edit().putStringSet("last_missing", pending).putStringSet("pending", Set.of()).commit(); status(p, "status", "expired", now); return;
            }
            if (now < p.getLong("retry_at", 0)) return;
            attempts++;
            if (!p.edit().putInt("attempts", attempts).putLong("retry_at", now + UpdatePermissionPolicy.retryDelay(attempts)).commit()) return;
            String outcome = "retry_pending";
            try (Session session = access.open()) {
                for (String action : Set.copyOf(pending)) {
                    if (!access.supported(action)) { pending.remove(action); continue; }
                    actual = access.granted();
                    if (read(p, "observed_grants").contains(action) && !actual.contains(action)) { pending.remove(action); continue; }
                    if (!complete(action, actual, access)) session.restore(action, false);
                }
            } catch (Exception | LinkageError error) {
                outcome = failure(error);
            }
            reconcile(p, pending, access.granted(), access);
            if (pending.isEmpty()) outcome = "restored_or_revoked";
            else if (attempts >= UpdatePermissionPolicy.MAX_ATTEMPTS) {
                p.edit().putStringSet("last_missing", pending).putStringSet("pending", Set.of()).commit(); outcome = "exhausted";
            }
            status(p, "status", outcome, now);
        }
    }
    static void cancelAccessibility(Context c) {
        synchronized (AdbBridge.LOCK) {
            var p = saved(c); var pending = read(p, "pending"); pending.remove("accessibility");
            var observed = read(p, "observed_grants"); observed.remove("accessibility");
            var grants = read(p, "granted"); grants.remove("accessibility");
            p.edit().putStringSet("pending", pending).putStringSet("observed_grants", observed)
                    .putStringSet("granted", grants)
                    .remove("disconnected_since").remove("health_retry_at").putInt("health_attempts", 0).commit();
            status(p, "health_status", "manual_disable", System.currentTimeMillis());
        }
    }
    // Background checks may rebind an enabled service, never grant a disabled permission.
    static void health(Context c, long now, Access access) {
        synchronized (AdbBridge.LOCK) {
            var p = saved(c); if (read(p, "pending").contains("accessibility")) return;
            boolean enabled = access.accessibilityEnabled(); var grants = read(p, "granted");
            if (enabled) grants.add("accessibility"); else grants.remove("accessibility");
            p.edit().putStringSet("granted", grants).commit();
            if (!enabled || access.connected()) {
                p.edit().remove("disconnected_since").remove("health_retry_at").putInt("health_attempts", 0).commit();
                status(p, "health_status", enabled ? "connected" : "disabled", now); return;
            }
            if (!p.contains("disconnected_since")) {
                p.edit().putLong("disconnected_since", now).putLong("health_retry_at", now + 30_000L).commit();
                status(p, "health_status", "binding_grace", now); return;
            }
            if (now < p.getLong("health_retry_at", 0)) return;
            int attempt = p.getInt("health_attempts", 0) + 1;
            p.edit().putInt("health_attempts", attempt >= 3 ? 0 : attempt)
                    .putLong("health_retry_at", now + (attempt >= 3 ? 3_600_000L : attempt * 60_000L)).commit();
            if (!access.accessibilityEnabled() || access.connected()) return;
            try (Session session = access.open()) {
                if (access.accessibilityEnabled() && !access.connected()) session.restore("accessibility", true);
                status(p, "health_status", access.connected() ? "reconnected" : "awaiting_connection", now);
            } catch (Exception | LinkageError error) {
                status(p, "health_status", failure(error), now);
            }
        }
    }
    static long nextCheck(Context c) {
        var p = saved(c); long update = read(p, "pending").isEmpty() ? 0 : p.getLong("retry_at", 0), health = p.getLong("health_retry_at", 0);
        return update == 0 ? health : health == 0 ? update : Math.min(update, health);
    }
    static Map<String, Object> report(Context c) {
        var p = saved(c);
        var pending = read(p, "pending");
        return Map.of("status", p.getString("status", "not_checked"), "pending", new java.util.ArrayList<>(pending),
                "attempts", p.getInt("attempts", 0), "retryAt", pending.isEmpty() ? 0L : p.getLong("retry_at", 0),
                "deadline", pending.isEmpty() ? 0L : p.getLong("deadline", 0), "lastChecked", p.getLong("last_checked", 0),
                "health", pending.contains("accessibility") ? "update_recovery_pending" : p.getString("health_status", "not_checked"),
                "healthRetryAt", p.getLong("health_retry_at", 0));
    }
}
