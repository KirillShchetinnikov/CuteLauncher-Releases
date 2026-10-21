package com.leanbitlab.ltvL;

/** Standalone JVM regression checks; no device or Android mocks required. */
public final class SystemBrightnessWriterTest {
    public static void main(String[] args) {
        int[] writes = {0};
        SystemBrightnessWriter.Operation write = () -> { writes[0]++; return true; };
        check(!SystemBrightnessWriter.apply(128, () -> false, write, write), "denied permission");
        check(writes[0] == 0, "denied permission must not write");
        check(!SystemBrightnessWriter.apply(128, () -> { throw new SecurityException(); }, write, write), "permission exception");
        check(!SystemBrightnessWriter.apply(128, () -> true, () -> false, write), "manual mode refused");
        check(writes[0] == 0, "failed manual mode must not write brightness");
        check(!SystemBrightnessWriter.apply(128, () -> true, write, () -> false), "brightness refused");
        check(!SystemBrightnessWriter.apply(128, () -> true, write, () -> { throw new SecurityException(); }), "write exception");
        check(!SystemBrightnessWriter.apply(-1, () -> true, write, write), "negative value");
        check(!SystemBrightnessWriter.apply(256, () -> true, write, write), "out of range");
        check(SystemBrightnessWriter.apply(0, () -> true, write, write), "zero is valid");
        check(SystemBrightnessWriter.apply(255, () -> true, write, write), "255 is valid");
        System.out.println("System brightness regression checks passed");
    }

    private static void check(boolean condition, String label) {
        if (!condition) throw new AssertionError(label);
    }
}
