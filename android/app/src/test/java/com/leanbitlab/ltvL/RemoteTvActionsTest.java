package com.leanbitlab.ltvL;

import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
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
