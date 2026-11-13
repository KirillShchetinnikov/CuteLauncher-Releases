package com.leanbitlab.ltvL;

import android.app.ActivityManager;
import android.content.Context;
import android.os.Environment;
import android.os.PowerManager;
import android.os.StatFs;
import android.os.SystemClock;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.util.HashMap;
import java.util.Map;

/** Read-only metrics; CPU can use the already-authorized localhost ADB connection. */
final class SystemStatusController {
    interface CpuReader { String read() throws Exception; }
    private final SystemCpuAdb adbCpu = new SystemCpuAdb();
    private final SystemCpuTemperature cpuTemperature = new SystemCpuTemperature(new File("/sys/class/thermal"));
    private long[] previousCpu;
    private long previousAt;
    private boolean previousAdb;

    static long[] parseCpu(String line) {
        if (line == null || !line.startsWith("cpu ")) return null;
        String[] fields = line.trim().split("\\s+");
        if (fields.length < 5) return null;
        long total = 0, idle = 0;
        // guest/guest_nice are already included in user/nice.
        for (int i = 1; i < Math.min(fields.length, 9); i++) {
            long value = Long.parseLong(fields[i]);
            if (value < 0) return null;
            total = Math.addExact(total, value);
            if (i == 4 || i == 5) idle = Math.addExact(idle, value);
        }
        return new long[]{total, idle};
    }

    static Double cpuPercent(long[] before, long[] after) {
        if (before == null || after == null) return null;
        long total = after[0] - before[0], idle = after[1] - before[1];
        if (total <= 0 || idle < 0 || idle > total) return null;
        return 100.0 * (total - idle) / total;
    }

    static long[] readCpu(CpuReader reader) {
        try { return parseCpu(reader.read()); }
        catch (Exception unavailable) { return null; }
    }

    Double sampleCpu(long now, long[] direct, long[] fallback) {
        long[] current = direct;
        boolean usingAdb = current == null;
        if (usingAdb) current = fallback;
        Double percent = now > previousAt && now - previousAt <= 15000 && usingAdb == previousAdb
                ? cpuPercent(previousCpu, current) : null;
        previousCpu = current;
        previousAdb = usingAdb;
        previousAt = now;
        return percent;
    }

    Map<String, Object> snapshot(Context context) {
        Map<String, Object> data = new HashMap<>();
        PowerManager power = context.getSystemService(PowerManager.class);
        boolean screenOn = power == null || power.isInteractive();
        data.put("screenOn", screenOn);
        if (!screenOn) { previousCpu = null; return data; }
        long now = SystemClock.elapsedRealtime();
        data.put("uptimeMinutes", now / 60000);
        long[] counters = readCpu(() -> {
            try (BufferedReader reader = new BufferedReader(new FileReader("/proc/stat"))) {
                return reader.readLine();
            }
        });
        Double temperature = cpuTemperature.sample(context, now);
        var adb = adbCpu.read(context, now, counters == null, temperature == null);
        data.put("cpuPercent", sampleCpu(now, counters, adb.counters()));
        if (temperature == null) temperature = adb.temperature();
        if (temperature != null) data.put("temperatureCelsius", temperature);
        data.putAll(ramSnapshot(context));
        try {
            StatFs disk = new StatFs(Environment.getDataDirectory().getPath());
            data.put("storageTotalBytes", disk.getTotalBytes());
            data.put("storageAvailableBytes", disk.getAvailableBytes());
        } catch (RuntimeException unavailable) { /* No fabricated free space. */ }
        return data;
    }

    static Map<String, Object> ramSnapshot(Context context) {
        Map<String, Object> data = new HashMap<>();
        try {
            ActivityManager manager = context.getSystemService(ActivityManager.class);
            if (manager != null) {
                ActivityManager.MemoryInfo memory = new ActivityManager.MemoryInfo();
                manager.getMemoryInfo(memory);
                if (memory.totalMem > 0 && memory.availMem >= 0 && memory.availMem <= memory.totalMem) {
                    data.put("ramTotalBytes", memory.totalMem);
                    data.put("ramAvailableBytes", memory.availMem);
                }
            }
        } catch (RuntimeException unavailable) { /* Independent metrics still work. */ }
        return data;
    }

    void resetCpu() { previousCpu = null; }
}
