package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.Instrumentation;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.SystemClock;
import java.io.File;
import java.nio.file.Files;
import org.json.JSONObject;

/** Run with the emulator-only release_runtime_probe.dart APK and document fixture. */
public final class ReleaseRuntimeProbe extends Instrumentation {
    private boolean readOnly;
    @Override public void onCreate(Bundle args) {
        super.onCreate(args); readOnly = args != null && "true".equals(args.getString("readOnly")); start();
    }
    @Override public void onStart() {
        Bundle report = new Bundle();
        Activity activity = null;
        try {
            if (!Build.HARDWARE.contains("ranchu") && !Build.HARDWARE.contains("goldfish"))
                throw new IllegalStateException("Emulator required");
            File result = new File(getTargetContext().getCacheDir(), "release-runtime-probe.json");
            if (!readOnly) {
                if (result.exists() && !result.delete()) throw new IllegalStateException("Old report retained");
                IntentFilter filter = new IntentFilter(Intent.ACTION_OPEN_DOCUMENT);
                filter.addCategory(Intent.CATEGORY_OPENABLE);
                filter.addDataType("*/*");
                addMonitor(filter, new ActivityResult(Activity.RESULT_OK,
                    new Intent().setData(Uri.parse("content://io.cutelauncher.fixture.documents/valid.png"))
                        .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)), true);
                activity = startActivitySync(new Intent(getTargetContext(), MainActivity.class)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
                long end = SystemClock.elapsedRealtime() + 45000;
                while (!result.exists() && SystemClock.elapsedRealtime() < end) SystemClock.sleep(100);
            }
            JSONObject data = new JSONObject(new String(Files.readAllBytes(result.toPath()), java.nio.charset.StandardCharsets.UTF_8));
            if (!data.optString("status").equals("WRITTEN") && !data.optString("status").equals("PASS"))
                throw new AssertionError(data.toString());
            report.putString("result", data.toString());
            finish(Activity.RESULT_OK, report);
        } catch (Throwable error) {
            report.putString("result", "FAIL: " + error);
            finish(Activity.RESULT_CANCELED, report);
        } finally {
            if (activity != null) { Activity launched = activity; runOnMainSync(launched::finish); }
        }
    }
}
