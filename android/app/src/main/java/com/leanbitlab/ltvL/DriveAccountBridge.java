package com.leanbitlab.ltvL;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import java.io.File;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.Executor;
import java.util.concurrent.atomic.AtomicLong;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import org.json.JSONObject;

/** Separate encrypted account/key from WebDAV. Never part of portable backups. */
final class DriveAccountBridge {
    static void register(Context context, BinaryMessenger messenger, Executor executor) {
        register(context, messenger, executor, false);
        register(context, messenger, executor, true);
    }
    private static void register(Context context, BinaryMessenger messenger, Executor executor, boolean yandex) {
        java.util.concurrent.ConcurrentHashMap<String, AtomicLong> revisions = new java.util.concurrent.ConcurrentHashMap<>();
        Object lock = new Object();
        Handler main = new Handler(Looper.getMainLooper());
        new MethodChannel(messenger, (yandex ? "cutelauncher/yandex_account" : "cutelauncher/drive_account")).setMethodCallHandler((call, result) -> {
            final String profile;
            try { profile = BackupAccountProfile.id(call.argument("profile")); }
            catch (Exception invalid) { result.error("invalid_argument", "Invalid profile", null); return; }
            AtomicLong revision = revisions.computeIfAbsent(profile, ignored -> new AtomicLong());
            if (call.method.equals("invalidate")) { revision.incrementAndGet(); result.success(true); return; }
            if (!java.util.Set.of("read", "save", "disconnect").contains(call.method)) { result.notImplemented(); return; }
            boolean mutation = !call.method.equals("read");
            long expected = mutation ? revision.incrementAndGet() : 0;
            executor.execute(() -> {
                try {
                    CloudAccountStore store = BackupAccountProfile.store(context, yandex ? "yandex" : "drive", profile);
                    Object value;
                    synchronized (lock) {
                        if (mutation && expected != revision.get()) throw new IllegalStateException();
                        switch (call.method) {
                            case "save" -> {
                                String id = call.argument("clientId"), payload = call.argument("payload");
                                JSONObject data = new JSONObject(payload);
                                if (data.length() != (yandex ? 4 : 3) || data.getString("refreshToken").isEmpty()
                                    || !data.getString("scope").equals(yandex ? "cloud_api:disk.app_folder" : "https://www.googleapis.com/auth/drive.file")) throw new IllegalArgumentException();
                                data.getString("clientSecret");
                                if (yandex && !data.getString("connectionId").matches("[a-f0-9]{32}")) throw new IllegalArgumentException();
                                store.save(yandex ? "https://disk.yandex.ru/" : "https://drive.google.com/", id, payload);
                                value = true;
                            }
                            case "read" -> {
                                if (Boolean.FALSE.equals(store.info().get("configured"))) value = null;
                                else {
                                    String header = store.authorization().get("authorization");
                                    String clear = new String(android.util.Base64.decode(header.substring(6), android.util.Base64.DEFAULT), StandardCharsets.UTF_8);
                                    int split = clear.indexOf(':');
                                    value = java.util.Map.of("clientId", clear.substring(0, split), "payload", clear.substring(split + 1));
                                }
                            }
                            default -> { store.disconnect(); value = true; }
                        }
                    }
                    Object response = value;
                    main.post(() -> result.success(response));
                } catch (Exception error) {
                    main.post(() -> result.error("storage", "Drive account storage unavailable", DiagnosticErrorDetails.from(error)));
                }
            });
        });
    }
}
