package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.*;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.Shadows;
import org.robolectric.annotation.Config;
import java.util.*;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class RecentAppsControlTest {
    private void install(Activity context, String pkg, boolean tv, int flags, boolean home) {
        var app = new ApplicationInfo(); app.packageName = pkg; app.enabled = true; app.flags = flags; app.nonLocalizedLabel = pkg;
        var activity = new ActivityInfo(); activity.packageName = pkg; activity.name = pkg + ".Main"; activity.applicationInfo = app; activity.enabled = true; activity.exported = true;
        var info = new PackageInfo(); info.packageName = pkg; info.applicationInfo = app; info.activities = new ActivityInfo[]{activity};
        var pm = Shadows.shadowOf(context.getPackageManager()); pm.installPackage(info);
        var resolve = new ResolveInfo(); resolve.activityInfo = activity;
        if (tv) pm.addResolveInfoForIntent(new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LEANBACK_LAUNCHER).setPackage(pkg), resolve);
        if (home) pm.addResolveInfoForIntent(new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME), resolve);
    }
    private static final class Shell implements AdbBridge.Shell {
        final Map<Integer, String> tasks = new LinkedHashMap<>();
        final List<String> changes = new ArrayList<>();
        String user = "0";
        boolean refuseStop;
        boolean delayRemoval;
        int pendingId = -1, pendingReads;
        @Override public String execute(String command) {
            if (command.equals("id -u")) return "2000";
            if (command.equals("am get-current-user")) return user;
            if (command.equals("dumpsys activity recents")) return "* Recent #0: Task{abc #2}";
            if (command.equals("am stack list")) {
                var text = new StringBuilder();
                tasks.forEach((id,pkg) -> text.append("taskId=").append(id).append(": ").append(pkg).append("/.Main userId=0\n"));
                if (pendingReads > 0 && --pendingReads == 0) tasks.remove(pendingId);
                return text.toString();
            }
            changes.add(command);
            if (command.startsWith("am force-stop --user 0 ") && !refuseStop) tasks.values().removeIf(command.substring(23)::equals);
            else if (command.startsWith("am stack remove ")) {
                int id = Integer.parseInt(command.substring(16));
                if (delayRemoval) { pendingId = id; pendingReads = 2; } else tasks.remove(id);
            }
            else if (!command.startsWith("am task focus ") && !command.startsWith("am force-stop ")) throw new AssertionError(command);
            return "";
        }
        @Override public void close() {}
    }
    @Test public void filterTasksAndCloseAllProtectsSystemAndHome() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var context = controller.get();
            install(context,"tv.user",true,0,false);
            install(context,"tv.system",true,ApplicationInfo.FLAG_SYSTEM,false);
            install(context,"tv.updated",true,ApplicationInfo.FLAG_UPDATED_SYSTEM_APP,false);
            install(context,"tv.launcher",true,0,true);
            install(context,"phone.only",false,0,false);
            var shell = new Shell();
            shell.tasks.put(1,"tv.user"); shell.tasks.put(2,"tv.user"); shell.tasks.put(3,"tv.system");
            shell.tasks.put(4,"tv.updated"); shell.tasks.put(5,"tv.launcher"); shell.tasks.put(6,"phone.only");
            shell.tasks.put(7,context.getPackageName());
            var control = new RecentAppsControl(context,shell);
            var apps = (List<?>)control.run("list",null).get("apps");
            assertEquals(3,apps.size());
            assertEquals("tv.user",((Map<?,?>)apps.get(0)).get("packageName"));
            assertTrue(shell.changes.isEmpty());
            assertEquals("success",control.run("closeAll",null).get("status"));
            assertEquals(List.of("am force-stop --user 0 tv.user"),shell.changes);
            assertFalse(shell.tasks.containsValue("tv.user"));
            assertTrue(shell.tasks.containsValue("tv.launcher"));
            assertTrue(shell.tasks.containsValue("tv.system"));
            assertTrue(shell.tasks.containsValue("phone.only"));
        }
    }
    @Test public void homeSnapshotIsRefreshedForEachOperation() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var context = controller.get();
            install(context, "tv.user", true, 0, false);
            var shell = new Shell(); shell.tasks.put(1, "tv.user"); shell.tasks.put(2, "tv.user");
            var control = new RecentAppsControl(context, shell);
            assertEquals(1, ((List<?>) control.run("list", null).get("apps")).size());
            install(context, "tv.user", true, 0, true);
            assertEquals("success", control.run("closeAll", null).get("status"));
            assertTrue(shell.changes.isEmpty());
            assertTrue(((List<?>) control.run("list", null).get("apps")).isEmpty());
        }
    }
    @Test public void closeRemovesEveryTaskSwitchResumesAndStaleTargetIsNotLaunched() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var context = controller.get(); install(context,"tv.user",true,0,false);
            var shell = new Shell(); shell.tasks.put(1,"tv.user"); shell.tasks.put(2,"tv.user");
            var control = new RecentAppsControl(context,shell);
            assertEquals("success",control.run("switch","tv.user").get("status"));
            assertEquals(List.of("am task focus 2"),shell.changes);
            assertEquals("success",control.run("close","tv.user").get("status"));
            assertEquals(List.of("am task focus 2","am stack remove 2","am stack remove 1"),shell.changes);
            assertEquals("stale",control.run("switch","tv.user").get("status"));
            int before = shell.changes.size();
            try { control.run("close","tv.user;reboot"); fail(); } catch (IllegalArgumentException expected) { }
            assertEquals(before,shell.changes.size());
        }
    }
    @Test public void refusalsAndOtherUserCannotLookSuccessful() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var context = controller.get(); install(context,"tv.user",true,0,false);
            var shell = new Shell(); shell.tasks.put(1,"tv.user"); shell.refuseStop = true;
            var control = new RecentAppsControl(context,shell);
            assertEquals("partial",control.run("closeAll",null).get("status"));
            shell.user = "10"; int before = shell.changes.size();
            try { control.run("closeAll",null); fail(); } catch (IllegalStateException expected) { }
            assertEquals(before,shell.changes.size());
        }
    }
    @Test public void asynchronousRemovalConvergesWithoutFalseFailure() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var context = controller.get(); install(context,"tv.user",true,0,false);
            var shell = new Shell(); shell.tasks.put(1,"tv.user"); shell.delayRemoval = true;
            assertEquals("success",new RecentAppsControl(context,shell).run("close","tv.user").get("status"));
            assertFalse(shell.tasks.containsValue("tv.user"));
        }
    }
}
