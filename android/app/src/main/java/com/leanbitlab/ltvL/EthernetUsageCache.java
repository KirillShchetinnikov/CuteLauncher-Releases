package com.leanbitlab.ltvL;

/** One bounded snapshot shared by day/week/month queries; no timer or persisted counters. */
final class EthernetUsageCache {
    interface Loader { String load() throws Exception; }
    private EthernetUsageHistory history;
    private long loadedAt;
    private long retryAt;

    synchronized long read(long start, long end, long now, Loader loader) {
        if (history != null && now >= loadedAt && now - loadedAt < 300000) {
            long usage = history.usage(start, end);
            if (usage >= 0) return usage;
        }
        history = null;
        if (now < retryAt) return NetworkUsageTotals.UNAVAILABLE;
        try {
            var snapshot = EthernetUsageHistory.parse(loader.load());
            long usage = snapshot.usage(start, end);
            if (usage < 0) throw new IllegalArgumentException("History does not cover period");
            history = snapshot;
            loadedAt = now;
            retryAt = 0;
            return usage;
        } catch (Exception | LinkageError unavailable) {
            retryAt = now + 60000;
            return NetworkUsageTotals.UNAVAILABLE;
        }
    }
}
