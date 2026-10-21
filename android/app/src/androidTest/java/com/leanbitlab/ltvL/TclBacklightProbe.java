package com.leanbitlab.ltvL;

import android.app.Instrumentation;
import android.content.Intent;
import android.os.Bundle;

/** Executes the application's brightness path and restores the physical panel in finally. */
public final class TclBacklightProbe extends Instrumentation {
    private Bundle arguments;
    @Override public void onCreate(Bundle args) { super.onCreate(args); arguments = args; start(); }
    @Override public void onStart() {
        Bundle report = new Bundle();
        TclBacklight panel = null;
        int original = -1;
        boolean passed = false;
        try {
            panel = new TclBacklight();
            original = panel.read();
            var context = getTargetContext();
            var state = context.getSharedPreferences("brightness_restore", android.content.Context.MODE_PRIVATE);
            if (!state.getAll().isEmpty()) throw new AssertionError("Existing scheduler baseline: stop test to preserve it");
            Intent intent = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            MainActivity activity = (MainActivity) startActivitySync(intent);
            var apply = MainActivity.class.getDeclaredMethod(arguments.getString("applyName", "setSystemBrightness"), int.class);
            var restore = MainActivity.class.getDeclaredMethod(arguments.getString("restoreName", "restoreSystemBrightness"));
            apply.setAccessible(true); restore.setAccessible(true);
            for (int level : new int[]{30, 75}) {
                if (!Boolean.TRUE.equals(apply.invoke(activity, Math.round(level * 255f / 100))))
                    throw new AssertionError("Application write failed");
                if (panel.read() != level) throw new AssertionError("Panel unchanged");
            }
            if (!Boolean.TRUE.equals(restore.invoke(activity)) || panel.read() != original)
                throw new AssertionError("Application restoration failed");
            if (!state.getAll().isEmpty()) throw new AssertionError("Baseline not cleared");
            report.putString("stream", "\nPASS panel " + original + " -> 30 -> 75 -> " + original + "; application brightness path and restoration\n");
            passed = true;
        } catch (Throwable error) { report.putString("stream", "\nFAIL " + error + "\n"); }
        finally {
            if (panel != null && original >= 0) {
                try { panel.write(original); }
                catch (Exception error) { passed = false; report.putString("stream", "\nFAIL final panel restore: " + error + "\n"); }
            }
        }
        finish(passed ? -1 : 0, report);
    }
}
