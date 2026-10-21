package com.leanbitlab.ltvL;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;

/** Reads effective AppOps before building the user-confirmed Accessibility plan. */
final class AdbAccessibilityOps {
    interface Shell { String execute(String command) throws Exception; }
    static final List<String> OPERATIONS = List.of("AUTO_START", "ACCESS_RESTRICTED_SETTINGS",
        "BIND_ACCESSIBILITY_SERVICE", "RUN_ANY_IN_BACKGROUND");

    static String mode(String operation, String output) {
        if (output.contains("Unknown operation") || output.contains("Unknown op")) return "unsupported";
        var explicit = Pattern.compile("(?m)^\\s*" + Pattern.quote(operation)
            + ":\\s*(allow|ignore|deny|default|foreground)(?:[;\\s]|$)").matcher(output);
        if (explicit.find()) return explicit.group(1);
        var fallback = Pattern.compile("(?m)^\\s*Default mode:\\s*(allow|ignore|deny|default|foreground)\\s*$").matcher(output);
        if (fallback.find()) return fallback.group(1);
        throw new IllegalStateException("Cannot read Accessibility AppOp " + operation);
    }

    static boolean needsAllow(String operation, String mode) {
        // Android's restricted-settings check accepts MODE_DEFAULT as well as MODE_ALLOWED.
        return !mode.equals("unsupported") && !mode.equals("allow")
            && !(operation.equals("ACCESS_RESTRICTED_SETTINGS") && mode.equals("default"));
    }

    static List<String> plan(String own, Shell shell) throws Exception {
        var commands = new ArrayList<String>();
        for (String operation : OPERATIONS) {
            String output = query(own, operation, shell);
            if (needsAllow(operation, mode(operation, output)))
                commands.add("appops set --user 0 '" + own + "' " + operation + " allow");
        }
        return commands;
    }

    static boolean apply(String own, Shell shell, List<?> confirmed) throws Exception {
        for (Object item : confirmed) {
            String command = (String)item;
            if (!command.startsWith("appops set --user 0 '" + own + "' ")) break;
            shell.execute(command);
            String operation = command.substring(command.lastIndexOf("' ") + 2, command.lastIndexOf(" allow"));
            boolean allowed = false;
            // Some OEMs publish the changed mode asynchronously. Bound the verification
            // on the existing ADB worker; never report success based only on shell exit.
            for (int attempt = 0; attempt < 11; attempt++) {
                String actual = mode(operation, query(own, operation, shell));
                if (actual.equals("allow")) { allowed = true; break; }
                if (actual.equals("unsupported")) break;
                if (attempt < 10) Thread.sleep(100);
            }
            if (!allowed) return false;
        }
        return true;
    }
    private static String query(String own, String operation, Shell shell) throws Exception {
        // Unsupported OEM operations return nonzero on AOSP. Keep their diagnostic output
        // for parsing; permission/transport errors are still rejected rather than ignored.
        return shell.execute("appops get --user 0 '" + own + "' " + operation + " 2>&1 || true");
    }
}
