package com.leanbitlab.ltvL;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Map;

/** Identity scoped by Android to signing key, Android user and device. */
final class BackupDeviceIdentity {
    static Map<String, String> create(String androidId, String manufacturer, String model) {
        String label = (manufacturer + "_" + model).replaceAll("[^A-Za-z0-9]+", "_")
            .replaceAll("^_+|_+$", "");
        if (label.isEmpty()) label = "TV";
        label = label.substring(0, Math.min(label.length(), 64));
        if (androidId == null || !androidId.matches("[a-fA-F0-9]{1,16}") || androidId.matches("0+"))
            return Map.of("label", label);
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(
                ("CuteLauncher.backup.device:" + androidId.toLowerCase(java.util.Locale.ROOT))
                    .getBytes(StandardCharsets.UTF_8));
            StringBuilder id = new StringBuilder();
            for (int i = 0; i < 16; i++) id.append(String.format(java.util.Locale.ROOT, "%02x", digest[i] & 255));
            return Map.of("id", id.toString(), "label", label);
        } catch (java.security.NoSuchAlgorithmException impossible) {
            return Map.of("label", label);
        }
    }
}
