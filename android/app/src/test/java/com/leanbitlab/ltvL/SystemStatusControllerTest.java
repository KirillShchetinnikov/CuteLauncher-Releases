package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.ActivityManager;
import android.os.PowerManager;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;
import static org.robolectric.Shadows.shadowOf;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class SystemStatusControllerTest {
    @Test public void deniedDirectReadUsesFreshAdbCountersAndResetsAcrossSourcesAndFailures() {
        var controller = new SystemStatusController();
        var denied = (SystemStatusController.CpuReader) () -> { throw new SecurityException("denied"); };
        var first = (SystemStatusController.CpuReader) () -> "cpu 10 0 10 80 0 0 0 0";
        var next = (SystemStatusController.CpuReader) () -> "cpu 30 0 10 160 0 0 0 0";
        assertNull(controller.sampleCpu(1000, denied, first));
        assertEquals(20, controller.sampleCpu(6000, denied, next), .001);
        // Direct and ADB measurements must not be combined into one interval.
        assertNull(controller.sampleCpu(11000, next, () -> { fail("Unneeded ADB"); return null; }));
        assertNull(controller.sampleCpu(16000, denied, () -> null));
        assertNull(controller.sampleCpu(21000, denied, next));
        assertNull(controller.sampleCpu(41000, denied, next));
        controller.resetCpu();
        assertNull(controller.sampleCpu(46000, denied, next));
    }

    @Test public void malformedOrDeniedSourcesRemainUnknownAndDirectReadAvoidsAdb() {
        var controller = new SystemStatusController();
        var first = (SystemStatusController.CpuReader) () -> "cpu 10 0 10 80 0 0 0 0";
        var unused = (SystemStatusController.CpuReader) () -> { fail("Unneeded ADB"); return null; };
        assertNull(controller.sampleCpu(1000, first, unused));
        assertEquals(0, controller.sampleCpu(6000, () -> "cpu 10 0 10 180 0 0 0 0", unused), .001);
        assertNull(controller.sampleCpu(11000, () -> "cpu invalid", () -> "Permission denied"));
        assertNull(controller.sampleCpu(16000, () -> null, () -> { throw new java.io.IOException(); }));
    }

    @Test public void adbFallbackRequiresSavedVerificationAndKeysWithoutCreatingThem() throws Exception {
        try (var lifecycle = Robolectric.buildActivity(Activity.class).setup()) {
            var context = lifecycle.get();
            var worker = java.util.concurrent.Executors.newSingleThreadExecutor();
            try {
                var saved = context.getSharedPreferences("adb_connection", 0);
                saved.edit().clear().commit();
                var reader = new SystemCpuAdb();
                assertNull(worker.submit(() -> reader.read(context)).get(2, java.util.concurrent.TimeUnit.SECONDS));
                assertFalse(saved.contains("connection_snapshot"));
                saved.edit().putString("connection_snapshot", "{\"status\":\"ready\"}").commit();
                assertNull(worker.submit(() -> reader.read(context)).get(2, java.util.concurrent.TimeUnit.SECONDS));
                assertFalse(new java.io.File(context.getNoBackupFilesDir(), "adb/private-key").exists());
                assertFalse(new java.io.File(context.getNoBackupFilesDir(), "adb/public-key").exists());
            } finally { worker.shutdownNow(); }
        }
    }

    @Test public void cpuUsesCounterDeltasAndDoesNotDoubleCountGuestTime() {
        long[] first = SystemStatusController.parseCpu("cpu  10 0 10 80 0 0 0 0 10 0");
        long[] next = SystemStatusController.parseCpu("cpu  30 0 10 160 0 0 0 0 30 0");
        assertEquals(100, first[0]);
        assertEquals(20, SystemStatusController.cpuPercent(first, next), .001);
        assertNull(SystemStatusController.cpuPercent(null, next));
        assertNull(SystemStatusController.cpuPercent(next, first));
        assertNull(SystemStatusController.cpuPercent(first, first));
        assertNull(SystemStatusController.parseCpu("cpu0 1 2 3 4"));
        assertNull(SystemStatusController.parseCpu("cpu 1 -1 2 3"));
    }
    @Test public void snapshotUsesAvailableMemoryAndSkipsReadingsWhenScreenOff() {
        try (var lifecycle = Robolectric.buildActivity(Activity.class).setup()) {
            var context = lifecycle.get();
            var memory = new ActivityManager.MemoryInfo();
            memory.totalMem = 2048; memory.availMem = 768;
            shadowOf(context.getSystemService(ActivityManager.class)).setMemoryInfo(memory);
            var controller = new SystemStatusController();
            var state = controller.snapshot(context);
            assertEquals(2048L, state.get("ramTotalBytes"));
            assertEquals(768L, state.get("ramAvailableBytes"));
            assertTrue(state.containsKey("uptimeMinutes"));
            shadowOf(context.getSystemService(PowerManager.class)).setIsInteractive(false);
            state = controller.snapshot(context);
            assertEquals(false, state.get("screenOn"));
            assertFalse(state.containsKey("cpuPercent"));
            assertFalse(state.containsKey("ramTotalBytes"));
        }
    }
}
