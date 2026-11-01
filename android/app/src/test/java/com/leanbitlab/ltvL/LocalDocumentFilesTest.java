package com.leanbitlab.ltvL;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.ResolveInfo;
import android.os.Environment;
import android.os.Looper;
import io.flutter.plugin.common.MethodChannel;
import java.io.File;
import java.nio.file.Files;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.Shadows;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 29, 36}, shadows = LocalWallpaperFilesTest.StorageEnvironment.class)
public class LocalDocumentFilesTest {
    private static class Reply implements MethodChannel.Result {
        Object value;
        String error;
        public void success(Object value) { this.value = value; }
        public void error(String code, String message, Object details) { this.error = code; }
        public void notImplemented() { fail("Not implemented"); }
    }

    private static void grant(Activity activity) {
        LocalWallpaperFilesTest.StorageEnvironment.manager = true;
        Shadows.shadowOf(activity.getApplication()).grantPermissions(
            Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE);
    }

    private static File folder() throws Exception {
        return Files.createTempDirectory(Environment.getExternalStorageDirectory().toPath(), "documents-").toFile().getCanonicalFile();
    }

    private static void finish(ExecutorService executor) throws Exception {
        executor.shutdown();
        assertTrue(executor.awaitTermination(10, TimeUnit.SECONDS));
        Shadows.shadowOf(Looper.getMainLooper()).idle();
    }

    @Test public void capabilityChecksRejectStubAndMatchOperationAndMime() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            var executor = Executors.newSingleThreadExecutor();
            try {
                var bridge = new DocumentFiles(activity, executor);
                var stub = new ResolveInfo();
                stub.activityInfo = new ActivityInfo();
                stub.activityInfo.packageName = "com.google.android.tv.frameworkpackagestubs";
                stub.activityInfo.name = "Stub";
                stub.activityInfo.enabled = stub.activityInfo.exported = true;
                var pm = Shadows.shadowOf(activity.getPackageManager());
                var tree = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE);
                pm.addResolveInfoForIntent(tree, stub);
                assertFalse(bridge.pickerAvailable("pickBackupFolder"));
                var real = new ResolveInfo();
                real.activityInfo = new ActivityInfo();
                real.activityInfo.packageName = "test.files";
                real.activityInfo.name = "Picker";
                real.activityInfo.enabled = real.activityInfo.exported = true;
                pm.addResolveInfoForIntent(new Intent(Intent.ACTION_GET_CONTENT).setType("image/*")
                    .addCategory(Intent.CATEGORY_OPENABLE), real);
                assertTrue(bridge.pickerAvailable("pickImageDocument"));
                assertFalse(bridge.pickerAvailable("saveBackupDocument"));
                assertNull(Shadows.shadowOf(activity).getNextStartedActivity());
            } finally { executor.shutdownNow(); }
        }
    }

    @Test public void reportPickerOffersMultipleCompatibleHandlersAndCancellationKeepsSource() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            var candidates = new java.util.ArrayList<ResolveInfo>();
            for (String packageName : List.of("test.files.first", "test.files.second")) {
                var real = new ResolveInfo();
                real.activityInfo = new ActivityInfo();
                real.activityInfo.packageName = packageName;
                real.activityInfo.name = "Picker";
                real.activityInfo.enabled = real.activityInfo.exported = true;
                candidates.add(real);
            }
            Shadows.shadowOf(activity.getPackageManager()).addResolveInfoForIntent(
                new Intent(Intent.ACTION_CREATE_DOCUMENT).setType("application/json").addCategory(Intent.CATEGORY_OPENABLE), candidates);
            File source = new File(activity.getFilesDir(), "source.json");
            Files.write(source.toPath(), new byte[]{123, 125});
            var executor = Executors.newSingleThreadExecutor();
            try {
                var documents = new DocumentFiles(activity, executor);
                var reply = new Reply();
                documents.saveReport(source.getPath(), "cutelauncher_diagnostics_123.json", reply);
                assertNull(reply.error);
                var started = Shadows.shadowOf(activity).getNextStartedActivityForResult();
                assertNotNull(started);
                assertEquals(Intent.ACTION_CHOOSER, started.intent.getAction());
                assertEquals(DocumentFiles.REQUEST, started.requestCode);
                documents.complete(Activity.RESULT_CANCELED, null);
                assertNull(reply.error);
                assertNull(reply.value);
                assertTrue(source.exists());
            } finally { executor.shutdownNow(); }
        }
    }

    @Test public void localImportsRejectWrongTypesBeforeStaging() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            grant(activity);
            var executor = Executors.newSingleThreadExecutor();
            try {
                File source = new File(folder(), "video.mp4");
                Files.write(source.toPath(), new byte[]{1, 2, 3});
                var local = new LocalDocumentFiles(activity, executor, new LocalWallpaperFiles(activity, executor));
                var replies = new java.util.ArrayList<Reply>();
                for (String operation : List.of("pickBackupDocument", "pickWebhookDocument", "pickCleanerDocument", "pickCleanerListDocument", "pickImageDocument")) {
                    var reply = new Reply();
                    replies.add(reply);
                    local.operate(operation, source.getPath(), null, null, reply);
                }
                finish(executor);
                for (var reply : replies) {
                    assertEquals("document_failed", reply.error);
                    assertNull(reply.value);
                }
                assertArrayEquals(new byte[]{1, 2, 3}, Files.readAllBytes(source.toPath()));
                assertEquals(0, activity.getCacheDir().listFiles((dir, name) -> name.startsWith("selected-document-")).length);
            } finally { executor.shutdownNow(); }
        }
    }

    @Test public void importsAreStagedBoundedAndNeverDeleteOriginal() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            grant(activity);
            var executor = Executors.newSingleThreadExecutor();
            try {
                File root = folder(), source = new File(root, "список #1.json");
                Files.write(source.toPath(), "{}".getBytes(java.nio.charset.StandardCharsets.UTF_8));
                var local = new LocalDocumentFiles(activity, executor, new LocalWallpaperFiles(activity, executor));
                var selected = new Reply();
                local.operate("pickCleanerListDocument", source.toURI().toASCIIString(), null, null, selected);
                File large = new File(root, "large.txt");
                Files.write(large.toPath(), new byte[64 * 1024 + 1]);
                var rejected = new Reply();
                local.operate("pickWebhookDocument", large.getPath(), null, null, rejected);
                finish(executor);
                assertNull(selected.error);
                var data = (Map<?, ?>) selected.value;
                File staged = new File((String) data.get("path"));
                assertEquals(source.getName(), data.get("name"));
                assertEquals("{}", new String(Files.readAllBytes(staged.toPath()), java.nio.charset.StandardCharsets.UTF_8));
                assertTrue(staged.delete());
                assertTrue(source.exists());
                assertEquals("document_too_large", rejected.error);
                assertEquals(0, activity.getCacheDir().listFiles((dir, name) -> name.startsWith("selected-document-")).length);
            } finally { executor.shutdownNow(); }
        }
    }

    @Test public void exportsKeepExistingFilesAndRemovePartialFiles() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            grant(activity);
            File root = folder();
            Files.write(new File(root, "cutelauncher_diagnostics_123.json").toPath(), "old".getBytes(java.nio.charset.StandardCharsets.UTF_8));
            File source = new File(activity.getFilesDir(), "cutelauncher_diagnostics_123.json");
            Files.write(source.toPath(), "new".getBytes(java.nio.charset.StandardCharsets.UTF_8));
            var executor = Executors.newSingleThreadExecutor();
            try {
                var local = new LocalDocumentFiles(activity, executor, new LocalWallpaperFiles(activity, executor));
                var saved = new Reply();
                local.operate("saveDiagnosticsDocument", root.getPath(), source.getPath(), "cutelauncher_diagnostics_123.json", saved);
                var rejected = new Reply();
                local.operate("saveBackupDocument", root.getPath(), source.getPath(), "../escape.json", rejected);
                finish(executor);
                assertEquals("saved", ((Map<?, ?>) saved.value).get("result"));
                assertEquals(new File(root, "cutelauncher_diagnostics_123-1.json").getPath(), ((Map<?, ?>) saved.value).get("path"));
                assertEquals("old", new String(Files.readAllBytes(new File(root, "cutelauncher_diagnostics_123.json").toPath()), java.nio.charset.StandardCharsets.UTF_8));
                assertEquals("new", new String(Files.readAllBytes(new File(root, "cutelauncher_diagnostics_123-1.json").toPath()), java.nio.charset.StandardCharsets.UTF_8));
                assertEquals("document_failed", rejected.error);
                assertEquals(2, root.listFiles().length);
            } finally { executor.shutdownNow(); }
        }
    }

    @Test public void localBackupFolderVerifiesUploadsListsDownloadsAndDeletes() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            grant(activity);
            File root = folder(), source = new File(activity.getFilesDir(), "source.json");
            Files.write(source.toPath(), "{}".getBytes(java.nio.charset.StandardCharsets.UTF_8));
            String uri = root.toURI().toASCIIString();
            String name = "cute-backup-shared-0123456789abcdef0123456789abcdef-123-0123456789abcdef.json";
            var executor = Executors.newSingleThreadExecutor();
            try {
                var folder = new BackupFolder(activity, executor);
                var verified = new Reply(); folder.operate("verify", uri, null, null, verified);
                var uploaded = new Reply(); folder.operate("upload", uri, name, source.getPath(), uploaded);
                var duplicate = new Reply(); folder.operate("upload", uri, name, source.getPath(), duplicate);
                var listed = new Reply(); folder.operate("list", uri, null, null, listed);
                File output = new File(activity.getFilesDir(), "output.json");
                var downloaded = new Reply(); folder.operate("download", uri, name, output.getPath(), downloaded);
                var deleted = new Reply(); folder.operate("delete", uri, name, null, deleted);
                finish(executor);
                assertEquals(uri, verified.value);
                assertEquals(true, uploaded.value);
                assertEquals("document_failed", duplicate.error);
                assertEquals(1, ((List<?>) listed.value).size());
                assertEquals(true, downloaded.value);
                assertEquals("{}", new String(Files.readAllBytes(output.toPath()), java.nio.charset.StandardCharsets.UTF_8));
                assertEquals(true, deleted.value);
                assertEquals(0, root.listFiles().length);
                assertTrue(source.exists());
            } finally { executor.shutdownNow(); }
        }
    }

    @Test public void fileFiltersKeepFoldersAndOnlyRelevantExtensions() throws Exception {
        assertTrue(LocalWallpaperFiles.matches(new File("photo.JPG"), "image"));
        assertFalse(LocalWallpaperFiles.matches(new File("movie.mp4"), "image"));
        assertTrue(LocalWallpaperFiles.matches(new File("movie.mp4"), "media"));
        assertTrue(LocalWallpaperFiles.matches(new File("settings.json"), "document"));
        assertTrue(LocalWallpaperFiles.matches(new File("webhook.txt"), "text"));
        assertFalse(LocalWallpaperFiles.matches(new File("image.png"), "text"));
    }
}
