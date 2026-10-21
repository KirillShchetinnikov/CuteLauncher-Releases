/*
 * FLauncher
 * Copyright (C) 2021  Oscar Rojas
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

package com.leanbitlab.ltvL;

import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.media.tv.TvContract;
import android.net.Uri;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import android.database.ContentObserver;
import android.os.Handler;
import android.os.Looper;
import io.flutter.plugin.common.EventChannel;
/** Native WatchNextBridge operations; channel names and payloads remain owned by MainActivity. */
final class WatchNextBridge implements EventChannel.StreamHandler {
    private final Context context;
    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    private ContentObserver observer;
    private boolean registered;
    private Runnable debounce;
    private int generation;

    WatchNextBridge(Context context) { this.context = context; }

    @Override public void onListen(Object arguments, EventChannel.EventSink events) {
        onCancel(null);
        int subscription = generation;
        observer = new ContentObserver(mainHandler) {
            @Override public void onChange(boolean selfChange, Uri uri) {
                if (subscription != generation) return;
                if (debounce != null) mainHandler.removeCallbacks(debounce);
                debounce = () -> {
                    if (subscription != generation) return;
                    try { events.success(true); }
                    catch (Exception error) { error.printStackTrace(); }
                };
                mainHandler.postDelayed(debounce, 500);
            }
        };
        try {
            context.getContentResolver().registerContentObserver(TvContract.WatchNextPrograms.CONTENT_URI, true, observer);
            registered = true;
        } catch (Exception error) { error.printStackTrace(); }
    }

    @Override public void onCancel(Object arguments) {
        generation++;
        mainHandler.removeCallbacksAndMessages(null);
        debounce = null;
        if (registered && observer != null) {
            try { context.getContentResolver().unregisterContentObserver(observer); }
            catch (Exception error) { error.printStackTrace(); }
        }
        registered = false;
        observer = null;
    }

    private static String cursorStringOrEmpty(android.database.Cursor cursor, String column) {
        String val = cursor.getString(cursor.getColumnIndexOrThrow(column));
        return val != null ? val : "";
    }

    List<Map<String, Object>> getWatchNextPrograms() {
        return getWatchNextProgramsApi26();
    }

    private List<Map<String, Object>> getWatchNextProgramsApi26() {
        List<Map<String, Object>> list = new ArrayList<>();

        String[] projection = {
            TvContract.WatchNextPrograms._ID,
            TvContract.WatchNextPrograms.COLUMN_PACKAGE_NAME,
            TvContract.WatchNextPrograms.COLUMN_TITLE,
            TvContract.WatchNextPrograms.COLUMN_SHORT_DESCRIPTION,
            TvContract.WatchNextPrograms.COLUMN_LONG_DESCRIPTION,
            TvContract.WatchNextPrograms.COLUMN_EPISODE_TITLE,
            TvContract.WatchNextPrograms.COLUMN_WATCH_NEXT_TYPE,
            TvContract.WatchNextPrograms.COLUMN_LAST_ENGAGEMENT_TIME_UTC_MILLIS,
            TvContract.WatchNextPrograms.COLUMN_LAST_PLAYBACK_POSITION_MILLIS,
            TvContract.WatchNextPrograms.COLUMN_DURATION_MILLIS,
            TvContract.WatchNextPrograms.COLUMN_INTENT_URI,
            TvContract.WatchNextPrograms.COLUMN_POSTER_ART_URI,
            TvContract.WatchNextPrograms.COLUMN_THUMBNAIL_URI
        };

        try (android.database.Cursor cursor = context.getContentResolver().query(
                TvContract.WatchNextPrograms.CONTENT_URI,
                projection,
                null,
                null,
                TvContract.WatchNextPrograms.COLUMN_LAST_ENGAGEMENT_TIME_UTC_MILLIS + " DESC")) {

            if (cursor == null) {
                return list;
            }

            final int maxFetch = 100;
            int row = 0;
            while (row < maxFetch && cursor.moveToNext()) {
                row++;

                long time = 0;
                int timeCol = cursor.getColumnIndex(TvContract.WatchNextPrograms.COLUMN_LAST_ENGAGEMENT_TIME_UTC_MILLIS);
                if (timeCol != -1 && !cursor.isNull(timeCol)) {
                    time = cursor.getLong(timeCol);
                    if (time > 0 && time < 10000000000L) {
                        time *= 1000L;
                    }
                }

                String poster = cursorStringOrEmpty(cursor, TvContract.WatchNextPrograms.COLUMN_POSTER_ART_URI);
                if (poster.isEmpty()) {
                    poster = cursorStringOrEmpty(cursor, TvContract.WatchNextPrograms.COLUMN_THUMBNAIL_URI);
                }

                String title = cursorStringOrEmpty(cursor, TvContract.WatchNextPrograms.COLUMN_TITLE);
                String episodeTitle = cursorStringOrEmpty(cursor, TvContract.WatchNextPrograms.COLUMN_EPISODE_TITLE);
                if (title.isEmpty() && !episodeTitle.isEmpty()) {
                    title = episodeTitle;
                }

                String shortDesc = cursorStringOrEmpty(cursor, TvContract.WatchNextPrograms.COLUMN_SHORT_DESCRIPTION);
                String longDesc = cursorStringOrEmpty(cursor, TvContract.WatchNextPrograms.COLUMN_LONG_DESCRIPTION);

                String description = shortDesc;
                if (description.isEmpty() || description.trim().equalsIgnoreCase(title.trim())) {
                    if (!longDesc.isEmpty() && !longDesc.trim().equalsIgnoreCase(title.trim())) {
                        description = longDesc;
                    } else if (!episodeTitle.isEmpty() && !episodeTitle.trim().equalsIgnoreCase(title.trim())) {
                        description = episodeTitle;
                    }
                }

                Map<String, Object> map = new HashMap<>();
                map.put("id", cursor.getLong(cursor.getColumnIndexOrThrow(TvContract.WatchNextPrograms._ID)));
                map.put("packageName", cursorStringOrEmpty(cursor, TvContract.WatchNextPrograms.COLUMN_PACKAGE_NAME));
                map.put("title", title);
                map.put("description", description);
                map.put("watchNextType", cursor.getInt(cursor.getColumnIndexOrThrow(TvContract.WatchNextPrograms.COLUMN_WATCH_NEXT_TYPE)));
                map.put("lastEngagementTime", time);
                map.put("playbackPosition", cursor.getLong(cursor.getColumnIndexOrThrow(TvContract.WatchNextPrograms.COLUMN_LAST_PLAYBACK_POSITION_MILLIS)));
                map.put("duration", cursor.getLong(cursor.getColumnIndexOrThrow(TvContract.WatchNextPrograms.COLUMN_DURATION_MILLIS)));
                map.put("intentUri", cursorStringOrEmpty(cursor, TvContract.WatchNextPrograms.COLUMN_INTENT_URI));
                map.put("posterArtUri", poster);
                list.add(map);
            }

            // Explicitly sort descending by last engagement time (most recently watched first),
            // and fallback to ID descending if timestamps are identical.
            list.sort((a, b) -> {
                long timeA = (Long) a.get("lastEngagementTime");
                long timeB = (Long) b.get("lastEngagementTime");
                if (timeA != timeB) {
                    return Long.compare(timeB, timeA);
                }
                long idA = (Long) a.get("id");
                long idB = (Long) b.get("id");
                return Long.compare(idB, idA);
            });

            if (list.size() > 20) {
                list = new ArrayList<>(list.subList(0, 20));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return list;
    }

    boolean deleteWatchNextProgram(long id) {
        return deleteWatchNextProgramApi26(id);
    }

    private boolean deleteWatchNextProgramApi26(long id) {
        try {
            Uri uri = TvContract.buildWatchNextProgramUri(id);
            int rowsDeleted = context.getContentResolver().delete(uri, null, null);
            return rowsDeleted > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    private byte[] readPosterImage(java.io.InputStream input) throws java.io.IOException {
        byte[] bytes = BoundedImageInput.read(input, BoundedImageInput.MAX_BYTES);
        android.graphics.BitmapFactory.Options dimensions = new android.graphics.BitmapFactory.Options();
        dimensions.inJustDecodeBounds = true;
        android.graphics.BitmapFactory.decodeByteArray(bytes, 0, bytes.length, dimensions);
        if (dimensions.outWidth <= 0 || dimensions.outHeight <= 0 ||
                dimensions.outWidth > 16384 || dimensions.outHeight > 16384 ||
                (long) dimensions.outWidth * dimensions.outHeight > 48L * 1024 * 1024) {
            throw new java.io.IOException("Invalid image dimensions");
        }
        return bytes;
    }

    // android.resource URIs name resources of other installed apps, not this APK's R table.
    @android.annotation.SuppressLint("DiscouragedApi")
    byte[] getWatchNextPoster(String posterArtUri) {
        if (posterArtUri == null || posterArtUri.isEmpty()) {
            return null;
        }
        try {
            if (posterArtUri.startsWith("http://") || posterArtUri.startsWith("https://")) {
                // Fully offline launcher: remote network fetching disabled
                return null;
            } else if (posterArtUri.startsWith("file://")) {
                Uri fileUri = Uri.parse(posterArtUri);
                java.io.File file = new java.io.File(fileUri.getPath());
                if (file.exists() && file.canRead()) {
                    try (java.io.FileInputStream fis = new java.io.FileInputStream(file)) {
                        return readPosterImage(fis);
                    }
                }
            } else if (posterArtUri.startsWith("/")) {
                java.io.File file = new java.io.File(posterArtUri);
                if (file.exists() && file.canRead()) {
                    try (java.io.FileInputStream fis = new java.io.FileInputStream(file)) {
                        return readPosterImage(fis);
                    }
                }
            } else if (posterArtUri.startsWith("android.resource://")) {
                Uri uri = Uri.parse(posterArtUri);
                try (java.io.InputStream inputStream = context.getContentResolver().openInputStream(uri)) {
                    if (inputStream != null) {
                        return readPosterImage(inputStream);
                    }
                } catch (Exception ignored) {}
                try {
                    String authority = uri.getAuthority();
                    if (authority != null && !authority.isEmpty()) {
                        android.content.res.Resources res = context.getPackageManager().getResourcesForApplication(authority);
                        List<String> pathSegments = uri.getPathSegments();
                        int resId = 0;
                        if (pathSegments.size() == 1) {
                            try {
                                resId = Integer.parseInt(pathSegments.get(0));
                            } catch (NumberFormatException ignored) {}
                        } else if (pathSegments.size() >= 2) {
                            String type = pathSegments.get(0);
                            String name = pathSegments.get(1);
                            resId = res.getIdentifier(name, type, authority);
                        }
                        if (resId != 0) {
                            try (java.io.InputStream is = res.openRawResource(resId)) {
                                return readPosterImage(is);
                            }
                        }
                    }
                } catch (Exception ignored) {}
            } else {
                Uri uri = Uri.parse(posterArtUri);
                try (java.io.InputStream inputStream = context.getContentResolver().openInputStream(uri)) {
                    if (inputStream != null) {
                        return readPosterImage(inputStream);
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    boolean launchWatchNextProgram(String intentUri) {
        if (intentUri == null || intentUri.isEmpty()) {
            return false;
        }
        try {
            Intent intent = Intent.parseUri(intentUri, Intent.URI_INTENT_SCHEME);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            return tryStartActivity(intent);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    boolean checkWatchNextPermission() {
        return context.checkSelfPermission("com.android.providers.tv.permission.READ_WRITE_WATCH_NEXT_PROGRAMS") == PackageManager.PERMISSION_GRANTED
            || context.checkSelfPermission("android.permission.READ_TV_LISTINGS") == PackageManager.PERMISSION_GRANTED;
    }



    private boolean tryStartActivity(Intent intent) {
        try { context.startActivity(intent); return true; }
        catch (Exception ignored) { return false; }
    }
}
