package com.leanbitlab.ltvL;

import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.BooleanSupplier;

public class RemotePanelLaunchPolicyTest {
    private static void require(boolean condition, String message) {
        if (!condition) throw new AssertionError(message);
    }
    public static void main(String[] args) {
        RemotePanelLaunchPolicy policy = new RemotePanelLaunchPolicy();
        AtomicInteger toggles = new AtomicInteger(), notices = new AtomicInteger();
        BooleanSupplier toggle = () -> { toggles.incrementAndGet(); return true; };
        Runnable notice = notices::incrementAndGet;
        Object first = new Object(), replacement = new Object();
        require(policy.toggle(false, toggle, notice), "Panel opens over another app before launcher starts");
        policy.started(first);
        require(!policy.toggle(false, toggle, notice), "Visible launcher blocks opening");
        require(toggles.get() == 1 && notices.get() == 1, "Blocked request notifies without constructing an engine/window");
        require(!policy.toggle(false, toggle, notice), "Repeated press remains blocked");
        require(toggles.get() == 1 && notices.get() == 2, "Each blocked action gives feedback");
        require(policy.toggle(true, toggle, notice), "Already open panel can always close");
        policy.started(replacement);
        policy.stopped(first);
        require(!policy.toggle(false, toggle, notice), "Old Activity stopping must not clear replacement visibility");
        policy.stopped(replacement);
        require(policy.toggle(false, toggle, notice), "Stopping launcher permits panel again");
        require(!policy.toggle(false, () -> false, notice), "Native opening failure propagates");
        policy.started(first);
        require(!policy.toggle(false, toggle, notice), "Returning to launcher blocks again");
        policy.stopped(first);
        policy.stopped(first);
        require(policy.toggle(false, toggle, notice), "Duplicate stop is harmless");
        System.out.println("RemotePanelLaunchPolicy: all checks passed");
    }
}
