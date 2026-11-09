package com.leanbitlab.ltvL;

import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.media.tv.TvContract;
import android.net.Uri;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Reads only the public preview-channel catalogue. Never changes provider rows. */
final class AppChannelsBridge {
    private static final int PROGRAM_LIMIT = 50;
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
        Map<Long, String> channelOwners = new HashMap<>();
        Map<String, Boolean> posterProviders = new HashMap<>();
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
                if (!appNames.containsKey(owner)) {
                    try {
                        var manager = context.getPackageManager();
                        appNames.put(owner, manager.getApplicationLabel(
                                manager.getApplicationInfo(owner, 0)).toString());
                    } catch (PackageManager.NameNotFoundException error) {
                        appNames.put(owner, null);
                    }
                }
                String appName = appNames.get(owner);
                if (appName == null) continue;
                row.put("appName", appName);
                String name = c.isNull(2) ? owner : c.getString(2);
                row.put("name", name);
                if ("com.tcl.partnercustomizer".equals(owner) && "Избранное".equals(name)) {
                    // Keep the identity so a saved selection is not shown as a missing feed.
                    row.put("hidden", true);
                } else {
                    channelOwners.put(id, owner);
                }
                result.add(row);
            }
        }
        Set<Long> brokenFeeds = feedsWithoutReadableArtwork(channelOwners, posterProviders);
        for (Map<String, Object> row : result) {
            long id = (Long) row.get("id");
            String owner = (String) row.get("packageName");
            boolean hidden = Boolean.TRUE.equals(row.get("hidden")) || brokenFeeds.contains(id);
            if (hidden) row.put("hidden", true);
            row.put("programs", !hidden && enabled.contains(owner + ":" + id)
                    ? programs(id, owner, posterProviders) : List.of());
        }
        return result;
    }

    private Set<Long> feedsWithoutReadableArtwork(Map<Long, String> channelOwners,
            Map<String, Boolean> posterProviders) {
        Map<Long, Integer> broken = new HashMap<>();
        if (channelOwners.isEmpty()) return broken.keySet();
        // A feed with no displayable cards has no usable artwork either.
        for (long id : channelOwners.keySet()) broken.put(id, 0);
        Map<String, Boolean> resourcePosters = new HashMap<>();
        // Read only fields needed to classify artwork, including unselected feeds.
        String[] projection = {"channel_id", "package_name", "intent_uri",
                "poster_art_uri", "thumbnail_uri"};
        try (Cursor c = context.getContentResolver().query(TvContract.PreviewPrograms.CONTENT_URI,
                projection, null, null, "weight DESC, _id ASC")) {
            if (c == null) throw new IllegalStateException("Preview programs query returned no cursor");
            while (!channelOwners.isEmpty() && c.moveToNext()) {
                long id = c.getLong(0);
                String owner = channelOwners.get(id);
                if (owner == null || !owner.equals(c.getString(1))
                        || c.isNull(2) || c.getString(2).isEmpty()) continue;
                String poster = c.getString(3);
                String thumbnail = c.getString(4);
                if (canSupplyArtwork(poster, posterProviders, resourcePosters)
                        || canSupplyArtwork(thumbnail, posterProviders, resourcePosters)) {
                    broken.remove(id);
                    channelOwners.remove(id);
                } else if (broken.merge(id, 1, Integer::sum) == PROGRAM_LIMIT) {
                    channelOwners.remove(id);
                }
            }
        }
        return broken.keySet();
    }

    private boolean canSupplyArtwork(String address, Map<String, Boolean> posterProviders,
            Map<String, Boolean> resourcePosters) {
        String available = availablePoster(address, posterProviders);
        if (available.isEmpty()) return false;
        // Check local resources with the same reader used when displaying the card.
        // Defer network and provider I/O to the card loader.
        return !available.startsWith("android.resource://")
                || resourcePosters.computeIfAbsent(available, value ->
                        WatchNextBridge.readResourcePoster(context, Uri.parse(value)) != null);
    }

    private static boolean hasAddress(String address) {
        return address != null && !address.isEmpty();
    }

    private List<Map<String, Object>> programs(long channel, String owner,
            Map<String, Boolean> posterProviders) {
        List<Map<String, Object>> result = new ArrayList<>();
        String[] projection = {"_id", "package_name", "title", "short_description",
                "intent_uri", "poster_art_uri", "thumbnail_uri",
                "poster_art_aspect_ratio", "poster_thumbnail_aspect_ratio",
                TvContract.PreviewPrograms.COLUMN_RELEASE_DATE,
                TvContract.PreviewPrograms.COLUMN_REVIEW_RATING,
                TvContract.PreviewPrograms.COLUMN_REVIEW_RATING_STYLE,
                TvContract.PreviewPrograms.COLUMN_CANONICAL_GENRE,
                TvContract.PreviewPrograms.COLUMN_AUTHOR,
                TvContract.PreviewPrograms.COLUMN_DURATION_MILLIS};
        try (Cursor c = context.getContentResolver().query(
                TvContract.buildPreviewProgramsUriForChannel(channel), projection,
                null, null, "weight DESC, _id ASC")) {
            if (c == null) return result;
            while (c.moveToNext() && result.size() < PROGRAM_LIMIT) {
                if (!owner.equals(c.getString(1)) || c.isNull(4) || c.getString(4).isEmpty()) continue;
                Map<String, Object> row = new HashMap<>();
                row.put("id", c.getLong(0));
                row.put("packageName", owner);
                row.put("title", c.isNull(2) ? "" : c.getString(2));
                row.put("description", c.isNull(3) ? "" : c.getString(3));
                row.put("intentUri", c.getString(4));
                String poster = availablePoster(c.getString(5), posterProviders);
                String thumbnail = availablePoster(c.getString(6), posterProviders);
                row.put("posterArtUri", poster.isEmpty() ? thumbnail : poster);
                if (!poster.isEmpty() && !thumbnail.isEmpty() && !poster.equals(thumbnail)) {
                    row.put("thumbnailUri", thumbnail);
                }
                int ratioColumn = poster.isEmpty() ? 8 : 7;
                if (!c.isNull(ratioColumn)) {
                    Double ratio = switch (c.getInt(ratioColumn)) {
                        case 0 -> 16.0 / 9;
                        case 1 -> 3.0 / 2;
                        case 2 -> 4.0 / 3;
                        case 3 -> 1.0;
                        case 4 -> 2.0 / 3;
                        default -> null;
                    };
                    if (ratio != null) row.put("posterAspectRatio", ratio);
                }
                row.put("releaseDate", c.getString(9));
                row.put("reviewRating", c.getString(10));
                if (!c.isNull(11)) row.put("reviewRatingStyle", c.getInt(11));
                if (!c.isNull(12)) {
                    String[] genres = TvContract.Programs.Genres.decode(c.getString(12));
                    if (genres.length > 0) row.put("genre", genres[0]);
                }
                row.put("author", c.getString(13));
                if (!c.isNull(14)) row.put("duration", c.getLong(14));
                result.add(row);
            }
        }
        return result;
    }

    private String availablePoster(String address, Map<String, Boolean> posterProviders) {
        if (!hasAddress(address)) return "";
        Uri uri = Uri.parse(address);
        String authority = uri.getAuthority();
        // A feed can outlive the provider removed by an app update.
        // Leave cross-user URI resolution to ContentResolver.
        if ("content".equals(uri.getScheme()) && authority != null && !authority.contains("@")
                && !posterProviders.computeIfAbsent(authority, name ->
                        context.getPackageManager().resolveContentProvider(name, 0) != null)) {
            return "";
        }
        return address;
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
