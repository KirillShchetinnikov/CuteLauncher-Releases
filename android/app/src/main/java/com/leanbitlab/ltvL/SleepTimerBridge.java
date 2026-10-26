package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.PowerManager;
import android.os.SystemClock;
import android.provider.Settings;
import java.io.File;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import dadb.AdbKeyPair;
import dadb.Dadb;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;

/** One-shot elapsed-time alarm, independent of Flutter and the foreground app. */
final class SleepTimerBridge {
    private static SharedPreferences prefs(Context c) { return c.getSharedPreferences("sleep_timer", 0); }
    private static AlarmManager alarms(Context c) { return c.getSystemService(AlarmManager.class); }
    private static int boot(Context c) { return Settings.Global.getInt(c.getContentResolver(), Settings.Global.BOOT_COUNT, -1); }
    private static PendingIntent alarm(Context c, long deadline) {
        return PendingIntent.getBroadcast(c, 0,
            new Intent(c, SleepTimerReceiver.class).putExtra("deadline", deadline),
            PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
    }
    static synchronized void cancel(Context c) {
        alarms(c).cancel(alarm(c, 0));
        prefs(c).edit().clear().commit();
    }
    private static boolean exact(Context c) {
        return Build.VERSION.SDK_INT < 31 || alarms(c).canScheduleExactAlarms();
    }
    static synchronized Map<String, Object> state(Context c) {
        SharedPreferences p = prefs(c);
        if (p.getLong("deadline", 0) != 0 && p.getInt("boot", -2) != boot(c)) cancel(c);
        return Map.of("remainingMs", Math.max(0, p.getLong("deadline", 0) - SystemClock.elapsedRealtime()),
            "exactAllowed", exact(c), "error", p.getString("error", ""));
    }
    static void register(Context activity, BinaryMessenger messenger, ExecutorService executor) {
        Context c = activity.getApplicationContext();
        new MethodChannel(messenger, "cutelauncher/sleep_timer").setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "state" -> result.success(state(c));
                case "cancel" -> { cancel(c); result.success(state(c)); }
                case "requestExact" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= 31) activity.startActivity(new Intent(
                            Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:" + c.getPackageName())));
                        result.success(true);
                    } catch (RuntimeException e) { result.success(false); }
                }
                case "start", "startTest", "startDuration" -> {
                    boolean test = call.method.equals("startTest");
                    Object raw = call.argument(call.method.equals("startDuration") ? "seconds" : "minutes");
                    if (!test && !(raw instanceof Integer || raw instanceof Long)) {
                        result.error("INVALID", "Invalid duration", null); return;
                    }
                    long seconds = test ? 30L : ((Number) raw).longValue();
                    if (!test && call.method.equals("start")) {
                        if (seconds <= 0 || seconds > 3599999999L / 60) {
                            result.error("INVALID", "Invalid duration", null); return;
                        }
                        seconds *= 60;
                    }
                    if (!SleepTimerPolicy.validSeconds(seconds)) {
                        result.error("INVALID", "Invalid duration", null); return;
                    }
                    long delayMillis = seconds * 1000L;
                    executor.execute(() -> {
                        String error = "";
                        try {
                            if (!exact(c)) error = "exact";
                            else if (!LauncherAccessibilityService.canSleep() && !adb(c, 0)) error = "access";
                            if (error.isEmpty()) start(c, delayMillis);
                        } catch (Exception | LinkageError e) {
                            NativeShellDiagnostics.failure("sleepTimer", e);
                            error = "unavailable";
                        }
                        final String failure = error;
                        new Handler(Looper.getMainLooper()).post(() -> {
                            if (failure.isEmpty()) result.success(state(c));
                            else result.error(failure, "Sleep timer unavailable", null);
                        });
                    });
                }
                default -> result.notImplemented();
            }
        });
    }
    private static synchronized void start(Context c, long delayMillis) {
        long deadline = SystemClock.elapsedRealtime() + delayMillis;
        long old = prefs(c).getLong("deadline", 0);
        if (!prefs(c).edit().putLong("deadline", deadline).putInt("boot", boot(c)).remove("error").remove("firing").commit())
            throw new IllegalStateException("Cannot save timer");
        try { alarms(c).setExactAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, deadline, alarm(c, deadline)); }
        catch (RuntimeException e) {
            prefs(c).edit().putLong("deadline", old).commit();
            alarm(c, old); // Restore extras of the previous PendingIntent as well.
            throw e;
        }
    }
    static synchronized boolean claim(Context c, long deadline) {
        SharedPreferences p = prefs(c);
        if (!SleepTimerPolicy.due(p.getLong("deadline", 0), deadline,
                p.getInt("boot", -2), boot(c), SystemClock.elapsedRealtime())) return false;
        return p.edit().remove("deadline").putLong("firing", deadline).commit();
    }
    static void expire(Context c, long deadline, Runnable done) {
        new Handler(Looper.getMainLooper()).post(() -> {
            if (!claim(c, deadline)) { done.run(); return; }
            PowerManager power = c.getSystemService(PowerManager.class);
            if (!power.isInteractive() || LauncherAccessibilityService.sleep()) {
                finish(c, deadline, ""); done.run(); return;
            }
            // Only a fixed SLEEP key, never the POWER toggle which could wake a sleeping TV.
            Thread worker = new Thread(() -> {
                try {
                    finish(c, deadline, adb(c, deadline) ? "" : "access");
                } catch (Exception | LinkageError e) {
                    NativeShellDiagnostics.failure("sleepTimer", e);
                    finish(c, deadline, "unavailable");
                }
                finally { done.run(); }
            }, "SleepTimerPower");
            worker.start();
        });
    }
    private static synchronized void finish(Context c, long deadline, String error) {
        if (prefs(c).getLong("firing", 0) == deadline)
            prefs(c).edit().remove("firing").putString("error", error).commit();
    }
    private static boolean adb(Context c, long deadline) throws Exception {
        File privateKey = new File(c.getNoBackupFilesDir(), "adb/private-key");
        File publicKey = new File(c.getNoBackupFilesDir(), "adb/public-key");
        if (!privateKey.exists() || !publicKey.exists()) throw new IllegalStateException("ADB keys unavailable");
        int port = c.getSharedPreferences("adb_connection", 0).getInt("port", 5555);
        try (Dadb adb = Dadb.create("127.0.0.1", port, AdbKeyPair.read(privateKey, publicKey), 2000, 3000)) {
            var user = NativeShellDiagnostics.execute(adb, "id -u", "sleepTimer");
            if (user.getExitCode() != 0 || !user.getOutput().trim().equals("2000")) return false;
            if (deadline == 0) return true;
            if (prefs(c).getLong("firing", 0) != deadline) return true;
            return NativeShellDiagnostics.execute(adb, "input keyevent KEYCODE_SLEEP", "sleepTimer").getExitCode() == 0;
        }
    }
}
