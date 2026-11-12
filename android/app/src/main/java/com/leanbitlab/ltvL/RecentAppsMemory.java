package com.leanbitlab.ltvL;

import java.util.HashMap;
import java.util.Map;
import java.util.function.BooleanSupplier;
import java.util.regex.Pattern;

/** Optional, bounded snapshots. Never turn missing or partial dumps into zero RAM. */
final class RecentAppsMemory {
    static final Map<String, Object> UNAVAILABLE = Map.of("status", "unavailable");
    private static final Pattern HEADER = Pattern.compile("(?m)^\\s*\\*\\* MEMINFO in pid (\\d+) \\[.*?] \\*\\*\\s*$");
    private static final Pattern TOTAL = Pattern.compile("(?m)^\\s*TOTAL(?: PSS)?:\\s+(\\d+)(?=\\s|$)");
    private static final Pattern UID = Pattern.compile("(?m)^\\s*(\\d+)\\s+(\\d+)\\s*$");

    static Map<String, Object> read(AdbBridge.Shell shell, String pkg, BooleanSupplier cancelled) throws Exception {
        if (pkg == null || !pkg.matches("[A-Za-z][A-Za-z0-9_]*(\\.[A-Za-z0-9_]+)+"))
            throw new IllegalArgumentException("Invalid package");
        if (cancelled.getAsBoolean()) return UNAVAILABLE;
        if (!"2000".equals(shell.execute("id -u").trim())
                || !"0".equals(shell.execute("am get-current-user").trim())) return UNAVAILABLE;
        if (cancelled.getAsBoolean()) return UNAVAILABLE;
        String processes = shell.execute("ps -A -n -o PID,UID");
        if (cancelled.getAsBoolean()) return UNAVAILABLE;
        // Package mode includes secondary/custom-named processes; local avoids calling the app.
        String dump = shell.execute("dumpsys -t 1 meminfo --local -s --package " + pkg);
        return cancelled.getAsBoolean() ? UNAVAILABLE : snapshot(dump, processes, pkg);
    }

    static Map<String, Object> snapshot(String dump, String processes, String pkg) {
        // Only an explicit, complete system response proves the process is gone.
        if (pkg != null && dump != null && dump.trim().equals("No process found for: " + pkg))
            return Map.of("status", "unloaded");
        Long bytes = parse(dump, processes);
        return bytes == null ? UNAVAILABLE : Map.of("status", "running", "pssBytes", bytes);
    }

    static Long parse(String dump, String processes) {
        if (dump == null || processes == null || dump.length() > 1024 * 1024
                || dump.toLowerCase(java.util.Locale.ROOT).contains("timeout")) return null;
        Map<String, Long> users = new HashMap<>();
        var uid = UID.matcher(processes);
        try {
            while (uid.find()) users.put(uid.group(1), Long.parseLong(uid.group(2)) / 100000);
            var header = HEADER.matcher(dump);
            Map<String, Long> pss = new HashMap<>();
            String pid = null;
            int start = 0;
            while (header.find()) {
                if (pid != null && !add(pss, users, pid, dump.substring(start, header.start()))) return null;
                pid = header.group(1);
                start = header.end();
            }
            if (pid == null || !add(pss, users, pid, dump.substring(start)) || pss.isEmpty()) return null;
            long total = 0;
            for (long kb : pss.values()) total = Math.addExact(total, Math.multiplyExact(kb, 1024));
            return total;
        } catch (ArithmeticException | NumberFormatException invalid) { return null; }
    }

    private static boolean add(Map<String, Long> pss, Map<String, Long> users, String pid, String block) {
        Long user = users.get(pid);
        if (user == null) return false; // Process exited or UID could not be established.
        if (user != 0) return true;
        var total = TOTAL.matcher(block);
        if (!total.find()) return false;
        long value = Long.parseLong(total.group(1));
        if (total.find() || pss.putIfAbsent(pid, value) != null) return false;
        return true;
    }
}
