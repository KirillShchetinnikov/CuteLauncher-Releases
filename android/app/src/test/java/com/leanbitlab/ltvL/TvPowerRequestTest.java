package com.leanbitlab.ltvL;

import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.os.Looper;
import android.os.PowerManager;
import android.view.KeyEvent;
import android.view.WindowManager;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.Robolectric;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.Shadows;
import org.robolectric.annotation.Config;
import org.robolectric.shadows.ShadowAlertDialog;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class TvPowerRequestTest {
    @Test public void remapperExecutesPowerOnlyAfterConfirmationWithoutFlutter() throws Exception {
        var service = Robolectric.buildService(LauncherAccessibilityService.class).get();
        Shadows.shadowOf(service.getSystemService(PowerManager.class)).setIsInteractive(false);
        try (var remapper = new RemoteButtonRemapper(service)) {
            RemoteButtonRemapper.editing = false;
            for (String action : List.of("sleep", "reboot")) {
                boolean reboot = action.equals("reboot");
                var binding = new RemoteMappingConfiguration.Binding(4137, true, action, "", reboot ? "hold" : "press");
                RemoteButtonRemapper.updated(new RemoteMappingConfiguration(true, Map.of(binding.slot(), binding)));
                press(remapper, 100, reboot ? RemoteMappingPolicy.HOLD_MS : 10);
                var dialog = ShadowAlertDialog.getLatestAlertDialog();
                assertTrue(dialog.isShowing());
                assertEquals(WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY, dialog.getWindow().getAttributes().type);
                assertTrue(dialog.getButton(DialogInterface.BUTTON_NEGATIVE).hasFocus());
                assertEquals("idle", RemoteButtonRemapper.status);
                dialog.getButton(DialogInterface.BUTTON_POSITIVE).performClick();
                assertEquals(reboot ? "unavailable" : "success", powerResult());
            }
        }
    }

    @Test public void immediateMappingsRunWithoutOpeningAConfirmation() throws Exception {
        var service = Robolectric.buildService(LauncherAccessibilityService.class).get();
        Shadows.shadowOf(service.getSystemService(PowerManager.class)).setIsInteractive(false);
        try (var remapper = new RemoteButtonRemapper(service)) {
            RemoteButtonRemapper.editing = false;
            for (String action : List.of("sleep_immediate", "reboot_immediate")) {
                boolean reboot = action.equals("reboot_immediate");
                var binding = new RemoteMappingConfiguration.Binding(4137, true, action, "", reboot ? "hold" : "press");
                RemoteButtonRemapper.updated(new RemoteMappingConfiguration(true, Map.of(binding.slot(), binding)));
                press(remapper, 100, reboot ? RemoteMappingPolicy.HOLD_MS : 10);
                assertNull(ShadowAlertDialog.getLatestAlertDialog());
                assertEquals(reboot ? "unavailable" : "success", powerResult());
                assertNull(ShadowAlertDialog.getLatestAlertDialog());
            }
        }
    }

    @Test public void cancelBackAndScreenOffDropThePendingAction() {
        var service = Robolectric.buildService(LauncherAccessibilityService.class).get();
        service.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .edit().putString("flutter.app_language", "ru").apply();
        var binding = new RemoteMappingConfiguration.Binding(4137, true, "reboot", "");
        try (var remapper = new RemoteButtonRemapper(service)) {
            RemoteButtonRemapper.editing = false;
            RemoteButtonRemapper.updated(new RemoteMappingConfiguration(true, Map.of(binding.slot(), binding)));

            press(remapper, 100, 10);
            var dialog = ShadowAlertDialog.getLatestAlertDialog();
            assertEquals("Перезагрузить устройство",
                dialog.getButton(DialogInterface.BUTTON_POSITIVE).getText().toString());
            assertFalse(remapper.event(new KeyEvent(200, 200, KeyEvent.ACTION_DOWN, 4137, 0)));
            assertFalse(remapper.event(new KeyEvent(200, 210, KeyEvent.ACTION_UP, 4137, 0)));
            assertSame(dialog, ShadowAlertDialog.getLatestAlertDialog());
            dialog.getButton(DialogInterface.BUTTON_NEGATIVE).performClick();
            Shadows.shadowOf(Looper.getMainLooper()).idle();
            assertFalse(remapper.confirmingPower());
            assertEquals("idle", RemoteButtonRemapper.status);

            press(remapper, 300, 10);
            ShadowAlertDialog.getLatestAlertDialog().onBackPressed();
            assertFalse(remapper.confirmingPower());
            assertEquals("idle", RemoteButtonRemapper.status);

            press(remapper, 400, 10);
            dialog = ShadowAlertDialog.getLatestAlertDialog();
            service.sendBroadcast(new Intent(Intent.ACTION_SCREEN_OFF));
            Shadows.shadowOf(Looper.getMainLooper()).idle();
            assertFalse(remapper.confirmingPower());
            dialog.getButton(DialogInterface.BUTTON_POSITIVE).performClick();
            Shadows.shadowOf(Looper.getMainLooper()).idle();
            assertEquals("idle", RemoteButtonRemapper.status);
        }
    }

    private static void press(RemoteButtonRemapper remapper, long time, long duration) {
        assertTrue(remapper.event(new KeyEvent(time, time, KeyEvent.ACTION_DOWN, 4137, 0)));
        assertTrue(remapper.event(new KeyEvent(time, time + duration, KeyEvent.ACTION_UP, 4137, 0)));
    }

    private static String powerResult() throws InterruptedException {
        Shadows.shadowOf(Looper.getMainLooper()).idle();
        for (int i = 0; i < 200 && RemoteButtonRemapper.status.equals("busy"); i++) {
            Thread.sleep(10);
            Shadows.shadowOf(Looper.getMainLooper()).idle();
        }
        return RemoteButtonRemapper.status;
    }

    @Test public void powerMappingsRoundTripAndRejectTargets() {
        for (String action : List.of("sleep", "sleep_immediate", "reboot", "reboot_immediate")) {
            for (String trigger : List.of("press", "hold")) {
                var row = Map.of("keyCode", 4137, "enabled", true, "action", action, "target", "", "trigger", trigger);
                var config = RemoteMappingConfiguration.fromMap(Map.of("enabled", true, "bindings", List.of(row)));
                assertEquals(action, RemoteMappingConfiguration.fromMap(config.toMap()).binding(4137, trigger).action());
                var invalid = Map.of("keyCode", 4137, "enabled", true, "action", action, "target", "shell command", "trigger", trigger);
                assertThrows(IllegalArgumentException.class, () -> RemoteMappingConfiguration.fromMap(
                    Map.of("enabled", true, "bindings", List.of(invalid))));
            }
        }
    }

    @Test public void sleepingScreenDoesNotWakeOrRequireAdb() {
        Context context = RuntimeEnvironment.getApplication();
        Shadows.shadowOf(context.getSystemService(PowerManager.class)).setIsInteractive(false);
        var worker = Executors.newSingleThreadExecutor();
        worker.shutdown(); // Sleep succeeds without submitting work, even without ADB keys.
        var results = new ArrayList<String>();
        TvPowerBridge.request(context, false, worker, results::add);
        assertEquals(List.of("success"), results);
    }

    @Test public void rejectedWorkerAndMissingAdbReleaseGuard() throws Exception {
        Context context = RuntimeEnvironment.getApplication();
        var rejected = Executors.newSingleThreadExecutor(); rejected.shutdown();
        var results = new ArrayList<String>();
        TvPowerBridge.request(context, true, rejected, results::add);
        assertEquals(List.of("busy"), results);
        var worker = Executors.newSingleThreadExecutor();
        try {
            // Keep the request pending until the worker and main callback have completed.
            TvPowerBridge.request(context, true, worker, results::add);
            TvPowerBridge.request(context, true, worker, results::add);
            worker.shutdown(); assertTrue(worker.awaitTermination(5, TimeUnit.SECONDS));
            Shadows.shadowOf(Looper.getMainLooper()).idle();
            assertEquals(List.of("busy", "busy", "unavailable"), results);
            TvPowerBridge.request(context, true, rejected, results::add);
            assertEquals("busy", results.get(3));
        } finally { worker.shutdownNow(); }
    }
}
