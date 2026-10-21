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
import android.os.Build;
import android.provider.Settings;
import java.util.Map;
/** Native NetworkStatistics operations; channel names and payloads remain owned by MainActivity. */
final class NetworkStatistics {
    private final Context context;

    NetworkStatistics(Context context) { this.context = context; }

    Map<String, Object> getActiveNetworkInformation() {
        try {
            ConnectivityManager connectivityManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
            return NetworkUtils.getNetworkInformation(context, connectivityManager.getActiveNetwork());
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
        if (!checkUsageStatsPermission()) {
            return -1;
        }

        NetworkStatsManager networkStatsManager = (NetworkStatsManager) context.getSystemService(Context.NETWORK_STATS_SERVICE);
        if (networkStatsManager == null)
            return 0;



        java.util.Calendar calendar = java.util.Calendar.getInstance();
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0);
        calendar.set(java.util.Calendar.MINUTE, 0);
        calendar.set(java.util.Calendar.SECOND, 0);
        calendar.set(java.util.Calendar.MILLISECOND, 0);
        long startTime = calendar.getTimeInMillis();
        long endTime = System.currentTimeMillis();

        long totalBytes = 0;
        try {
            NetworkStats.Bucket wifiBucket = networkStatsManager.querySummaryForDevice(
                    LegacyNetworkTypes.WIFI,
                    null,
                    startTime,
                    endTime);
            if (wifiBucket != null) {
                totalBytes += wifiBucket.getRxBytes() + wifiBucket.getTxBytes();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        try {
            NetworkStats.Bucket mobileBucket = networkStatsManager.querySummaryForDevice(
                    LegacyNetworkTypes.MOBILE,
                    null,
                    startTime,
                    endTime);
            if (mobileBucket != null) {
                totalBytes += mobileBucket.getRxBytes() + mobileBucket.getTxBytes();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        try {
            NetworkStats.Bucket ethernetBucket = networkStatsManager.querySummaryForDevice(
                    LegacyNetworkTypes.ETHERNET,
                    null,
                    startTime,
                    endTime);
            if (ethernetBucket != null) {
                totalBytes += ethernetBucket.getRxBytes() + ethernetBucket.getTxBytes();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return totalBytes;
    }

    long getWeeklyDataUsage() {
        if (!checkUsageStatsPermission()) {
            return -1;
        }

        NetworkStatsManager networkStatsManager = (NetworkStatsManager) context.getSystemService(Context.NETWORK_STATS_SERVICE);
        if (networkStatsManager == null)
            return 0;



        java.util.Calendar calendar = java.util.Calendar.getInstance();
        calendar.set(java.util.Calendar.DAY_OF_WEEK, calendar.getFirstDayOfWeek());
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0);
        calendar.set(java.util.Calendar.MINUTE, 0);
        calendar.set(java.util.Calendar.SECOND, 0);
        calendar.set(java.util.Calendar.MILLISECOND, 0);
        long startTime = calendar.getTimeInMillis();
        long endTime = System.currentTimeMillis();

        long totalBytes = 0;
        try {
            NetworkStats.Bucket wifiBucket = networkStatsManager.querySummaryForDevice(
                    LegacyNetworkTypes.WIFI,
                    null,
                    startTime,
                    endTime);
            if (wifiBucket != null) {
                totalBytes += wifiBucket.getRxBytes() + wifiBucket.getTxBytes();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        try {
            NetworkStats.Bucket mobileBucket = networkStatsManager.querySummaryForDevice(
                    LegacyNetworkTypes.MOBILE,
                    null,
                    startTime,
                    endTime);
            if (mobileBucket != null) {
                totalBytes += mobileBucket.getRxBytes() + mobileBucket.getTxBytes();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        try {
            NetworkStats.Bucket ethernetBucket = networkStatsManager.querySummaryForDevice(
                    LegacyNetworkTypes.ETHERNET,
                    null,
                    startTime,
                    endTime);
            if (ethernetBucket != null) {
                totalBytes += ethernetBucket.getRxBytes() + ethernetBucket.getTxBytes();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return totalBytes;
    }

    long getMonthlyDataUsage() {
        if (!checkUsageStatsPermission()) {
            return -1;
        }

        NetworkStatsManager networkStatsManager = (NetworkStatsManager) context.getSystemService(Context.NETWORK_STATS_SERVICE);
        if (networkStatsManager == null)
            return 0;



        java.util.Calendar calendar = java.util.Calendar.getInstance();
        calendar.set(java.util.Calendar.DAY_OF_MONTH, 1);
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0);
        calendar.set(java.util.Calendar.MINUTE, 0);
        calendar.set(java.util.Calendar.SECOND, 0);
        calendar.set(java.util.Calendar.MILLISECOND, 0);
        long startTime = calendar.getTimeInMillis();
        long endTime = System.currentTimeMillis();

        long totalBytes = 0;
        try {
            NetworkStats.Bucket wifiBucket = networkStatsManager.querySummaryForDevice(
                    LegacyNetworkTypes.WIFI,
                    null,
                    startTime,
                    endTime);
            if (wifiBucket != null) {
                totalBytes += wifiBucket.getRxBytes() + wifiBucket.getTxBytes();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        try {
            NetworkStats.Bucket mobileBucket = networkStatsManager.querySummaryForDevice(
                    LegacyNetworkTypes.MOBILE,
                    null,
                    startTime,
                    endTime);
            if (mobileBucket != null) {
                totalBytes += mobileBucket.getRxBytes() + mobileBucket.getTxBytes();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        try {
            NetworkStats.Bucket ethernetBucket = networkStatsManager.querySummaryForDevice(
                    LegacyNetworkTypes.ETHERNET,
                    null,
                    startTime,
                    endTime);
            if (ethernetBucket != null) {
                totalBytes += ethernetBucket.getRxBytes() + ethernetBucket.getTxBytes();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return totalBytes;
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
