package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.os.Build;
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
    private static final long EVENT_MAX_AGE_MS = 60_000;
    private static final String FROM_HOME_KEY = "android.intent.extra.FROM_HOME_KEY";
    private static java.lang.ref.WeakReference<AutoLaunchBridge> active = new java.lang.ref.WeakReference<>(null);
    private final Activity activity;
    private final SharedPreferences preferences;
    private final WakeEvents wakeEvents;
    private final Handler main=new Handler(Looper.getMainLooper());
    final AutoLaunchPolicy policy;
    private final BackgroundStartup background;
    private boolean resumed,focused;
    static final class Timer implements AutoLaunchPolicy.Scheduler {
        private final Handler handler;
        private Runnable pending;
        Timer(Handler handler) { this.handler = handler; }
        public void post(Runnable work, long delay) {
            cancel(); pending = work; handler.postDelayed(work, delay);
        }
        public void cancel() {
            if (pending != null) handler.removeCallbacks(pending);
            pending = null;
        }
    }
    private android.net.ConnectivityManager.NetworkCallback networkCallback;
    private void watchNetwork(boolean enabled) {
        var manager = activity.getSystemService(android.net.ConnectivityManager.class);
        if (networkCallback != null) {
            try { if (manager != null) manager.unregisterNetworkCallback(networkCallback); }
            catch (RuntimeException ignored) { }
            networkCallback = null;
        }
        policy.networkAvailable(false);
        if (!enabled || manager == null) return;
        var callback = new android.net.ConnectivityManager.NetworkCallback() {
            private android.net.Network observed;
            @Override public void onAvailable(android.net.Network network) { observed = network; }
            @Override public void onCapabilitiesChanged(android.net.Network network, android.net.NetworkCapabilities caps) {
                if (networkCallback == this && network.equals(observed)) policy.networkAvailable(caps.hasCapability(
                        android.net.NetworkCapabilities.NET_CAPABILITY_VALIDATED));
            }
            @Override public void onLost(android.net.Network network) {
                if (networkCallback == this && network.equals(observed)) { observed = null; policy.networkAvailable(false); }
            }
        };
        try { networkCallback = callback; manager.registerDefaultNetworkCallback(callback, main); }
        catch (RuntimeException ignored) { networkCallback = null; }
    }
    /** The Application observes wake even between launcher Activity instances. */
    static final class WakeEvents extends BroadcastReceiver {
        private boolean listening;
        private long wakeAt = -1;

        void setEnabled(Context application, boolean enabled) {
            if (listening == enabled) return;
            if (enabled) {
                IntentFilter filter = new IntentFilter(Intent.ACTION_SCREEN_OFF);
                filter.addAction(Intent.ACTION_SCREEN_ON);
                if (Build.VERSION.SDK_INT >= 33) application.registerReceiver(this, filter, Context.RECEIVER_NOT_EXPORTED);
                else application.registerReceiver(this, filter);
            } else {
                application.unregisterReceiver(this);
                clearPending();
            }
            listening = enabled;
        }

        void clearPending() { wakeAt = -1; }

        long takePending() {
            long time = wakeAt;
            clearPending();
            return time;
        }

        @Override public void onReceive(Context context, Intent intent) {
            if (!listening) return;
            AutoLaunchBridge bridge = active.get();
            if (Intent.ACTION_SCREEN_OFF.equals(intent.getAction())) {
                clearPending();
                if (bridge != null) bridge.policy.cancel();
            } else if (Intent.ACTION_SCREEN_ON.equals(intent.getAction())) {
                // Android can keep only the latest screen broadcast for a cached process.
                wakeAt = SystemClock.elapsedRealtime();
                if (bridge != null) bridge.dispatchWake();
            }
        }
    }
    AutoLaunchBridge(Activity activity,BinaryMessenger messenger) {
        this.activity=activity; preferences=activity.getSharedPreferences("auto_launch",Context.MODE_PRIVATE);
        wakeEvents = ((LauncherApplication) activity.getApplication()).autoLaunchWake;
        background = new BackgroundStartup(activity);
        policy=new AutoLaunchPolicy(new Timer(main),this::launch);
        active=new java.lang.ref.WeakReference<>(this); reload();
        new MethodChannel(messenger,"cutelauncher/auto_launch").setMethodCallHandler((call,result) -> {
            if(background.handle(call.method, call.arguments, result)) return;
            if(call.method.equals("info")) result.success(info());
            else if(call.method.equals("save")) {
                Map<String,Object> config=call.arguments();
                if(!valid(config,activity.getPackageName())) { result.success(Map.of("status","invalid")); return; }
                boolean saved=preferences.edit().putString("mode",(String)config.get("mode"))
                    .putString("app",(String)config.get("app")).putString("input",(String)config.get("input"))
                    .putBoolean("boot",(Boolean)config.get("boot")).putBoolean("wake",(Boolean)config.get("wake"))
                    .putInt("delay",(Integer)config.get("delay"))
                    .putBoolean("waitForInternet", Boolean.TRUE.equals(config.get("waitForInternet"))).remove("boot_at").commit();
                if (saved) NativeSyncBridge.changed("native_config_auto_launch");
                wakeEvents.clearPending(); reload(); result.success(Map.of("status",saved?"success":"unavailable"));
            } else if(call.method.equals("cancel")) { cancel(); result.success(Map.of("status","success")); }
            else result.notImplemented();
        });
    }
    static boolean valid(Map<String,Object> map,String own) {
        if(map==null || (map.containsKey("waitForInternet") && !(map.get("waitForInternet") instanceof Boolean)) || !(map.get("mode") instanceof String) || !(map.get("app") instanceof String) || !(map.get("input") instanceof String)
            || !(map.get("boot") instanceof Boolean) || !(map.get("wake") instanceof Boolean) || !(map.get("delay") instanceof Integer)) return false;
        String mode=(String)map.get("mode"),app=(String)map.get("app"),input=(String)map.get("input"); int delay=(Integer)map.get("delay");
        if(!java.util.Set.of("off","app","hdmi").contains(mode) || delay<0 || delay>60 || input.length()>512 || app.length()>255
            || (!app.isEmpty() && (!app.matches("[A-Za-z][A-Za-z0-9_]*(\\.[A-Za-z][A-Za-z0-9_]*)+") || app.equals(own)))) return false;
        return mode.equals("off") || mode.equals("app") && !app.isEmpty() || mode.equals("hdmi") && !input.isEmpty();
    }
    Map<String,Object> info() {
        return Map.of("mode",preferences.getString("mode","off"),"app",preferences.getString("app",""),
            "input",preferences.getString("input",""),"boot",preferences.getBoolean("boot",false),
            "wake",preferences.getBoolean("wake",false),"delay",preferences.getInt("delay",5),"status",policy.status,"ownPackage",activity.getPackageName(),
            "waitForInternet", preferences.getBoolean("waitForInternet", false));
    }
    private void reload() {
        Map<String,Object> config=info();
        if(!valid(config,activity.getPackageName())) config=Map.of("mode","off","app","","input","","boot",false,"wake",false,"delay",5);
        String mode=(String)config.get("mode");
        policy.configure(mode,(String)config.get(mode.equals("hdmi")?"input":"app"),(Boolean)config.get("boot"),(Boolean)config.get("wake"),(Integer)config.get("delay"), Boolean.TRUE.equals(config.get("waitForInternet")));
        watchNetwork(resumed && mode.equals("app") && preferences.getBoolean("waitForInternet", false));
        wakeEvents.setEnabled(activity.getApplication(), !mode.equals("off") && (Boolean)config.get("wake"));
    }
    static void syncReload() {
        AutoLaunchBridge bridge = active.get();
        if (bridge != null) { bridge.wakeEvents.clearPending(); bridge.reload(); }
    }
    static void boot(Context context) {
        SharedPreferences prefs=context.getSharedPreferences("auto_launch",Context.MODE_PRIVATE);
        if((prefs.getString("mode","off").equals("off") || !prefs.getBoolean("boot",false))
                && !BackgroundStartup.enabled(context)) return;
        prefs.edit().putLong("boot_at",SystemClock.elapsedRealtime()).apply();
        AutoLaunchBridge bridge=active.get();
        if(bridge!=null && bridge.resumed && bridge.focused) bridge.dispatchBoot();
    }
    void resume() { resumed=true; watchNetwork(preferences.getString("mode", "off").equals("app") && preferences.getBoolean("waitForInternet", false)); focus(activity.hasWindowFocus()); }
    void focus(boolean value) {
        if(focused && !value) cancelScheduled(); focused=value;
        policy.foreground(resumed && focused);
        if(resumed && focused) { dispatchBoot(); dispatchWake(); }
    }
    void pause() { resumed=false; cancelScheduled(); policy.foreground(false); watchNetwork(false); }
    void onEntry(Intent intent) {
        if (intent == null) return;
        // Android also sends CATEGORY_HOME when it restores Home after waking.
        if (intent.getBooleanExtra("return_home", false) || Intent.ACTION_MAIN.equals(intent.getAction())
                && (intent.hasCategory(Intent.CATEGORY_LAUNCHER)
                    || intent.hasCategory(Intent.CATEGORY_LEANBACK_LAUNCHER)
                    || intent.hasCategory(Intent.CATEGORY_HOME) && intent.getBooleanExtra(FROM_HOME_KEY, false))) {
            cancel();
        }
    }
    void cancel() { wakeEvents.clearPending(); cancelScheduled(); }
    private void cancelScheduled() {
        if (preferences.contains("boot_at")) preferences.edit().remove("boot_at").apply();
        policy.cancel();
        background.cancel();
    }
    private void dispatchBoot() {
        long time=preferences.getLong("boot_at",-1); if(time>=0) preferences.edit().remove("boot_at").apply();
        if(time>=0 && fresh(time)) background.launch(
            () -> resumed && focused && activity.hasWindowFocus() && !activity.isFinishing() && !activity.isDestroyed(),
            () -> policy.event("boot"));
    }
    private void dispatchWake() {
        if (!resumed || !focused || !activity.hasWindowFocus()) return;
        long time = wakeEvents.takePending();
        if (time >= 0 && fresh(time)) policy.event("wake");
    }
    private boolean fresh(long time) { long age=SystemClock.elapsedRealtime()-time; return age>=0 && age<=EVENT_MAX_AGE_MS; }
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
        watchNetwork(false);
        cancelScheduled();
        background.close();
        if(active.get()==this) active.clear();
    }
}
