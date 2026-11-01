package com.leanbitlab.ltvL;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.net.ConnectivityManager;
import android.net.NetworkCapabilities;
import android.os.Process;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/** Shared by the home engine, overlay engine and bounded startup job. Worker-thread only. */
final class VpnController {
    private static final Object CONTROL_LOCK = new Object();
    static final String PREFS = "vpn_widget";
    final Context context;
    final SharedPreferences prefs;
    private final java.util.function.Supplier<VpnPolicy.Active> ownerReader;
    private final java.util.function.BooleanSupplier activeReader;
    VpnController(Context context) {
        this(context, null, null);
    }
    VpnController(Context context, java.util.function.Supplier<VpnPolicy.Active> ownerReader,
            java.util.function.BooleanSupplier activeReader) {
        this.context = context;
        prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        this.ownerReader = ownerReader == null ? this::readOwner : ownerReader;
        this.activeReader = activeReader == null ? this::readActive : activeReader;
    }
    static String permission(String app) { return app + ".permission.CONTROL_TUNNELS"; }
    List<Map<String, Object>> clients() {
        var manager = context.getPackageManager();
        var result = new ArrayList<Map<String, Object>>();
        for (var entry : manager.queryIntentServices(new Intent("android.net.VpnService"), PackageManager.GET_META_DATA)) {
            var service = entry.serviceInfo;
            if (service == null || !service.enabled || !service.applicationInfo.enabled
                    || !"android.permission.BIND_VPN_SERVICE".equals(service.permission)) continue;
            String app = service.packageName;
            if (result.stream().anyMatch(row -> app.equals(row.get("app")))) continue;
            result.add(Map.of("app", app, "name", service.applicationInfo.loadLabel(manager).toString(),
                "supported", VpnPolicy.supported(app), "requiresProfile", VpnPolicy.requiresProfile(app),
                "alwaysOnSupported", service.applicationInfo.targetSdkVersion >= 24
                    && (service.metaData == null || service.metaData.getBoolean("android.net.VpnService.SUPPORTS_ALWAYS_ON", true)),
                "permission", VpnPolicy.supported(app) && (!VpnPolicy.requiresProfile(app)
                    || context.checkSelfPermission(permission(app)) == PackageManager.PERMISSION_GRANTED)));
        }
        result.sort((a, b) -> ((String)a.get("name")).compareToIgnoreCase((String)b.get("name")));
        return result;
    }
    boolean active() {
        return activeReader.getAsBoolean();
    }
    private boolean readActive() {
        var manager = context.getSystemService(ConnectivityManager.class);
        if (manager == null) throw new IllegalStateException("Network unavailable");
        for (var network : manager.getAllNetworks()) {
            var caps = manager.getNetworkCapabilities(network);
            if (caps != null && caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) return true;
        }
        return false;
    }
    VpnPolicy.Active owner() {
        return ownerReader.get();
    }
    private VpnPolicy.Active readOwner() {
        try {
            return AdbBridge.recentSession(context, shell -> VpnPolicy.parse(
                shell.execute("dumpsys vpn_management"), Process.myUid() / 100000));
        } catch (Exception unavailable) { return new VpnPolicy.Active("", ""); }
    }
    Map<String, Object> snapshot() {
        return snapshot(true);
    }
    Map<String, Object> snapshot(boolean identify) {
        boolean systemKnown = false;
        if (identify) {
            try { VpnAlwaysOn.refresh(context); systemKnown = true; }
            catch (Exception unavailable) { /* Cached configuration keeps first-frame/ADB failure paths local. */ }
        }
        var clients = clients();
        boolean active = active();
        var owner = active && identify ? owner() : new VpnPolicy.Active("", "");
        String app = owner.app();
        // Check the package is still an installed VPN service before remembering it.
        if (!app.isEmpty() && clients.stream().noneMatch(row -> app.equals(row.get("app"))))
            owner = new VpnPolicy.Active("", "");
        if (active && !owner.app().isEmpty()) {
            var edit = prefs.edit().putString("last", owner.app());
            if (!owner.profile().isEmpty()) edit.putString("profile_" + owner.app(), owner.profile());
            edit.apply();
        }
        String target = VpnPolicy.target(prefs.getString("selected", ""), active, owner.app(), prefs.getString("last", ""));
        String profile = prefs.getString("profile_" + target, "");
        boolean installed = clients.stream().anyMatch(row -> target.equals(row.get("app")));
        boolean supported = installed && VpnPolicy.supported(target);
        boolean requiresProfile = VpnPolicy.requiresProfile(target);
        boolean allowed = supported && (!requiresProfile || context.checkSelfPermission(permission(target)) == PackageManager.PERMISSION_GRANTED);
        String systemApp = prefs.getString("systemApp", "");
        // A pending reboot describes persisted boot configuration, not widget ownership.
        // Clearing our system selection must immediately restore direct client controls.
        boolean managed = active && !systemApp.isEmpty() && owner.app().equals(systemApp);
        var result = new HashMap<String, Object>();
        result.put("active", active); result.put("owner", owner.app()); result.put("target", target);
        result.put("activeProfile", owner.profile());
        result.put("profile", profile); result.put("clients", clients);
        var profiles = new HashMap<String, String>();
        for (var client : clients) {
            String name = (String)client.get("app");
            profiles.put(name, prefs.getString("profile_" + name, ""));
        }
        result.put("profiles", profiles);
        result.put("supported", supported); result.put("permission", allowed);
        result.put("requiresProfile", requiresProfile);
        result.put("systemApp", systemApp); result.put("systemKnown", systemKnown);
        result.put("managed", managed); result.put("restartRequired", prefs.getBoolean("restartRequired", false));
        result.put("bootMode", prefs.getString("bootMode", "client"));
        result.put("canRequestPermission", context instanceof android.app.Activity);
        result.put("canControl", allowed && !managed && (!requiresProfile || VpnPolicy.profileName(profile))
            && (!active || target.equals(owner.app()) && (!requiresProfile || profile.equals(owner.profile()))));
        result.put("selected", prefs.getString("selected", ""));
        result.put("onlyActive", prefs.getBoolean("onlyActive", true));
        result.put("showName", prefs.getBoolean("showName", false));
        result.put("color", prefs.getBoolean("color", true));
        result.put("notify", prefs.getBoolean("notify", true));
        result.put("bootApp", prefs.getString("bootApp", ""));
        result.put("bootEnabled", prefs.getBoolean("bootEnabled", !prefs.getString("bootApp", "").isEmpty()));
        result.put("wake", prefs.getBoolean("wake", false));
        result.put("delay", prefs.getInt("delay", 5));
        result.put("startupStatus", prefs.getString("startupStatus", "idle"));
        return result;
    }
    boolean save(Map<String, Object> data) {
        if (data == null || data.size() != 2 || !(data.get("key") instanceof String key)) return false;
        Object value = data.get("value");
        if (key.equals("bootApp") || key.equals("bootMode") || key.equals("bootEnabled")) {
            return saveStartup(key, value);
        }
        var edit = prefs.edit();
        if (key.equals("selected") && value instanceof String name
                && (name.isEmpty() || VpnPolicy.packageName(name))) {
            if (!name.isEmpty() && clients().stream().noneMatch(row -> name.equals(row.get("app")))) return false;
            edit.putString(key, name);
        } else if (List.of("onlyActive", "showName", "color", "notify", "wake").contains(key)
                && value instanceof Boolean flag) edit.putBoolean(key, flag);
        else if (key.equals("delay") && value instanceof Integer delay && delay >= 0 && delay <= 60) edit.putInt(key, delay);
        else if (key.startsWith("profile_") && VpnPolicy.packageName(key.substring(8)) && value instanceof String profile
                && (profile.isEmpty() || VpnPolicy.profileName(profile))) edit.putString(key, profile);
        else return false;
        return edit.commit();
    }
    private boolean saveStartup(String key, Object value) {
        if (key.equals("bootEnabled") ? !(value instanceof Boolean) : !(value instanceof String)) return false;
        String text = value instanceof String s ? s : "";
        synchronized (CONTROL_LOCK) {
            String app = key.equals("bootApp") ? text : prefs.getString("bootApp", "");
            boolean enabled = key.equals("bootEnabled") ? (Boolean)value
                : prefs.getBoolean("bootEnabled", !app.isEmpty());
            String mode = key.equals("bootMode") ? text : prefs.getString("bootMode", "client");
            if (!List.of("client", "alwaysOn").contains(mode)) return false;
            var clients = clients();
            if (enabled && !app.isEmpty() && clients.stream().noneMatch(row -> app.equals(row.get("app")))) return false;
            if (enabled && mode.equals("alwaysOn") && !app.isEmpty()
                    && clients.stream().noneMatch(row -> app.equals(row.get("app")) && Boolean.TRUE.equals(row.get("alwaysOnSupported")))) return false;
            try {
                if ((enabled && mode.equals("alwaysOn") && !app.isEmpty()) || !prefs.getString("ownedAlwaysOn", "").isEmpty()) {
                    if (!VpnAlwaysOn.configure(context, enabled && mode.equals("alwaysOn") ? app : "")) return false;
                }
            } catch (Exception unavailable) { return false; }
            boolean saved = prefs.edit().putBoolean("bootEnabled", enabled).putString("bootApp", app).putString("bootMode", mode).putString("startupStatus", "idle").commit();
            if (saved) VpnStartupJob.cancel(context);
            return saved;
        }
    }
    String command(String app, String profile, boolean up) {
        return command(app, profile, up, () -> true);
    }
    String command(String app, String profile, boolean up, java.util.function.BooleanSupplier valid) {
        synchronized (CONTROL_LOCK) { return commandLocked(app, profile, up, valid); }
    }
    private String commandLocked(String app, String profile, boolean up, java.util.function.BooleanSupplier valid) {
        if (!valid.getAsBoolean()) return "cancelled";
        if (!VpnPolicy.supported(app)) return "unsupported";
        boolean named = VpnPolicy.requiresProfile(app);
        if (named && !VpnPolicy.profileName(profile)) return "profile";
        if (named && context.checkSelfPermission(permission(app)) != PackageManager.PERMISSION_GRANTED) return "permission";
        var state = snapshot();
        if (!valid.getAsBoolean() || Thread.currentThread().isInterrupted()) return "cancelled";
        boolean active = Boolean.TRUE.equals(state.get("active"));
        if (active) {
            if (!app.equals(state.get("owner"))) return "other";
            if (!up && Boolean.TRUE.equals(state.get("managed"))) return "alwaysOn";
            // Never disconnect a stale/different profile.
            if (named && !profile.equals(state.get("activeProfile"))) return "profile";
            if (up) return "connected";
        } else if (!up) return "disconnected";
        if (app.equals("com.happproxy") || app.equals("su.happ.proxyutility")) {
            var intent = new Intent(Intent.ACTION_VIEW, android.net.Uri.parse("happ://" + (up ? "connect_without_ui" : "disconnect_without_ui")))
                .setPackage(app).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS);
            var resolved = context.getPackageManager().resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY);
            if (resolved == null || resolved.activityInfo == null || !resolved.activityInfo.exported) return "unsupported";
            // The no-UI command must not dismiss the quick-settings overlay's menu.
            context.getApplicationContext().startActivity(intent);
            return "sent";
        }
        if (app.equals("com.mantaray.vpn")) {
            // Public actions preserve MantaRay's own confirmation. Its widget broadcast is token-protected.
            var intent = new Intent(app + ".action." + (up ? "CONNECT" : "DISCONNECT"))
                .setClassName(app, app + ".VpnActionActivity")
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS);
            var resolved = context.getPackageManager().resolveActivity(intent, 0);
            if (resolved == null || resolved.activityInfo == null || !resolved.activityInfo.exported) return "unsupported";
            context.getApplicationContext().startActivity(intent);
            return "sent";
        }
        String action = app + ".action.SET_TUNNEL_" + (up ? "UP" : "DOWN");
        var intent = new Intent(action).setPackage(app).putExtra("tunnel", profile)
            .addFlags(Intent.FLAG_INCLUDE_STOPPED_PACKAGES | Intent.FLAG_RECEIVER_FOREGROUND);
        var receivers = context.getPackageManager().queryBroadcastReceivers(intent, 0);
        var receiver = receivers.stream().filter(row -> row.activityInfo != null && row.activityInfo.exported
            && app.equals(row.activityInfo.packageName)).findFirst();
        if (receiver.isEmpty()) return "unsupported";
        // Package-scoped broadcasts may not reach a cold/background receiver on TV firmware.
        // Resolve the client's exported handler and explicitly address that component.
        intent.setComponent(new android.content.ComponentName(app, receiver.get().activityInfo.name));
        context.sendBroadcast(intent);
        return "sent"; // Reception is not confirmation: the UI/job must observe the resulting state.
    }
    boolean open(String app) {
        if (!VpnPolicy.packageName(app) || clients().stream().noneMatch(row -> app.equals(row.get("app")))) return false;
        var manager = context.getPackageManager();
        Intent intent = manager.getLeanbackLaunchIntentForPackage(app);
        if (intent == null) intent = manager.getLaunchIntentForPackage(app);
        if (intent == null) return false;
        context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
        return true;
    }
}
