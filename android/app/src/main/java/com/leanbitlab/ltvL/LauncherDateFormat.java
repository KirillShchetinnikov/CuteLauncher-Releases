package com.leanbitlab.ltvL;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.Locale;

/** Date formatting shared by the native screensaver and Flutter's saved presets. */
final class LauncherDateFormat {
    static Locale locale(String language) {
        return language == null || language.isEmpty()
                ? Locale.getDefault() : Locale.forLanguageTag(language.replace('_', '-'));
    }

    static String format(String pattern, Date date, Locale locale, String fallback) {
        if ("cute_compact_date".equals(pattern)) {
            if ("ru".equals(locale.getLanguage())) {
                String[] weekdays = {"ВСК", "ПНД", "ВТР", "СРД", "ЧТВ", "ПТН", "СБТ"};
                String[] months = {"Янв", "Фев", "Мар", "Апр", "Май", "Июн", "Июл", "Авг", "Сен", "Окт", "Ноя", "Дек"};
                Calendar calendar = Calendar.getInstance(locale);
                calendar.setTime(date);
                return weekdays[calendar.get(Calendar.DAY_OF_WEEK) - 1] + " "
                        + calendar.get(Calendar.DAY_OF_MONTH) + " " + months[calendar.get(Calendar.MONTH)];
            }
            pattern = "EEE d MMM";
        }
        try {
            return new SimpleDateFormat(pattern, locale).format(date);
        } catch (IllegalArgumentException exception) {
            return new SimpleDateFormat(fallback, locale).format(date);
        }
    }
}
