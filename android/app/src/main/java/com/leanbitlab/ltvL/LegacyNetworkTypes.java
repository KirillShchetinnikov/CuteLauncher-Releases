package com.leanbitlab.ltvL;

import android.net.ConnectivityManager;

/** NetworkStatsManager requires these legacy types; transport IDs are different. */
final class LegacyNetworkTypes {
    @SuppressWarnings("deprecation") static final int WIFI = ConnectivityManager.TYPE_WIFI;
    @SuppressWarnings("deprecation") static final int MOBILE = ConnectivityManager.TYPE_MOBILE;
    @SuppressWarnings("deprecation") static final int ETHERNET = ConnectivityManager.TYPE_ETHERNET;
    @SuppressWarnings("deprecation") static final int VPN = ConnectivityManager.TYPE_VPN;
    private LegacyNetworkTypes() { }
}
