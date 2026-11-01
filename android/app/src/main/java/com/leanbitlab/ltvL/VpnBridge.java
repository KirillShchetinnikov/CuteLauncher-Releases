package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.os.Handler;
import android.os.Looper;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import java.util.concurrent.ExecutorService;

/** Engine-scoped adapter; reuses the existing worker pool and releases all listeners. */
final class VpnBridge implements AutoCloseable {
    private final Context context;
    private final ExecutorService worker;
    private final MethodChannel channel;
    private final Handler main = new Handler(Looper.getMainLooper());
    private final SharedPreferences prefs;
    private final SharedPreferences.OnSharedPreferenceChangeListener listener;
    private boolean closed, listening, screenOff;
    private final BroadcastReceiver screen = new BroadcastReceiver() {
        @Override public void onReceive(Context unused, Intent intent) {
            if (Intent.ACTION_SCREEN_OFF.equals(intent.getAction())) screenOff = true;
            else if (Intent.ACTION_SCREEN_ON.equals(intent.getAction()) && screenOff) {
                screenOff = false;
                VpnStartupJob.schedule(context, true);
            }
        }
    };
    VpnBridge(Context context, BinaryMessenger messenger, ExecutorService worker) {
        this.context = context; this.worker = worker;
        prefs = context.getSharedPreferences(VpnController.PREFS, Context.MODE_PRIVATE);
        listener = (saved, key) -> {
            if ("wake".equals(key) || "bootApp".equals(key) || "bootMode".equals(key) || "bootEnabled".equals(key)) main.post(this::listen);
        };
        if (context instanceof Activity) { prefs.registerOnSharedPreferenceChangeListener(listener); listen(); }
        channel = new MethodChannel(messenger, "cutelauncher/vpn");
        channel.setMethodCallHandler((call, result) -> {
            if (call.method.equals("permission")) {
                String app = call.argument("app");
                if (!(context instanceof Activity activity) || !VpnPolicy.requiresProfile(app)) { result.success(false); return; }
                activity.requestPermissions(new String[]{VpnController.permission(app)}, 6421);
                result.success(true); return;
            }
            worker.execute(() -> {
                try {
                    var vpn = new VpnController(context);
                    Object value = switch (call.method) {
                        case "snapshot" -> vpn.snapshot(!Boolean.FALSE.equals(call.argument("identify")));
                        case "save" -> vpn.save(call.arguments());
                        case "command" -> vpn.command(call.argument("app"), call.argument("profile"), Boolean.TRUE.equals(call.argument("up")));
                        // Opening an Activity must happen on the main thread (and dismiss the overlay).
                        case "open" -> null;
                        default -> throw new IllegalArgumentException("Unsupported VPN operation");
                    };
                    main.post(() -> {
                        if (closed) return;
                        try { result.success(call.method.equals("open") ? vpn.open(call.argument("app")) : value); }
                        catch (RuntimeException unavailable) { result.error("unavailable", "VPN unavailable", null); }
                    });
                } catch (Exception unavailable) {
                    main.post(() -> { if (!closed) result.error("unavailable", "VPN unavailable", null); });
                }
            });
        });
    }
    private void listen() {
        if (closed) return;
        boolean needed = prefs.getBoolean("bootEnabled", !prefs.getString("bootApp", "").isEmpty()) && prefs.getString("bootMode", "client").equals("client")
            && prefs.getBoolean("wake", false) && !prefs.getString("bootApp", "").isEmpty();
        if (needed && !listening) {
            var filter = new IntentFilter(Intent.ACTION_SCREEN_OFF); filter.addAction(Intent.ACTION_SCREEN_ON);
            if (android.os.Build.VERSION.SDK_INT >= 33) context.registerReceiver(screen, filter, Context.RECEIVER_NOT_EXPORTED);
            else context.registerReceiver(screen, filter);
            listening = true;
        } else if (!needed && listening) { context.unregisterReceiver(screen); listening = false; screenOff = false; }
    }
    @Override public void close() {
        closed = true; channel.setMethodCallHandler(null);
        prefs.unregisterOnSharedPreferenceChangeListener(listener);
        if (listening) context.unregisterReceiver(screen);
        main.removeCallbacksAndMessages(null);
    }
}
