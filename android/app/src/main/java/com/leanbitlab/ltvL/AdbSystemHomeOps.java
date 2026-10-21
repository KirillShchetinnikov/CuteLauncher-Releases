package com.leanbitlab.ltvL;

import java.util.*;

/** Fixed, reversible changes to stock HOME packages and the known Google setup package. */
final class AdbSystemHomeOps {
    static final Set<String> BUILT_INS = Set.of(
        "com.google.android.apps.tv.launcherx", "com.google.android.tvlauncher", "com.android.tv.launcher");
    static final String RECOVERY = "com.google.android.tungsten.setupwraith/com.google.android.tungsten.setupwraith.RecoveryActivity";
    static final String RECOVERY_PACKAGE = "com.google.android.tungsten.setupwraith";

    static boolean recovery(Map<String, Object> home) {
        return RECOVERY.equals(home.get("component")) && Boolean.TRUE.equals(home.get("system"));
    }

    static boolean canDisable(int ownPriority, String target, List<Map<String, Object>> homes) {
        if (!BUILT_INS.contains(target) || ownPriority == Integer.MIN_VALUE) return false;
        return homes.stream().filter(home -> Boolean.TRUE.equals(home.get("enabled"))
            && !target.equals(home.get("package")) && !recovery(home))
            .noneMatch(home -> ((Number)home.get("priority")).intValue() > ownPriority);
    }

    static LinkedHashMap<String, Integer> disableStates(int ownPriority, String target, List<Map<String, Object>> homes) {
        if (!canDisable(ownPriority, target, homes)) throw new IllegalArgumentException("Unsupported HOME");
        var states = new LinkedHashMap<String, Integer>();
        for (var home : homes) if (recovery(home) && Boolean.TRUE.equals(home.get("enabled"))
            && ((Number)home.get("priority")).intValue() > ownPriority) states.put(RECOVERY_PACKAGE, 3);
        states.put(target, 3);
        return states;
    }

    static String command(String target, int state) {
        if (!BUILT_INS.contains(target) && !RECOVERY_PACKAGE.equals(target)) throw new IllegalArgumentException("Invalid HOME target");
        String operation;
        switch (state) {
            case 0: operation = "default-state"; break;
            case 1: operation = "enable"; break;
            case 2: operation = "disable"; break;
            case 3: operation = "disable-user"; break;
            case 4: operation = "disable-until-used"; break;
            default: throw new IllegalArgumentException("Invalid HOME state");
        }
        return "pm " + operation + " --user 0 '" + target + "'";
    }

    static List<String> commands(Map<String, Integer> states, String selectedHome) {
        var commands = new ArrayList<String>();
        states.forEach((target, state) -> commands.add(command(target, state)));
        if (!selectedHome.isEmpty()) commands.add(selectHome(selectedHome));
        return commands;
    }

    static String selectHome(String component) {
        if (!component.matches("[a-zA-Z0-9_.]+/[a-zA-Z0-9_.]+")) throw new IllegalArgumentException("Invalid HOME");
        return "cmd package set-home-activity '" + component + "'";
    }

    interface Shell { String execute(String command) throws Exception; }
    interface StateReader { int read(String target) throws Exception; }
    interface Journal { boolean save(Map<String, Integer> states) throws Exception; }
    interface HomeReader { String read() throws Exception; }

    static boolean apply(Map<String, Integer> desired, String selectedHome, String expectedHome, Shell shell,
                         StateReader reader, Journal journal, HomeReader home) throws Exception {
        var before = new LinkedHashMap<String, Integer>();
        for (String target : desired.keySet()) {
            int state = reader.read(target);
            command(target, state); // Validate every recovery state before persisting or changing anything.
            before.put(target, state);
        }
        String previousHome = home.read();
        if (!journal.save(before)) return false;
        try {
            for (var entry : desired.entrySet()) {
                shell.execute(command(entry.getKey(), entry.getValue()));
                if (reader.read(entry.getKey()) != entry.getValue()) throw new IllegalStateException("HOME state unchanged");
            }
            if (!selectedHome.isEmpty()) {
                shell.execute(selectHome(selectedHome));
            }
            if (!expectedHome.isEmpty() && !expectedHome.equals(home.read())) throw new IllegalStateException("HOME unchanged");
            return true;
        } catch (Exception failure) {
            // Restore every touched state even if one recovery command fails. The persisted journal
            // remains available for a later explicit restore, including after a lost connection.
            var entries = new ArrayList<>(before.entrySet());
            Collections.reverse(entries);
            for (var entry : entries) try { shell.execute(command(entry.getKey(), entry.getValue())); }
                catch (Exception ignored) { /* Continue restoring the remaining entries. */ }
            if (!selectedHome.isEmpty() && !previousHome.isEmpty()) try { shell.execute(selectHome(previousHome)); }
                catch (Exception ignored) { /* The stock HOME can also win through its priority. */ }
            return false;
        }
    }
}
