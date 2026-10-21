package com.leanbitlab.ltvL;

import java.util.Calendar;
import java.util.Locale;

public final class LauncherDateFormatTest {
    public static void main(String[] args) {
        Calendar calendar = Calendar.getInstance();
        calendar.set(2026, Calendar.OCTOBER, 2, 15, 45, 0);
        check("ПТН 2 Окт", LauncherDateFormat.format("cute_compact_date", calendar.getTime(),
                LauncherDateFormat.locale("ru"), "EEEE d"));
        check("Fri 2 Oct", LauncherDateFormat.format("cute_compact_date", calendar.getTime(),
                LauncherDateFormat.locale("en"), "EEEE d"));
        check("15:45", LauncherDateFormat.format("invalid", calendar.getTime(), Locale.US, "H:mm"));
        check("ru", LauncherDateFormat.locale("ru_RU").getLanguage());
        System.out.println("Launcher date format checks passed");
    }

    private static void check(String expected, String actual) {
        if (!expected.equals(actual)) throw new AssertionError(expected + " != " + actual);
    }
}
