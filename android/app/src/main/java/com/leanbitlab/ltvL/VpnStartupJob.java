package com.leanbitlab.ltvL;

import android.app.job.JobInfo;
import android.app.job.JobParameters;
import android.app.job.JobScheduler;
import android.app.job.JobService;
import android.content.ComponentName;
import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/** One startup attempt, constrained to a network, with no persistent service or retry loop. */
public final class VpnStartupJob extends JobService {
    private static final int ID = 6422;
    private final Handler main = new Handler(Looper.getMainLooper());
    private ExecutorService worker;
    private volatile int generation;
    static void cancel(Context context) {
        context.getSharedPreferences(VpnController.PREFS, MODE_PRIVATE).edit().remove("startupAttempt").apply();
        var scheduler = context.getSystemService(JobScheduler.class);
        if (scheduler != null) scheduler.cancel(ID);
    }
    static void schedule(Context context, boolean wake) {
        var prefs = context.getSharedPreferences(VpnController.PREFS, MODE_PRIVATE);
        String app = prefs.getString("bootApp", "");
        boolean systemMode = prefs.getString("bootMode", "client").equals("alwaysOn");
        // Some OEMs retain the system selection without starting a third-party tunnel.
        // Named-tunnel clients have an explicit, bounded fallback; never open a confirmation UI at boot.
        if (!prefs.getBoolean("bootEnabled", !app.isEmpty()) || (systemMode && (wake || !VpnPolicy.requiresProfile(app))) || app.isEmpty()
                || wake && !prefs.getBoolean("wake", false)) return;
        var scheduler = context.getSystemService(JobScheduler.class);
        if (scheduler == null) return;
        int delay = Math.max(0, Math.min(60, prefs.getInt("delay", 5)));
        var extras = new android.os.PersistableBundle(); extras.putBoolean("wake", wake);
        long attempt = android.os.SystemClock.elapsedRealtimeNanos();
        extras.putLong("attempt", attempt);
        var job = new JobInfo.Builder(ID, new ComponentName(context, VpnStartupJob.class))
            .setExtras(extras)
            .setRequiredNetworkType(JobInfo.NETWORK_TYPE_ANY)
            .setMinimumLatency(delay * 1000L).setOverrideDeadline((delay + 60) * 1000L).build();
        prefs.edit().putLong("startupAttempt", attempt).putString("startupStatus", "pending").apply();
        boolean ok = scheduler.schedule(job) == JobScheduler.RESULT_SUCCESS;
        if (!ok && prefs.getLong("startupAttempt", 0) == attempt)
            prefs.edit().putString("startupStatus", "failed").apply();
    }
    @Override public boolean onStartJob(JobParameters params) {
        int request = ++generation;
        worker = Executors.newSingleThreadExecutor();
        worker.execute(() -> {
            var vpn = new VpnController(getApplicationContext());
            String status = "failed";
            String detail = "starting";
            String app = vpn.prefs.getString("bootApp", "");
            String mode = vpn.prefs.getString("bootMode", "client");
            long attempt = params.getExtras().getLong("attempt", 0);
            java.util.function.BooleanSupplier valid = () -> generation == request
                && vpn.prefs.getLong("startupAttempt", 0) == attempt
                && vpn.prefs.getBoolean("bootEnabled", !app.isEmpty())
                && app.equals(vpn.prefs.getString("bootApp", ""))
                && mode.equals(vpn.prefs.getString("bootMode", "client"));
            try {
                if (app.isEmpty() || !vpn.prefs.getBoolean("bootEnabled", !app.isEmpty())) status = "idle";
                else if (params.getNetwork() == null) status = "network";
                else {
                    String profile = vpn.prefs.getString("profile_" + app, "");
                    status = vpn.command(app, profile, true, valid);
                    detail = status;
                    if (status.equals("sent")) {
                        status = "failed";
                        // Bounded confirmation; Android's VPN state, not broadcast delivery, is the result.
                        for (int i = 0; i < 30 && generation == request; i++) {
                            Thread.sleep(500);
                            if (vpn.active()) {
                                var actual = vpn.owner();
                                status = app.equals(actual.app()) && (!VpnPolicy.requiresProfile(app) || profile.equals(actual.profile())) ? "connected" : "other";
                                break;
                            }
                        }
                    }
                    if (status.equals("failed") && detail.equals("sent") && generation == request
                            && !params.getExtras().getBoolean("wake", false)
                            && android.os.Build.MANUFACTURER.equalsIgnoreCase("TCL") && VpnPolicy.requiresProfile(app)) {
                        var session = VpnStartupRecovery.begin(getApplicationContext(), app, valid);
                        try {
                            detail = "clientInitialization";
                            for (int i = 0; i < 30 && generation == request; i++) {
                                Thread.sleep(500);
                                if (vpn.active()) {
                                    var actual = vpn.owner();
                                    status = app.equals(actual.app()) && profile.equals(actual.profile()) ? "connected" : "other";
                                    break;
                                }
                                if (i == 9) vpn.command(app, profile, true, valid);
                            }
                        } finally {
                            try { VpnStartupRecovery.restore(getApplicationContext(), session); }
                            catch (Exception unavailable) { detail += ":returnUnavailable"; }
                        }
                    }
                }
            } catch (Exception unavailable) { status = "failed"; detail = unavailable.getClass().getSimpleName(); }
            if (generation != request) return;
            if (valid.getAsBoolean())
                vpn.prefs.edit().putString("startupStatus", status).putString("startupDetail", detail).apply();
            main.post(() -> { if (generation == request) { worker.shutdown(); jobFinished(params, false); } });
        });
        return true;
    }
    @Override public boolean onStopJob(JobParameters params) {
        generation++; if (worker != null) worker.shutdownNow();
        recordStop(getSharedPreferences(VpnController.PREFS, MODE_PRIVATE),
            params == null ? 0 : params.getExtras().getLong("attempt", 0));
        return false;
    }
    static void recordStop(android.content.SharedPreferences prefs, long attempt) {
        if (attempt != 0 && prefs.getLong("startupAttempt", 0) == attempt
                && prefs.getString("startupStatus", "idle").equals("pending"))
            prefs.edit().putString("startupStatus", "failed").apply();
    }
    @Override public void onDestroy() {
        generation++; if (worker != null) worker.shutdownNow();
        main.removeCallbacksAndMessages(null); super.onDestroy();
    }
}
