package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.ActivityManager;
import android.os.PowerManager;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;
import static org.robolectric.Shadows.shadowOf;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class SystemStatusControllerTest {
    @Rule public final TemporaryFolder temporary = new TemporaryFolder();

    @Test public void temperatureUsesOnlyCurrentCpuReadingsAndKeepsPrecision() {
        assertEquals(62.875, SystemCpuTemperature.parseDump(
                "CPU temperatures: [41.125, -3.4028235E38, NaN, 62.875, 1000, Infinity]"), .001);
        assertNull(SystemCpuTemperature.parseDump("CPU throttling temperatures: [90.0]"));
        assertNull(SystemCpuTemperature.parseDump("GPU temperatures: [53.0]"));
        assertNull(SystemCpuTemperature.parseDump("CPU temperatures: []"));
        assertNull(SystemCpuTemperature.parseDump("CPU temperatures: [-3.4028235E38, unknown]"));
        assertNull(SystemCpuTemperature.parseDump("Permission Denial"));
        assertNull(SystemCpuTemperature.parseDump("CPU temperatures: [53.0"));
    }

    @Test public void thermalZonesReadNamedCpuSensorsAndRetryUnavailableSensors() throws Exception {
        Path root = temporary.newFolder().toPath();
        Path first = thermalZone(root, 0, "cpu-thermal", "41250");
        Path second = thermalZone(root, 1, "cpu0-silver", "62875");
        thermalZone(root, 2, "gpu-thermal", "90000");
        thermalZone(root, 3, "battery", "92000");
        thermalZone(root, 4, "cpu-cooling", "94000");
        thermalZone(root, 5, "cpu1", "63");
        var temperature = new SystemCpuTemperature(root.toFile());
        assertEquals(62.875, temperature.readThermalZones(0), .001);
        writeSensor(first, "72000");
        assertEquals(72, temperature.readThermalZones(1000), .001);
        Files.delete(first);
        writeSensor(second, "unavailable");
        assertNull(temperature.readThermalZones(2000));
        writeSensor(second, "42000");
        assertNull(temperature.readThermalZones(3000));
        assertEquals(42, temperature.readThermalZones(60_000), .001);
    }

    private static Path thermalZone(Path root, int index, String type, String temperature) throws Exception {
        Path zone = Files.createDirectory(root.resolve("thermal_zone" + index));
        writeSensor(zone.resolve("type"), type);
        return writeSensor(zone.resolve("temp"), temperature);
    }

    private static Path writeSensor(Path file, String value) throws Exception {
        return Files.write(file, value.getBytes(StandardCharsets.UTF_8));
    }
    @Test public void ramSnapshotRejectsImpossibleReadingsWithoutAdb() {
        try (var lifecycle = Robolectric.buildActivity(Activity.class).setup()) {
            var context = lifecycle.get();
            var info = new ActivityManager.MemoryInfo();
            info.totalMem = 2048L * 1024 * 1024;
            info.availMem = 512L * 1024 * 1024;
            var manager = shadowOf(context.getSystemService(ActivityManager.class));
            manager.setMemoryInfo(info);
            assertEquals(info.totalMem, SystemStatusController.ramSnapshot(context).get("ramTotalBytes"));
            assertEquals(info.availMem, SystemStatusController.ramSnapshot(context).get("ramAvailableBytes"));
            info.availMem = info.totalMem + 1;
            manager.setMemoryInfo(info);
            assertTrue(SystemStatusController.ramSnapshot(context).isEmpty());
            info.totalMem = 0; info.availMem = 0;
            manager.setMemoryInfo(info);
            assertTrue(SystemStatusController.ramSnapshot(context).isEmpty());
        }
    }
    @Test public void deniedDirectReadUsesFreshAdbCountersAndResetsAcrossSourcesAndFailures() {
        var controller = new SystemStatusController();
        var first = SystemStatusController.parseCpu("cpu 10 0 10 80 0 0 0 0");
        var next = SystemStatusController.parseCpu("cpu 30 0 10 160 0 0 0 0");
        assertNull(controller.sampleCpu(1000, null, first));
        assertEquals(20, controller.sampleCpu(6000, null, next), .001);
        // Direct and ADB measurements must not be combined into one interval.
        assertNull(controller.sampleCpu(11000, next, null));
        assertNull(controller.sampleCpu(16000, null, null));
        assertNull(controller.sampleCpu(21000, null, next));
        assertNull(controller.sampleCpu(41000, null, next));
        controller.resetCpu();
        assertNull(controller.sampleCpu(46000, null, next));
    }

    @Test public void malformedOrDeniedSourcesRemainUnknownAndDirectCountersTakePriority() {
        var controller = new SystemStatusController();
        var first = SystemStatusController.parseCpu("cpu 10 0 10 80 0 0 0 0");
        var next = SystemStatusController.parseCpu("cpu 10 0 10 180 0 0 0 0");
        assertNull(controller.sampleCpu(1000, first, next));
        assertEquals(0, controller.sampleCpu(6000, next, first), .001);
        assertNull(SystemStatusController.readCpu(() -> "cpu invalid"));
        assertNull(SystemStatusController.readCpu(() -> "Permission denied"));
        assertNull(SystemStatusController.readCpu(() -> { throw new java.io.IOException(); }));
    }

    @Test public void adbFallbackRequiresSavedVerificationAndKeysWithoutCreatingThem() throws Exception {
        try (var lifecycle = Robolectric.buildActivity(Activity.class).setup()) {
            var context = lifecycle.get();
            var worker = java.util.concurrent.Executors.newSingleThreadExecutor();
            try {
                var saved = context.getSharedPreferences("adb_connection", 0);
                saved.edit().clear().commit();
                var reader = new SystemCpuAdb();
                var result = worker.submit(() -> reader.read(context, 0, true, true))
                        .get(2, java.util.concurrent.TimeUnit.SECONDS);
                assertNull(result.counters());
                assertNull(result.temperature());
                assertFalse(saved.contains("connection_snapshot"));
                saved.edit().putString("connection_snapshot", "{\"status\":\"ready\"}").commit();
                result = worker.submit(() -> reader.read(context, 0, true, true))
                        .get(2, java.util.concurrent.TimeUnit.SECONDS);
                assertNull(result.counters());
                assertNull(result.temperature());
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
            assertFalse(state.containsKey("temperatureCelsius"));
        }
    }
}
