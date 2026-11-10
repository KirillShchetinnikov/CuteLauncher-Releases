package com.leanbitlab.ltvL;

import android.content.ComponentName;
import android.content.ActivityNotFoundException;
import android.content.ContextWrapper;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.media.tv.TvContract;
import android.provider.Settings;
import java.util.List;
import java.util.Map;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.Shadows;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class RemoteTvActionsTest {
    @Test public void explicitSettingsRoutesPreferXiaomiPictureAndRecoverMissingSystemAction() {
        var context = RuntimeEnvironment.getApplication();
        var packages = Shadows.shadowOf(context.getPackageManager());
        var info = new PackageInfo();
        info.packageName = RemoteTvActions.TV_SETTINGS.getPackageName();
        info.applicationInfo = new ApplicationInfo();
        info.applicationInfo.packageName = info.packageName;
        info.applicationInfo.flags = ApplicationInfo.FLAG_SYSTEM;
        info.applicationInfo.enabled = true;
        info.activities = new ActivityInfo[2];
        int i = 0;
        for (var component : List.of(RemoteTvActions.TV_SETTINGS, RemoteTvActions.XIAOMI_PICTURE_SETTINGS)) {
            var activity = new ActivityInfo();
            activity.applicationInfo = info.applicationInfo;
            activity.packageName = component.getPackageName();
            activity.name = component.getClassName();
            activity.enabled = true;
            activity.exported = true;
            info.activities[i++] = activity;
        }
        packages.installPackage(info);
        var started = new java.util.ArrayList<Intent>();
        var caller = new ContextWrapper(context) {
            @Override public void startActivity(Intent intent) {
                if (Settings.ACTION_SETTINGS.equals(intent.getAction())) throw new ActivityNotFoundException();
                started.add(intent);
            }
        };
        assertTrue(RemoteTvActions.open(caller, "display_settings"));
        assertEquals(RemoteTvActions.XIAOMI_PICTURE_SETTINGS, started.get(0).getComponent());
        assertTrue(RemoteTvActions.openSettings(caller));
        assertEquals(RemoteTvActions.TV_SETTINGS, started.get(1).getComponent());
    }

    @Test public void settingsUseOnlyAccessibleSystemHandlers() {
        var context = RuntimeEnvironment.getApplication();
        var packages = Shadows.shadowOf(context.getPackageManager());
        var wifi = new Intent(Settings.ACTION_WIFI_SETTINGS);
        var other = TvCleanerHandlersTest.handler("vendor.untrusted");
        var hidden = TvCleanerHandlersTest.handler("vendor.private");
        hidden.activityInfo.exported = false;
        hidden.activityInfo.applicationInfo.flags = ApplicationInfo.FLAG_SYSTEM;
        packages.addResolveInfoForIntent(wifi, other);
        packages.addResolveInfoForIntent(wifi, hidden);
        assertFalse(RemoteTvActions.available(context).contains("wifi_settings"));
        assertFalse(RemoteTvActions.open(context, "wifi_settings"));

        var handler = TvCleanerHandlersTest.handler("vendor.settings");
        handler.activityInfo.applicationInfo.flags = ApplicationInfo.FLAG_SYSTEM;
        packages.addResolveInfoForIntent(wifi, handler);
        assertTrue(RemoteTvActions.available(context).contains("wifi_settings"));
        assertTrue(RemoteTvActions.open(context, "wifi_settings"));
        var started = Shadows.shadowOf(context).getNextStartedActivity();
        assertEquals(new ComponentName(handler.activityInfo.packageName, handler.activityInfo.name),
            started.getComponent());
        assertEquals(Settings.ACTION_WIFI_SETTINGS, started.getAction());
        assertEquals(Intent.FLAG_ACTIVITY_NEW_TASK, started.getFlags());
    }

    @Test public void tvUsesChannelListAndHdmiRejectsMissingInput() {
        var context = RuntimeEnvironment.getApplication();
        assertEquals(TvContract.Channels.CONTENT_TYPE, RemoteTvActions.request("live_tv").getType());
        assertFalse(TvInputLaunch.openHdmi(context, "vendor.tv/.Input/HW1"));
        assertNull(Shadows.shadowOf(context).getNextStartedActivity());
    }

    @Test public void hdmiTargetRoundTripsAndSettingsRejectTargets() {
        var config = config("hdmi", "vendor.tv/.Input/HW1");
        assertEquals("vendor.tv/.Input/HW1", RemoteMappingConfiguration.fromMap(config.toMap())
            .binding(190).target());
        for (String invalid : List.of("", " ", "vendor\ninput", "a".repeat(513))) {
            assertThrows(IllegalArgumentException.class, () -> config("hdmi", invalid));
        }
        for (String action : List.of("live_tv", "display_settings", "wifi_settings", "bluetooth_settings", "mute")) {
            assertEquals(action, config(action, "").binding(190).action());
            assertThrows(IllegalArgumentException.class, () -> config(action, "vendor.tv"));
        }
    }

    private static RemoteMappingConfiguration config(String action, String target) {
        return RemoteMappingConfiguration.fromMap(Map.of("enabled", true, "bindings", List.of(
            Map.of("keyCode", 190, "enabled", true, "action", action, "target", target))));
    }
}
