package com.leanbitlab.ltvL;
import java.util.List;
import java.util.Map;
public final class AdbLauncherPolicyTest {
    static void check(boolean condition) { if (!condition) throw new AssertionError(); }
    public static void main(String[] args) {
        var disabled = Map.<String,Object>of("component","builtin/Home", "enabled",false);
        var enabled = Map.<String,Object>of("component","other/Home", "enabled",true);
        var candidates = List.of(disabled,enabled);
        check(AdbLauncherPolicy.restoreTarget("builtin/Home",candidates).equals("builtin/Home"));
        check(AdbLauncherPolicy.restoreTarget("missing/Home",candidates).equals("other/Home"));
        check(AdbLauncherPolicy.restoreTarget("",List.of(disabled)).equals("builtin/Home"));
        check(AdbLauncherPolicy.restoreTarget("missing/Home",List.of()).isEmpty());
        check(AdbLauncherPolicy.resolvedHome("priority=2\ncom.example/.Home\n").equals("com.example/com.example.Home"));
        check(AdbLauncherPolicy.resolvedHome("priority=2\r\ncom.example/.Home\r\n").equals("com.example/com.example.Home"));
        check(AdbLauncherPolicy.lines("package:first\npackage:second").contains("package:second"));
        check(AdbLauncherPolicy.normalizeComponent("com.example/.Home").equals("com.example/com.example.Home"));
        check(AdbLauncherPolicy.restoreTarget("com.example/.Home", List.of(Map.of("component","com.example/com.example.Home","enabled",true))).equals("com.example/com.example.Home"));
        check(!AdbLauncherPolicy.confirmed(null,List.of("grant")));
        check(!AdbLauncherPolicy.confirmed(List.of(),List.of()));
        check(!AdbLauncherPolicy.confirmed(List.of("old target"),List.of("new target")));
        check(AdbLauncherPolicy.confirmed(List.of("first","second"),List.of("first","second")));
        check(!AdbLauncherPolicy.confirmed(List.of("second","first"),List.of("first","second")));
        System.out.println("ADB restoration and stale confirmation regressions: 14 passed");
    }
}
