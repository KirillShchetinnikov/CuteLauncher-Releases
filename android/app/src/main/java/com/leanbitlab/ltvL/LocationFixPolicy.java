package com.leanbitlab.ltvL;

/** Approximate coordinates are enough for sunrise/weather; never accept stale or invalid fixes. */
final class LocationFixPolicy {
    static boolean usable(double latitude, double longitude, float accuracy, long ageMillis) {
        return Double.isFinite(latitude) && Double.isFinite(longitude) && Math.abs(latitude)<=90 &&
            Math.abs(longitude)<=180 && Float.isFinite(accuracy) && accuracy>=0 && accuracy<=100000 &&
            ageMillis>=0 && ageMillis<=24*60*60*1000L;
    }
}
