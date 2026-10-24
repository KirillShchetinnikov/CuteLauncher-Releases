package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.Instrumentation;
import android.app.usage.NetworkStats;
import android.app.usage.NetworkStatsManager;
import android.content.Context;
import android.os.Bundle;
import org.json.JSONArray;
import org.json.JSONObject;

/** Read-only comparison of public traffic APIs under the launcher's UID. */
public final class NetworkUsageProbe extends Instrumentation {
    private boolean verifyEthernet;
    @Override public void onCreate(Bundle args) {
        super.onCreate(args);
        verifyEthernet = args != null && "true".equals(args.getString("verifyEthernet"));
        start();
    }
    @Override public void onStart() {
        JSONArray rows = new JSONArray();
        boolean passed = true;
        try {
            var manager = (NetworkStatsManager) getTargetContext().getSystemService(Context.NETWORK_STATS_SERVICE);
            var calendar = java.util.Calendar.getInstance();
            calendar.set(java.util.Calendar.HOUR_OF_DAY, 0);
            calendar.set(java.util.Calendar.MINUTE, 0);
            calendar.set(java.util.Calendar.SECOND, 0);
            calendar.set(java.util.Calendar.MILLISECOND, 0);
            long start = calendar.getTimeInMillis(), end = System.currentTimeMillis();
            if (verifyEthernet) {
                var statistics = new NetworkStatistics(getTargetContext());
                long daily = statistics.getDailyDataUsage();
                long weekly = statistics.getWeeklyDataUsage();
                long monthly = statistics.getMonthlyDataUsage();
                rows.put(new JSONObject().put("nativeDaily", daily).put("nativeWeekly", weekly)
                        .put("nativeMonthly", monthly));
                if (daily < 0 || weekly < daily || monthly < daily)
                    throw new AssertionError("Ethernet period history not available");
            }
            for (int type : new int[]{1, 0, 9}) {
                for (String api : new String[]{"device", "user", "summary"}) {
                    JSONObject row = new JSONObject().put("type", type).put("api", api);
                    try {
                        long bytes = -1;
                        if (api.equals("summary")) {
                            try (NetworkStats stats = manager.querySummary(type, null, start, end)) {
                                if (stats != null) {
                                    bytes = 0;
                                    var bucket = new NetworkStats.Bucket();
                                    while (stats.hasNextBucket()) {
                                        stats.getNextBucket(bucket);
                                        bytes += bucket.getRxBytes() + bucket.getTxBytes();
                                    }
                                }
                            }
                        } else {
                            var bucket = api.equals("device")
                                ? manager.querySummaryForDevice(type, null, start, end)
                                : manager.querySummaryForUser(type, null, start, end);
                            if (bucket != null) bytes = bucket.getRxBytes() + bucket.getTxBytes();
                        }
                        row.put("bytes", bytes);
                    } catch (Throwable error) { row.put("error", error.toString()); }
                    rows.put(row);
                }
            }
        } catch (Throwable error) { passed = false; rows.put(error.toString()); }
        Bundle report = new Bundle(); report.putString("stream", "\n" + rows + "\n");
        finish(passed ? Activity.RESULT_OK : Activity.RESULT_CANCELED, report);
    }
}
