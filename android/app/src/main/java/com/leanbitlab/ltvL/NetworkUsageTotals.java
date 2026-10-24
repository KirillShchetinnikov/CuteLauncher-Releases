package com.leanbitlab.ltvL;

/** Keeps unavailable transport history distinct from a measured zero. */
final class NetworkUsageTotals {
    static final long UNAVAILABLE = -2;
    static long sum(long[] bytes, boolean[] required) {
        long total = 0;
        boolean available = false;
        for (int i = 0; i < bytes.length; i++) {
            if (bytes[i] < 0) {
                if (required[i]) return UNAVAILABLE;
            } else {
                available = true;
                total += bytes[i];
            }
        }
        return available ? total : UNAVAILABLE;
    }
    private NetworkUsageTotals() { }
}
