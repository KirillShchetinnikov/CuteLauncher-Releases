package com.leanbitlab.ltvL;

import android.app.Instrumentation;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.media.tv.TvContract;
import android.os.Bundle;
import org.json.JSONObject;

/** Read-only queries under the installed launcher's UID. Never changes provider rows. */
public final class AppChannelsAccessProbe extends Instrumentation {
    private boolean expectedPermission;
    @Override public void onCreate(Bundle arguments) {
        super.onCreate(arguments);
        expectedPermission = "true".equals(arguments.getString("permission"));
        start();
    }
    @Override public void onStart() {
        Bundle result = new Bundle();
        try {
            var context = getTargetContext();
            if (android.os.Process.myUid() != context.getApplicationInfo().uid)
                throw new AssertionError("Not target UID");
            boolean granted = context.checkSelfPermission("android.permission.READ_TV_LISTINGS")
                    == PackageManager.PERMISSION_GRANTED;
            if (granted != expectedPermission) throw new AssertionError("Unexpected TV listings access: " + granted);
            JSONObject report = new JSONObject();
            report.put("permission", granted);
            int channels = 0, previews = 0;
            JSONObject sources = new JSONObject();
            try (Cursor c = context.getContentResolver().query(TvContract.Channels.CONTENT_URI,
                    new String[]{"_id", "package_name", "type"}, null, null, "_id ASC")) {
                while (c != null && c.moveToNext() && channels < 10000) {
                    channels++;
                    if (!TvContract.Channels.TYPE_PREVIEW.equals(c.getString(2))) continue;
                    previews++;
                    String owner = c.getString(1);
                    sources.put(owner, sources.optInt(owner) + 1);
                }
            }
            report.put("channels", channels);
            report.put("previewChannels", previews);
            report.put("sources", sources);
            int programs = 0;
            try (Cursor c = context.getContentResolver().query(TvContract.PreviewPrograms.CONTENT_URI,
                    new String[]{"_id"}, null, null, null)) {
                while (c != null && c.moveToNext() && programs < 10000) programs++;
            }
            report.put("previewPrograms", programs);
            result.putString("stream", "PASS: " + report);
            finish(-1, result);
        } catch (Throwable error) {
            result.putString("stream", "FAIL: " + error);
            finish(0, result);
        }
    }
}
