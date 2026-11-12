package com.leanbitlab.ltvL;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import java.io.File;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.*;
import org.json.*;

/** Explicit portable native settings; system permissions and runtime state stay local. */
final class NativeSyncBridge {
    private static final Object LOCK = new Object();
    private static Context application;
    private static final ThreadLocal<Boolean> importing = ThreadLocal.withInitial(() -> false);
    static String accountIdentity(String id, JSONObject account) throws Exception {
        if (id.equals("yandex") && account != null) {
            JSONObject payload = new JSONObject(account.getString("password"));
            account = new JSONObject().put("clientId", account.getString("user"))
                .put("connectionId", payload.getString("connectionId"));
        }
        return canonical(account);
    }
    static void changed(String record) {
        Context c = application;
        if (c != null && !importing.get()) c.getSharedPreferences("sync_change_times", 0).edit()
            .putLong(record, System.currentTimeMillis()).apply();
    }
    static final Map<String, Map<String, Object>> SETTINGS = Map.of(
        "auto_launch", Map.of("mode", "off", "app", "", "input", "", "boot", false, "wake", false, "delay", 5, "waitForInternet", false),
        "background_startup", Map.of("apps", List.of()),
        "recent_apps", Map.of("mode", "auto"),
        "launcher_control", Map.of("override_home", true),
        "vpn_widget", Map.ofEntries(Map.entry("selected", ""), Map.entry("onlyActive", false), Map.entry("showName", false),
            Map.entry("color", false), Map.entry("notify", false), Map.entry("wake", false), Map.entry("delay", 5),
            Map.entry("bootApp", ""), Map.entry("bootEnabled", false), Map.entry("bootMode", "client")));
    static final Set<String> SECRETS = Set.of("weather_token", "weather_yandex", "weather_openweather", "remote_mappings");
    private final Context context;
    private final SyncPrivateStore vault, journal;
    NativeSyncBridge(Context context) {
        this(context, new SyncPrivateStore(context, "vault"), new SyncPrivateStore(context, "journal"));
    }
    NativeSyncBridge(Context context, SyncPrivateStore vault, SyncPrivateStore journal) {
        this.context = context.getApplicationContext();
        application = this.context;
        this.vault = vault; this.journal = journal;
    }
    static void register(Context context, BinaryMessenger messenger) {
        NativeSyncBridge sync = new NativeSyncBridge(context);
        new MethodChannel(messenger, "cutelauncher/native_sync", io.flutter.plugin.common.StandardMethodCodec.INSTANCE,
            messenger.makeBackgroundTaskQueue()).setMethodCallHandler((call, result) -> {
                try {
                    synchronized (LOCK) {
                        switch (call.method) {
                            case "passwordInfo", "setPassword", "encryptFile", "decryptFile" -> {
                                String mode = call.argument("mode");
                                if (!Set.of("backup", "synchronization").contains(mode)) throw new IllegalArgumentException();
                                SyncPrivateStore passwords = new SyncPrivateStore(sync.context, "password-" + mode);
                                JSONObject state = passwords.read();
                                // An upgrade must not silently turn previously protected
                                // automatic transfers into plaintext exports.
                                if(!state.has("password") && !sync.vault.read().optString("key").isEmpty()) {
                                    state.put("password",sync.vault.read().getString("key"));passwords.write(state);
                                }
                                String password = state.optString("password");
                                if (call.method.equals("passwordInfo")) { result.success(!password.isEmpty()); break; }
                                if (call.method.equals("setPassword")) {
                                    String next = call.argument("password");
                                    if(next == null || next.length() > 1024) throw new IllegalArgumentException();
                                    JSONArray previous = state.optJSONArray("previous"); if(previous == null) previous = new JSONArray();
                                    if(!password.isEmpty() && !password.equals(next)) {
                                        boolean known = false; for(int i=0;i<previous.length();i++) known |= password.equals(previous.getString(i));
                                        if(!known) { if(previous.length() >= 8) throw new IllegalStateException(); previous.put(password); }
                                    }
                                    passwords.write(new JSONObject().put("password", next).put("previous", previous)); result.success(null); break;
                                }
                                File file = new File((String)call.argument("path")).getCanonicalFile();
                                String path = file.getPath();
                                if(!path.startsWith(sync.context.getCacheDir().getCanonicalPath() + File.separator) &&
                                   !path.startsWith(sync.context.getFilesDir().getCanonicalPath() + File.separator)) throw new IllegalArgumentException();
                                if(call.method.equals("encryptFile")) BackupDataCipher.transform(file, password, true);
                                else if(BackupDataCipher.encrypted(file)) {
                                    List<String> candidates = new ArrayList<>(); candidates.add(password);
                                    JSONArray previous = state.optJSONArray("previous");
                                    if(previous != null) for(int i=0;i<previous.length();i++) candidates.add(previous.getString(i));
                                    boolean opened = false;
                                    for(String candidate : candidates) { if(candidate.isEmpty()) continue; try { BackupDataCipher.transform(file, candidate, false); opened=true; break; } catch(java.security.GeneralSecurityException wrong) { /* Keep input intact. */ } }
                                    if(!opened) throw new java.security.GeneralSecurityException();
                                }
                                result.success(null);
                            }
                            case "keyInfo" -> result.success(!sync.vault.read().optString("key").isEmpty());
                            case "generateKey" -> result.success(SyncCipher.generate());
                            case "readKey" -> result.success(sync.vault.read().optString("key"));
                            case "setKey" -> {
                                String key = call.argument("key"); SyncCipher.key(key);
                                if (sync.journal.read().length() != 0) throw new IllegalStateException();
                                JSONObject state = sync.vault.read();
                                String previous = state.optString("key");
                                JSONArray history = state.optJSONArray("previousKeys"); if (history == null) history = new JSONArray();
                                if (!previous.isEmpty() && !previous.equalsIgnoreCase(key)) {
                                    if (history.length() >= 8) throw new IllegalStateException();
                                    history.put(previous);
                                }
                                sync.vault.write(new JSONObject().put("key", key.toLowerCase(Locale.ROOT)).put("previousKeys", history));
                                result.success(null);
                            }
                            case "capture" -> result.success(sync.capture());
                            case "changeTimes" -> result.success(sync.context.getSharedPreferences("sync_change_times", 0).getAll());
                            case "changed" -> {
                                String record = call.argument("record");
                                if (!Set.of("native_secret_weather_yandex", "native_secret_weather_openweather").contains(record)) throw new IllegalArgumentException();
                                changed(record); result.success(null);
                            }
                            case "validate" -> { sync.decodePacket(call.arguments()); result.success(null); }
                            case "identity" -> {
                                String id = call.argument("account");
                                if(!Set.of("webdav","drive","yandex","smb").contains(id)) throw new IllegalArgumentException();
                                String value = accountIdentity(id,
                                    BackupAccountProfile.store(sync.context, id, call.argument("profile")).snapshot());
                                byte[] hash = java.security.MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8));
                                result.success(java.util.Base64.getEncoder().encodeToString(hash));
                            }
                            case "begin" -> { sync.begin(call.arguments()); result.success(null); }
                            case "commit" -> { sync.journal.delete(); result.success(null); }
                            case "rollback" -> { sync.rollback(); result.success(null); }
                            default -> result.notImplemented();
                        }
                    }
                } catch (Exception ignored) {
                    // Never include arguments, credential values, URLs or exception details.
                    result.error("sync_storage", "Protected synchronization unavailable", null);
                }
            });
    }
    private static String canonical(Object value) throws Exception {
        if (value instanceof JSONObject object) {
            TreeMap<String, String> fields = new TreeMap<>();
            for (Iterator<String> it = object.keys(); it.hasNext();) { String k = it.next(); fields.put(k, canonical(object.get(k))); }
            List<String> pairs = new ArrayList<>(); fields.forEach((k,v) -> pairs.add(JSONObject.quote(k) + ":" + v));
            return "{" + String.join(",", pairs) + "}";
        }
        if (value instanceof JSONArray array) {
            List<String> entries = new ArrayList<>(); for (int i = 0; i < array.length(); i++) entries.add(canonical(array.get(i)));
            return "[" + String.join(",", entries) + "]";
        }
        return value == null || value == JSONObject.NULL ? "null" : value instanceof String text ? JSONObject.quote(text) : String.valueOf(value);
    }
    Map<String, String> capture() throws Exception {
        Map<String, String> result = new TreeMap<>();
        for (String area : SETTINGS.keySet()) result.put("native_config_" + area, canonical(readSettings(area)));
        // Transport accounts never enter snapshots. The outer file optionally
        // encrypts all portable data, including these stable private records.
        for (String id : SECRETS) result.put("native_secret_" + id,
            canonical(new JSONObject().put("plainVersion", 1).put("value", readSecret(id))));
        return result;

    }
    private JSONObject readSettings(String area) throws Exception {
        JSONObject value = new JSONObject();
        for (var e : context.getSharedPreferences(area, 0).getAll().entrySet()) {
            if (!allowed(area, e.getKey())) continue;
            Object v = e.getValue();
            if (v instanceof Set<?> set) {
                var list = new ArrayList<String>(set.size());
                for (Object item : set) list.add(item.toString());
                Collections.sort(list);
                v = new JSONArray(list);
            }
            value.put(e.getKey(), v);
        }
        return value;
    }
    private static boolean allowed(String area, String key) {
        return SETTINGS.containsKey(area) && (SETTINGS.get(area).containsKey(key) ||
            area.equals("vpn_widget") && key.startsWith("profile_") && VpnPolicy.packageName(key.substring(8)));
    }
    static void validateSettings(String area, JSONObject value) throws Exception {
        if (!SETTINGS.containsKey(area) || value.length() > 512) throw new IllegalArgumentException();
        for (Iterator<String> it = value.keys(); it.hasNext();) {
            String k = it.next(); Object v = value.get(k);
            if (!allowed(area, k)) throw new IllegalArgumentException();
            Object sample = SETTINGS.get(area).getOrDefault(k, "");
            if (sample instanceof Boolean ? !(v instanceof Boolean) : sample instanceof Integer ? !(v instanceof Integer) :
                sample instanceof List ? !(v instanceof JSONArray) : !(v instanceof String)) throw new IllegalArgumentException();
            if (v instanceof String s && s.length() > 4096) throw new IllegalArgumentException();
            if (k.equals("delay") && ((Integer)v < 0 || (Integer)v > 60)) throw new IllegalArgumentException();
            if (v instanceof JSONArray list) {
                if (list.length() > 200) throw new IllegalArgumentException();
                for (int i = 0; i < list.length(); i++) if (!VpnPolicy.packageName(list.getString(i))) throw new IllegalArgumentException();
            }
        }
        if (area.equals("recent_apps") && value.has("mode") && !Set.of("auto", "system", "custom").contains(value.getString("mode"))) throw new IllegalArgumentException();
        if (area.equals("auto_launch")) {
            Map<String, Object> full = new HashMap<>(SETTINGS.get(area));
            for (Iterator<String> it = value.keys(); it.hasNext();) { String k = it.next(); full.put(k, value.get(k)); }
            if (!AutoLaunchBridge.valid(full, "io.github.kirillshchetinnikov.cutelauncher") ||
                !AutoLaunchBridge.valid(full, "io.github.kirillshchetinnikov.cutelauncher.debug")) throw new IllegalArgumentException();
        }
        if (area.equals("vpn_widget")) {
            if (value.has("bootMode") && !Set.of("client", "alwaysOn").contains(value.getString("bootMode"))) throw new IllegalArgumentException();
            for (String k : List.of("selected", "bootApp")) if (value.has(k) && !value.getString(k).isEmpty() && !VpnPolicy.packageName(value.getString(k))) throw new IllegalArgumentException();
        }
    }
    private CloudAccountStore account(String id) {
        return id.equals("webdav") ? new CloudAccountStore(context) : new CloudAccountStore(
            new File(context.getNoBackupFilesDir(), "cloud/drive"), "cutelauncher_drive_account");
    }
    private Object readSecret(String id) throws Exception {
        return switch (id) {
            case "weather_token" -> Objects.requireNonNullElse(new WeatherTokenBridge(context).snapshot(), JSONObject.NULL);
            case "remote_mappings" -> new JSONObject(new RemoteMappingStore(context).load().toMap());
            case "webdav", "drive" -> Objects.requireNonNullElse(account(id).snapshot(), JSONObject.NULL);
            default -> {
                File f = weatherFile(id);
                if (f.length() > 4096) throw new IllegalArgumentException();
                yield f.exists() ? new String(Files.readAllBytes(f.toPath()), StandardCharsets.UTF_8) : JSONObject.NULL;
            }
        };
    }
    private File weatherFile(String id) {
        return new File(context.getFilesDir(), id.equals("weather_yandex") ? "weather-api-key" : "weather-api-key-openweather");
    }
    private void validateSecret(String id, Object value) throws Exception {
        if (!SECRETS.contains(id)) throw new IllegalArgumentException();
        if (value == JSONObject.NULL) return;
        switch (id) {
            case "remote_mappings" -> RemoteMappingStore.decode((JSONObject)value);
            case "weather_token" -> {
                JSONObject data = (JSONObject)value;
                String server = data.getString("server"), token = data.getString("token");
                if (server.length() > 4096 || !server.startsWith("https://") || token.length() > 1024) throw new IllegalArgumentException();
            }
            case "webdav", "drive" -> {
                JSONObject data = (JSONObject)value;
                CloudAccountStore.directory(data.getString("url"));
                CloudAccountStore.validate(data.getString("user"), data.getString("password"));
                if (id.equals("drive")) {
                    JSONObject payload = new JSONObject(data.getString("password"));
                    if (payload.length() != 3 || payload.getString("refreshToken").isEmpty() || !payload.getString("scope").equals("https://www.googleapis.com/auth/drive.file")) throw new IllegalArgumentException();
                    payload.getString("clientSecret");
                }
            }
            default -> { if (!(value instanceof String s) || s.length() > 4096) throw new IllegalArgumentException(); }
        }
    }
    JSONObject decodePacket(Map<String, String> packet) throws Exception {
        if (packet.size() > 32) throw new IllegalArgumentException();
        JSONObject incoming = new JSONObject();
        JSONObject state = vault.read();
        String key = state.optString("key");
        // Validate and decrypt every record before writing any setting.
        for (var e : packet.entrySet()) {
            if (e.getKey().startsWith("native_config_")) {
                String area = e.getKey().substring(14); JSONObject data = new JSONObject(e.getValue());
                validateSettings(area, data); incoming.put(e.getKey(), data);
            } else if (e.getKey().startsWith("native_secret_")) {
                String id = e.getKey().substring(14);
                if (id.equals("drive") || id.equals("webdav")) continue;
                JSONObject envelope = e.getValue().startsWith("{") ? new JSONObject(e.getValue()) : null;
                if (envelope != null && envelope.optInt("plainVersion") == 1) {
                    if(envelope.length()!=2) throw new IllegalArgumentException();
                    Object data = envelope.get("value"); validateSecret(id, data); incoming.put(e.getKey(),data); continue;
                }
                if (key.isEmpty()) throw new IllegalStateException();
                String clear = null;
                List<String> keys = new ArrayList<>(); keys.add(key);
                JSONArray previousKeys = state.optJSONArray("previousKeys");
                if (previousKeys != null) for (int i = 0; i < previousKeys.length(); i++) keys.add(previousKeys.getString(i));
                for (String candidate : keys) {
                    try { clear = SyncCipher.open(candidate, id, e.getValue()); break; }
                    catch (java.security.GeneralSecurityException wrongKey) { /* Try locally retained old keys. */ }
                }
                if (clear == null) throw new java.security.GeneralSecurityException();
                Object data = new JSONTokener(clear).nextValue();
                validateSecret(id, data); incoming.put(e.getKey(), data);
            } else throw new IllegalArgumentException();
        }
        return incoming;
    }
    void begin(Map<String, String> packet) throws Exception {
        if (journal.read().length() != 0) throw new IllegalStateException();
        JSONObject incoming = decodePacket(packet), old = new JSONObject();
        for (Iterator<String> it = incoming.keys(); it.hasNext();) {
            String name = it.next();
            String id = name.substring(14);
            old.put(name, name.startsWith("native_config_") ? readSettings(id) : readSecret(id));
        }
        journal.write(new JSONObject().put("old", old).put("vault", vault.read()));
        try {
            install(incoming);
            JSONObject state = vault.read(), cache = state.optJSONObject("cache"); if (cache == null) cache = new JSONObject();
            for (var e : packet.entrySet()) if (e.getKey().startsWith("native_secret_") && incoming.has(e.getKey())) {
                String id = e.getKey().substring(14);
                cache.put(id, new JSONObject().put("clear", canonical(incoming.get(e.getKey()))).put("sealed", e.getValue()));
            }
            state.put("cache", cache); vault.write(state);
        } catch (Exception failed) { rollback(); throw failed; }
    }
    private void install(JSONObject records) throws Exception {
        importing.set(true);
        try { installValues(records); }
        finally { importing.remove(); }
    }
    private void installValues(JSONObject records) throws Exception {
        for (Iterator<String> it = records.keys(); it.hasNext();) {
            String name = it.next(), id = name.substring(14); Object value = records.get(name);
            if (name.startsWith("native_config_")) {
                JSONObject data = (JSONObject)value; var prefs = context.getSharedPreferences(id, 0); var edit = prefs.edit();
                for (String k : prefs.getAll().keySet()) if (allowed(id, k)) edit.remove(k);
                for (Iterator<String> keys = data.keys(); keys.hasNext();) {
                    String k = keys.next(); Object v = data.get(k);
                    if (v instanceof Boolean b) edit.putBoolean(k, b);
                    else if (v instanceof Integer n) edit.putInt(k, n);
                    else if (v instanceof String s) edit.putString(k, s);
                    else if (v instanceof JSONArray a) { Set<String> set = new HashSet<>(); for (int i = 0; i < a.length(); i++) set.add(a.getString(i)); edit.putStringSet(k, set); }
                }
                if (!edit.commit()) throw new java.io.IOException();
            } else switch (id) {
                case "remote_mappings" -> {
                    var config = value == JSONObject.NULL ? RemoteMappingConfiguration.empty() : RemoteMappingStore.decode((JSONObject)value);
                    new RemoteMappingStore(context).save(config);
                    new Handler(Looper.getMainLooper()).post(() -> RemoteButtonRemapper.updated(config));
                }
                case "weather_token" -> {
                    JSONObject data = value == JSONObject.NULL ? new JSONObject().put("server", "").put("token", "") : (JSONObject)value;
                    new WeatherTokenBridge(context).save(data.getString("server"), data.getString("token"));
                }
                case "webdav", "drive" -> {
                    var store = account(id);
                    if (value == JSONObject.NULL) store.disconnect();
                    else { JSONObject data = (JSONObject)value; store.save(data.getString("url"), data.getString("user"), data.getString("password")); }
                }
                default -> {
                    File f = weatherFile(id);
                    if (value == JSONObject.NULL) Files.deleteIfExists(f.toPath());
                    else {
                        android.util.AtomicFile file = new android.util.AtomicFile(f); var stream = file.startWrite();
                        try { stream.write(((String)value).getBytes(StandardCharsets.UTF_8)); file.finishWrite(stream); }
                        catch (Exception error) { file.failWrite(stream); throw error; }
                    }
                }
            }
        }
        new Handler(Looper.getMainLooper()).post(AutoLaunchBridge::syncReload);
    }
    void rollback() throws Exception {
        JSONObject saved = journal.read(); if (saved.length() == 0) return;
        install(saved.getJSONObject("old")); vault.write(saved.getJSONObject("vault")); journal.delete();
    }
}
