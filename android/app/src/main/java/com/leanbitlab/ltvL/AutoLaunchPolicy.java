package com.leanbitlab.ltvL;

/** One-shot policy. No input holding, retries, HOME handling or background polling. */
final class AutoLaunchPolicy {
    interface Scheduler { void post(Runnable work,long delay); void cancel(); }
    interface Launcher { boolean launch(String mode,String target); }
    private final Scheduler scheduler;
    private final Launcher launcher;
    private int generation,delay;
    private String mode="off",target="";
    private boolean boot,wake,foreground,waitForInternet,online;
    String status="idle";
    AutoLaunchPolicy(Scheduler scheduler,Launcher launcher) { this.scheduler=scheduler; this.launcher=launcher; }
    void configure(String mode,String target,boolean boot,boolean wake,int delay) {
        configure(mode, target, boot, wake, delay, false);
    }
    void configure(String mode,String target,boolean boot,boolean wake,int delay,boolean waitForInternet) {
        cancel(); this.mode=mode; this.target=target; this.boot=boot; this.wake=wake; this.delay=delay; status="idle";
        this.waitForInternet = waitForInternet;
    }
    void foreground(boolean value) { foreground=value; if(!value) cancel(); }
    void cancel() { generation++; scheduler.cancel(); if(status.equals("pending") || status.equals("waitingNetwork")) status="cancelled"; }
    void networkAvailable(boolean available) {
        online = available;
        if (available && foreground && status.equals("waitingNetwork")) launch(generation);
    }
    private void launch(int request) {
        if (request != generation || !foreground) return;
        generation++;
        scheduler.cancel();
        status="idle"; // Consume before launch: resulting pause cannot repeat it.
        try { status=launcher.launch(mode,target) ? "launched" : "unavailable"; }
        catch(RuntimeException ignored) { status="unavailable"; }
    }
    void event(String event) {
        if(!foreground || mode.equals("off") || target.isEmpty() || !(event.equals("boot") ? boot : event.equals("wake") && wake) || status.equals("pending") || status.equals("waitingNetwork")) return;
        int request=++generation; status="pending";
        scheduler.post(() -> {
            if(request!=generation || !foreground) return;
            if (waitForInternet && mode.equals("app") && !online) {
                status = "waitingNetwork";
                scheduler.post(() -> launch(request), 60_000L);
            } else launch(request);
        },delay*1000L);
    }
}
