package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.Shadows;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = 34)
public class AdbHomeAssignmentTest {
    private static final String STOCK = "com.google.android.apps.tv.launcherx";
    private static final String STOCK_HOME = STOCK + "/.Home";
    private static final String DISABLED = "pm list packages -d --user 0";
    private static final String RESOLVE_HOME =
        "cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME";

    @Test public void assignmentDisablesStockAndRestoreReturnsItsSavedState() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            var pm = Shadows.shadowOf(activity.getPackageManager());
            pm.setSystemFeature(PackageManager.FEATURE_LEANBACK, true);
            var homeIntent = new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME);
            pm.addResolveInfoForIntent(homeIntent, home(activity.getPackageName(), MainActivity.class.getName(), 0));
            var stock = home(STOCK, STOCK + ".Home", 2);
            var stockPackage = new PackageInfo();
            stockPackage.packageName = STOCK;
            stockPackage.applicationInfo = stock.activityInfo.applicationInfo;
            stockPackage.activities = new ActivityInfo[]{stock.activityInfo};
            pm.installPackage(stockPackage);
            pm.addResolveInfoForIntent(homeIntent, stock);
            assertFalse(AdbCapabilities.homePriorityAllowsSelection(activity));
            assertEquals(true, ((Map<?, ?>) AdbCapabilities.info(activity).get("actions")).get("home"));

            String own = activity.getPackageName() + "/" + MainActivity.class.getName();
            String command = AdbSystemHomeOps.selectHome(own);
            String disable = AdbSystemHomeOps.command(STOCK, PackageManager.COMPONENT_ENABLED_STATE_DISABLED_USER);
            String restore = AdbSystemHomeOps.command(STOCK, PackageManager.COMPONENT_ENABLED_STATE_DEFAULT);
            var packageManager = activity.getPackageManager();
            for (boolean selected : new boolean[]{false, true}) {
                var executed = new ArrayList<String>();
                var shell = new AdbBridge.Shell() {
                    @Override public String execute(String text) {
                        int state = packageManager.getApplicationEnabledSetting(STOCK);
                        boolean stockDisabled = state == PackageManager.COMPONENT_ENABLED_STATE_DISABLED_USER;
                        return switch (text) {
                            case "am get-current-user" -> "0";
                            case "id -u" -> "2000";
                            case DISABLED -> stockDisabled ? "package:" + STOCK : "";
                            case RESOLVE_HOME -> selected && stockDisabled ? own : STOCK_HOME;
                            default -> {
                                if (text.equals(disable))
                                    packageManager.setApplicationEnabledSetting(STOCK, PackageManager.COMPONENT_ENABLED_STATE_DISABLED_USER, 0);
                                else if (text.equals(restore))
                                    packageManager.setApplicationEnabledSetting(STOCK, PackageManager.COMPONENT_ENABLED_STATE_DEFAULT, 0);
                                else assertTrue(text.equals(command) || text.equals(AdbSystemHomeOps.selectHome(STOCK + "/" + STOCK + ".Home")));
                                executed.add(text);
                                yield "Success";
                            }
                        };
                    }
                    @Override public void close() {}
                };
                var plan = AdbLauncherControl.plan(activity, shell, "home", null);
                assertEquals("ready", plan.get("status"));
                assertEquals(List.of(disable, command), plan.get("commands"));
                assertTrue(executed.isEmpty());
                assertEquals("changed", AdbLauncherControl.plan(activity, shell, "home", "com.android.tv.launcher", true)
                    .get("status"));
                assertEquals("changed", AdbLauncherControl.apply(activity, shell, "home", null, List.of("stale")));
                assertTrue(executed.isEmpty());
                assertEquals(selected ? "success" : "denied",
                    AdbLauncherControl.apply(activity, shell, "home", null, List.of(disable, command)));
                assertEquals(disable, executed.get(0));
                assertEquals(command, executed.get(1));
                if (selected) assertEquals(PackageManager.COMPONENT_ENABLED_STATE_DISABLED_USER,
                    packageManager.getApplicationEnabledSetting(STOCK));
                else assertEquals(PackageManager.COMPONENT_ENABLED_STATE_DEFAULT,
                    packageManager.getApplicationEnabledSetting(STOCK));
                var recoveryPlan = AdbLauncherControl.plan(activity, shell, "restore", null);
                assertEquals("ready", recoveryPlan.get("status"));
                assertEquals(List.of(restore), recoveryPlan.get("commands"));
                assertEquals("success", AdbLauncherControl.apply(activity, shell, "restore", null, List.of(restore)));
                assertEquals(PackageManager.COMPONENT_ENABLED_STATE_DEFAULT,
                    packageManager.getApplicationEnabledSetting(STOCK));
                assertFalse(activity.getSharedPreferences("adb_recovery", 0).contains("home_states_" + STOCK));
            }
            assertEquals(STOCK + "/" + STOCK + ".Home", activity.getSharedPreferences("adb_recovery", 0)
                .getString("previous_home", null));
        }
    }

    @Test public void assignmentWithoutAnEnabledBuiltInLauncherUsesOnlySetHome() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            var pm = Shadows.shadowOf(activity.getPackageManager());
            pm.setSystemFeature(PackageManager.FEATURE_LEANBACK, true);
            var homeIntent = new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME);
            pm.addResolveInfoForIntent(homeIntent, home(activity.getPackageName(), MainActivity.class.getName(), 0));
            String own = new ComponentName(activity, MainActivity.class).flattenToString();
            var shell = new AdbBridge.Shell() {
                @Override public String execute(String command) {
                    return switch (command) {
                        case RESOLVE_HOME -> own;
                        case DISABLED -> "";
                        default -> throw new AssertionError(command);
                    };
                }
                @Override public void close() {}
            };
            var plan = AdbLauncherControl.plan(activity, shell, "home", null);
            assertEquals("ready", plan.get("status"));
            assertEquals(List.of(AdbSystemHomeOps.selectHome(own)), plan.get("commands"));
        }
    }

    private static ResolveInfo home(String pkg, String name, int priority) {
        var app = new ApplicationInfo();
        app.packageName = pkg;
        app.enabled = true;
        var activity = new ActivityInfo();
        activity.packageName = pkg;
        activity.name = name;
        activity.applicationInfo = app;
        activity.enabled = true;
        activity.exported = true;
        var result = new ResolveInfo();
        result.activityInfo = activity;
        result.isDefault = true;
        result.priority = priority;
        return result;
    }
}
