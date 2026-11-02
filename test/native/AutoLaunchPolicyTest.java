package com.leanbitlab.ltvL;
import java.util.*;

public final class AutoLaunchPolicyTest {
    static void check(boolean value) { if (!value) throw new AssertionError(); }
    static class Clock implements AutoLaunchPolicy.Scheduler {
        Runnable pending;
        long delay;
        public void post(Runnable work, long delay) { this.pending = work; this.delay = delay; }
        public void cancel() { pending = null; }
        void run() { var work = pending; pending = null; work.run(); }
    }
    public static void main(String[] args) {
        var clock = new Clock(); var launches = new ArrayList<String>();
        var policy = new AutoLaunchPolicy(clock, (mode, target) -> { launches.add(mode); return true; });
        policy.configure("app", "org.example.player", true, true, 5, true);
        policy.foreground(true); policy.event("boot"); check(clock.delay == 5000);
        policy.networkAvailable(true); check(launches.isEmpty()); // Keep the chosen initial delay.
        clock.run(); check(launches.size() == 1 && clock.pending == null);
        policy.networkAvailable(false); policy.event("wake"); clock.run();
        check(policy.status.equals("waitingNetwork") && clock.delay == 60000);
        Runnable timeout = clock.pending;
        policy.event("wake"); check(clock.pending == timeout);
        policy.networkAvailable(true); check(launches.size() == 2 && clock.pending == null);
        // A removed but already dispatched deadline must not launch twice.
        timeout.run(); check(launches.size() == 2);
        policy.networkAvailable(false); policy.event("wake"); clock.run(); clock.run();
        check(launches.size() == 3); // Timeout launches once even if internet never validates.
        policy.event("wake"); clock.run(); timeout = clock.pending;
        policy.cancel(); policy.networkAvailable(true); timeout.run();
        check(launches.size() == 3 && policy.status.equals("cancelled"));
        policy.networkAvailable(false); policy.event("wake"); clock.run();
        policy.foreground(false); policy.networkAvailable(true);
        check(launches.size() == 3 && clock.pending == null);
        policy.configure("hdmi", "port", true, false, 0, true);
        policy.foreground(true); policy.event("boot"); clock.run();
        check(launches.size() == 4 && launches.get(3).equals("hdmi"));
        policy.configure("app", "org.example.player", true, false, 0);
        policy.event("boot"); clock.run(); check(launches.size() == 5);
        System.out.println("AutoLaunchPolicyTest passed");
    }
}
