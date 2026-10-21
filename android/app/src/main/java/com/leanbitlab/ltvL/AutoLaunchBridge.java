package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;
import android.media.tv.TvInputInfo;
import android.media.tv.TvInputManager;
import java.util.Map;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;

/** Activity-scoped dispatch: Android must bring the launcher to the foreground. */
final class AutoLaunchBridge {
    private static java.lang.ref.WeakReference<AutoLaunchBridge> active = new java.lang.ref.WeakReference<>(null);
    private final Activity activity;
    private final SharedPreferences preferences;
    private final Handler main=new Handler(Looper.getMainLooper());
    final AutoLaunchPolicy policy;
    private boolean listening,screenOff,resumed,focused;
    private long wakeAt;
    private final BroadcastReceiver screen=new BroadcastReceiver() {
        @Override public void onReceive(Context context,Intent intent) {
            if(Intent.ACTION_SCREEN_OFF.equals(intent.getAction())) { screenOff=true; wakeAt=0; policy.cancel(); }
            else if(Intent.ACTION_SCREEN_ON.equals(intent.getAction()) && screenOff) {
                screenOff=false; wakeAt=SystemClock.elapsedRealtime(); if(resumed && focused) dispatchWake();
            }
        }
    };
    AutoLaunchBridge(Activity activity,BinaryMessenger messenger) {
        this.activity=activity; preferences=activity.getSharedPreferences("auto_launch",Context.MODE_PRIVATE);
        policy=new AutoLaunchPolicy(new AutoLaunchPolicy.Scheduler() {
            public void post(Runnable work,long delay) { main.postDelayed(work,delay); }
            public void cancel() { main.removeCallbacksAndMessages(null); }
        },this::launch);
        active=new java.lang.ref.WeakReference<>(this); reload();
        new MethodChannel(messenger,"cutelauncher/auto_launch").setMethodCallHandler((call,result) -> {
            if(call.method.equals("info")) result.success(info());
            else if(call.method.equals("save")) {
                Map<String,Object> config=call.arguments();
                if(!valid(config,activity.getPackageName())) { result.success(Map.of("status","invalid")); return; }
                boolean saved=preferences.edit().putString("mode",(String)config.get("mode"))
                    .putString("app",(String)config.get("app")).putString("input",(String)config.get("input"))
                    .putBoolean("boot",(Boolean)config.get("boot")).putBoolean("wake",(Boolean)config.get("wake"))
                    .putInt("delay",(Integer)config.get("delay")).remove("boot_at").commit();
                wakeAt=0; reload(); result.success(Map.of("status",saved?"success":"unavailable"));
            } else if(call.method.equals("cancel")) { cancel(); result.success(Map.of("status","success")); }
            else result.notImplemented();
        });
    }
    static boolean valid(Map<String,Object> map,String own) {
        if(map==null || !(map.get("mode") instanceof String) || !(map.get("app") instanceof String) || !(map.get("input") instanceof String)
            || !(map.get("boot") instanceof Boolean) || !(map.get("wake") instanceof Boolean) || !(map.get("delay") instanceof Integer)) return false;
        String mode=(String)map.get("mode"),app=(String)map.get("app"),input=(String)map.get("input"); int delay=(Integer)map.get("delay");
        if(!java.util.Set.of("off","app","hdmi").contains(mode) || delay<0 || delay>60 || input.length()>512 || app.length()>255
            || (!app.isEmpty() && (!app.matches("[A-Za-z][A-Za-z0-9_]*(\\.[A-Za-z][A-Za-z0-9_]*)+") || app.equals(own)))) return false;
        return mode.equals("off") || mode.equals("app") && !app.isEmpty() || mode.equals("hdmi") && !input.isEmpty();
    }
    Map<String,Object> info() {
        return Map.of("mode",preferences.getString("mode","off"),"app",preferences.getString("app",""),
            "input",preferences.getString("input",""),"boot",preferences.getBoolean("boot",false),
            "wake",preferences.getBoolean("wake",false),"delay",preferences.getInt("delay",5),"status",policy.status,"ownPackage",activity.getPackageName());
    }
    private void reload() {
        Map<String,Object> config=info();
        if(!valid(config,activity.getPackageName())) config=Map.of("mode","off","app","","input","","boot",false,"wake",false,"delay",5);
        String mode=(String)config.get("mode");
        policy.configure(mode,(String)config.get(mode.equals("hdmi")?"input":"app"),(Boolean)config.get("boot"),(Boolean)config.get("wake"),(Integer)config.get("delay"));
        boolean needed=!mode.equals("off") && (Boolean)config.get("wake");
        if(needed && !listening) {
            IntentFilter filter=new IntentFilter(Intent.ACTION_SCREEN_OFF); filter.addAction(Intent.ACTION_SCREEN_ON);
            if(android.os.Build.VERSION.SDK_INT >= 33) activity.registerReceiver(screen,filter,Context.RECEIVER_NOT_EXPORTED);
            else activity.registerReceiver(screen,filter);
            listening=true;
        } else if(!needed && listening) { activity.unregisterReceiver(screen); listening=false; screenOff=false; }
    }
    static void boot(Context context) {
        SharedPreferences prefs=context.getSharedPreferences("auto_launch",Context.MODE_PRIVATE);
        if(prefs.getString("mode","off").equals("off") || !prefs.getBoolean("boot",false)) return;
        prefs.edit().putLong("boot_at",SystemClock.elapsedRealtime()).apply();
        AutoLaunchBridge bridge=active.get();
        if(bridge!=null && bridge.resumed && bridge.focused) bridge.dispatchBoot();
    }
    void resume() { resumed=true; focus(activity.hasWindowFocus()); }
    void focus(boolean value) {
        if(focused && !value) cancel(); focused=value;
        policy.foreground(resumed && focused);
        if(resumed && focused) { dispatchBoot(); dispatchWake(); }
    }
    void pause() { resumed=false; cancel(); policy.foreground(false); }
    void cancel() { wakeAt=0; if(preferences.contains("boot_at")) preferences.edit().remove("boot_at").apply(); policy.cancel(); }
    private void dispatchBoot() {
        long time=preferences.getLong("boot_at",-1); if(time>=0) preferences.edit().remove("boot_at").apply();
        if(time>=0 && fresh(time)) policy.event("boot");
    }
    private void dispatchWake() {
        long time=wakeAt; wakeAt=0; long age=SystemClock.elapsedRealtime()-time;
        if(time>0 && age>=0 && age<=2000) policy.event("wake");
    }
    private boolean fresh(long time) { long age=SystemClock.elapsedRealtime()-time; return age>=0 && age<=60000; }
    private boolean launch(String mode,String target) {
        if(!resumed || !activity.hasWindowFocus() || activity.isFinishing() || activity.isDestroyed()) return false;
        if(mode.equals("hdmi")) {
            TvInputManager manager=activity.getSystemService(TvInputManager.class);
            TvInputInfo input=manager==null ? null : manager.getTvInputInfo(target);
            return input!=null && input.getType()==TvInputInfo.TYPE_HDMI && input.isPassthroughInput()
                && new TvInputBridge(activity).launchTvInput(target);
        }
        if(!mode.equals("app") || target.equals(activity.getPackageName())) return false;
        var packages=activity.getPackageManager(); Intent intent=packages.getLeanbackLaunchIntentForPackage(target);
        if(intent==null) intent=packages.getLaunchIntentForPackage(target);
        if(intent==null) return false;
        activity.startActivity(intent); return true;
    }
    void close() {
        cancel(); if(listening) { activity.unregisterReceiver(screen); listening=false; }
        if(active.get()==this) active.clear();
    }
}
