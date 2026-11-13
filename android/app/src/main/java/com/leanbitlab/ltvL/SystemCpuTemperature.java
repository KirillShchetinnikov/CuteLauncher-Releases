package com.leanbitlab.ltvL;

import android.content.Context;
import android.os.HardwarePropertiesManager;
import androidx.annotation.Nullable;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.regex.Pattern;

/** Optional temperature sources for the existing system-status worker. */
final class SystemCpuTemperature {
    private static final long SOURCE_RETRY_MS = 60_000;
    private static final String DUMP_PREFIX = "CPU temperatures: [";
    private static final Pattern CPU_ZONE = Pattern.compile(
            "cpu[0-9]*(?:[-_](?:[0-9]+|thermal|temp|little|big|mid|silver|gold|prime))*"
                    + "|mtktscpu|x86_pkg_temp");
    private final File thermalRoot;
    private List<File> cpuSensors = List.of();
    private long discoverAfter;
    private long hardwareRetryAfter;

    SystemCpuTemperature(File thermalRoot) {
        this.thermalRoot = thermalRoot;
    }

    @Nullable Double sample(Context context, long now) {
        if (now >= hardwareRetryAfter) {
            Double temperature = readHardware(context);
            if (temperature != null) return temperature;
            hardwareRetryAfter = now + SOURCE_RETRY_MS;
        }
        return readThermalZones(now);
    }

    @Nullable private static Double readHardware(Context context) {
        try {
            HardwarePropertiesManager hardware = context.getSystemService(HardwarePropertiesManager.class);
            if (hardware == null) return null;
            Double hottest = null;
            for (float value : hardware.getDeviceTemperatures(
                    HardwarePropertiesManager.DEVICE_TEMPERATURE_CPU,
                    HardwarePropertiesManager.TEMPERATURE_CURRENT)) {
                hottest = hottestReading(hottest, value);
            }
            return hottest;
        } catch (RuntimeException unavailable) {
            return null;
        }
    }

    @Nullable Double readThermalZones(long now) {
        if (now >= discoverAfter) {
            cpuSensors = findCpuSensors();
            discoverAfter = now + SOURCE_RETRY_MS;
        }
        Double hottest = null;
        for (File sensor : cpuSensors) {
            String raw = readLine(sensor);
            if (raw == null) continue;
            try {
                // The Linux thermal sysfs ABI reports millidegrees Celsius.
                double value = Long.parseLong(raw) / 1000.0;
                // Skip sub-degree values that can come from unscaled or inactive vendor sensors.
                if (Math.abs(value) >= 1) hottest = hottestReading(hottest, value);
            } catch (NumberFormatException unavailable) { /* Ignore a malformed sensor. */ }
        }
        if (hottest == null) cpuSensors = List.of();
        return hottest;
    }

    private List<File> findCpuSensors() {
        List<File> sensors = new ArrayList<>();
        File[] zones;
        try {
            zones = thermalRoot.listFiles((dir, name) -> name.startsWith("thermal_zone"));
        } catch (SecurityException unavailable) {
            return sensors;
        }
        if (zones == null) return sensors;
        for (File zone : zones) {
            String type = readLine(new File(zone, "type"));
            if (type != null && CPU_ZONE.matcher(type.toLowerCase(Locale.ROOT)).matches()) {
                sensors.add(new File(zone, "temp"));
            }
        }
        return sensors;
    }

    @Nullable private static String readLine(File file) {
        try (BufferedReader reader = new BufferedReader(new FileReader(file))) {
            String line = reader.readLine();
            return line == null ? null : line.trim();
        } catch (IOException | SecurityException unavailable) {
            return null;
        }
    }

    @Nullable static Double parseDump(@Nullable String line) {
        if (line == null || !line.startsWith(DUMP_PREFIX) || !line.endsWith("]")) return null;
        Double hottest = null;
        for (String token : line.substring(DUMP_PREFIX.length(), line.length() - 1).split(",")) {
            try {
                hottest = hottestReading(hottest, Double.parseDouble(token.trim()));
            } catch (NumberFormatException unavailable) { /* Ignore a malformed sensor. */ }
        }
        return hottest;
    }

    @Nullable private static Double hottestReading(@Nullable Double hottest, double value) {
        if (!Double.isFinite(value) || value < -49 || value > 199) return hottest;
        return hottest == null ? value : Math.max(hottest, value);
    }
}
