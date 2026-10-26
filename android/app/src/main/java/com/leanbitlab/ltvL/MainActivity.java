package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

/** HOME entry point. The recovery UI never constructs a Flutter engine. */
public class MainActivity extends Activity {
    static final RemotePanelLaunchPolicy remotePanelPolicy = LauncherActivity.remotePanelPolicy;
    static void panelClosed() { LauncherActivity.panelClosed(); }
    static void panelBlocked() { LauncherActivity.panelBlocked(); }
    private final java.util.concurrent.ExecutorService worker = java.util.concurrent.Executors.newSingleThreadExecutor();
    private boolean checking;
    private TextView cleanerStatus;
    private Button retryLauncher, retryCleaner;
    @Override public void onCreate(Bundle state) { super.onCreate(state); check(); }
    @Override public void onNewIntent(Intent intent) { super.onNewIntent(intent); setIntent(intent); check(); }
    @Override protected void onStart() { super.onStart(); remotePanelPolicy.started(this); }
    @Override protected void onStop() { remotePanelPolicy.stopped(this); super.onStop(); }
    @Override protected void onDestroy() { worker.shutdown(); super.onDestroy(); }
    private void check() {
        if (checking) return;
        Boolean blocked = CrashLoopGuard.inspectedState();
        if (blocked != null) {
            if (blocked) recovery(); else launch();
            return;
        }
        checking = true;
        worker.execute(() -> {
            boolean recoveryRequired = CrashLoopGuard.inspect(this);
            runOnUiThread(() -> {
                checking = false;
                if (isFinishing() || isDestroyed()) return;
                if (recoveryRequired) recovery(); else launch();
            });
        });
    }
    private void launch() {
        Intent next = new Intent(getIntent()).setClass(this, LauncherActivity.class);
        next.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        startActivity(next); finish();
    }
    private void recovery() {
        ScrollView scroll = new ScrollView(this);
        scroll.setBackgroundColor(0xff10151e);
        LinearLayout body = new LinearLayout(this); body.setOrientation(LinearLayout.VERTICAL);
        int pad = (int)(32 * getResources().getDisplayMetrics().density); body.setPadding(pad,pad,pad,pad);
        body.setBackgroundColor(0xff10151e); scroll.addView(body);
        TextView title = new TextView(this); title.setText(R.string.recovery_title); title.setTextSize(26); title.setTextColor(-1); body.addView(title);
        TextView text = new TextView(this); text.setText(R.string.recovery_description); text.setTextColor(-1); text.setTextSize(18); body.addView(text);
        cleanerStatus = new TextView(this); cleanerStatus.setTextColor(-1); cleanerStatus.setTextSize(18); body.addView(cleanerStatus);
        Button retry = button(body, getString(R.string.recovery_retry), () -> worker.execute(() -> {
            CrashLoopGuard.retry(this); runOnUiThread(() -> { if (!isDestroyed()) launch(); });
        }));
        retryLauncher = retry;
        retryCleaner = button(body, getString(R.string.recovery_cleaner_retry), () -> restoreCleaner(false));
        button(body, getString(R.string.recovery_restore), () -> new android.app.AlertDialog.Builder(this)
            .setMessage(R.string.recovery_restore_confirm)
            .setNegativeButton(android.R.string.cancel, null)
            .setPositiveButton(android.R.string.ok, (dialog, which) -> worker.execute(() -> {
                boolean restored = AdbBridge.restoreFromRecovery(this);
                runOnUiThread(() -> {
                    if (isDestroyed()) return;
                    if (restored) { open(new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)); finish(); }
                    else android.widget.Toast.makeText(this, R.string.recovery_unavailable, android.widget.Toast.LENGTH_LONG).show();
                });
            })).show());
        button(body, getString(R.string.recovery_settings), () -> open(new Intent(android.provider.Settings.ACTION_SETTINGS)));
        button(body, getString(R.string.recovery_home), () -> open(new Intent(android.provider.Settings.ACTION_HOME_SETTINGS)));
        var pm = getPackageManager();
        var apps = pm.queryIntentActivities(new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LEANBACK_LAUNCHER), 0);
        apps.sort(java.util.Comparator.comparing(a -> a.loadLabel(pm).toString(), String.CASE_INSENSITIVE_ORDER));
        for (var app : apps) if (!getPackageName().equals(app.activityInfo.packageName)) {
            button(body, app.loadLabel(pm).toString(), () -> open(new Intent(Intent.ACTION_MAIN)
                .setComponent(new android.content.ComponentName(app.activityInfo.packageName, app.activityInfo.name))));
        }
        setContentView(scroll); retry.requestFocus();
        restoreCleaner(true);
    }
    private void restoreCleaner(boolean automatic) {
        retryLauncher.setEnabled(false); retryCleaner.setEnabled(false);
        cleanerStatus.setText(R.string.recovery_cleaner_running);
        worker.execute(() -> {
            String status;
            if (!automatic || CrashLoopGuard.claimCleanerRestore(this)) {
                if (!automatic) CrashLoopGuard.cleanerRestoreFinished(this, "running");
                status = AdbBridge.restoreCleanerFromRecovery(this);
                CrashLoopGuard.cleanerRestoreFinished(this, status);
            } else status = CrashLoopGuard.cleanerRestoreStatus(this);
            final String result = status;
            runOnUiThread(() -> {
                if (isFinishing() || isDestroyed()) return;
                cleanerStatus.setText("success".equals(result) ? R.string.recovery_cleaner_done
                    : "noSnapshot".equals(result) ? R.string.recovery_cleaner_no_baseline
                    : "partial".equals(result) ? R.string.recovery_cleaner_partial : R.string.recovery_cleaner_failed);
                retryLauncher.setEnabled(true); retryCleaner.setEnabled(true);
                if (getCurrentFocus() == null) retryLauncher.requestFocus();
            });
        });
    }
    private Button button(LinearLayout body, String text, Runnable action) {
        Button b = new Button(this); b.setText(text); b.setOnClickListener(v -> action.run()); body.addView(b); return b;
    }
    private void open(Intent intent) {
        try { startActivity(intent); }
        catch (RuntimeException e) { android.widget.Toast.makeText(this, R.string.recovery_unavailable, android.widget.Toast.LENGTH_LONG).show(); }
    }
    @Override public void onBackPressed() { /* HOME recovery stays available until explicit retry or app launch. */ }
}
