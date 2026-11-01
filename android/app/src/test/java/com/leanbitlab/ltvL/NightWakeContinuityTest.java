package com.leanbitlab.ltvL;

import android.app.AppOpsManager;
import android.os.PowerManager;
import android.os.Process;
import android.view.View;
import java.lang.reflect.Field;
import org.json.JSONArray;
import org.json.JSONObject;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.Shadows;
import org.robolectric.annotation.Config;
import org.robolectric.shadows.ShadowSettings;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class NightWakeContinuityTest {
    private static Field field(String name) throws Exception {
        Field field = NightOverlayService.class.getDeclaredField(name);
        field.setAccessible(true);
        return field;
    }

    private static void refresh(NightOverlayService service) throws Exception {
        var refresh = NightOverlayService.class.getDeclaredMethod("refresh");
        refresh.setAccessible(true);
        refresh.invoke(service);
    }

    private static JSONObject configure(NightOverlayService service) throws Exception {
        ShadowSettings.setCanDrawOverlays(true);
        Shadows.shadowOf(service.getSystemService(AppOpsManager.class)).setMode(
            AppOpsManager.OPSTR_SYSTEM_ALERT_WINDOW, Process.myUid(),
            service.getPackageName(), AppOpsManager.MODE_ALLOWED);
        JSONObject config = new JSONObject().put("enabled", true).put("scheduled", false)
            .put("temperature", 2700).put("dim", 40)
            .put("warmth", 0).put("tclScheduled", false).put("ignoreHdmiInputs", false);
        field("config").set(service, config);
        Shadows.shadowOf(service.getSystemService(PowerManager.class)).setIsInteractive(true);
        return config;
    }

    @Test public void sleepAndWakeKeepTheSameAttachedFilter() throws Exception {
        var controller = Robolectric.buildService(NightOverlayService.class).create();
        try {
            var service = controller.get();
            configure(service);
            refresh(service);
            View window = (View) field("overlay").get(service);
            assertNotNull(window);
            var power = Shadows.shadowOf(service.getSystemService(PowerManager.class));
            for (int cycle = 0; cycle < 3; cycle++) {
                power.setIsInteractive(false);
                refresh(service);
                assertSame(window, field("overlay").get(service));
                assertTrue((Boolean) NightOverlayService.status(service,
                    (JSONObject) field("config").get(service)).get("visible"));
                power.setIsInteractive(true);
                refresh(service);
                assertSame(window, field("overlay").get(service));
            }
        } finally { controller.destroy(); }
    }

    @Test public void excludedSourceStaysExcludedWhileAsleepAndAwaitingWakeRead() throws Exception {
        var controller = Robolectric.buildService(NightOverlayService.class).create();
        try {
            var service = controller.get();
            JSONObject config = configure(service);
            // Exercise app exclusions without picture-mode exclusions.
            config.put("excludedPackages", new JSONArray().put("example.player"));
            Shadows.shadowOf(service.getSystemService(AppOpsManager.class)).setMode(
                AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(),
                service.getPackageName(), AppOpsManager.MODE_ALLOWED);
            field("tracking").set(service, true);
            field("trackingReady").set(service, true);
            field("trackedConfiguration").set(service, config);
            field("excluded").set(service, true);
            var power = Shadows.shadowOf(service.getSystemService(PowerManager.class));
            power.setIsInteractive(false);
            refresh(service);
            assertEquals(true, field("excluded").get(service));
            assertNull(field("overlay").get(service));
            power.setIsInteractive(true);
            refresh(service);
            assertEquals(true, field("tracking").get(service));
            assertEquals(false, field("trackingReady").get(service));
            assertEquals(true, field("excluded").get(service));
            assertNull(field("overlay").get(service));
        } finally { controller.destroy(); }
    }

    @Test public void disablingWhileAsleepStillRemovesTheFilter() throws Exception {
        var controller = Robolectric.buildService(NightOverlayService.class).create();
        try {
            var service = controller.get();
            JSONObject config = configure(service);
            refresh(service);
            assertNotNull(field("overlay").get(service));
            Shadows.shadowOf(service.getSystemService(PowerManager.class)).setIsInteractive(false);
            config.put("enabled", false);
            refresh(service);
            assertNull(field("overlay").get(service));
        } finally { controller.destroy(); }
    }
}
