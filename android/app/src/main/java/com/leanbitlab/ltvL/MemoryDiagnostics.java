package com.leanbitlab.ltvL;

import android.app.ActivityManager;
import android.content.Context;
import android.os.Build;
import android.os.Debug;
import java.io.BufferedReader;
import java.io.FileReader;
import java.util.HashMap;
import java.util.Map;

final class MemoryDiagnostics {
    static Map<String, Object> snapshot(Context context) {
        Map<String, Object> data = new HashMap<>();
        Debug.MemoryInfo process = new Debug.MemoryInfo();
        Debug.getMemoryInfo(process);
        data.put("pssBytes", process.getTotalPss() * 1024L);
        data.put("graphicsBytes", null);
        try {
            long graphicsKiB = Long.parseLong(process.getMemoryStat("summary.graphics"));
            if (graphicsKiB >= 0) data.put("graphicsBytes", graphicsKiB * 1024L);
        } catch (NumberFormatException ignored) { }
        data.put("rssBytes", null);
        try (BufferedReader reader = new BufferedReader(new FileReader("/proc/self/status"))) {
            String line;
            while ((line = reader.readLine()) != null) {
                if (line.startsWith("VmRSS:")) {
                    data.put("rssBytes", Long.parseLong(line.trim().split("\\s+")[1]) * 1024L);
                    break;
                }
            }
        } catch (Exception ignored) { }
        ActivityManager manager = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
        if (manager != null) {
            ActivityManager.MemoryInfo device = new ActivityManager.MemoryInfo();
            manager.getMemoryInfo(device);
            data.put("deviceRamBytes", device.totalMem);
            data.put("lowMemoryDevice", manager.isLowRamDevice());
        }
        data.put("model", Build.MODEL);
        data.put("android", Build.VERSION.RELEASE);
        data.put("measuredAtMillis", System.currentTimeMillis());
        // Dart heap/external require a profile VM service; they are not Android Java heap.
        return data;
    }
}
