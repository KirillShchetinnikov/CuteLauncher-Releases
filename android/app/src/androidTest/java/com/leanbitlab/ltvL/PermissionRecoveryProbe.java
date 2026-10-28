package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.Instrumentation;
import android.os.Build;
import android.os.Bundle;
import org.json.JSONArray;
import org.json.JSONObject;
import java.util.Set;

/** TCL .73 port fixture; instrumentation force-stops the target, so never inspect a healthy live service. */
public final class PermissionRecoveryProbe extends Instrumentation {
    private Bundle arguments;
    @Override public void onCreate(Bundle args) { super.onCreate(args); arguments = args; start(); }
    @Override public void onStart() {
        Bundle result = new Bundle();
        try {
            if (!"192.168.1.73".equals(arguments.getString("authorizedTv"))
                    || !"TCL".equalsIgnoreCase(Build.MANUFACTURER) || !"Smart TV Pro".equals(Build.MODEL))
                throw new IllegalStateException("Explicit authorized TV fixture required");
            var context = getTargetContext();
            var connection = context.getSharedPreferences("adb_connection", 0);
            var backup = context.getSharedPreferences("permission_recovery_probe", 0);
            String phase = arguments.getString("phase", "inspect");
            if (phase.equals("block")) {
                if (backup.getBoolean("saved", false)) throw new IllegalStateException("Restore earlier fixture first");
                if (!backup.edit().putBoolean("saved", true).putBoolean("had_port", connection.contains("port"))
                        .putInt("port", connection.getInt("port", 5555)).commit()) throw new IllegalStateException("Backup failed");
                if (!connection.edit().putInt("port", 5556).commit()) throw new IllegalStateException("Port change failed");
            } else if (phase.equals("restore")) {
                if (!backup.getBoolean("saved", false)) throw new IllegalStateException("No fixture backup");
                var editor = connection.edit();
                if (backup.getBoolean("had_port", false)) editor.putInt("port", backup.getInt("port", 5555));
                else editor.remove("port");
                if (!editor.commit()) throw new IllegalStateException("Restore failed");
                backup.edit().clear().commit();
            } else if (!phase.equals("inspect")) throw new IllegalArgumentException("Invalid phase");
            JSONObject report = new JSONObject();
            var state = context.getSharedPreferences("update_permissions", 0);
            for (String key : Set.of("installation", "granted", "pending", "status", "attempts", "deadline", "retry_at",
                    "health_status", "health_retry_at", "disconnected_since", "health_attempts", "last_checked")) {
                Object value = state.getAll().get(key);
                report.put(key, value instanceof Set<?> values ? new JSONArray(values) : value == null ? JSONObject.NULL : value);
            }
            report.put("port", connection.getInt("port", 5555));
            report.put("versionCode", context.getPackageManager().getPackageInfo(context.getPackageName(), 0).getLongVersionCode());
            result.putString("stream", "\nPASS " + phase + " " + report + "\n");
            finish(Activity.RESULT_OK, result);
        } catch (Throwable error) {
            result.putString("stream", "\nFAIL permission fixture: " + error.getClass().getSimpleName() + "\n");
            finish(Activity.RESULT_CANCELED, result);
        }
    }
}
