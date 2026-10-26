package com.leanbitlab.ltvL;

public final class AdbCompatibilityPolicyTest {
    private static int checks;
    private static void check(boolean value) { checks++; if (!value) throw new AssertionError("Check " + checks); }
    public static void main(String[] args) {
        for (int sdk = 28; sdk <= 37; sdk++) check(AdbCompatibilityPolicy.supportedSdk(sdk));
        check(!AdbCompatibilityPolicy.supportedSdk(27));
        check(AdbCompatibilityPolicy.grantable(1)); // runtime
        check(AdbCompatibilityPolicy.grantable(2 | 0x20)); // signature/development
        check(!AdbCompatibilityPolicy.grantable(2)); // signature
        check(!AdbCompatibilityPolicy.grantable(2 | 0x10)); // privileged
        check(!AdbCompatibilityPolicy.grantable(0)); // normal, not pm grant
        check(!AdbCompatibilityPolicy.canSelectHome(0, 2)); // both emulator stock launchers
        check(AdbCompatibilityPolicy.canSelectHome(0, 0)); // conventional HOME
        check(AdbCompatibilityPolicy.canSelectHome(0, Integer.MIN_VALUE)); // stock disabled
        check(AdbCompatibilityPolicy.canSelectHome(2, 0)); // restore system HOME
        check(!AdbCompatibilityPolicy.canSelectHome(Integer.MIN_VALUE, 0)); // own missing
        System.out.println(checks + " compatibility checks passed");
    }
}
