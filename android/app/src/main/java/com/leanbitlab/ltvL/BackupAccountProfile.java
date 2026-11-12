package com.leanbitlab.ltvL;

import android.content.Context;
import java.io.File;

final class BackupAccountProfile {
    static String id(String value) {
        if (value == null || value.equals("default")) return "default";
        if (!value.matches("[a-f0-9]{32}")) throw new IllegalArgumentException();
        return value;
    }
    static CloudAccountStore store(Context context, boolean drive, String profile) {
        return store(context, drive ? "drive" : "webdav", profile);
    }
    static CloudAccountStore store(Context context, String type, String profile) {
        if (!java.util.Set.of("drive", "webdav", "yandex", "smb").contains(type)) throw new IllegalArgumentException();
        profile = id(profile);
        if (profile.equals("default") && type.equals("webdav")) return new CloudAccountStore(context);
        String suffix = profile.equals("default") ? "" : "-" + profile;
        return new CloudAccountStore(new File(context.getNoBackupFilesDir(), "cloud/" + type + suffix),
            "cutelauncher_" + type + "_account" + suffix);
    }
}
