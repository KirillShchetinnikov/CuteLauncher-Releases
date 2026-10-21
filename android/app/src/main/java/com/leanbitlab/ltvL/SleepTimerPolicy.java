package com.leanbitlab.ltvL;

/** Monotonic deadline validation, including stale deliveries and device reboot. */
final class SleepTimerPolicy {
    static boolean validMinutes(int m) {
        return m == 10 || m == 20 || m == 30 || m == 40 || m == 50 || m == 60 || m == 90
            || m == 120 || m == 180 || m == 240 || m == 300 || m == 360;
    }
    static boolean due(long stored, long delivered, int savedBoot, int currentBoot, long now) {
        return delivered != 0 && stored == delivered && savedBoot == currentBoot && now >= delivered;
    }
}
