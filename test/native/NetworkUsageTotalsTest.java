package com.leanbitlab.ltvL;

public final class NetworkUsageTotalsTest {
    private static void expect(long expected, long[] bytes, boolean[] required) {
        long actual = NetworkUsageTotals.sum(bytes, required);
        if (actual != expected) throw new AssertionError("Expected " + expected + ", got " + actual);
    }
    public static void main(String[] args) {
        // TCL: Wi-Fi/mobile return zero; Ethernet returns null while Ethernet is connected.
        expect(-2, new long[]{0, 0, -2}, new boolean[]{false, false, true});
        expect(-2, new long[]{700, 0, -2}, new boolean[]{true, false, true});
        expect(700, new long[]{700, -2, -2}, new boolean[]{true, false, false});
        expect(0, new long[]{0, 0, -2}, new boolean[]{true, false, false});
        expect(1500, new long[]{700, 0, 800}, new boolean[]{false, false, true});
        expect(-2, new long[]{-2, -2, -2}, new boolean[]{false, false, false});
        System.out.println("NetworkUsageTotals: 6 cases passed");
    }
}
