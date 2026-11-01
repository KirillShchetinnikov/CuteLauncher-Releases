package com.leanbitlab.ltvL;

import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.media.tv.TvContract;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/** Reads only the public preview-channel catalogue. Never changes provider rows. */
final class AppChannelsBridge {
    private final Context context;
    AppChannelsBridge(Context context) { this.context = context; }

    List<Map<String, Object>> channels(List<String> selected) {
        // TvProvider may silently restrict callers to their own rows. A launcher
        // publishes none, so querying without this access looks like no feeds.
        if (context.checkSelfPermission("android.permission.READ_TV_LISTINGS")
                != android.content.pm.PackageManager.PERMISSION_GRANTED) {
            throw new SecurityException("TV listings access is required to read app feeds");
        }
        List<String> enabled = selected == null ? List.of()
                : selected.subList(0, Math.min(16, selected.size()));
        List<Map<String, Object>> result = new ArrayList<>();
        Map<String, String> appNames = new HashMap<>();
        String[] projection = {"_id", "package_name", "display_name", "type"};
        try (Cursor c = context.getContentResolver().query(TvContract.Channels.CONTENT_URI,
                projection, null, null, "_id ASC")) {
            if (c == null) return result;
            while (c.moveToNext() && result.size() < 128) {
                if (!TvContract.Channels.TYPE_PREVIEW.equals(c.getString(3))) continue;
                long id = c.getLong(0);
                String owner = c.getString(1);
                if (owner == null || owner.isEmpty()) continue;
                Map<String, Object> row = new HashMap<>();
                row.put("id", id);
                row.put("packageName", owner);
                row.put("appName", appNames.computeIfAbsent(owner, pkg -> {
                    try {
                        return context.getPackageManager().getApplicationLabel(
                                context.getPackageManager().getApplicationInfo(pkg, 0)).toString();
                    } catch (android.content.pm.PackageManager.NameNotFoundException error) { return pkg; }
                }));
                row.put("name", c.isNull(2) ? owner : c.getString(2));
                row.put("programs", enabled.contains(owner + ":" + id)
                        ? programs(id, owner) : new ArrayList<>());
                result.add(row);
            }
        }
        return result;
    }

    private List<Map<String, Object>> programs(long channel, String owner) {
        List<Map<String, Object>> result = new ArrayList<>();
        String[] projection = {"_id", "package_name", "title", "short_description",
                "intent_uri", "poster_art_uri", "thumbnail_uri"};
        try (Cursor c = context.getContentResolver().query(
                TvContract.buildPreviewProgramsUriForChannel(channel), projection,
                null, null, "weight DESC, _id ASC")) {
            if (c == null) return result;
            while (c.moveToNext() && result.size() < 20) {
                if (!owner.equals(c.getString(1)) || c.isNull(4) || c.getString(4).isEmpty()) continue;
                Map<String, Object> row = new HashMap<>();
                row.put("id", c.getLong(0));
                row.put("packageName", owner);
                row.put("title", c.isNull(2) ? "" : c.getString(2));
                row.put("description", c.isNull(3) ? "" : c.getString(3));
                row.put("intentUri", c.getString(4));
                row.put("posterArtUri", !c.isNull(5) && !c.getString(5).isEmpty()
                        ? c.getString(5) : c.isNull(6) ? "" : c.getString(6));
                result.add(row);
            }
        }
        return result;
    }

    boolean launch(String uri, String owner) {
        if (uri == null || uri.isEmpty() || owner == null || owner.isEmpty()) return false;
        try {
            Intent intent = Intent.parseUri(uri, Intent.URI_INTENT_SCHEME);
            if (intent.getComponent() != null && !owner.equals(intent.getComponent().getPackageName())) return false;
            intent.setSelector(null);
            intent.setPackage(owner);
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(intent);
            return true;
        } catch (Exception error) { return false; }
    }
}
