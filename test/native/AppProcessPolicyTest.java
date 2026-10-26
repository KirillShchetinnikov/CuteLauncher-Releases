package com.leanbitlab.ltvL;

public final class AppProcessPolicyTest {
    public static void main(String[] args) {
        check(true, " UID NAME\n 10123 test.app\n");
        check(true, "10123 test.app:player\r\n");
        check(false, "10123 test.application\n10123 other.test.app");
        check(false, "110123 test.app");
        check(false, "UID NAME\n");
        check(false, "");
        System.out.println("AppProcessPolicy: 6 cases passed");
    }
    private static void check(boolean expected, String output) {
        if (AppProcessPolicy.running(output, "test.app", 10123) != expected)
            throw new AssertionError(output);
    }
}
