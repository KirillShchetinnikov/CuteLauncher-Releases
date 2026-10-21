package com.leanbitlab.ltvL;

/** One-shot policy. No input holding, retries, HOME handling or background polling. */
final class AutoLaunchPolicy {
    interface Scheduler { void post(Runnable work,long delay); void cancel(); }
    interface Launcher { boolean launch(String mode,String target); }
    private final Scheduler scheduler;
    private final Launcher launcher;
    private int generation,delay;
    private String mode="off",target="";
    private boolean boot,wake,foreground;
    String status="idle";
    AutoLaunchPolicy(Scheduler scheduler,Launcher launcher) { this.scheduler=scheduler; this.launcher=launcher; }
    void configure(String mode,String target,boolean boot,boolean wake,int delay) {
        cancel(); this.mode=mode; this.target=target; this.boot=boot; this.wake=wake; this.delay=delay; status="idle";
    }
    void foreground(boolean value) { foreground=value; if(!value) cancel(); }
    void cancel() { generation++; scheduler.cancel(); if(status.equals("pending")) status="cancelled"; }
    void event(String event) {
        if(!foreground || mode.equals("off") || target.isEmpty() || !(event.equals("boot") ? boot : event.equals("wake") && wake) || status.equals("pending")) return;
        int request=++generation; status="pending";
        scheduler.post(() -> {
            if(request!=generation || !foreground) return;
            status="idle"; // Consume before launch: resulting pause cannot repeat it.
            try { status=launcher.launch(mode,target) ? "launched" : "unavailable"; }
            catch(RuntimeException ignored) { status="unavailable"; }
        },delay*1000L);
    }
}
