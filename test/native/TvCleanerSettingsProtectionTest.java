package com.leanbitlab.ltvL;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.*;

public final class TvCleanerSettingsProtectionTest {
    static void check(boolean value) { if (!value) throw new AssertionError(); }
    public static void main(String[] args) throws Exception {
        List<String> commands = new ArrayList<>();
        Set<String> names = TvCleanerSettingsProtection.collect(command -> {
            commands.add(command);
            return switch(command) {
                case "settings --user 0 get secure 'default_input_method'" -> "com.example.keyboard/.Ime";
                case "settings --user 0 get secure 'enabled_input_methods'" -> "com.example.keyboard/.Ime;12;-3:com.example.other/.Ime";
                case "settings --user 0 get secure 'enabled_accessibility_services'" -> "com.example.access/.Service";
                case "settings --user 0 get secure 'enabled_notification_listeners'" -> "com.example.notifications/.Listener";
                case "settings --user 0 get secure 'screensaver_components'" -> "com.example.dream/.One,com.example.dream2/.Two";
                case "settings --user 0 get secure 'always_on_vpn_app'" -> "com.example.vpn\n";
                default -> throw new AssertionError("Unexpected shell command");
            };
        });
        check(names.equals(Set.of("com.example.keyboard", "com.example.other", "com.example.access",
            "com.example.notifications", "com.example.dream", "com.example.dream2", "com.example.vpn")));
        check(commands.size() == 6);
        check(TvCleanerSettingsProtection.collect(command -> "null").isEmpty());
        check(TvCleanerSettingsProtection.collect(command -> "\n").isEmpty());
        for (String bad : List.of("Error: permission denied", "com.example.vpn;reboot", "Permission denial")) {
            boolean failed = false;
            try { TvCleanerSettingsProtection.collect(command -> bad); }
            catch (IllegalStateException expected) { failed = true; }
            check(failed);
        }
        boolean failed = false;
        try { TvCleanerSettingsProtection.collect(command -> { throw new SecurityException(); }); }
        catch (SecurityException expected) { failed = true; }
        check(failed); // No usable partial protection list is returned.
        String source = Files.readString(Path.of("android/app/src/main/java/com/leanbitlab/ltvL/TvCleaner.java"));
        check(!source.contains("Settings.Secure.getString"));
        check(source.contains("TvCleanerSettingsProtection.collect(shell::execute)"));
        System.out.println("TvCleanerSettingsProtectionTest passed");
    }
}
