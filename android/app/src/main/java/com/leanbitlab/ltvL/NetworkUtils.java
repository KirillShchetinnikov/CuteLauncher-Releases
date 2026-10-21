package com.leanbitlab.ltvL;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.net.NetworkInfo;
import android.net.TelephonyNetworkSpecifier;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Build;
import android.telephony.TelephonyManager;

import androidx.annotation.Nullable;

import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

public class NetworkUtils
{
    // Aligned with NetworkType enum value indices, on file lib/providers/network_service.dart
    public static final int NETWORK_TYPE_CELLULAR = 0;
    public static final int NETWORK_TYPE_WIFI = 1;
    public static final int NETWORK_TYPE_VPN = 2;
    public static final int NETWORK_TYPE_WIRED = 3;
    public static final int NETWORK_TYPE_UNKNOWN = 4;

    public static final String KEY_INTERNET_ACCESS = "internetAccess";
    public static final String KEY_NETWORK_ACCESS = "networkAccess";
    public static final String KEY_NETWORK_TYPE = "networkType";
    public static final String KEY_WIRELESS_SIGNAL_LEVEL = "wirelessSignalLevel";
    public static final String KEY_VPN_ACTIVE = "vpnActive";

    public static Map<String, Object> getNetworkCapabilitiesInformation(Context context, NetworkCapabilities capabilities)
    {
        boolean hasNetworkAccess, hasInternetAccess;
        int wirelessNetworkSignalLevel = 0;
        int networkType = NETWORK_TYPE_UNKNOWN;
        boolean isVpnActive = capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN);

        hasNetworkAccess = capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET);
        hasInternetAccess = capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED);

        if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) {
            networkType = NETWORK_TYPE_CELLULAR;
        }
        else if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
            WifiManager wifiManager = (WifiManager) context
                    .getApplicationContext().getSystemService(Context.WIFI_SERVICE);

            if (capabilities.getTransportInfo() instanceof WifiInfo) {
                WifiInfo wifiInfo = (WifiInfo) capabilities.getTransportInfo();
                wirelessNetworkSignalLevel = getWifiSignalLevel(wifiInfo);
            }
            else {
                try {
                    if (wifiManager != null) {
                        WifiInfo wifiInfo = legacyWifiInfo(wifiManager);
                        if (wifiInfo != null) {
                            wirelessNetworkSignalLevel = getWifiSignalLevel(wifiInfo);
                        }
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }

            networkType = NETWORK_TYPE_WIFI;
        }
        else if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)) {
            networkType = NETWORK_TYPE_WIRED;
        }
        else if (isVpnActive) {
            ConnectivityManager connectivityManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
            if (connectivityManager != null) {
                Map<String, Object> fullInfo = getNetworkInformation(context, connectivityManager.getActiveNetwork());
                if (fullInfo != null && fullInfo.containsKey(KEY_NETWORK_TYPE)) {
                    Object t = fullInfo.get(KEY_NETWORK_TYPE);
                    if (t instanceof Integer) {
                        networkType = (int) t;
                    }
                    Object s = fullInfo.get(KEY_WIRELESS_SIGNAL_LEVEL);
                    if (s instanceof Integer) {
                        wirelessNetworkSignalLevel = (int) s;
                    }
                }
            }
            if (networkType == NETWORK_TYPE_UNKNOWN) {
                networkType = NETWORK_TYPE_VPN;
            }
        }

        Map<String, Object> map = new java.util.HashMap<>();
        map.put(KEY_NETWORK_ACCESS, hasNetworkAccess);
        map.put(KEY_INTERNET_ACCESS, hasInternetAccess);
        map.put(KEY_NETWORK_TYPE, networkType);
        map.put(KEY_WIRELESS_SIGNAL_LEVEL, wirelessNetworkSignalLevel);
        map.put(KEY_VPN_ACTIVE, isVpnActive);
        return map;
    }

    public static Map<String, Object> getNetworkInformation(Context context, Network network)
    {
        ConnectivityManager connectivityManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
        boolean isVpnActive = false;
        NetworkCapabilities physicalCaps = null;

        if (network != null) {
            NetworkCapabilities activeCaps = connectivityManager.getNetworkCapabilities(network);
            if (activeCaps != null) {
                if (activeCaps.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) {
                    isVpnActive = true;
                } else {
                    physicalCaps = activeCaps;
                }
            }
        }

        if (isVpnActive || physicalCaps == null) {
            for (Network net : physicalNetworks(connectivityManager)) {
                NetworkCapabilities caps = connectivityManager.getNetworkCapabilities(net);
                if (caps != null) {
                    if (caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) {
                        isVpnActive = true;
                    } else if (caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
                               caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) ||
                               caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) {
                        if (physicalCaps == null) {
                            physicalCaps = caps;
                        }
                    }
                }
            }
        }

        Map<String, Object> map = null;
        int wirelessNetworkSignalLevel = 0;

        if (physicalCaps != null) {
            map = getNetworkCapabilitiesInformation(context, physicalCaps);

            if (Objects.equals(map.get(KEY_NETWORK_TYPE), NETWORK_TYPE_WIFI)) {
                try {
                    WifiManager wifiManager = (WifiManager) context.getApplicationContext().getSystemService(Context.WIFI_SERVICE);
                    if (wifiManager != null) {
                        WifiInfo wifiInfo = legacyWifiInfo(wifiManager);
                        if (wifiInfo != null) {
                            wirelessNetworkSignalLevel = getWifiSignalLevel(wifiInfo);
                        }
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }

        // Fallback for physical network when VPN is active or physicalCaps returned UNKNOWN/VPN
        if (map == null || Objects.equals(map.get(KEY_NETWORK_TYPE), NETWORK_TYPE_UNKNOWN) || Objects.equals(map.get(KEY_NETWORK_TYPE), NETWORK_TYPE_VPN)) {
            WifiManager wifiManager = (WifiManager) context.getApplicationContext().getSystemService(Context.WIFI_SERVICE);
            if (wifiManager != null && wifiManager.isWifiEnabled()) {
                WifiInfo wifiInfo = legacyWifiInfo(wifiManager);
                if (wifiInfo != null && wifiInfo.getNetworkId() != -1) {
                    if (map == null) map = new HashMap<>();
                    map.put(KEY_NETWORK_TYPE, NETWORK_TYPE_WIFI);
                    map.put(KEY_NETWORK_ACCESS, true);
                    map.put(KEY_INTERNET_ACCESS, true);
                    wirelessNetworkSignalLevel = getWifiSignalLevel(wifiInfo);
                }
            }
            if (map == null || Objects.equals(map.get(KEY_NETWORK_TYPE), NETWORK_TYPE_UNKNOWN) || Objects.equals(map.get(KEY_NETWORK_TYPE), NETWORK_TYPE_VPN)) {
                if (connectivityManager != null) {
                    if (legacyConnected(connectivityManager, LegacyNetworkTypes.ETHERNET)) {
                        if (map == null) map = new HashMap<>();
                        map.put(KEY_NETWORK_TYPE, NETWORK_TYPE_WIRED);
                        map.put(KEY_NETWORK_ACCESS, true);
                        map.put(KEY_INTERNET_ACCESS, true);
                    }
                }
            }
            if (map == null || Objects.equals(map.get(KEY_NETWORK_TYPE), NETWORK_TYPE_UNKNOWN) || Objects.equals(map.get(KEY_NETWORK_TYPE), NETWORK_TYPE_VPN)) {
                if (connectivityManager != null) {
                    if (legacyConnected(connectivityManager, LegacyNetworkTypes.MOBILE)) {
                        if (map == null) map = new HashMap<>();
                        map.put(KEY_NETWORK_TYPE, NETWORK_TYPE_CELLULAR);
                        map.put(KEY_NETWORK_ACCESS, true);
                        map.put(KEY_INTERNET_ACCESS, true);
                    }
                }
            }
        }

        if (map != null) {
            map = new HashMap<>(map);
        }
        else {
            map = new HashMap<>();
            map.put(KEY_NETWORK_TYPE, NETWORK_TYPE_UNKNOWN);
            map.put(KEY_NETWORK_ACCESS, false);
            map.put(KEY_INTERNET_ACCESS, false);
        }

        map.put(KEY_WIRELESS_SIGNAL_LEVEL, wirelessNetworkSignalLevel);
        map.put(KEY_VPN_ACTIVE, isVpnActive);

        return map;
    }

    // OEM/VPN fallback: some TV firmware omits underlying transport information.
    @SuppressWarnings("deprecation")
    private static WifiInfo legacyWifiInfo(WifiManager manager) {
        return manager.getConnectionInfo();
    }

    @SuppressWarnings("deprecation")
    private static boolean legacyConnected(ConnectivityManager manager, int type) {
        NetworkInfo info = manager.getNetworkInfo(type);
        return info != null && info.isConnected();
    }

    // A snapshot is required for synchronous status queries, including VPN underlay.
    @SuppressWarnings("deprecation")
    private static Network[] physicalNetworks(ConnectivityManager manager) {
        return manager.getAllNetworks();
    }

    public static int getWifiSignalLevel(WifiInfo wifiInfo)
    {
        final int SIGNAL_LEVELS = 5;
        int rssi = wifiInfo.getRssi();

        return calculateSignalLevel(rssi, SIGNAL_LEVELS);
    }

    private static final int MIN_RSSI = -90;
    private static final int MAX_RSSI = -55;
    public static int calculateSignalLevel(int rssi, int levels)
    {
        if (rssi <= MIN_RSSI) {
            return 0;
        } else if (rssi >= MAX_RSSI) {
            return levels - 1;
        } else {
            final float inputRange = (MAX_RSSI - MIN_RSSI);
            final float outputRange = (levels - 1);
            return (int)((float)(rssi - MIN_RSSI) * outputRange / inputRange);
        }
    }
}
