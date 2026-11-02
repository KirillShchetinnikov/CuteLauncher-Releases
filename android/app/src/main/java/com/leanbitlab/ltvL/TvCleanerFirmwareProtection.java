package com.leanbitlab.ltvL;

import android.content.Context;
import android.os.Build;
import java.nio.charset.StandardCharsets;
import java.util.*;
import org.json.*;

/** Bundled negative rules only: exact identities, never recommendations to disable anything. */
final class TvCleanerFirmwareProtection {
    static Set<String> collect(Context context) throws Exception {
        var identity = Map.of("manufacturer", Build.MANUFACTURER, "model", Build.MODEL,
                "device", Build.DEVICE, "fingerprint", Build.FINGERPRINT, "firmware", Build.DISPLAY);
        try (var input = context.getAssets().open("flutter_assets/catalog/cleaner_protections.json")) {
            var bytes = new java.io.ByteArrayOutputStream(); byte[] buffer = new byte[8192]; int count;
            while ((count = input.read(buffer)) != -1) {
                if (bytes.size() + count > 256 * 1024) throw new IllegalStateException("Protection catalog too large");
                bytes.write(buffer, 0, count);
            }
            return protectedPackages(new JSONObject(new String(bytes.toByteArray(), StandardCharsets.UTF_8)), identity);
        }
    }
    static Set<String> protectedPackages(JSONObject catalog, Map<String, String> actual) throws Exception {
        if (catalog.getInt("schemaVersion") != 1) throw new IllegalStateException("Unknown protection catalog");
        JSONArray rules = catalog.getJSONArray("rules");
        if (rules.length() > 128) throw new IllegalStateException("Too many protection rules");
        var result = new LinkedHashSet<String>();
        for (int i = 0; i < rules.length(); i++) {
            var rule = rules.getJSONObject(i); var identity = rule.getJSONObject("identity");
            if (!identity.has("manufacturer") || !identity.has("model") ||
                    (!identity.has("fingerprint") && !identity.has("firmware")))
                throw new IllegalStateException("Unscoped protection rule");
            boolean matches = true;
            var keys = identity.keys();
            while (keys.hasNext()) {
                String key = keys.next(); Object value = identity.get(key);
                if (!Set.of("manufacturer", "model", "device", "fingerprint", "firmware").contains(key)
                        || !(value instanceof String text) || text.trim().isEmpty() || text.length() > 1024)
                    throw new IllegalStateException("Invalid protection identity");
                if (!value.equals(actual.get(key))) matches = false;
            }
            var packages = rule.getJSONArray("protectedPackages");
            if (packages.length() > 500) throw new IllegalStateException("Too many protected packages");
            for (int j = 0; j < packages.length(); j++) {
                String name = packages.getString(j);
                if (!TvCleanerPolicy.packageId(name)) throw new IllegalStateException("Invalid protected package");
                if (matches) result.add(name);
            }
        }
        return result;
    }
}
