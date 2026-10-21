package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.Instrumentation;
import android.content.ContentValues;
import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.media.tv.TvContract;
import android.os.Build;
import android.os.Bundle;
import org.json.JSONObject;
import java.io.File;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;

/** Isolated emulator fixtures. Refuses real hardware and has an explicit restore phase. */
public final class EmulatorFixtureProbe extends Instrumentation {
    private Bundle arguments;
    private static final String PREFIX = "cutelauncher-acceptance-";
    @Override public void onCreate(Bundle args) { super.onCreate(args); arguments = args; start(); }
    @Override public void onStart() {
        Bundle report = new Bundle();
        try {
            if (!Build.HARDWARE.contains("ranchu") && !Build.HARDWARE.contains("goldfish"))
                throw new IllegalStateException("Fixtures may run only on an emulator");
            Context c = getTargetContext();
            getUiAutomation().adoptShellPermissionIdentity("com.android.providers.tv.permission.WRITE_EPG_DATA");
            SharedPreferences prefs = c.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE);
            File folder = new File(c.getNoBackupFilesDir(), PREFIX + "state");
            File wallpaper = new File(c.getDir("flutter", Context.MODE_PRIVATE), "wallpaper");
            String phase = arguments.getString("phase", "prepare");
            if (phase.equals("prepare")) {
                if (folder.exists()) throw new IllegalStateException("Restore previous fixtures before prepare");
                folder.mkdirs();
                JSONObject original = new JSONObject();
                for (var entry : prefs.getAll().entrySet()) {
                    Object value = entry.getValue();
                    if (!(value instanceof String || value instanceof Boolean || value instanceof Number))
                        throw new IllegalStateException("Unsupported preference type");
                    original.put(entry.getKey(), new JSONObject().put("type", value.getClass().getSimpleName()).put("value", value));
                }
                Files.write(new File(folder, "prefs.json").toPath(), original.toString().getBytes(java.nio.charset.StandardCharsets.UTF_8));
                if (wallpaper.exists()) Files.copy(wallpaper.toPath(), new File(folder, "wallpaper").toPath());
                File online = new File(c.getFilesDir(), "online-wallpaper");
                if (online.exists()) Files.copy(online.toPath(), new File(folder, "online-wallpaper").toPath());
                prefs.edit().putBoolean("flutter.show_continue_watching", true)
                    .putLong("flutter.continue_watching_max_items", 100).putString("flutter.app_language", "ru").commit();
                File poster = new File(folder, "poster.png");
                image(poster, 1800, 1000);
                for (int i = 0; i < 100; i++) {
                    ContentValues values = new ContentValues();
                    values.put(TvContract.WatchNextPrograms.COLUMN_TITLE, "Приёмка " + i + " — длинное русское название фильма");
                    values.put(TvContract.WatchNextPrograms.COLUMN_TYPE, TvContract.WatchNextPrograms.TYPE_MOVIE);
                    values.put(TvContract.WatchNextPrograms.COLUMN_WATCH_NEXT_TYPE, TvContract.WatchNextPrograms.WATCH_NEXT_TYPE_CONTINUE);
                    values.put(TvContract.WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_ID, PREFIX + i);
                    values.put(TvContract.WatchNextPrograms.COLUMN_LAST_ENGAGEMENT_TIME_UTC_MILLIS, System.currentTimeMillis() - i * 1000L);
                    values.put(TvContract.WatchNextPrograms.COLUMN_DURATION_MILLIS, 600000L);
                    values.put(TvContract.WatchNextPrograms.COLUMN_LAST_PLAYBACK_POSITION_MILLIS, 200000L);
                    values.put(TvContract.WatchNextPrograms.COLUMN_INTENT_URI, "https://example.invalid/acceptance/" + i);
                    values.put(TvContract.WatchNextPrograms.COLUMN_POSTER_ART_URI, "file://" + (i % 10 == 0 ? new File(folder, "missing.png") : poster).getAbsolutePath());
                    if (c.getContentResolver().insert(TvContract.WatchNextPrograms.CONTENT_URI, values) == null)
                        throw new AssertionError("Watch Next insert failed");
                }
            } else if (phase.equals("inspect-documents")) {
                var pm = c.getPackageManager();
                var open = new android.content.Intent(android.content.Intent.ACTION_OPEN_DOCUMENT)
                    .setType("image/*").addCategory(android.content.Intent.CATEGORY_OPENABLE).resolveActivity(pm);
                var get = new android.content.Intent(android.content.Intent.ACTION_GET_CONTENT)
                    .setType("image/*").addCategory(android.content.Intent.CATEGORY_OPENABLE).resolveActivity(pm);
                report.putString("stream", "\nOPEN_DOCUMENT=" + open + " GET_CONTENT=" + get + "\n");
                finish(Activity.RESULT_OK, report); return;
            } else if (phase.equals("large")) {
                image(wallpaper, 7680, 4320);
            } else if (phase.equals("corrupt")) {
                Files.write(wallpaper.toPath(), new byte[]{1, 2, 3, 4});
            } else if (phase.equals("inspect-wallpaper")) {
                byte[] bytes = Files.readAllBytes(wallpaper.toPath());
                StringBuilder hash = new StringBuilder();
                for (byte b : java.security.MessageDigest.getInstance("SHA-256").digest(bytes)) hash.append(String.format("%02x", b & 255));
                report.putString("stream", "\nPASS: wallpaper " + bytes.length + " bytes SHA256=" + hash + "\n");
                finish(Activity.RESULT_OK, report); return;
            } else if (phase.equals("online")) {
                JSONObject config = new JSONObject().put("enabled", true).put("source", "url")
                    .put("url", arguments.getString("url")).put("intervalHours", 1);
                prefs.edit().putString("flutter.online_wallpaper", config.toString()).commit();
            } else if (phase.equals("bing")) {
                prefs.edit().putString("flutter.online_wallpaper", new JSONObject().put("enabled", true)
                    .put("source", "bing").put("url", "").put("intervalHours", 1).toString()).commit();
            } else if (phase.equals("stale-bing")) {
                JSONObject cache = new JSONObject(prefs.getString("flutter.online_wallpaper_cache", "{}"));
                cache.put("expiresAt", "2000-01-01T00:00:00Z").put("updatedAt", "2000-01-01T00:00:00Z");
                prefs.edit().putString("flutter.online_wallpaper_cache", cache.toString()).commit();
            } else if (phase.equals("inspect-online")) {
                File online = new File(c.getFilesDir(), "online-wallpaper");
                if (!online.exists()) throw new AssertionError("Downloaded wallpaper missing");
                byte[] bytes = Files.readAllBytes(online.toPath());
                StringBuilder hash = new StringBuilder();
                for (byte b : java.security.MessageDigest.getInstance("SHA-256").digest(bytes)) hash.append(String.format("%02x", b & 255));
                JSONObject cache = new JSONObject(prefs.getString("flutter.online_wallpaper_cache", "{}"));
                report.putString("stream", "\nPASS: online file " + bytes.length + " bytes SHA256=" + hash + " updatedAt=" + cache.optString("updatedAt") + "\n");
                finish(Activity.RESULT_OK, report); return;
            } else if (phase.equals("appearance")) {
                prefs.edit().putString("flutter.tile_appearance", arguments.getString("json", "{}"))
                    .putBoolean("flutter.show_app_names_below_icons", true)
                    .putString("flutter.app_banner_shape", arguments.getString("style", "modern")).commit();
            } else if (phase.equals("restore")) {
                try (var cursor = c.getContentResolver().query(TvContract.WatchNextPrograms.CONTENT_URI,
                    new String[]{TvContract.WatchNextPrograms._ID, TvContract.WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_ID}, null, null, null)) {
                    if (cursor != null) while (cursor.moveToNext()) {
                        String id = cursor.getString(1);
                        if (id != null && id.startsWith(PREFIX)) c.getContentResolver().delete(
                            TvContract.buildWatchNextProgramUri(cursor.getLong(0)), null, null);
                    }
                }
                JSONObject original = new JSONObject(new String(Files.readAllBytes(new File(folder, "prefs.json").toPath()), java.nio.charset.StandardCharsets.UTF_8));
                SharedPreferences.Editor editor = prefs.edit().clear();
                for (var it = original.keys(); it.hasNext();) {
                    String key = it.next(); JSONObject entry = original.getJSONObject(key);
                    switch (entry.getString("type")) {
                        case "String": editor.putString(key, entry.getString("value")); break;
                        case "Boolean": editor.putBoolean(key, entry.getBoolean("value")); break;
                        case "Integer": editor.putInt(key, entry.getInt("value")); break;
                        case "Long": editor.putLong(key, entry.getLong("value")); break;
                        case "Float": editor.putFloat(key, (float) entry.getDouble("value")); break;
                        default: throw new IllegalStateException("Unknown preference type");
                    }
                }
                editor.commit();
                File previous = new File(folder, "wallpaper");
                if (previous.exists()) Files.copy(previous.toPath(), wallpaper.toPath(), StandardCopyOption.REPLACE_EXISTING);
                else Files.deleteIfExists(wallpaper.toPath());
                File online = new File(c.getFilesDir(), "online-wallpaper");
                File previousOnline = new File(folder, "online-wallpaper");
                if (previousOnline.exists()) Files.copy(previousOnline.toPath(), online.toPath(), StandardCopyOption.REPLACE_EXISTING);
                else Files.deleteIfExists(online.toPath());
                for (File file : folder.listFiles()) Files.delete(file.toPath());
                Files.delete(folder.toPath());
            } else throw new IllegalArgumentException("Unknown fixture phase");
            report.putString("stream", "\nPASS: emulator fixture phase " + phase + "\n");
            finish(Activity.RESULT_OK, report);
        } catch (Throwable e) {
            report.putString("stream", "\nFAIL: " + e + "\n");
            finish(Activity.RESULT_CANCELED, report);
        } finally {
            getUiAutomation().dropShellPermissionIdentity();
        }
    }
    private static void image(File file, int width, int height) throws Exception {
        Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
        try (var stream = Files.newOutputStream(file.toPath())) {
            bitmap.eraseColor(Color.rgb(210, 140, 70));
            if (!bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)) throw new AssertionError("PNG encode failed");
        } finally { bitmap.recycle(); }
    }
}
