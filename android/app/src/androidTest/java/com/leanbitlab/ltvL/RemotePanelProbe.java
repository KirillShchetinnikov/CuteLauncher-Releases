package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.Instrumentation;
import android.os.Build;
import android.os.Bundle;
import java.io.File;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.Map;

/** Emulator-only fixture. Keeps the original encrypted mappings intact for restoration. */
public final class RemotePanelProbe extends Instrumentation {
    private String phase;
    @Override public void onCreate(Bundle args) { super.onCreate(args); phase = args.getString("phase", "prepare"); start(); }
    @Override public void onStart() {
        Bundle report = new Bundle();
        try {
            if (!Build.HARDWARE.contains("ranchu") && !Build.HARDWARE.contains("goldfish")) throw new IllegalStateException("Emulator required");
            var context = getTargetContext();
            File current = new File(context.getNoBackupFilesDir(), "remote-mappings");
            File backup = new File(context.getNoBackupFilesDir(), "remote-panel-probe-original");
            File marker = new File(context.getNoBackupFilesDir(), "remote-panel-probe-marker");
            if (phase.equals("inspect")) {
                var config = new RemoteMappingStore(context).load();
                report.putString("stream", "\nPASS inspect: " + config.toMap() + " connected=" + LauncherAccessibilityService.connected() + " status=" + RemoteButtonRemapper.status + "\n");
                finish(Activity.RESULT_OK, report); return;
            } else if (phase.equals("restore")) {
                if (!marker.exists()) throw new IllegalStateException("No fixture to restore");
                if (backup.exists()) { Files.copy(backup.toPath(), current.toPath(), StandardCopyOption.REPLACE_EXISTING); Files.delete(backup.toPath()); }
                else Files.deleteIfExists(current.toPath());
                Files.delete(marker.toPath());
            } else {
                if (marker.exists()) throw new IllegalStateException("Fixture already prepared");
                if (current.exists()) Files.copy(current.toPath(), backup.toPath());
                Files.write(marker.toPath(), new byte[]{1});
                new RemoteMappingStore(context).save(RemoteMappingConfiguration.fromMap(Map.of("enabled", true, "bindings", List.of(
                    Map.of("keyCode", 164, "enabled", true, "action", "panel", "target", "", "trigger", "press"),
                    Map.of("keyCode", 190, "enabled", true, "action", "panel", "target", "", "trigger", "hold")
                ))));
            }
            report.putString("stream", "\nPASS remote panel fixture " + phase + "\n");
            finish(Activity.RESULT_OK, report);
        } catch (Throwable error) {
            report.putString("stream", "\nFAIL " + error + "\n"); finish(Activity.RESULT_CANCELED, report);
        }
    }
}
