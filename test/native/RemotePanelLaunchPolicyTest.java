package com.leanbitlab.ltvL;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.BooleanSupplier;

import static com.leanbitlab.ltvL.RemotePanelLaunchPolicy.ToggleResult.*;

public class RemotePanelLaunchPolicyTest {
    private static void require(boolean condition, String message) {
        if (!condition) throw new AssertionError(message);
    }
    public static void main(String[] args) {
        var visibility = new ArrayList<Boolean>();
        RemotePanelLaunchPolicy policy = new RemotePanelLaunchPolicy(visibility::add);
        AtomicInteger toggles = new AtomicInteger(), notices = new AtomicInteger();
        BooleanSupplier toggle = () -> { toggles.incrementAndGet(); return true; };
        Runnable notice = notices::incrementAndGet;
        Object first = new Object(), replacement = new Object();
        require(policy.toggle(false, toggle, notice) == TOGGLED, "Panel opens over another app before launcher starts");
        policy.started(first);
        require(policy.toggle(false, toggle, notice) == BLOCKED, "Visible launcher blocks opening");
        require(toggles.get() == 1 && notices.get() == 1, "Blocked request notifies without constructing an engine/window");
        require(policy.toggle(false, toggle, notice) == BLOCKED, "Repeated press remains blocked");
        require(toggles.get() == 1 && notices.get() == 2, "Each blocked action gives feedback");
        require(policy.toggle(true, toggle, notice) == TOGGLED, "Already open panel can always close");
        policy.started(replacement);
        policy.stopped(first);
        require(policy.toggle(false, toggle, notice) == BLOCKED, "Old Activity stopping must not clear replacement visibility");
        policy.stopped(replacement);
        require(policy.toggle(false, toggle, notice) == TOGGLED, "Stopping launcher permits panel again");
        require(policy.toggle(false, () -> false, notice) == FAILED, "Native opening failure propagates");
        require(notices.get() == 3, "Native opening failure does not send the blocked notice");
        policy.started(first);
        require(policy.toggle(false, toggle, notice) == BLOCKED, "Returning to launcher blocks again");
        policy.stopped(first);
        policy.stopped(first);
        require(policy.toggle(false, toggle, notice) == TOGGLED, "Duplicate stop is harmless");
        require(visibility.equals(List.of(true, false, true, false)),
            "Only visibility changes notify, including across Activity replacement");
        System.out.println("RemotePanelLaunchPolicy: all checks passed");
    }
}
