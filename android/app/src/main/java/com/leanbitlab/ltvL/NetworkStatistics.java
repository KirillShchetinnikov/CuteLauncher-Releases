/*
 * FLauncher
 * Copyright (C) 2021  Oscar Rojas
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

package com.leanbitlab.ltvL;

import android.content.Context;
import android.app.AppOpsManager;
import android.app.usage.NetworkStats;
import android.app.usage.NetworkStatsManager;
import android.content.Intent;
import android.net.ConnectivityManager;
import android.net.NetworkCapabilities;
import android.provider.Settings;
import java.util.Map;
/** Native NetworkStatistics operations; channel names and payloads remain owned by MainActivity. */
final class NetworkStatistics {
    private final Context context;

    NetworkStatistics(Context context) { this.context = context; }

    Map<String, Object> getActiveNetworkInformation() {
        try {
            ConnectivityManager connectivityManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
            android.net.Network active = connectivityManager.getActiveNetwork();
            Map<String, Object> map = NetworkUtils.getNetworkInformation(context, active);
            NetworkCapabilities caps = active == null ? null : connectivityManager.getNetworkCapabilities(active);
            map.put("internetAccess", caps != null && caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED));
            android.net.LinkProperties links = active == null ? null : connectivityManager.getLinkProperties(active);
            if (links != null) {
                java.util.List<String> addresses = new java.util.ArrayList<>();
                for (android.net.LinkAddress address : links.getLinkAddresses()) {
                    addresses.add(address.getAddress().getHostAddress());
                }
                map.put("addresses", String.join("\n", addresses));
            }
            if (java.util.Objects.equals(map.get("networkType"), NetworkUtils.NETWORK_TYPE_WIFI)) {
                try {
                    android.net.wifi.WifiManager wifi = (android.net.wifi.WifiManager) context.getApplicationContext().getSystemService(Context.WIFI_SERVICE);
                    @SuppressWarnings("deprecation")
                    android.net.wifi.WifiInfo info = android.os.Build.VERSION.SDK_INT >= 29 && caps != null && caps.getTransportInfo() instanceof android.net.wifi.WifiInfo
                            ? (android.net.wifi.WifiInfo) caps.getTransportInfo() : (wifi == null ? null : wifi.getConnectionInfo());
                    if (info != null) {
                        String ssid = info.getSSID();
                        if (ssid != null && !"<unknown ssid>".equals(ssid)) map.put("ssid", ssid.replaceAll("^\"|\"$", ""));
                        if (info.getRssi() > -127 && info.getRssi() < 0) map.put("rssi", info.getRssi());
                        if (info.getLinkSpeed() > 0) map.put("linkSpeed", info.getLinkSpeed());
                        if (info.getFrequency() > 0) map.put("frequency", info.getFrequency());
                    }
                } catch (SecurityException ignored) {
                    // Wi-Fi identity can be redacted by Android without location access.
                }
            }
            map.put("rxBytes", android.net.TrafficStats.getTotalRxBytes());
            map.put("txBytes", android.net.TrafficStats.getTotalTxBytes());
            map.put("elapsedMs", android.os.SystemClock.elapsedRealtime());
            return map;
        } catch (Exception e) {
            e.printStackTrace();
            Map<String, Object> map = new java.util.HashMap<>();
            map.put(NetworkUtils.KEY_NETWORK_TYPE, NetworkUtils.NETWORK_TYPE_UNKNOWN);
            map.put(NetworkUtils.KEY_NETWORK_ACCESS, false);
            map.put(NetworkUtils.KEY_INTERNET_ACCESS, false);
            map.put(NetworkUtils.KEY_WIRELESS_SIGNAL_LEVEL, 0);
            return map;
        }
    }

    private int getActiveNetworkTransportType() {
        try {
            ConnectivityManager connectivityManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
            if (connectivityManager == null) return -1;
            
            android.net.Network activeNetwork = connectivityManager.getActiveNetwork();
            if (activeNetwork != null) {
                NetworkCapabilities capabilities = connectivityManager.getNetworkCapabilities(activeNetwork);
                if (capabilities != null) {
                    if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
                        return LegacyNetworkTypes.WIFI;
                    } else if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) {
                        return LegacyNetworkTypes.MOBILE;
                    } else if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)) {
                        return LegacyNetworkTypes.ETHERNET;
                    } else if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) {
                        return LegacyNetworkTypes.VPN;
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return -1;
    }

    long getDailyDataUsage() {
        return getDataUsage(java.util.Calendar.DAY_OF_YEAR);
    }

    long getWeeklyDataUsage() {
        return getDataUsage(java.util.Calendar.WEEK_OF_YEAR);
    }

    long getMonthlyDataUsage() {
        return getDataUsage(java.util.Calendar.MONTH);
    }

    java.util.Map<String, Long> getTrafficUsage(String period) {
        int interval = "weekly".equals(period) ? java.util.Calendar.WEEK_OF_YEAR
                : "monthly".equals(period) ? java.util.Calendar.MONTH : java.util.Calendar.DAY_OF_YEAR;
        return getDataUsageDetails(interval);
    }

    private long getDataUsage(int period) {
        return getDataUsageDetails(period).get("totalBytes");
    }

    private java.util.Map<String, Long> unavailableUsage(long code) {
        return java.util.Map.of("rxBytes", code, "txBytes", code, "totalBytes", code);
    }

    private java.util.Map<String, Long> getDataUsageDetails(int period) {
        if (!checkUsageStatsPermission()) return unavailableUsage(-1);
        var manager = (NetworkStatsManager) context.getSystemService(Context.NETWORK_STATS_SERVICE);
        if (manager == null) return unavailableUsage(NetworkUsageTotals.UNAVAILABLE);
        var calendar = java.util.Calendar.getInstance();
        if (period == java.util.Calendar.WEEK_OF_YEAR) {
            calendar.set(java.util.Calendar.DAY_OF_WEEK, calendar.getFirstDayOfWeek());
        } else if (period == java.util.Calendar.MONTH) {
            calendar.set(java.util.Calendar.DAY_OF_MONTH, 1);
        }
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0);
        calendar.set(java.util.Calendar.MINUTE, 0);
        calendar.set(java.util.Calendar.SECOND, 0);
        calendar.set(java.util.Calendar.MILLISECOND, 0);
        long start = calendar.getTimeInMillis(), end = System.currentTimeMillis();
        int[] types = {LegacyNetworkTypes.WIFI, LegacyNetworkTypes.MOBILE, LegacyNetworkTypes.ETHERNET};
        int[] transports = {NetworkCapabilities.TRANSPORT_WIFI, NetworkCapabilities.TRANSPORT_CELLULAR,
                NetworkCapabilities.TRANSPORT_ETHERNET};
        boolean[] required = new boolean[types.length];
        var connectivity = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
        if (connectivity != null) {
            // Include the physical connection under a VPN, rather than treating VPN as a fourth history.
            for (var network : connectivity.getAllNetworks()) {
                var caps = connectivity.getNetworkCapabilities(network);
                if (caps == null || !caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)) continue;
                for (int i = 0; i < transports.length; i++) {
                    required[i] |= caps.hasTransport(transports[i]);
                }
            }
        }
        long[] received = new long[types.length], sent = new long[types.length];
        for (int i = 0; i < types.length; i++) {
            received[i] = sent[i] = NetworkUsageTotals.UNAVAILABLE;
            try {
                var bucket = manager.querySummaryForDevice(types[i], null, start, end);
                if (bucket != null) {
                    received[i] = bucket.getRxBytes();
                    sent[i] = bucket.getTxBytes();
                }
            } catch (Exception ignored) {
                // A missing/unsupported transport is not a successful zero-byte query.
            }
        }
        if (received[2] < 0 || sent[2] < 0) {
            long[] ethernet = AdbEthernetUsage.readBreakdown(context, start, end);
            received[2] = ethernet[0]; sent[2] = ethernet[1];
        }
        long rx = NetworkUsageTotals.sum(received, required);
        long tx = NetworkUsageTotals.sum(sent, required);
        long total = NetworkUsageTotals.UNAVAILABLE;
        if (rx >= 0 && tx >= 0) {
            try { total = Math.addExact(rx, tx); } catch (ArithmeticException ignored) { }
        }
        return java.util.Map.of("rxBytes", rx, "txBytes", tx, "totalBytes", total,
                "startMs", start, "endMs", end);
    }

    boolean checkUsageStatsPermission() {
        AppOpsManager appOps = (AppOpsManager) context.getSystemService(Context.APP_OPS_SERVICE);
        int mode = appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(), context.getPackageName());

        if (mode == AppOpsManager.MODE_ALLOWED) {
            return true;
        }

        if (mode == AppOpsManager.MODE_DEFAULT) {
            try {
                NetworkStatsManager networkStatsManager = (NetworkStatsManager) context.getSystemService(Context.NETWORK_STATS_SERVICE);
                if (networkStatsManager != null) {
                    long now = System.currentTimeMillis();
                    networkStatsManager.querySummaryForDevice(LegacyNetworkTypes.WIFI, null, now - 1, now);
                    return true;
                }
            } catch (SecurityException e) {
                return false;
            } catch (Exception e) {
                return true;
            }
        }

        return false;
    }

    void requestUsageStatsPermission() {
        Intent intent = new Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS);
        tryStartActivity(intent);
    }

    private boolean tryStartActivity(Intent intent) {
        try {
            context.startActivity(intent);
            return true;
        } catch (Exception ignored) {
            return false;
        }
    }

}
