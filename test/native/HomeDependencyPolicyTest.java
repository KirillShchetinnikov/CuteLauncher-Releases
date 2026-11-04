package com.leanbitlab.ltvL;
import java.util.*;
public final class HomeDependencyPolicyTest {
    static void check(boolean value) { if (!value) throw new AssertionError(); }
    static final class Fake implements HomeDependencyPolicy.Reader {
        Map<String, HomeDependencyPolicy.App> apps = new HashMap<>();
        String users = "0"; int userReads;
        boolean rejectCastRead;
        public HomeDependencyPolicy.App app(String name) {
            if (rejectCastRead && name.equals("com.google.android.apps.mediashell"))
                throw new IllegalStateException("Cast metadata unavailable");
            return apps.get(name);
        }
        public String userIds() { userReads++; return users; }
        void add(String name, String provider, String receiver) {
            apps.put(name, new HomeDependencyPolicy.App(true, provider.isEmpty() ? List.of() : List.of(provider),
                    receiver.isEmpty() ? List.of() : List.of(receiver)));
        }
    }
    public static void main(String[] args) {
        var f = new Fake(); String setup = AdbSystemHomeOps.RECOVERY_PACKAGE;
        f.add(setup, "com.google.libs.CastInfoProvider", ""); f.add("com.google.android.apps.mediashell", "", "");
        // CastInfoProvider and an enabled Cast receiver do not prove a HOME dependency.
        check(HomeDependencyPolicy.blocked(Map.of(setup, 3), f).isEmpty());
        f.rejectCastRead = true;
        check(HomeDependencyPolicy.blocked(Map.of(setup, 3), f).isEmpty());
        check(HomeDependencyPolicy.blocked(Map.of(setup, 1), f).isEmpty());
        f.apps.remove("com.google.android.apps.mediashell");
        check(HomeDependencyPolicy.blocked(Map.of(setup, 3), f).isEmpty());
        f.add("com.google.android.apps.mediashell", "", "");
        String home = "com.google.android.apps.tv.launcherx";
        f.add(home, "vendor.LiveTvContentProvider", "vendor.GlobalButtonLaunch_Receiver");
        check(HomeDependencyPolicy.blocked(Map.of(setup, 3, home, 3), f).isEmpty());
        f.add("com.realtek.advancesetting", "", "");
        check(HomeDependencyPolicy.blocked(Map.of(home, 3), f).equals("shortcutDependency"));
        check(HomeDependencyPolicy.blocked(Map.of(setup, 3, home, 3), f).equals("shortcutDependency"));
        f.apps.remove("com.realtek.advancesetting"); f.add("com.smartdevice.global.service", "", "");
        check(HomeDependencyPolicy.blocked(Map.of(home, 3), f).isEmpty());
        f.users = "0\n10";
        check(HomeDependencyPolicy.blocked(Map.of(home, 3), f).equals("multiUserDependency"));
        check(HomeDependencyPolicy.blocked(Map.of(setup, 3, home, 3), f).equals("multiUserDependency"));
        f.users = "permission denied";
        check(HomeDependencyPolicy.blocked(Map.of(home, 3), f).equals("dependencyUnavailable"));
        f.apps.remove("com.smartdevice.global.service"); int before = f.userReads;
        check(HomeDependencyPolicy.blocked(Map.of(home, 3), f).isEmpty() && before == f.userReads);
        check(HomeDependencyPolicy.blocked(Map.of("missing.package", 3), f).equals("dependencyUnavailable"));
        System.out.println("HomeDependencyPolicyTest passed");
    }
}
