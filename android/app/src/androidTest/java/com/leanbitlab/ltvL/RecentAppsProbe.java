package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.Instrumentation;
import android.os.Build;
import android.os.Bundle;
import android.os.ParcelFileDescriptor;
import java.nio.charset.StandardCharsets;
import java.util.*;

/** Real shell/task-manager contract check, restricted to an isolated TV fixture on emulators. */
public final class RecentAppsProbe extends Instrumentation {
    private static final String PKG = "io.cutelauncher.fixture.recents";
    private static void check(boolean value, String message) { if (!value) throw new AssertionError(message); }
    @Override public void onCreate(Bundle args) { super.onCreate(args); start(); }
    private String shell(String command) throws Exception {
        try (var input = new ParcelFileDescriptor.AutoCloseInputStream(getUiAutomation().executeShellCommand(command))) {
            return new String(input.readAllBytes(), StandardCharsets.UTF_8).trim();
        }
    }
    private void launch() throws Exception {
        shell("am start -n " + PKG + "/.RecentTasksFixture");
    }
    private List<?> apps(Map<String,Object> result) { return (List<?>)result.get("apps"); }
    private boolean contains(List<?> apps, String pkg) { return apps.stream().anyMatch(app -> pkg.equals(((Map<?,?>)app).get("packageName"))); }
    @Override public void onStart() {
        Bundle report = new Bundle();
        try {
            check(Build.HARDWARE.contains("ranchu") || Build.HARDWARE.contains("goldfish"), "Emulator required");
            var context = getTargetContext();
            AdbBridge.Shell commands = new AdbBridge.Shell() {
                public String execute(String command) throws Exception { return shell(command); }
                public void close() {}
            };
            launch();
            var control = new RecentAppsControl(context, commands);
            var listed = control.run("list", null);
            check(contains(apps(listed), PKG), "Live TV fixture missing: " + shell("am stack list"));
            check(!contains(apps(listed), context.getPackageName()), "Launcher exposed");
            shell("am start -n " + context.getPackageName() + "/com.leanbitlab.ltvL.MainActivity");
            check("success".equals(control.run("switch", PKG).get("status")), "Switch failed");
            boolean focused = false;
            for (int i = 0; i < 20; i++) {
                var root = getUiAutomation().getRootInActiveWindow();
                if (root != null && PKG.contentEquals(root.getPackageName())) { focused = true; break; }
                Thread.sleep(100);
            }
            check(focused, "Fixture did not receive focus");
            check(!contains(apps(control.run("close", PKG)), PKG), "Task was not removed");
            launch();
            // Never stop unrelated emulator apps even if a previous test left tasks behind.
            for (Object app : apps(control.run("list",null))) {
                Map<?,?> row = (Map<?,?>)app;
                check(!Boolean.TRUE.equals(row.get("userApp")) || PKG.equals(row.get("packageName")), "Unrelated user TV task; close-all test refused");
            }
            check(!contains(apps(control.run("closeAll",null)), PKG), "Close all did not stop fixture");
            check("stale".equals(control.run("switch",PKG).get("status")), "Stale task relaunched");
            report.putString("stream", "\nPASS RecentAppsProbe: live TV filtering, launcher protection, focus, remove, close-all, stale target\n");
            finish(Activity.RESULT_OK, report);
        } catch (Throwable failure) {
            report.putString("stream", "\nFAIL RecentAppsProbe: " + failure + "\n"); finish(Activity.RESULT_CANCELED, report);
        }
    }
}
