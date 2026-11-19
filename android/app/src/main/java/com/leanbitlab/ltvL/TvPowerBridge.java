package com.leanbitlab.ltvL;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.os.PowerManager;
import java.io.File;
import java.io.IOException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.RejectedExecutionException;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.Consumer;
import dadb.AdbConnectionClosedException;
import dadb.AdbKeyPair;
import dadb.Dadb;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;

/** Explicit power requests; only fixed commands over the existing local ADB trust. */
final class TvPowerBridge {
    private static final AtomicBoolean busy = new AtomicBoolean();
    enum Operation {
        SLEEP, REBOOT, SHUTDOWN, TCL_SCREEN_OFF;

        static Operation fromMethod(String method) {
            return switch (method) {
                case "sleep" -> SLEEP;
                case "reboot" -> REBOOT;
                case "shutdown" -> SHUTDOWN;
                default -> null;
            };
        }
    }

    static void register(Context activity, BinaryMessenger messenger, ExecutorService worker) {
        Context c = activity.getApplicationContext();
        new MethodChannel(messenger, "cutelauncher/tv_power").setMethodCallHandler((call, result) -> {
            Operation operation = Operation.fromMethod(call.method);
            if (operation == null) {
                result.notImplemented(); return;
            }
            request(c, operation, worker, status -> {
                if (status.equals("success")) result.success(true);
                else result.error(status, "Power request " + status, null);
            });
        });
    }

    static void requestTclScreenOff(Context context, ExecutorService worker, Consumer<String> result) {
        request(context, Operation.TCL_SCREEN_OFF, worker, result);
    }

    /** Shared by settings and service-owned mappings. Callback runs on main. */
    static void request(Context context, Operation operation, ExecutorService worker, Consumer<String> result) {
        Context c = context.getApplicationContext();
        Handler main = new Handler(Looper.getMainLooper());
        if (!busy.compareAndSet(false, true)) { result.accept("busy"); return; }
        try {
            PowerManager power = c.getSystemService(PowerManager.class);
            if (operation == Operation.SLEEP && ((power != null && !power.isInteractive()) || LauncherAccessibilityService.sleep())) {
                busy.set(false); result.accept("success"); return;
            }
            worker.execute(() -> {
                boolean accepted = false;
                try { accepted = adb(c, operation); }
                catch (Exception | LinkageError failure) { NativeShellDiagnostics.failure("tvPower", failure); }
                final boolean sent = accepted;
                main.post(() -> {
                    busy.set(false);
                    result.accept(sent ? "success" : "unavailable");
                });
            });
        } catch (RejectedExecutionException failure) {
            busy.set(false); result.accept("busy");
        } catch (RuntimeException failure) {
            busy.set(false); result.accept("unavailable");
        }
    }

    private static boolean adb(Context c, Operation operation) throws Exception {
        File privateKey = new File(c.getNoBackupFilesDir(), "adb/private-key");
        File publicKey = new File(c.getNoBackupFilesDir(), "adb/public-key");
        if (!privateKey.exists() || !publicKey.exists()) throw new IllegalStateException("ADB keys unavailable");
        int port = c.getSharedPreferences("adb_connection", 0).getInt("port", 5555);
        int readTimeoutMs = operation == Operation.REBOOT ? 15000 : 3000;
        try (Dadb adb = Dadb.create("127.0.0.1", port, AdbKeyPair.read(privateKey, publicKey), 2000, readTimeoutMs)) {
            return switch (operation) {
                case REBOOT -> reboot(adb);
                // Detach shutdown so the shell can acknowledge dispatch before power-off.
                case SHUTDOWN -> shell(adb, "sh -c 'sleep 1; svc power shutdown' >/dev/null 2>&1 </dev/null &");
                case SLEEP -> shell(adb, "input keyevent KEYCODE_SLEEP");
                case TCL_SCREEN_OFF -> shell(adb, TclScreenOff.SHELL_COMMAND);
            };
        }
    }

    private static boolean shell(Dadb adb, String command) throws Exception {
        var user = NativeShellDiagnostics.execute(adb, "id -u", "tvPower");
        if (user.getExitCode() != 0 || !user.getOutput().trim().equals("2000")) return false;
        return NativeShellDiagnostics.execute(adb, command, "tvPower").getExitCode() == 0;
    }

    private static boolean reboot(Dadb adb) throws Exception {
        try (var stream = adb.open("reboot:")) {
            var source = stream.getSource();
            try {
                // adbd writes an error on refusal and otherwise waits for the transport to drop.
                if (source.request(1)) {
                    var reply = source.getBuffer();
                    throw new IOException("ADB reboot failed: " + reply.readUtf8(Math.min(256, reply.size())).trim());
                }
                throw new IOException("ADB reboot stream closed without a transport disconnect");
            } catch (AdbConnectionClosedException failure) {
                // Dadb can fail while acknowledging a received error packet.
                if (source.getBuffer().size() != 0) throw failure;
                return true;
            }
        }
    }
}
