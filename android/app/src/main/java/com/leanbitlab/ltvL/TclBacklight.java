package com.leanbitlab.ltvL;

import android.content.Context;
import java.lang.reflect.Method;

/** Optional TCL panel backlight, independent of Android's logical brightness. */
final class TclBacklight {
    private final Object manager, current, save;
    private final Method reader, writer;

    TclBacklight() throws Exception {
        Class<?> type = Class.forName("com.tcl.tv.pq.TvBacklightManager");
        Class<?> apply = Class.forName("com.tcl.tv.pq.EnApplyType");
        Class<?> action = Class.forName("com.tcl.tv.pq.EnTclActType");
        manager = type.getMethod("getInstance").invoke(null);
        current = apply.getField("EN_APPLY_CURRENT").get(null);
        save = action.getField("EN_TCL_ACT_EXEC_SAVE").get(null);
        reader = type.getMethod("getBacklight");
        writer = type.getMethod("setBacklight", apply, int.class, action);
    }

    int read() throws Exception {
        Object value = reader.invoke(manager);
        if (!(value instanceof Integer level) || level < 0 || level > 100)
            throw new IllegalStateException("Invalid TCL backlight");
        return (Integer) value;
    }

    void write(int level) throws Exception {
        if (level < 0 || level > 100) throw new IllegalArgumentException("Invalid backlight");
        if (read() != level && !Boolean.TRUE.equals(writer.invoke(manager, current, level, save)))
            throw new IllegalStateException("TCL backlight rejected");
        if (read() != level) throw new IllegalStateException("TCL backlight verification failed");
    }

    static boolean available() {
        try { new TclBacklight(); return true; }
        catch (Exception | LinkageError error) { return false; }
    }

    static synchronized boolean apply(Context context, int value) {
        try {
            TclBacklight control = new TclBacklight();
            var state = context.getSharedPreferences("brightness_restore", Context.MODE_PRIVATE);
            if (!state.contains("tclBacklight") && !state.edit().putInt("tclBacklight", control.read()).commit()) return false;
            control.write(Math.round(value * 100f / 255));
            return true;
        } catch (Exception | LinkageError error) { return false; }
    }

    static synchronized boolean restore(Context context) {
        var state = context.getSharedPreferences("brightness_restore", Context.MODE_PRIVATE);
        if (!state.contains("tclBacklight")) return true;
        try {
            new TclBacklight().write(state.getInt("tclBacklight", -1));
            return state.edit().remove("tclBacklight").commit();
        } catch (Exception | LinkageError error) { return false; }
    }
}
