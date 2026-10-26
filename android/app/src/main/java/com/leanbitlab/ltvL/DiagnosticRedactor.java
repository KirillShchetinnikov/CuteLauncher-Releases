package com.leanbitlab.ltvL;

import java.util.regex.Pattern;

/** Conservative redaction for bounded diagnostic excerpts, never a replacement for access control. */
final class DiagnosticRedactor {
    static final int LIMIT = 2048;
    private static final Pattern SENSITIVE = Pattern.compile(
        "(?i)ssid|bssid|password|passwd|psk|token|secret|credential|private.?key|public.?key|"
        + "account|e-?mail|username|host.?name|device.?name|serial|latitude|longitude|coordinates|"
        + "(?:^|[\\s,:])(?:ip|ipv4|ipv6|mac|address|gateway|dns|dhcp|url|uri|path|location)(?:$|[\\s:=])");
    private static final Pattern PACKAGE = Pattern.compile("\\b[a-zA-Z_][a-zA-Z0-9_]*(?:\\.[a-zA-Z_][a-zA-Z0-9_]*)+\\b");
    static String redact(String raw) {
        if (raw == null) return "";
        // Bound work as well as the stored result. Redact before truncating the final text.
        String input = raw.substring(0, Math.min(raw.length(), 16384));
        var lines = new StringBuilder();
        for (String line : input.split("\\r?\\n", -1)) {
            if (lines.length() >= LIMIT) break;
            if (Pattern.compile("(?i)\\b(?:ssid|bssid)\\s*[:=]").matcher(line).find()) {
                line = line.replaceAll("(?i)(\\b(?:ssid|bssid)\\s*[:=]).*", "$1 [redacted]");
            } else if (SENSITIVE.matcher(line).find()) line = "[redacted personal data]";
            line = line.replaceAll("\\b(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\b", "[ip]")
                .replaceAll("(?i)(?<![a-z0-9])(?:[0-9a-f]{0,4}:){2,}[0-9a-f:.%a-z0-9]*(?![a-z0-9])", "[ip]")
                .replaceAll("(?i)\\b(?:[0-9a-f]{2}[:-]){5}[0-9a-f]{2}\\b", "[mac]")
                .replaceAll("(?i)\\b[a-z][a-z0-9+.-]*://\\S+", "[uri]")
                .replaceAll("[\\w.+-]+@[\\w.-]+", "[email]")
                .replaceAll("(?i)(?:[a-z]:\\\\|/(?:data|storage|sdcard|mnt|home|users|tmp|private)/)[^\\s'\"]+", "[path]")
                .replaceAll("\"[^\"]*\"", "\"[redacted]\"")
                .replaceAll("[\\p{Cntrl}&&[^\\t]]", "");
            var matcher = PACKAGE.matcher(line);
            var safe = new StringBuffer();
            while (matcher.find()) {
                String value = matcher.group();
                boolean allowed = value.equals("com.google.android.tungsten.setupwraith")
                    || value.equals("com.google.android.apps.tv.launcherx")
                    || value.equals("com.google.android.tvlauncher") || value.equals("com.android.tv.launcher")
                    || value.equals("com.android.settings") || value.equals("android.uid.system")
                    || value.startsWith("com.leanbitlab.ltvL") || value.startsWith("java.")
                    || value.startsWith("android.permission.");
                matcher.appendReplacement(safe, java.util.regex.Matcher.quoteReplacement(allowed ? value : "[identifier]"));
            }
            matcher.appendTail(safe);
            if (lines.length() > 0) lines.append('\n');
            lines.append(safe);
        }
        if (lines.length() > LIMIT) lines.setLength(LIMIT);
        if (raw.length() > input.length() || lines.length() >= LIMIT) lines.append("\n[truncated]");
        return lines.toString();
    }
}
