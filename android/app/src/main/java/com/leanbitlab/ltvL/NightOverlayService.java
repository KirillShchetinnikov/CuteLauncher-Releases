package com.leanbitlab.ltvL;

import android.app.*;
import android.animation.ArgbEvaluator;
import android.animation.ValueAnimator;
import android.content.*;
import android.content.pm.ServiceInfo;
import android.graphics.Color;
import android.graphics.PixelFormat;
import android.os.*;
import android.provider.Settings;
import android.view.*;
import android.view.animation.LinearInterpolator;
import org.json.JSONObject;
import org.json.JSONArray;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;

/** User-enabled dimming and TCL scheduling; never grabs input or wakes the TV. */
public class NightOverlayService extends Service {
    private static final String PREF = "night_overlay", KEY = "configuration";
    private static final String CHANNEL = "night_mode", STOP = "night_mode_stop";
    private static java.lang.ref.WeakReference<NightOverlayService> activeService = new java.lang.ref.WeakReference<>(null);
    private final Handler handler = new Handler(Looper.getMainLooper());
    private final ExecutorService worker = Executors.newSingleThreadExecutor();
    private View overlay;
    private WindowManager windows;
    private ValueAnimator filterAnimation;
    private float shownAlpha, targetAlpha;
    private int shownColor, targetColor;
    private JSONObject config = new JSONObject();
    private boolean overlayFailed;
    private boolean destroyed;
    private Boolean lastTclTarget;
    private final NightForegroundTracker foreground = new NightForegroundTracker();
    private final NightHdmiTracker hdmi = new NightHdmiTracker();
    private boolean tracking, excluded;
    private boolean trackingReady;
    private JSONObject trackedConfiguration;
    private int trackingGeneration;
    private final Runnable checkForeground = () -> {
        final int generation = trackingGeneration;
        final JSONObject configuration = config;
        worker.execute(() -> {
            String name = foreground.read(this, System.currentTimeMillis());
            java.util.Set<String> selectedInputs = null;
            if (configuration.optBoolean("selectHdmiInputs")) {
                selectedInputs = new java.util.HashSet<>();
                JSONArray ids = configuration.optJSONArray("ignoredHdmiInputIds");
                if (ids != null) for (int i = 0; i < ids.length(); i++) selectedInputs.add(ids.optString(i));
            }
            boolean skip = pictureExcluded(configuration) || excluded(configuration, name)
                || configuration.optBoolean("ignoreHdmiInputs", true)
                    && (selectedInputs == null || !selectedInputs.isEmpty()) && hdmi.read(this, name, selectedInputs);
            handler.post(() -> {
                if (destroyed || !tracking || generation != trackingGeneration) return;
                if (configuration != config) { this.checkForegroundAgain.run(); return; }
                excluded = skip;
                trackingReady = true;
                trackedConfiguration = configuration;
                refresh();
                if (tracking) handler.postDelayed(this.checkForegroundAgain, 2000);
            });
        });
    };
    // Separate indirection avoids referencing a field from its own initializer.
    private final Runnable checkForegroundAgain = () -> checkForeground.run();
    private final Runnable tick = new Runnable() {
        @Override public void run() { refresh(); handler.postDelayed(this, 60000); }
    };
    private final BroadcastReceiver changes = new BroadcastReceiver() {
        @Override public void onReceive(Context c, Intent i) { refresh(); }
    };

    private static JSONObject load(Context context) {
        try { return new JSONObject(context.getSharedPreferences(PREF, MODE_PRIVATE).getString(KEY, "{}")); }
        catch (Exception e) { return new JSONObject(); }
    }
    private static final Map<BinaryMessenger, io.flutter.plugin.common.EventChannel.EventSink> visibilitySinks = new HashMap<>();
    private static final Map<BinaryMessenger, io.flutter.plugin.common.EventChannel.EventSink> panelSinks = new HashMap<>();
    static void detachVisibility(BinaryMessenger messenger) { visibilitySinks.remove(messenger); panelSinks.remove(messenger); }
    private static void emitVisibility(boolean visible) { for (var sink : java.util.List.copyOf(visibilitySinks.values())) sink.success(visible); }
    private static Map<String, Object> panelState() {
        NightOverlayService instance = activeService.get();
        return Map.of("visible", instance != null && instance.overlay != null,
            "excluded", instance != null && instance.excluded,
            "presentationReady", instance == null || !instance.tracking
                || instance.trackingReady && instance.trackedConfiguration == instance.config);
    }
    private static void emitPanelState() {
        var state = panelState();
        for (var sink : java.util.List.copyOf(panelSinks.values())) sink.success(state);
    }
    static boolean popupExcluded() {
        NightOverlayService service=activeService.get();
        return service != null && service.excluded;
    }
    static void register(Context activity, BinaryMessenger messenger, ExecutorService executor) {
        new io.flutter.plugin.common.EventChannel(messenger, "cutelauncher/night_panel_state").setStreamHandler(new io.flutter.plugin.common.EventChannel.StreamHandler() {
            public void onListen(Object args, io.flutter.plugin.common.EventChannel.EventSink sink) {
                panelSinks.put(messenger, sink);
                sink.success(panelState());
            }
            public void onCancel(Object args) { panelSinks.remove(messenger); }
        });
        new io.flutter.plugin.common.EventChannel(messenger, "cutelauncher/night_visibility").setStreamHandler(new io.flutter.plugin.common.EventChannel.StreamHandler() {
            public void onListen(Object args, io.flutter.plugin.common.EventChannel.EventSink sink) {
                visibilitySinks.put(messenger, sink);
                NightOverlayService instance = activeService.get();
                sink.success(instance != null && instance.overlay != null);
            }
            public void onCancel(Object args) { visibilitySinks.remove(messenger); }
        });
        new MethodChannel(messenger, "cutelauncher/night").setMethodCallHandler((call, result) -> {
            try {
                if (call.method.equals("solarCache")) {
                    // Read only: capture must never configure filters or refresh the network cache.
                    result.success(NightSolarTimes.list(NightSolarTimes.days(activity, load(activity))));
                    return;
                }
                if (call.method.equals("pictureMode")) {
                    executor.execute(() -> {
                        Integer mode = TclPictureMode.read();
                        new Handler(Looper.getMainLooper()).post(() -> result.success(mode));
                    });
                    return;
                }
                if (call.method.equals("cities")) {
                    String query = call.argument("query"), language = call.argument("language");
                    new Thread(() -> {
                        try {
                            var cities = NightSolarTimes.cities(query, language);
                            new Handler(Looper.getMainLooper()).post(() -> result.success(cities));
                        } catch (Exception e) { new Handler(Looper.getMainLooper()).post(() -> result.error("unavailable", "City search unavailable", null)); }
                    }, "NightCitySearch").start();
                    return;
                }
                if (call.method.equals("batterySettings")) {
                    if (activity instanceof Activity foreground) result.success(openBatterySettings(foreground, call.argument("guide"), Boolean.TRUE.equals(call.argument("withoutOverlay"))));
                    else { activity.startActivity(new Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)); result.success("opened"); }
                    return;
                }
                if (call.method.equals("permission")) {
                    Intent intent = new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        android.net.Uri.parse("package:" + activity.getPackageName()));
                    try { activity.startActivity(intent); }
                    catch (ActivityNotFoundException e) { activity.startActivity(new Intent(Settings.ACTION_SETTINGS)); }
                } else if (call.method.equals("usagePermission")) {
                    try { activity.startActivity(new Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)); }
                    catch (ActivityNotFoundException e) { activity.startActivity(new Intent(Settings.ACTION_SETTINGS)); }
                } else if (call.method.equals("notifications")) {
                    if (activity instanceof Activity foreground && Build.VERSION.SDK_INT >= 33 && activity.checkSelfPermission(
                            android.Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED
                            && (!activity.getSharedPreferences(PREF, MODE_PRIVATE).getBoolean("notification_requested", false)
                                || foreground.shouldShowRequestPermissionRationale(android.Manifest.permission.POST_NOTIFICATIONS))) {
                        activity.getSharedPreferences(PREF, MODE_PRIVATE).edit().putBoolean("notification_requested", true).apply();
                        foreground.requestPermissions(new String[]{android.Manifest.permission.POST_NOTIFICATIONS}, 2401);
                    } else if (!notificationsAllowed(activity)) {
                        Intent intent = new Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                            .putExtra(Settings.EXTRA_APP_PACKAGE, activity.getPackageName());
                        try { activity.startActivity(intent); }
                        catch (ActivityNotFoundException e) {
                            activity.startActivity(new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                android.net.Uri.parse("package:" + activity.getPackageName())));
                        }
                    }
                } else if (call.method.equals("configure")) {
                    if (!(call.arguments instanceof Map<?, ?> arguments)
                            || arguments.keySet().stream().anyMatch(key -> !(key instanceof String))) {
                        result.error("invalid", "Invalid night mode", null); return;
                    }
                    JSONObject value = new JSONObject(arguments);
                    if (!valid(value)) { result.error("invalid", "Invalid night mode", null); return; }
                    activity.getSharedPreferences(PREF, MODE_PRIVATE).edit().putString(KEY, value.toString()).apply();
                    NightOverlayService instance = activeService.get();
                    if (!value.optBoolean("enabled") || (!OverlayPermission.granted(activity)
                        && !(value.optBoolean("tclScheduled", true)))) {
                        if (instance != null) { instance.config = value; instance.restoreTcl(); }
                        activity.stopService(new Intent(activity, NightOverlayService.class));
                    } else {
                        if (instance != null) {
                            // Slider changes do not invalidate the resolved foreground exclusions.
                            if (instance.trackedConfiguration == instance.config && sameExclusions(instance.config, value))
                                instance.trackedConfiguration=value;
                            instance.config = value; instance.overlayFailed = false; instance.refresh();
                        }
                        else activity.startForegroundService(new Intent(activity, NightOverlayService.class));
                    }
                    LauncherNotificationListenerService.refreshNightFilter();
                } else if (!call.method.equals("status") && !call.method.equals("solarRefresh")) { result.notImplemented(); return; }
                JSONObject c = load(activity);
                NightSolarTimes.refresh(activity.getApplicationContext(), c, call.method.equals("solarRefresh"), () -> {
                    NightOverlayService service = activeService.get();
                    if (service != null) service.handler.post(() -> {
                        if (!service.destroyed && activeService.get() == service) service.refresh();
                    });
                });
                result.success(status(activity, c));
            } catch (Exception e) { result.error("unavailable", "Night mode service unavailable", null); }
        });
    }
    static Map<String, Object> status(Context context, JSONObject c) {
        NightOverlayService instance = activeService.get();
        JSONArray days = NightSolarTimes.days(context, c);
        long now = System.currentTimeMillis();
        boolean granted = OverlayPermission.granted(context) && (instance == null || !instance.overlayFailed);
        Map<String, Object> status = new HashMap<>();
        PowerManager power = context.getSystemService(PowerManager.class);
        status.put("batteryExempt", power == null ? null : power.isIgnoringBatteryOptimizations(context.getPackageName()));
        status.put("permission", granted); status.put("notifications", notificationsAllowed(context));
        status.put("running", instance != null); status.put("visible", instance != null && instance.overlay != null);
        status.put("active", NightSchedule.active(c, days, now, false));
        status.put("usagePermission", NightForegroundTracker.allowed(context));
        status.put("localExcluded", NightForegroundTracker.allowed(context) && excluded(c, context.getPackageName()));
        status.put("excluded", instance != null && instance.excluded);
        status.put("presentationReady", panelState().get("presentationReady"));
        status.put("solarDays", NightSolarTimes.list(days));
        status.put("solarLoading", NightSolarTimes.loading());
        status.put("solarUpdated", NightSolarTimes.cache(context, c).optLong("updated"));
        status.put("nextStart", NightSchedule.next(c, days, now, true));
        status.put("nextEnd", NightSchedule.next(c, days, now, false));
        return status;
    }
    static boolean batterySettingsAvailable(Context context) {
        return settingsIntent(context, Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS) != null;
    }
    private static Intent settingsIntent(Context context, String action) {
        var candidates = context.getPackageManager().queryIntentActivities(new Intent(action),
            android.content.pm.PackageManager.MATCH_DEFAULT_ONLY);
        // Android TV may advertise a no-op stub rather than an actual settings page.
        // Choose the system Settings explicitly; a resolver can hide overlays.
        for (String preferred : new String[]{"com.android.tv.settings", "com.android.settings", ""}) {
            for (var candidate : candidates) {
                var info = candidate.activityInfo;
                if (info == null || !info.enabled || !info.exported
                        || info.name.endsWith(".EmptyStubActivity")) continue;
                if (preferred.isEmpty()) {
                    if ((info.applicationInfo.flags & android.content.pm.ApplicationInfo.FLAG_SYSTEM) == 0) continue;
                } else if (!info.packageName.equals(preferred)) continue;
                return new Intent(action).setComponent(new ComponentName(info.packageName, info.name));
            }
        }
        return null;
    }
    static String openBatterySettings(Activity activity, Map<String, Object> guide, boolean withoutOverlay) {
        BatterySettingsGuide.close(activity);
        Intent direct = settingsIntent(activity, Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS);
        if (direct != null) {
            try {
                activity.startActivity(direct);
                return "opened";
            } catch (ActivityNotFoundException | SecurityException ignored) {}
        }
        for (String action : new String[]{Settings.ACTION_APPLICATION_SETTINGS, Settings.ACTION_MANAGE_APPLICATIONS_SETTINGS}) {
            Intent intent = settingsIntent(activity, action);
            if (intent == null) continue;
            if (!withoutOverlay && !BatterySettingsGuide.show(activity, guide)) return "hintRequired";
            try {
                activity.startActivity(intent);
                return "opened";
            } catch (ActivityNotFoundException | SecurityException ignored) { BatterySettingsGuide.close(activity); }
        }
        return "unavailable";
    }
    private static boolean notificationsAllowed(Context context) {
        NotificationManager manager = context.getSystemService(NotificationManager.class);
        NotificationChannel channel = manager.getNotificationChannel(CHANNEL);
        return manager.areNotificationsEnabled() && (channel == null || channel.getImportance() != NotificationManager.IMPORTANCE_NONE);
    }
    private static boolean integer(JSONObject c, String key, int min, int max, int fallback) {
        Object v = c.opt(key); if (v == null) v = fallback;
        return (v instanceof Integer || v instanceof Long) && ((Number)v).longValue() >= min && ((Number)v).longValue() <= max;
    }
    static boolean valid(JSONObject c) {
        try {
            if (c.has("ignoredPictureModes")) {
                JSONArray modes = c.getJSONArray("ignoredPictureModes");
                if (modes.length() > 128) return false;
                for (int i = 0; i < modes.length(); i++) {
                    Object mode = modes.get(i);
                    if (!(mode instanceof Integer || mode instanceof Long)
                        || ((Number)mode).longValue() < 0 || ((Number)mode).longValue() > 255) return false;
                }
            }
            if (c.has("ignoredHdmiInputIds")) {
                JSONArray ids = c.getJSONArray("ignoredHdmiInputIds");
                if (ids.length() > 128) return false;
                for (int i = 0; i < ids.length(); i++) {
                    Object id = ids.get(i);
                    if (!(id instanceof String) || ((String)id).isEmpty() || ((String)id).length() > 512) return false;
                }
            }
            if (c.has("excludedPackages")) {
                JSONArray packages = c.getJSONArray("excludedPackages");
                if (packages.length() > 128) return false;
                for (int i = 0; i < packages.length(); i++) {
                    Object p = packages.get(i);
                    if (!(p instanceof String) || ((String)p).length() > 255
                        || !((String)p).matches("[A-Za-z][A-Za-z0-9_]*(\\.[A-Za-z][A-Za-z0-9_]*)+")) return false;
                }
            }
            if (!(c.get("enabled") instanceof Boolean) || !(c.get("scheduled") instanceof Boolean)) return false;
            if (!integer(c,"startHour",0,23,22) || !integer(c,"endHour",0,23,7)
                || !integer(c,"startMinute",0,59,0) || !integer(c,"endMinute",0,59,0)
                || !integer(c,"dim",0,95,30) || !integer(c,"warmth",0,90,10)
                || !integer(c,"temperature",1000,6500,2700)
                || !integer(c,"sunsetOffset",-360,360,0) || !integer(c,"sunriseOffset",-360,360,0) || !integer(c,"transitionMinutes",15,120,60)
                || c.optInt("transitionMinutes",60) % 15 != 0) return false;
            for (String key : new String[]{"solar", "tclScheduled", "automaticLocation", "ignoreHdmiInputs", "selectHdmiInputs"}) if (c.has(key) && !(c.get(key) instanceof Boolean)) return false;
            for (String prefix : new String[]{"override", "tclOverride"}) {
                String mode = c.optString(prefix + "Mode", "none");
                if (!mode.equals("none") && !mode.equals("on") && !mode.equals("off")) return false;
                Object until = c.opt(prefix + "Until");
                if (until != null && (!(until instanceof Integer || until instanceof Long)
                    || ((Number)until).longValue() < 0 || ((Number)until).longValue() > 4102444800000L)) return false;
            }
            if (c.has("city") && (!(c.get("city") instanceof String) || c.getString("city").length() > 200)) return false;
            if (c.isNull("latitude") != c.isNull("longitude")) return false;
            if (!c.isNull("latitude")) {
                Object lat = c.get("latitude"), lon = c.get("longitude");
                if (!(lat instanceof Number) || !(lon instanceof Number)) return false;
                double a=((Number)lat).doubleValue(), b=((Number)lon).doubleValue();
                if (!Double.isFinite(a) || !Double.isFinite(b) || Math.abs(a)>90 || Math.abs(b)>180) return false;
            }
            return true;
        } catch (Exception e) { return false; }
    }
    static void restoreAfterBoot(Context context) {
        try {
            JSONObject c = load(context);
            if (valid(c) && c.optBoolean("enabled") && (OverlayPermission.granted(context)
                    || (c.optBoolean("tclScheduled", true))))
                context.startForegroundService(new Intent(context, NightOverlayService.class));
        } catch (Exception ignored) { /* Next launcher opening retries if OEM blocks boot start. */ }
    }
    @Override public void onCreate() {
        super.onCreate(); activeService=new java.lang.ref.WeakReference<>(this); windows=(WindowManager)getSystemService(WINDOW_SERVICE);
        IntentFilter filter=new IntentFilter();
        filter.addAction(Intent.ACTION_SCREEN_OFF); filter.addAction(Intent.ACTION_SCREEN_ON);
        filter.addAction(Intent.ACTION_TIME_CHANGED); filter.addAction(Intent.ACTION_TIMEZONE_CHANGED);
        if (Build.VERSION.SDK_INT>=33) registerReceiver(changes, filter, Context.RECEIVER_NOT_EXPORTED);
        else registerReceiver(changes, filter);
    }
    @Override public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null && STOP.equals(intent.getAction())) {
            try {
                JSONObject c=load(this); c.put("enabled",false); config=c;
                getSharedPreferences(PREF, MODE_PRIVATE).edit().putString(KEY,c.toString()).apply();
                getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE).edit()
                    .putString("flutter.night_mode_configuration",c.toString()).apply();
                restoreTcl();
            } catch (Exception ignored) {}
            stopSelf(); return START_NOT_STICKY;
        }
        NotificationManager manager=getSystemService(NotificationManager.class);
        manager.createNotificationChannel(new NotificationChannel(CHANNEL,getString(R.string.night_mode_title),NotificationManager.IMPORTANCE_LOW));
        PendingIntent stop=PendingIntent.getService(this,0,new Intent(this,NightOverlayService.class).setAction(STOP),PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
        PendingIntent open=PendingIntent.getActivity(this,1,new Intent(this,MainActivity.class),PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
        Notification notice=new Notification.Builder(this,CHANNEL).setSmallIcon(android.R.drawable.ic_menu_view)
            .setOnlyAlertOnce(true)
            .setContentTitle(getString(R.string.night_mode_title)).setContentText(getString(R.string.night_mode_notice))
            .setContentIntent(open).setOngoing(true).addAction(new Notification.Action.Builder(
                android.graphics.drawable.Icon.createWithResource(this, android.R.drawable.ic_menu_close_clear_cancel),
                getString(R.string.night_mode_stop), stop).build()).build();
        if (Build.VERSION.SDK_INT>=34) startForeground(2401,notice,ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE);
        else startForeground(2401,notice);
        config=load(this); overlayFailed=false;
        handler.removeCallbacks(tick); tick.run(); return START_STICKY;
    }
    private void refresh() {
        try { refreshFilter(); }
        finally { emitPanelState(); }
    }
    private void refreshFilter() {
        if (destroyed) return;
        LauncherNotificationListenerService.refreshNightFilter();
        if (!valid(config) || !config.optBoolean("enabled")) { remove(); restoreTcl(); stopSelf(); return; }
        NightSolarTimes.refresh(getApplicationContext(), config, false, () -> handler.post(this::refresh));
        JSONArray days = NightSolarTimes.days(this, config); long now = System.currentTimeMillis();
        PowerManager power=(PowerManager)getSystemService(POWER_SERVICE);
        boolean active=NightSchedule.active(config, days, now, false);
        boolean tclActive=config.optBoolean("tclScheduled", true)
            && active;
        JSONArray selectedInputs = config.optJSONArray("ignoredHdmiInputIds");
        boolean hdmiNeeded = config.optBoolean("ignoreHdmiInputs", true)
            && (!config.optBoolean("selectHdmiInputs") || selectedInputs != null && selectedInputs.length() > 0);
        JSONArray pictureModes = config.optJSONArray("ignoredPictureModes");
        boolean pictureNeeded = pictureModes != null && pictureModes.length() > 0;
        boolean needed=power.isInteractive() && (active || tclActive)
            && (pictureNeeded || NightForegroundTracker.allowed(this) && (hdmiNeeded
                || config.optJSONArray("excludedPackages") != null && config.optJSONArray("excludedPackages").length() > 0));
        if (needed != tracking) {
            tracking=needed; trackingGeneration++;
            trackingReady=false; trackedConfiguration=null;
            handler.removeCallbacks(checkForegroundAgain);
            excluded=false;
            worker.execute(() -> { foreground.reset(); hdmi.reset(); });
            if (needed) checkForeground.run();
        }
        // Wait before first adding a filter, but keep an existing window/TCL state while
        // refreshing exclusions. Home resync and unrelated selections must not cause a bright gap.
        if (needed && pictureNeeded && (!trackingReady || trackedConfiguration != config)) {
            return;
        }
        if (config.optBoolean("tclScheduled", true)) {
            boolean target = tclActive && !excluded;
            if (lastTclTarget == null || lastTclTarget != target) {
                lastTclTarget=target;
                worker.execute(() -> {
                    try { synchronized (TclBlueLight.class) {
                        TclBlueLight filter = new TclBlueLight();
                        if (!getSharedPreferences(PREF, MODE_PRIVATE).contains("tcl_original"))
                            saveTclOriginal(filter.read());
                        filter.set(target);
                    }} catch (Exception | LinkageError e) { handler.post(() -> lastTclTarget=null); }
                });
            }
        } else restoreTcl();
        if (!OverlayPermission.granted(this)) { remove(); if (!(config.optBoolean("tclScheduled", true))) stopSelf(); return; }
        float intensity=(float)NightSchedule.intensity(config, days, now);
        float dim=config.optInt("dim")/100f*intensity, warm=config.optInt("warmth")/100f*intensity, alpha=dim+warm*(1-dim);
        if (!active || excluded || !power.isInteractive() || alpha==0) { remove(); return; }
        float factor=warm*(1-dim)/alpha;
        double t=config.optInt("temperature",2700)/100.0;
        int red=255, green=clamp(99.4708025861*Math.log(t)-161.1195681661);
        int blue=t<=19 ? 0 : clamp(138.5177312231*Math.log(t-10)-305.0447927307);
        int color=Color.rgb(Math.round(red*factor),Math.round(green*factor),Math.round(blue*factor));
        WindowManager.LayoutParams params=new WindowManager.LayoutParams(-1,-1,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE|WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE|WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT);
        // TV remote key events remain unaffected; Android may block touch through opacity > .8.
        params.alpha=alpha; params.gravity=Gravity.TOP|Gravity.START;
        params.layoutInDisplayCutoutMode=WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS;
        params.setTitle("CuteLauncher Night Mode");
        try {
            if (overlay==null) {
                View view=new View(this); view.setBackgroundColor(color); windows.addView(view,params); overlay=view;
                shownAlpha=targetAlpha=alpha; shownColor=targetColor=color;
                LauncherNotificationListenerService.raiseAboveNightFilter(); emitVisibility(true);
            } else animateFilter(alpha, color);
            overlayFailed=false;
        } catch (RuntimeException e) { overlayFailed=true; remove(); }
    }
    private static boolean sameExclusions(JSONObject first, JSONObject second) {
        for (String key : new String[]{"excludedPackages", "ignoreHdmiInputs", "selectHdmiInputs",
                "ignoredHdmiInputIds", "ignoredPictureModes"}) {
            if (!String.valueOf(first.opt(key)).equals(String.valueOf(second.opt(key)))) return false;
        }
        return true;
    }
    private void animateFilter(float alpha, int color) {
        if (targetAlpha == alpha && targetColor == color) return;
        if (filterAnimation != null) filterAnimation.cancel();
        targetAlpha=alpha; targetColor=color;
        final float fromAlpha=shownAlpha;
        final int fromColor=shownColor;
        final View view=overlay;
        final WindowManager.LayoutParams params=(WindowManager.LayoutParams)view.getLayoutParams();
        final ArgbEvaluator colors=new ArgbEvaluator();
        filterAnimation=ValueAnimator.ofFloat(0, 1);
        filterAnimation.setDuration(180);
        filterAnimation.setInterpolator(new LinearInterpolator());
        filterAnimation.addUpdateListener(animation -> {
            if (destroyed || overlay != view) return;
            float progress=(float)animation.getAnimatedValue();
            shownAlpha=fromAlpha+(alpha-fromAlpha)*progress;
            shownColor=(int)colors.evaluate(progress, fromColor, color);
            params.alpha=shownAlpha;
            try {
                view.setBackgroundColor(shownColor);
                windows.updateViewLayout(view,params);
            } catch (RuntimeException e) { overlayFailed=true; remove(); }
        });
        filterAnimation.start();
    }
    private static int clamp(double value) { return (int)Math.round(Math.max(0,Math.min(255,value))); }
    static boolean pictureExcluded(JSONObject configuration) {
        JSONArray modes = configuration.optJSONArray("ignoredPictureModes");
        if (modes == null || modes.length() == 0) return false;
        java.util.Set<Integer> selected = new java.util.HashSet<>();
        for (int i = 0; i < modes.length(); i++) selected.add(modes.optInt(i, -1));
        return TclPictureMode.excluded(TclPictureMode.read(), selected);
    }

    static boolean excluded(JSONObject configuration, String packageName) {
        if (packageName == null) return false;
        JSONArray packages = configuration.optJSONArray("excludedPackages");
        if (packages != null) for (int i=0; i<packages.length(); i++)
            if (packageName.equals(packages.optString(i))) return true;
        return false;
    }
    // Runs on the worker: persist recovery before changing the OEM setting.
    @android.annotation.SuppressLint("ApplySharedPref")
    private void saveTclOriginal(boolean original) throws java.io.IOException {
        if (!getSharedPreferences(PREF, MODE_PRIVATE).edit().putBoolean("tcl_original", original).commit()) {
            throw new java.io.IOException("Cannot save TCL recovery state");
        }
    }
    private void restoreTcl() {
        lastTclTarget=null;
        if (!getSharedPreferences(PREF, MODE_PRIVATE).contains("tcl_original") || worker.isShutdown()) return;
        // While linked, switching the main filter off must also switch TCL off.
        boolean restoreOriginal = !config.optBoolean("tclScheduled", true);
        worker.execute(() -> {
            try { synchronized (TclBlueLight.class) {
                if (!getSharedPreferences(PREF, MODE_PRIVATE).contains("tcl_original")) return;
                new TclBlueLight().set(restoreOriginal &&
                    getSharedPreferences(PREF, MODE_PRIVATE).getBoolean("tcl_original",false));
                getSharedPreferences(PREF, MODE_PRIVATE).edit().remove("tcl_original").apply();
            }} catch (Exception | LinkageError ignored) {}
        });
    }
    private void remove() {
        if (filterAnimation != null) { filterAnimation.cancel(); filterAnimation=null; }
        if (overlay!=null) { try { windows.removeView(overlay); } catch (RuntimeException ignored) {} overlay=null; emitVisibility(false); }
    }
    @Override public void onDestroy() {
        destroyed=true;
        handler.removeCallbacksAndMessages(null); remove(); worker.shutdown(); unregisterReceiver(changes);
        if (activeService.get()==this) activeService.clear();
        emitPanelState(); super.onDestroy();
    }
    @Override public IBinder onBind(Intent intent) { return null; }
}
