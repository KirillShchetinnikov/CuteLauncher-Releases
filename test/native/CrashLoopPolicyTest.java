package com.leanbitlab.ltvL;
import java.util.List;
public final class CrashLoopPolicyTest {
    public static void main(String[] args) {
        long now = 1_000_000;
        check(!CrashLoopPolicy.blocked(List.of(now, now-1), now));
        check(CrashLoopPolicy.blocked(List.of(now, now-1, now-2), now));
        check(!CrashLoopPolicy.blocked(List.of(now, now-1, now-300_000), now));
        check(!CrashLoopPolicy.blocked(List.of(now, now-1, now+1), now));
        check(CrashLoopPolicy.recent(List.of(now, now-1, now-2, now-3), now).size() == 3);
        System.out.println("CrashLoopPolicy: all checks passed");
    }
    static void check(boolean value) { if (!value) throw new AssertionError(); }
}
