package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.Instrumentation;
import android.os.Build;
import android.os.Bundle;
import java.util.Map;

/** Deterministic policy checks; HDMI callbacks are a fixture, never physical input switching. */
public final class AutoLaunchProbe extends Instrumentation {
    private String mode;
    @Override public void onCreate(Bundle args) { super.onCreate(args); mode=args.getString("mode","policy"); start(); }
    private static void require(boolean value,String text) { if(!value) throw new AssertionError(text); }
    @Override public void onStart() {
        Bundle report=new Bundle();
        try {
            require(Build.HARDWARE.equals("ranchu") || Build.HARDWARE.equals("goldfish"),"Emulator only");
            class Schedule implements AutoLaunchPolicy.Scheduler {
                Runnable pending; long delay;
                public void post(Runnable work,long time) { require(pending==null,"Single pending action"); pending=work; delay=time; }
                public void cancel() { pending=null; }
                void run() { Runnable work=pending; pending=null; if(work!=null) work.run(); }
            }
            Schedule schedule=new Schedule(); int[] launches={0}; boolean[] available={true};
            AutoLaunchPolicy policy=new AutoLaunchPolicy(schedule,(mode,target) -> { launches[0]++; return available[0]; });
            policy.foreground(true); policy.event("boot"); policy.event("wake");
            require(schedule.pending==null && launches[0]==0,"Default off");
            policy.configure("hdmi","fixture-input",true,true,10);
            policy.event("boot"); policy.event("wake");
            require(schedule.delay==10000 && policy.status.equals("pending"),"Delay and coalescing");
            Runnable stale=schedule.pending; policy.cancel(); stale.run();
            require(launches[0]==0 && policy.status.equals("cancelled"),"Manual input/Home cancels stale task");
            policy.event("wake"); policy.foreground(false); schedule.run();
            require(launches[0]==0,"Leaving launcher cancels");
            policy.event("boot"); require(schedule.pending==null,"No background takeover");
            policy.foreground(true); policy.event("wake"); schedule.run();
            require(launches[0]==1 && policy.status.equals("launched"),"One-shot HDMI fixture");
            schedule.run(); policy.foreground(false); policy.foreground(true); schedule.run();
            require(launches[0]==1,"Resume and input changes never hold HDMI");
            policy.configure("off","fixture-input",true,true,0); policy.event("wake"); schedule.run();
            require(launches[0]==1,"No-manage HDMI mode");
            policy.configure("app","missing.app",false,true,0); policy.event("boot"); require(schedule.pending==null,"Selected events only");
            available[0]=false; policy.event("wake"); schedule.run(); schedule.run();
            require(launches[0]==2 && policy.status.equals("unavailable"),"Unavailable target has no retry loop");
            policy.event("wake"); Runnable old=schedule.pending; policy.configure("off","",false,false,5); old.run();
            require(launches[0]==2,"Configuration change cancels queued work");
            Map<String,Object> config=Map.of("mode","hdmi","app","","input","fixture-input","boot",true,"wake",false,"delay",60);
            require(AutoLaunchBridge.valid(config,"own.app"),"Valid HDMI config");
            require(!AutoLaunchBridge.valid(Map.of("mode","app","app","own.app","input","","boot",true,"wake",true,"delay",5),"own.app"),"No self launch");
            require(!AutoLaunchBridge.valid(Map.of("mode","off","app","","input","","boot",true,"wake",true,"delay",61),"own.app"),"Bounded delay");
            if(mode.startsWith("activity")) activityChecks();
            report.putString("stream","\nPASS "+mode+": off, app/HDMI policy, events, delay, cancellation, foreground, unavailable target, validation\n");
        } catch(Throwable error) { report.putString("stream","\nFAIL "+error.getClass().getSimpleName()+": "+error.getMessage()+"\n"); }
        finish(report.getString("stream","").contains("PASS")?Activity.RESULT_OK:Activity.RESULT_CANCELED,report);
    }
    private void activityChecks() throws Exception {
        var context=getTargetContext();
        var preferences=context.getSharedPreferences("auto_launch",android.content.Context.MODE_PRIVATE);
        Map<String,?> original=new java.util.HashMap<>(preferences.getAll());
        MainActivity[] activity={null};
        try {
            activity[0]=(MainActivity)startActivitySync(new android.content.Intent(context,MainActivity.class).addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK));
            waitForIdleSync(); Thread.sleep(800);
            var field=MainActivity.class.getDeclaredField("autoLaunch"); field.setAccessible(true);
            AutoLaunchBridge bridge=(AutoLaunchBridge)field.get(activity[0]);
            require(bridge!=null && activity[0].hasWindowFocus(),"Launcher foreground");
            var reload=AutoLaunchBridge.class.getDeclaredMethod("reload"); reload.setAccessible(true);
            preferences.edit().putString("mode","app").putString("app","com.android.tv.settings")
                .putString("input","").putBoolean("boot",true).putBoolean("wake",false).putInt("delay",1).commit();
            runOnMainSync(() -> { try { reload.invoke(bridge); AutoLaunchBridge.boot(context); } catch(Exception error) { throw new RuntimeException(error); } });
            Thread.sleep(1600); waitForIdleSync();
            require(bridge.policy.status.equals("launched"),"Boot dispatch launched Settings");
            try(var input=new android.os.ParcelFileDescriptor.AutoCloseInputStream(getUiAutomation().executeShellCommand("dumpsys activity activities"))) {
                String state=new String(input.readAllBytes(),java.nio.charset.StandardCharsets.UTF_8);
                require(state.lines().anyMatch(line -> line.contains("topResumedActivity=") && line.contains("com.android.tv.settings/")),"Real Settings foreground");
            }
            try(var input=new android.os.ParcelFileDescriptor.AutoCloseInputStream(getUiAutomation().executeShellCommand("am start -n "+context.getPackageName()+"/com.leanbitlab.ltvL.MainActivity"))) { input.readAllBytes(); }
            Thread.sleep(800); waitForIdleSync(); require(activity[0].hasWindowFocus(),"Return to launcher");
            Thread.sleep(1400); require(activity[0].hasWindowFocus(),"No launch loop on resume");
            runOnMainSync(() -> { AutoLaunchBridge.boot(context); activity[0].onUserInteraction(); });
            Thread.sleep(1400); require(activity[0].hasWindowFocus() && bridge.policy.status.equals("cancelled"),"Remote interaction cancels boot delay");
            runOnMainSync(() -> {
                AutoLaunchBridge.boot(context);
                if(!mode.equals("activityWake")) {
                    android.content.Intent home=new android.content.Intent(android.content.Intent.ACTION_MAIN).addCategory(android.content.Intent.CATEGORY_HOME);
                    activity[0].onNewIntent(home);
                }
            });
            if(mode.equals("activityWake")) shell("input keyevent KEYCODE_HOME");
            Thread.sleep(1400);
            String top;
            try(var input=new android.os.ParcelFileDescriptor.AutoCloseInputStream(getUiAutomation().executeShellCommand("dumpsys activity activities"))) {
                top=new String(input.readAllBytes(),java.nio.charset.StandardCharsets.UTF_8).lines().filter(line -> line.contains("topResumedActivity=")).findFirst().orElse("none");
            }
            require(bridge.policy.status.equals("cancelled") && !top.contains("com.android.tv.settings/"),"Home cancellation: status="+bridge.policy.status+", "+top);
            if(!activity[0].hasWindowFocus()) {
                shell("am start -n "+context.getPackageName()+"/com.leanbitlab.ltvL.MainActivity");
                Thread.sleep(800); waitForIdleSync();
            }
            require(activity[0].hasWindowFocus(),"Launcher foreground after explicit return");
            preferences.edit().putString("app","missing.auto.target").commit();
            runOnMainSync(() -> { try { reload.invoke(bridge); AutoLaunchBridge.boot(context); } catch(Exception error) { throw new RuntimeException(error); } });
            Thread.sleep(1400); require(activity[0].hasWindowFocus() && bridge.policy.status.equals("unavailable"),"Missing app reported without takeover");
            if(mode.equals("activityWake")) {
                preferences.edit().putString("app","com.android.tv.settings").putBoolean("boot",false).putBoolean("wake",true).commit();
                runOnMainSync(() -> { try { reload.invoke(bridge); } catch(Exception error) { throw new RuntimeException(error); } });
                shell("input keyevent KEYCODE_SLEEP"); Thread.sleep(700);
                shell("input keyevent KEYCODE_WAKEUP");
                // Stock Google TV ignores a preferred HOME change; explicitly present
                // the launcher to test its foreground-only wake dispatch.
                shell("am start -n "+context.getPackageName()+"/com.leanbitlab.ltvL.MainActivity");
                Thread.sleep(1800); waitForIdleSync();
                require(bridge.policy.status.equals("launched"),"Screen off/on dispatch launches once");
            }
        } finally {
            var editor=preferences.edit().clear();
            for(var entry:original.entrySet()) {
                Object value=entry.getValue();
                if(value instanceof String) editor.putString(entry.getKey(),(String)value);
                else if(value instanceof Boolean) editor.putBoolean(entry.getKey(),(Boolean)value);
                else if(value instanceof Integer) editor.putInt(entry.getKey(),(Integer)value);
                else if(value instanceof Long) editor.putLong(entry.getKey(),(Long)value);
            }
            editor.commit();
            if(activity[0]!=null) runOnMainSync(activity[0]::finish);
        }
    }
    private void shell(String command) throws Exception {
        try(var input=new android.os.ParcelFileDescriptor.AutoCloseInputStream(getUiAutomation().executeShellCommand(command))) { input.readAllBytes(); }
    }
}
