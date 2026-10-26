package com.leanbitlab.ltvL;

/** Monotonic deadline validation, including stale deliveries and device reboot. */
final class SleepTimerPolicy {
    static boolean validSeconds(long seconds) {
        return seconds > 0 && seconds <= 3599999999L;
    }
    static boolean validMinutes(int minutes) {
        return validSeconds(minutes * 60L);
    }
    static boolean due(long stored, long delivered, int savedBoot, int currentBoot, long now) {
        return delivered != 0 && stored == delivered && savedBoot == currentBoot && now >= delivered;
    }
}
