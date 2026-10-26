package com.leanbitlab.ltvL;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;

/** Parses only the device-wide, untagged Ethernet section of netstats checkin v1. */
final class EthernetUsageHistory {
    static final int MAX_OUTPUT = 1024 * 1024;
    record Bucket(long start, long duration, long bytes, long received, long sent) { }
    private final long windowStart;
    private final long windowEnd;
    private final List<Bucket> buckets;

    private EthernetUsageHistory(long start, long end, List<Bucket> buckets) {
        windowStart = start;
        windowEnd = end;
        this.buckets = List.copyOf(buckets);
    }

    static EthernetUsageHistory parse(String output) {
        if (output == null || output.length() > MAX_OUTPUT || !output.endsWith("\n"))
            throw new IllegalArgumentException("Missing or truncated history");
        String[] lines = output.split("\r?\n");
        if (lines.length < 2 || lines.length > 12000) throw new IllegalArgumentException("Invalid history size");
        String[] header = lines[0].split(",", -1);
        if (header.length != 3 || !header[0].equals("v1")) throw new IllegalArgumentException("Unknown history version");
        long start = seconds(header[1]), end = seconds(header[2]);
        if (end <= start) throw new IllegalArgumentException("Invalid history interval");
        boolean xt = false, ethernet = false, found = false;
        long duration = 0, previousEnd = -1;
        var buckets = new ArrayList<Bucket>();
        for (int i = 1; i < lines.length; i++) {
            String line = lines[i];
            if (line.isEmpty()) continue;
            if (line.equals("xt")) {
                if (xt) throw new IllegalArgumentException("Duplicate device section");
                xt = true;
                continue;
            }
            if (!xt) throw new IllegalArgumentException("Missing device section");
            String[] fields = line.split(",", -1);
            switch (fields[0]) {
                case "c" -> {
                    if (fields.length != 5) throw new IllegalArgumentException("Invalid group");
                    ethernet = fields[1].equals("eth");
                    duration = 0;
                    previousEnd = -1;
                    if (ethernet) {
                        if (found || !fields[2].equals("-1") || !fields[3].equals("all") || !fields[4].equals("0"))
                            throw new IllegalArgumentException("Non-device or duplicate Ethernet group");
                        found = true;
                    }
                }
                case "d" -> {
                    if (fields.length != 2) throw new IllegalArgumentException("Invalid bucket duration");
                    duration = seconds(fields[1]);
                    if (duration <= 0 || duration > 7L * 86400000) throw new IllegalArgumentException("Invalid bucket duration");
                }
                case "b" -> {
                    if (fields.length != 7 || duration == 0) throw new IllegalArgumentException("Invalid bucket");
                    if (ethernet) {
                        long timestamp = seconds(fields[1]);
                        if (timestamp < previousEnd || buckets.size() >= 4096)
                            throw new IllegalArgumentException("Duplicate or excessive buckets");
                        long bucketEnd = Math.addExact(timestamp, duration);
                        long received = nonnegative(fields[2]), sent = nonnegative(fields[4]);
                        long bytes = Math.addExact(received, sent);
                        buckets.add(new Bucket(timestamp, duration, bytes, received, sent));
                        previousEnd = bucketEnd;
                    }
                }
                default -> throw new IllegalArgumentException("Unknown or failed history output");
            }
        }
        if (!xt || !found || buckets.isEmpty()) throw new IllegalArgumentException("Ethernet history unavailable");
        return new EthernetUsageHistory(start, end, buckets);
    }

    long usage(long start, long end) { return usage(start, end, 0); }
    long received(long start, long end) { return usage(start, end, 1); }
    long sent(long start, long end) { return usage(start, end, 2); }
    private long usage(long start, long end, int direction) {
        if (start < windowStart || start > windowEnd || end < start)
            return NetworkUsageTotals.UNAVAILABLE;
        BigInteger total = BigInteger.ZERO;
        for (var bucket : buckets) {
            long overlap = Math.min(Math.min(end, windowEnd), bucket.start + bucket.duration)
                    - Math.max(start, bucket.start);
            if (overlap > 0) {
                // Calendar boundaries can cut an hourly system bucket (time zones / DST).
                total = total.add(BigInteger.valueOf(direction == 1 ? bucket.received : direction == 2 ? bucket.sent : bucket.bytes).multiply(BigInteger.valueOf(overlap))
                        .divide(BigInteger.valueOf(bucket.duration)));
            }
        }
        return total.bitLength() > 63 ? NetworkUsageTotals.UNAVAILABLE : total.longValue();
    }

    private static long nonnegative(String value) {
        long number = Long.parseLong(value);
        if (number < 0) throw new IllegalArgumentException("Negative history value");
        return number;
    }
    private static long seconds(String value) { return Math.multiplyExact(nonnegative(value), 1000); }
}
