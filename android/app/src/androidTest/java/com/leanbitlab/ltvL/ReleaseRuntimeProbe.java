package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.Instrumentation;
import android.content.ComponentName;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.os.SystemClock;
import java.io.File;
import java.nio.file.Files;
import org.json.JSONObject;

/** Run with the emulator-only release_runtime_probe.dart APK and document fixture. */
public final class ReleaseRuntimeProbe extends Instrumentation {
    private boolean readOnly;
    private volatile String pickerAction = "not_requested";
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
                // Use a real, deterministic provider and its normal activity-result path.
                addMonitor(new ActivityMonitor() {
                    @Override public ActivityResult onStartActivity(Intent intent) {
                        Intent request = intent;
                        if (Intent.ACTION_CHOOSER.equals(intent.getAction())) {
                            request = intent.getParcelableExtra(Intent.EXTRA_INTENT);
                            if (request == null) return null;
                        }
                        if (!Intent.ACTION_OPEN_DOCUMENT.equals(request.getAction()) &&
                            !Intent.ACTION_GET_CONTENT.equals(request.getAction())) return null;
                        pickerAction = request.getAction();
                        String fixture = "io.cutelauncher.fixture.documents";
                        String type = Intent.ACTION_OPEN_DOCUMENT.equals(request.getAction()) ? "OpenDocument" : "GetContent";
                        intent.setAction(request.getAction()).setDataAndType(request.getData(), request.getType());
                        intent.replaceExtras(request.getExtras());
                        intent.setComponent(new ComponentName(fixture, fixture + ".DocumentsFixture$" + type));
                        return null;
                    }
                });
                activity = startActivitySync(new Intent(getTargetContext(), LauncherActivity.class)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
                long end = SystemClock.elapsedRealtime() + 45000;
                boolean selected = false;
                String rootPackage = "none";
                JSONObject written = null;
                while (written == null && SystemClock.elapsedRealtime() < end) {
                    if (result.isFile()) {
                        try {
                            written = new JSONObject(new String(Files.readAllBytes(result.toPath()), java.nio.charset.StandardCharsets.UTF_8));
                        } catch (java.io.IOException | org.json.JSONException incomplete) { }
                        if (written != null) break;
                    }
                    var root = getUiAutomation().getRootInActiveWindow();
                    if (root != null) rootPackage = String.valueOf(root.getPackageName());
                    if (!selected && root != null) {
                        for (var node : root.findAccessibilityNodeInfosByText("Valid document")) {
                            if (node.getPackageName() != null && "io.cutelauncher.fixture.documents".contentEquals(node.getPackageName()) && node.isClickable()) {
                                selected = node.performAction(android.view.accessibility.AccessibilityNodeInfo.ACTION_CLICK);
                                break;
                            }
                        }
                    }
                    SystemClock.sleep(100);
                }
                if (written == null) throw new AssertionError("Runtime report incomplete");
                if (written.optString("status").equals("FAIL")) {
                    written.put("pickerAction", pickerAction).put("rootPackage", rootPackage).put("selected", selected);
                    throw new AssertionError(written.toString());
                }
                if (written.optString("status").equals("WRITTEN") && !selected)
                    throw new AssertionError("Document fixture selection was not exercised");
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
