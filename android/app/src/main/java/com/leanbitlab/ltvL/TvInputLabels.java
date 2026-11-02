package com.leanbitlab.ltvL;

import java.util.Locale;
import java.util.regex.Pattern;

/** Decodes TP Vision's source-name metadata, leaving other vendors' labels intact. */
final class TvInputLabels {
    private static final Pattern TYPE_SUFFIX = Pattern.compile("&[A-Z][A-Z0-9_]{2,}$");

    static String customLabel(CharSequence label, String manufacturer, String brand) {
        if (label == null) return null;
        String value = label.toString();
        if (!philips(manufacturer) && !philips(brand)) return value;
        value = value.trim();
        var suffix = TYPE_SUFFIX.matcher(value);
        if (suffix.find()) value = value.substring(0, suffix.start()).trim();
        return value.isEmpty() || value.equals("null") ? null : value;
    }

    private static boolean philips(String vendor) {
        if (vendor == null) return false;
        return switch (vendor.toLowerCase(Locale.ROOT).replaceAll("[\\s_-]", "")) {
            case "philips", "tpvision", "tpv" -> true;
            default -> false;
        };
    }
}
