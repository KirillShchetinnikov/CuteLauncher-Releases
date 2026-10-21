package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.Instrumentation;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.provider.DocumentsContract;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import io.flutter.plugin.common.MethodChannel;

/** Emulator-only SAF smoke test; does not change launcher preferences. */
public final class WallpaperFolderProbe extends Instrumentation {
    @Override public void onCreate(Bundle args) { super.onCreate(args); start(); }
    @Override public void onStart() {
        Bundle report = new Bundle();
        var executor = Executors.newSingleThreadExecutor();
        Activity activity = null;
        try {
            if (!Build.HARDWARE.contains("ranchu") && !Build.HARDWARE.contains("goldfish"))
                throw new IllegalStateException("Emulator required");
            activity = startActivitySync(new Intent(getTargetContext(), MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
            var folder = new WallpaperFolder(activity, executor);
            String root = DocumentsContract.buildTreeDocumentUri("io.cutelauncher.fixture.documents", "root").toString();
            Result direct = new Result(); folder.list(root, false, direct); direct.await();
            if (!(direct.value instanceof List) || ((List<?>) direct.value).size() != 2) throw new AssertionError("Direct images");
            Result recursive = new Result(); folder.list(root, true, recursive); recursive.await();
            if (!(recursive.value instanceof List) || ((List<?>) recursive.value).size() != 3) throw new AssertionError("Recursive images");
            String valid = ((List<String>) recursive.value).stream().filter(v -> v.endsWith("nested.png")).findFirst().orElseThrow();
            Result image = new Result(); folder.read(valid, image); image.await();
            if (!(image.value instanceof byte[]) || ((byte[]) image.value).length < 8) throw new AssertionError("Image bytes");
            Result invalid = new Result(); folder.read("content://io.cutelauncher.fixture.documents/failure", invalid); invalid.await();
            if (invalid.error == null) throw new AssertionError("Provider failure must report error");
            report.putString("stream", "\nPASS: direct=2 recursive=3 nested image readable; provider error reported\n");
            finish(Activity.RESULT_OK, report);
        } catch (Exception | AssertionError error) {
            report.putString("stream", "\nFAIL: " + error.getClass().getSimpleName() + ": " + error.getMessage() + "\n");
            finish(Activity.RESULT_CANCELED, report);
        } finally {
            executor.shutdownNow();
            if (activity != null) { Activity launched = activity; runOnMainSync(launched::finish); }
        }
    }
    private static final class Result implements MethodChannel.Result {
        final CountDownLatch done = new CountDownLatch(1);
        Object value; String error;
        public void success(Object value) { this.value = value; done.countDown(); }
        public void error(String code, String message, Object details) { error = code; done.countDown(); }
        public void notImplemented() { error = "notImplemented"; done.countDown(); }
        void await() throws InterruptedException {
            if (!done.await(10, TimeUnit.SECONDS)) throw new AssertionError("Folder operation timeout");
        }
    }
}
