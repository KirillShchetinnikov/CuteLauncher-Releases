package com.leanbitlab.ltvL;

/** Pure Android protection-level rules, independently testable without an emulator. */
final class AdbCompatibilityPolicy {
    static boolean supportedSdk(int sdk) { return sdk >= 30; }
    static boolean canSelectHome(int targetPriority, int highestEnabledPriority) {
        return targetPriority != Integer.MIN_VALUE && targetPriority >= highestEnabledPriority;
    }
    static boolean grantable(int protectionLevel) {
        // pm grant supports runtime (dangerous) and development permissions, not privileged/signature alone.
        return (protectionLevel & 0xf) == 1 || (protectionLevel & 0x20) != 0;
    }
}
