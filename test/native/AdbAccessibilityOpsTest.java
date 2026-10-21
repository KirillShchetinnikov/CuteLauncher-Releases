package com.leanbitlab.ltvL;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public final class AdbAccessibilityOpsTest {
    private static void check(boolean value) { if (!value) throw new AssertionError(); }
    public static void main(String[] args) throws Exception {
        check(AdbAccessibilityOps.mode("AUTO_START", "Error: Unknown operation string: AUTO_START").equals("unsupported"));
        check(AdbAccessibilityOps.mode("BIND_ACCESSIBILITY_SERVICE", "BIND_ACCESSIBILITY_SERVICE: allow; time=+1s").equals("allow"));
        check(AdbAccessibilityOps.mode("AUTO_START", "No operations.\r\nDefault mode: ignore\r\n").equals("ignore"));
        check(!AdbAccessibilityOps.needsAllow("ACCESS_RESTRICTED_SETTINGS", "default"));
        check(AdbAccessibilityOps.needsAllow("RUN_ANY_IN_BACKGROUND", "ignore"));
        check(AdbAccessibilityOps.needsAllow("BIND_ACCESSIBILITY_SERVICE", "foreground"));
        boolean rejected = false;
        try { AdbAccessibilityOps.mode("AUTO_START", "SecurityException: denied"); }
        catch (IllegalStateException expected) { rejected = true; }
        check(rejected);
        class Shell implements AdbAccessibilityOps.Shell {
            final Map<String,String> modes = new HashMap<>(Map.of("AUTO_START", "ignore",
                "ACCESS_RESTRICTED_SETTINGS", "deny", "BIND_ACCESSIBILITY_SERVICE", "allow", "RUN_ANY_IN_BACKGROUND", "allow"));
            final List<String> writes = new ArrayList<>();
            boolean refuse;
            int delayedReads;
            public String execute(String command) {
                String op = command.split(" ")[5];
                if (command.startsWith("appops get")) {
                    if (delayedReads > 0) { delayedReads--; return op + ": ignore; time=+1s"; }
                    return op + ": " + modes.get(op) + "; time=+1s";
                }
                writes.add(command);
                if (!refuse) modes.put(op, "allow");
                return "";
            }
            public void close() {}
        }
        var shell = new Shell();
        var plan = AdbAccessibilityOps.plan("own.package", shell);
        check(plan.equals(List.of("appops set --user 0 'own.package' AUTO_START allow",
            "appops set --user 0 'own.package' ACCESS_RESTRICTED_SETTINGS allow")));
        check(shell.writes.isEmpty());
        check(AdbAccessibilityOps.apply("own.package", shell, plan));
        check(AdbAccessibilityOps.plan("own.package", shell).isEmpty());
        shell.delayedReads = 2;
        check(AdbAccessibilityOps.apply("own.package", shell, plan));
        shell.modes.put("RUN_ANY_IN_BACKGROUND", "deny");
        shell.refuse = true;
        check(!AdbAccessibilityOps.apply("own.package", shell, AdbAccessibilityOps.plan("own.package", shell)));
        System.out.println("Accessibility AppOps: parsing, OEM support, selective plan, read-only preview, verification passed");
    }
}
