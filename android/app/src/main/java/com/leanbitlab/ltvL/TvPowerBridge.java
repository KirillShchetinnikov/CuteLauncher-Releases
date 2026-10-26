package com.leanbitlab.ltvL;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.os.PowerManager;
import java.io.File;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.atomic.AtomicBoolean;
import dadb.AdbKeyPair;
import dadb.Dadb;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;

/** Explicit power requests; only fixed commands over the existing local ADB trust. */
final class TvPowerBridge {
    static void register(Context activity, BinaryMessenger messenger, ExecutorService worker) {
        Context c = activity.getApplicationContext();
        Handler main = new Handler(Looper.getMainLooper());
        AtomicBoolean busy = new AtomicBoolean();
        new MethodChannel(messenger, "cutelauncher/tv_power").setMethodCallHandler((call, result) -> {
            if (!call.method.equals("sleep") && !call.method.equals("reboot")) {
                result.notImplemented(); return;
            }
            if (!busy.compareAndSet(false, true)) {
                result.error("busy", "Power request in progress", null); return;
            }
            if (call.method.equals("sleep") &&
                    (!c.getSystemService(PowerManager.class).isInteractive() || LauncherAccessibilityService.sleep())) {
                busy.set(false); result.success(true); return;
            }
            worker.execute(() -> {
                boolean accepted = false;
                try { accepted = adb(c, call.method.equals("reboot")); }
                catch (Exception | LinkageError failure) { NativeShellDiagnostics.failure("tvPower", failure); }
                final boolean sent = accepted;
                main.post(() -> {
                    busy.set(false);
                    if (sent) result.success(true);
                    else result.error("unavailable", "Power request unavailable", null);
                });
            });
        });
    }

    private static boolean adb(Context c, boolean reboot) throws Exception {
        File privateKey = new File(c.getNoBackupFilesDir(), "adb/private-key");
        File publicKey = new File(c.getNoBackupFilesDir(), "adb/public-key");
        if (!privateKey.exists() || !publicKey.exists()) throw new IllegalStateException("ADB keys unavailable");
        int port = c.getSharedPreferences("adb_connection", 0).getInt("port", 5555);
        try (Dadb adb = Dadb.create("127.0.0.1", port, AdbKeyPair.read(privateKey, publicKey), 2000, 3000)) {
            var user = NativeShellDiagnostics.execute(adb, "id -u", "tvPower");
            if (user.getExitCode() != 0 || !user.getOutput().trim().equals("2000")) return false;
            // Detach the delayed reboot so the shell can acknowledge before ADB disconnects.
            String command = reboot
                ? "sh -c 'sleep 1; svc power reboot' >/dev/null 2>&1 </dev/null &"
                : "input keyevent KEYCODE_SLEEP";
            return NativeShellDiagnostics.execute(adb, command, "tvPower").getExitCode() == 0;
        }
    }
}
