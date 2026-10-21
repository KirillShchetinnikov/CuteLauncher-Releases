package com.leanbitlab.ltvL;

import java.util.*;

public final class AdbSystemHomeOpsTest {
    static final String STOCK = "com.google.android.apps.tv.launcherx";
    static final String STOCK_HOME = STOCK + "/home.HomeActivity";
    static final String OWN = "io.github.kirillshchetinnikov.cutelauncher/com.leanbitlab.ltvL.MainActivity";
    static void check(boolean value) { if (!value) throw new AssertionError(); }
    static Map<String, Object> home(String pkg, String component, int priority, boolean enabled, boolean system) {
        return Map.of("package", pkg, "component", component, "priority", priority, "enabled", enabled, "system", system);
    }
    static Map<String, Object> recovery(boolean enabled, boolean system) {
        return home("com.google.android.tungsten.setupwraith", AdbSystemHomeOps.RECOVERY, 1, enabled, system);
    }
    static final class Device {
        final Map<String, Integer> states = new HashMap<>();
        final List<String> commands = new ArrayList<>();
        Map<String, Integer> saved = Map.of();
        String selected = STOCK_HOME;
        String refuse = "";
        boolean throwOnRefusal;
        boolean pinnedHome;
        Device(int recoveryState) {
            states.put(STOCK, 0);
            states.put(AdbSystemHomeOps.RECOVERY_PACKAGE, recoveryState);
        }
        String home() {
            if (pinnedHome || states.get(STOCK) < 2) return STOCK_HOME;
            if (states.get(AdbSystemHomeOps.RECOVERY_PACKAGE) < 2) return AdbSystemHomeOps.RECOVERY_PACKAGE;
            return selected;
        }
        String execute(String command) throws Exception {
            commands.add(command);
            if (command.equals(refuse)) {
                if (throwOnRefusal) throw new java.io.IOException("Connection lost");
                return "SecurityException"; // Some shell implementations return errors as text.
            }
            if (command.startsWith("cmd package")) {
                selected = command.split("'")[1];
                return "Success";
            }
            for (var target : states.keySet()) for (int state = 0; state <= 4; state++)
                if (command.equals(AdbSystemHomeOps.command(target, state))) {
                    states.put(target, state);
                    return "new state";
                }
            throw new AssertionError("Unexpected command: " + command);
        }
        boolean apply(Map<String, Integer> desired, String selected, String expected) throws Exception {
            return AdbSystemHomeOps.apply(desired, selected, expected, this::execute, states::get,
                before -> { saved = new LinkedHashMap<>(before); return true; }, this::home);
        }
    }
    public static void main(String[] args) throws Exception {
        var stock = home(STOCK, STOCK_HOME, 2, true, true);
        var homes = List.of(stock, recovery(true, true));
        check(AdbSystemHomeOps.canDisable(0, STOCK, homes));
        var desired = AdbSystemHomeOps.disableStates(0, STOCK, homes);
        check(new ArrayList<>(desired.keySet()).equals(List.of(AdbSystemHomeOps.RECOVERY_PACKAGE, STOCK)));
        check(AdbSystemHomeOps.commands(desired, OWN).equals(List.of(
            "pm disable-user --user 0 '" + AdbSystemHomeOps.RECOVERY_PACKAGE + "'",
            "pm disable-user --user 0 '" + STOCK + "'",
            "cmd package set-home-activity '" + OWN + "'")));
        check(!AdbSystemHomeOps.canDisable(0, STOCK, List.of(stock, recovery(true, false))));
        check(!AdbSystemHomeOps.canDisable(0, STOCK, List.of(stock,
            home("unknown", "unknown/Home", 1, true, true))));
        check(!AdbSystemHomeOps.canDisable(Integer.MIN_VALUE, STOCK, homes));
        check(!AdbSystemHomeOps.canDisable(0, "unknown", homes));
        check(AdbSystemHomeOps.disableStates(0, STOCK, List.of(stock, recovery(false, true)))
            .equals(Map.of(STOCK, 3))); // A previously disabled wizard is left untouched.
        check(AdbSystemHomeOps.disableStates(1, STOCK, homes).equals(Map.of(STOCK, 3)));
        check(AdbSystemHomeOps.canDisable(0, STOCK, List.of(stock,
            home("projectivy", "projectivy/Home", 0, true, false))));

        for (int originalState : List.of(0, 1)) {
            var device = new Device(originalState);
            check(device.apply(desired, OWN, OWN));
            check(device.home().equals(OWN));
            check(device.saved.equals(Map.of(STOCK, 0, AdbSystemHomeOps.RECOVERY_PACKAGE, originalState)));
            var original = new LinkedHashMap<String, Integer>();
            original.put(STOCK, 0);
            original.put(AdbSystemHomeOps.RECOVERY_PACKAGE, originalState);
            check(device.apply(original, "", STOCK_HOME));
            check(device.states.equals(original));
        }
        for (boolean thrown : List.of(false, true)) {
            var device = new Device(1);
            device.refuse = AdbSystemHomeOps.command(STOCK, 3);
            device.throwOnRefusal = thrown;
            check(!device.apply(desired, OWN, OWN));
            check(device.states.equals(Map.of(STOCK, 0, AdbSystemHomeOps.RECOVERY_PACKAGE, 1)));
            check(!device.commands.contains(AdbSystemHomeOps.selectHome(OWN)));
            check(device.saved.size() == 2); // Recovery journal survives a failed/lost operation.
        }
        var rejectedSetup = new Device(0);
        rejectedSetup.refuse = AdbSystemHomeOps.command(AdbSystemHomeOps.RECOVERY_PACKAGE, 3);
        rejectedSetup.throwOnRefusal = true;
        check(!rejectedSetup.apply(desired, OWN, OWN));
        check(rejectedSetup.states.equals(Map.of(STOCK, 0, AdbSystemHomeOps.RECOVERY_PACKAGE, 0)));
        check(!rejectedSetup.commands.contains(AdbSystemHomeOps.command(STOCK, 3)));
        var pinned = new Device(1);
        pinned.pinnedHome = true;
        check(!pinned.apply(desired, OWN, OWN));
        check(pinned.states.equals(Map.of(STOCK, 0, AdbSystemHomeOps.RECOVERY_PACKAGE, 1)));
        check(pinned.selected.equals(STOCK_HOME));
        var noStorage = new Device(1);
        check(!AdbSystemHomeOps.apply(desired, OWN, OWN, noStorage::execute, noStorage.states::get,
            before -> false, noStorage::home));
        check(noStorage.commands.isEmpty());
        try { AdbSystemHomeOps.command("unknown/Home", 2); throw new AssertionError(); }
        catch (IllegalArgumentException expected) { }
        try { AdbSystemHomeOps.command(AdbSystemHomeOps.RECOVERY, 2); throw new AssertionError(); }
        catch (IllegalArgumentException expected) { } // Never issue component changes from shell again.
        try { AdbSystemHomeOps.command(STOCK, 5); throw new AssertionError(); }
        catch (IllegalArgumentException expected) { }
        System.out.println("AdbSystemHomeOpsTest passed");
    }
}
