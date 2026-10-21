package com.leanbitlab.ltvL;

import android.app.Activity;
import java.lang.reflect.Method;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;

/** Uses the optional on-device TCL library; never changes a setting during discovery. */
public final class TclBlueLight {
    private final Object manager, save;
    private final Method reader, writer;

    public TclBlueLight() throws Exception {
        Class<?> pq = Class.forName("com.tcl.tv.pq.TvPqManager");
        Class<?> action = Class.forName("com.tcl.tv.pq.EnTclActType");
        manager = pq.getMethod("getInstance").invoke(null);
        reader = pq.getMethod("getLowBlueRay", int.class);
        writer = pq.getMethod("setLowBlueRay", int.class, int.class, action);
        save = action.getField("EN_TCL_ACT_EXEC_SAVE").get(null);
    }

    public boolean read() throws Exception {
        Object state = reader.invoke(manager, 0);
        if (!(state instanceof Integer) || ((Integer) state != 0 && (Integer) state != 1))
            throw new IllegalStateException("Unknown filter state");
        return (Integer) state == 1;
    }

    public boolean set(boolean enabled) throws Exception {
        if (read() == enabled) return enabled;
        if (!Boolean.TRUE.equals(writer.invoke(manager, 0, enabled ? 1 : 0, save)))
            throw new IllegalStateException("Filter write rejected");
        boolean actual = read();
        if (actual != enabled) throw new IllegalStateException("Filter verification failed");
        return actual;
    }

    private static synchronized Map<String, Object> perform(Boolean enabled) {
        try {
            TclBlueLight control = new TclBlueLight();
            return Map.of("status", "success", "enabled",
                    enabled == null ? control.read() : control.set(enabled));
        } catch (ClassNotFoundException | NoSuchMethodException | NoSuchFieldException | LinkageError e) {
            return Map.of("status", "unsupported");
        } catch (Exception e) {
            return Map.of("status", "error");
        }
    }

    static void register(android.content.Context activity, BinaryMessenger messenger, ExecutorService executor) {
        new MethodChannel(messenger, "cutelauncher/tcl_blue_light").setMethodCallHandler((call, result) -> {
            if (!call.method.equals("status") && !call.method.equals("set")) {
                result.notImplemented(); return;
            }
            Object value = call.method.equals("set") ? call.argument("enabled") : null;
            if (call.method.equals("set") && !(value instanceof Boolean)) {
                result.error("invalid_argument", "Expected boolean", null); return;
            }
            executor.execute(() -> {
                Map<String, Object> response = perform((Boolean) value);
                new android.os.Handler(android.os.Looper.getMainLooper()).post(() -> result.success(response));
            });
        });
    }
}
