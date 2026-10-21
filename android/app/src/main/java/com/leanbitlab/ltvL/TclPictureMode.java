package com.leanbitlab.ltvL;

import java.lang.reflect.Method;
import java.util.Set;

/** Read-only optional TCL API. An unavailable/invalid reading never excludes the filter. */
final class TclPictureMode {
    static Integer read() {
        try {
            Class<?> type = Class.forName("com.tcl.tv.pq.TvPqManager");
            return read(type.getMethod("getInstance").invoke(null), type.getMethod("getPictureMode"));
        } catch (Exception | LinkageError error) { return null; }
    }

    static Integer read(Object manager, Method getter) {
        try {
            Object value = getter.invoke(manager);
            return value instanceof Integer && (Integer)value >= 0 && (Integer)value <= 255
                ? (Integer)value : null;
        } catch (Exception | LinkageError error) { return null; }
    }

    static boolean excluded(Integer current, Set<Integer> selected) {
        return current != null && selected.contains(current);
    }
}
