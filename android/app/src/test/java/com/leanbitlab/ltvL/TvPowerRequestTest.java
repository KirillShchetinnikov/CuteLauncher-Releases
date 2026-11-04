package com.leanbitlab.ltvL;

import android.content.Context;
import android.os.Looper;
import android.os.PowerManager;
import android.view.KeyEvent;
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
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class TvPowerRequestTest {
    @Test public void remapperExecutesPowerWithoutFlutter() throws Exception {
        var service = Robolectric.buildService(LauncherAccessibilityService.class).get();
        Shadows.shadowOf(service.getSystemService(PowerManager.class)).setIsInteractive(false);
        try (var remapper = new RemoteButtonRemapper(service)) {
            RemoteButtonRemapper.editing = false;
            for (String action : List.of("sleep", "reboot")) {
                var binding = new RemoteMappingConfiguration.Binding(4137, true, action, "");
                RemoteButtonRemapper.updated(new RemoteMappingConfiguration(true, Map.of(binding.slot(), binding)));
                assertTrue(remapper.event(new KeyEvent(100, 100, KeyEvent.ACTION_DOWN, 4137, 0)));
                assertTrue(remapper.event(new KeyEvent(100, 110, KeyEvent.ACTION_UP, 4137, 0)));
                for (int i = 0; i < 200 && RemoteButtonRemapper.status.equals("busy"); i++) {
                    Thread.sleep(10);
                    Shadows.shadowOf(Looper.getMainLooper()).idle();
                }
                assertEquals(action.equals("sleep") ? "success" : "unavailable", RemoteButtonRemapper.status);
            }
        }
    }

    @Test public void powerMappingsRoundTripAndRejectTargets() {
        for (String action : List.of("sleep", "reboot")) {
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
