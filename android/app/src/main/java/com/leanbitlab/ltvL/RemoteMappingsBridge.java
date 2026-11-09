package com.leanbitlab.ltvL;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.Executor;
import java.util.function.BooleanSupplier;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;

final class RemoteMappingsBridge implements AutoCloseable {
    private final MethodChannel channel;
    private final RemoteMappingStore store;
    private final Context context;
    private final Handler main = new Handler(Looper.getMainLooper());
    private final BooleanSupplier permission;
    private boolean closed;
    private final Runnable learningTimeout = RemoteButtonLearning::cancel;
    RemoteMappingsBridge(Context context, BinaryMessenger messenger, Executor io, BooleanSupplier permission) {
        this.context = context.getApplicationContext();
        this.permission = permission; store = new RemoteMappingStore(context);
        channel = new MethodChannel(messenger, "cutelauncher/remote_mappings");
        channel.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "editing":
                    RemoteButtonRemapper.editing = Boolean.TRUE.equals(call.arguments);
                    if (!RemoteButtonRemapper.editing) RemoteButtonLearning.cancel();
                    result.success(null); break;
                case "learn":
                    if (!permission.getAsBoolean() || !LauncherAccessibilityService.connected()) {
                        result.error("permission_denied", "Service unavailable", null); break;
                    }
                    RemoteButtonLearning.start(code -> {
                        main.removeCallbacks(learningTimeout);
                        if (!closed) result.success(code);
                    });
                    main.postDelayed(learningTimeout, 30_000); break;
                case "cancelLearn": RemoteButtonLearning.cancel(); result.success(null); break;
                case "info": case "save":
                    RemoteMappingConfiguration value;
                    try {
                        value = call.method.equals("save")
                            ? RemoteMappingConfiguration.fromMap((Map<?, ?>)call.arguments) : null;
                    } catch (RuntimeException invalid) {
                        result.error("invalid_argument", "Invalid mapping", DiagnosticErrorDetails.from(invalid)); break;
                    }
                    io.execute(() -> {
                        try {
                            RemoteMappingConfiguration loaded;
                            if (value != null) { store.save(value); loaded = value; }
                            else loaded = store.load();
                            Map<String, Object> info = info(loaded);
                            main.post(() -> {
                                if (closed) return;
                                if (value != null) RemoteButtonRemapper.updated(loaded);
                                info.put("permission", permission.getAsBoolean());
                                info.put("connected", LauncherAccessibilityService.connected());
                                info.put("status", RemoteButtonRemapper.status);
                                result.success(info);
                            });
                        } catch (Exception ignored) {
                            main.post(() -> { if (!closed) result.error("unavailable", "Mappings unavailable", DiagnosticErrorDetails.from(ignored)); });
                        }
                    }); break;
                default: result.notImplemented();
            }
        });
    }
    private Map<String, Object> info(RemoteMappingConfiguration configuration) {
        Map<String, Object> result = new LinkedHashMap<>(configuration.toMap());
        try { result.put("tclScreenOff", TclScreenOff.available(context)); }
        catch (RuntimeException unavailable) { result.put("tclScreenOff", false); }
        result.put("directHdmi", TvInputLaunch.supportsDirectHdmi());
        result.put("tvActions", RemoteTvActions.available(context));
        return result;
    }
    @Override public void close() {
        RemoteButtonLearning.cancel(); main.removeCallbacks(learningTimeout);
        closed = true; RemoteButtonRemapper.editing = false; channel.setMethodCallHandler(null);
    }
}
