package com.leanbitlab.ltvL;

import android.Manifest;
import android.app.Activity;
import android.net.Uri;
import android.os.Environment;
import android.os.Looper;
import io.flutter.plugin.common.MethodChannel;
import java.io.File;
import java.nio.file.FileSystemException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.Shadows;
import org.robolectric.annotation.Config;
import org.robolectric.annotation.Implements;
import org.robolectric.annotation.Implementation;
import org.robolectric.annotation.Resetter;
import org.robolectric.shadows.ShadowEnvironment;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 29, 36}, shadows = LocalWallpaperFilesTest.StorageEnvironment.class)
public class LocalWallpaperFilesTest {
    @Implements(Environment.class)
    public static class StorageEnvironment extends ShadowEnvironment {
        static boolean manager;
        @Implementation(minSdk = 30) protected static boolean isExternalStorageManager() { return manager; }
        @Resetter public static void resetManager() { manager = false; }
    }
    private static class Reply implements MethodChannel.Result {
        Object value;
        String error;
        public void success(Object value) { this.value = value; }
        public void error(String code, String message, Object details) { error = code; }
        public void notImplemented() { fail("Not implemented"); }
    }

    private static File folder() throws Exception {
        return Files.createTempDirectory(Environment.getExternalStorageDirectory().toPath(), "wallpapers-").toFile().getCanonicalFile();
    }

    private static void linkDirectory(Path link, Path target) throws Exception {
        try {
            Files.createSymbolicLink(link, target);
        } catch (FileSystemException error) {
            if (!System.getProperty("os.name").startsWith("Windows")) throw error;
            // A junction also resolves to its target through File.getCanonicalFile().
            var builder = new ProcessBuilder("powershell.exe", "-NoProfile", "-NonInteractive", "-Command",
                    "New-Item -ItemType Junction -Path $env:CUTE_TEST_LINK "
                            + "-Target $env:CUTE_TEST_TARGET -ErrorAction Stop | Out-Null");
            builder.environment().put("CUTE_TEST_LINK", link.toString());
            builder.environment().put("CUTE_TEST_TARGET", target.toString());
            var process = builder.redirectErrorStream(true).start();
            if (!process.waitFor(15, TimeUnit.SECONDS)) {
                process.destroyForcibly();
                fail("Creating the test junction timed out");
            }
            assertEquals(new String(process.getInputStream().readAllBytes()), 0, process.exitValue());
        }
        assertEquals(target.toFile().getCanonicalFile(), link.toFile().getCanonicalFile());
    }

    @Test public void everyPickerKindFiltersExtensionsAndRejectsUnrelatedFiles() {
        var formats = java.util.Map.of(
            "image", List.of("jpg", "jpeg", "png", "webp", "gif", "bmp"),
            "media", List.of("jpg", "jpeg", "png", "webp", "gif", "bmp", "mp4", "m4v", "mkv", "webm", "mov", "avi", "3gp"),
            "text", List.of("txt", "json"), "document", List.of("json"),
            "folder", List.<String>of());
        for (var kind : formats.entrySet()) {
            for (String extension : List.of("jpg", "jpeg", "png", "webp", "gif", "bmp", "mp4", "m4v", "mkv", "webm", "mov", "avi", "3gp", "txt", "json", "apk", "zip")) {
                assertEquals(kind.getKey() + ": " + extension, kind.getValue().contains(extension),
                    LocalWallpaperFiles.matches(new File("file." + extension.toUpperCase(java.util.Locale.ROOT)), kind.getKey()));
            }
            assertFalse(LocalWallpaperFiles.matches(new File("file.json.mp4"), "document"));
            assertFalse(LocalWallpaperFiles.matches(new File("no-extension"), kind.getKey()));
        }
    }

    @Test public void filteredBrowserKeepsFoldersAndReturnsFileMetadata() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            if (android.os.Build.VERSION.SDK_INT >= 30) StorageEnvironment.manager = true;
            else Shadows.shadowOf(activity.getApplication()).grantPermissions(Manifest.permission.READ_EXTERNAL_STORAGE);
            var executor = Executors.newSingleThreadExecutor();
            try {
                File root = folder();
                assertTrue(new File(root, "subfolder").mkdir());
                File json = new File(root, "backup.JSON");
                Files.write(json.toPath(), new byte[]{123, 125});
                Files.write(new File(root, "video.mp4").toPath(), new byte[]{1});
                var result = new Reply();
                new LocalWallpaperFiles(activity, executor).browse(root.getPath(), "document", result);
                executor.shutdown();
                assertTrue(executor.awaitTermination(10, TimeUnit.SECONDS));
                Shadows.shadowOf(Looper.getMainLooper()).idle();
                assertNull(result.error);
                var data = (java.util.Map<?, ?>) result.value;
                assertEquals(1, ((List<?>) data.get("folders")).size());
                var files = (List<?>) data.get("files");
                assertEquals(1, files.size());
                var file = (java.util.Map<?, ?>) files.get(0);
                assertEquals("backup.JSON", file.get("name"));
                assertEquals(2L, file.get("size"));
                assertEquals(json.lastModified(), file.get("modified"));
                assertTrue(((Long) file.get("created")) >= 0);
            } finally { executor.shutdownNow(); }
        }
    }

    @Test public void directAndRecursiveImagesUseEncodedUrisAndIgnoreOtherFiles() throws Exception {
        File root = folder();
        File nested = new File(root, "nested");
        assertTrue(nested.mkdir());
        File first = new File(root, "фото #1.JPG");
        File second = new File(nested, "night.png");
        Files.write(first.toPath(), new byte[]{1, 2});
        Files.write(second.toPath(), new byte[]{3});
        Files.write(new File(root, "video.mp4").toPath(), new byte[]{4});
        Files.write(new File(root, "notes.txt").toPath(), new byte[]{5});
        assertEquals(List.of(first.toURI().toASCIIString()), LocalWallpaperFiles.images(root, false));
        var recursive = LocalWallpaperFiles.images(root, true);
        assertEquals(2, recursive.size());
        assertTrue(recursive.contains(second.toURI().toASCIIString()));
        assertEquals(root, LocalWallpaperFiles.directory(root.toURI().toASCIIString()));
        assertArrayEquals(new byte[]{1, 2}, Files.readAllBytes(first.toPath()));
    }

    @Test public void pathsMustBeAbsoluteAccessibleSharedDirectories() throws Exception {
        assertThrows(java.io.IOException.class, () -> LocalWallpaperFiles.directory("Pictures"));
        assertThrows(Exception.class, () -> LocalWallpaperFiles.sharedFile("/data/user/0/private"));
        assertThrows(Exception.class, () -> LocalWallpaperFiles.sharedFile("/storage/emulated/0/Android/data/private"));
        assertThrows(Exception.class, () -> LocalWallpaperFiles.sharedFile("/storage/../data/private"));
        assertThrows(java.io.IOException.class, () -> LocalWallpaperFiles.directory(new File(folder(), "missing").getPath()));
    }

    @Test public void recursionDoesNotFollowLinksOutsideSelectedFolderOrLoop() throws Exception {
        File root = folder();
        File outside = folder();
        Path nested = Files.createDirectory(root.toPath().resolve("nested"));
        Path inside = Files.write(nested.resolve("inside.png"), new byte[]{1});
        Files.write(new File(outside, "outside.png").toPath(), new byte[]{1});
        Path escape = root.toPath().resolve("escape");
        Path loop = nested.resolve("loop");
        try {
            linkDirectory(escape, outside.toPath());
            linkDirectory(loop, nested);
            assertEquals(List.of(inside.toFile().toURI().toASCIIString()),
                    LocalWallpaperFiles.images(root, true));
        } finally {
            Files.deleteIfExists(loop);
            Files.deleteIfExists(escape);
        }
    }

    @Test public void imageEnumerationIsBounded() throws Exception {
        File root = folder();
        for (int i = 0; i < 1005; i++) Files.write(new File(root, i + ".png").toPath(), new byte[]{1});
        assertEquals(1000, LocalWallpaperFiles.images(root, true).size());
    }

    @Test public void missingPermissionNeverEnumeratesOrPromptsInBackground() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            var executor = Executors.newSingleThreadExecutor();
            try {
                LocalWallpaperFilesTest.StorageEnvironment.manager = false;
                Shadows.shadowOf(activity.getApplication()).denyPermissions(Manifest.permission.READ_EXTERNAL_STORAGE);
                var local = new LocalWallpaperFiles(activity, executor);
                var result = new Reply();
                local.browse(null, result);
                assertEquals("permission_denied", result.error);
                assertNull(Shadows.shadowOf(activity).getNextStartedActivity());
            } finally { executor.shutdownNow(); }
        }
    }

    @Test public void grantedStorageBrowsesFoldersAndReadsThroughWallpaperBridge() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            if (android.os.Build.VERSION.SDK_INT >= 30) StorageEnvironment.manager = true;
            else Shadows.shadowOf(activity.getApplication()).grantPermissions(Manifest.permission.READ_EXTERNAL_STORAGE);
            var executor = Executors.newSingleThreadExecutor();
            try {
                File root = folder();
                File nested = new File(root, "photos");
                assertTrue(nested.mkdir());
                File image = new File(root, "image.png");
                byte[] bytes = {1, 2, 3};
                Files.write(image.toPath(), bytes);
                var bridge = new WallpaperFolder(activity, executor);
                var permission = new Reply();
                bridge.local.request(permission);
                assertEquals(true, permission.value);
                var browse = new Reply();
                bridge.local.browse(root.getPath(), browse);
                var list = new Reply();
                bridge.list(root.toURI().toASCIIString(), false, list);
                var read = new Reply();
                bridge.read(image.toURI().toASCIIString(), read);
                executor.shutdown();
                assertTrue(executor.awaitTermination(10, TimeUnit.SECONDS));
                Shadows.shadowOf(Looper.getMainLooper()).idle();
                assertNull(browse.error);
                var info = (java.util.Map<?, ?>) browse.value;
                assertEquals(root.getPath(), info.get("path"));
                assertEquals(false, info.get("truncated"));
                assertEquals(1, ((List<?>) info.get("folders")).size());
                assertEquals(List.of(image.toURI().toASCIIString()), list.value);
                assertArrayEquals(bytes, (byte[]) read.value);
            } finally { executor.shutdownNow(); }
        }
    }
    @Test public void browserReportsTruncatedResultsWithoutIncreasingLimits() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            if (android.os.Build.VERSION.SDK_INT >= 30) StorageEnvironment.manager = true;
            else Shadows.shadowOf(activity.getApplication()).grantPermissions(Manifest.permission.READ_EXTERNAL_STORAGE);
            var executor = Executors.newSingleThreadExecutor();
            try {
                File root = folder();
                for (int i = 0; i < 1001; i++) Files.write(new File(root, i + ".json").toPath(), new byte[]{1});
                var result = new Reply();
                new LocalWallpaperFiles(activity, executor).browse(root.getPath(), "document", result);
                executor.shutdown();
                assertTrue(executor.awaitTermination(120, TimeUnit.SECONDS));
                Shadows.shadowOf(Looper.getMainLooper()).idle();
                assertNull(result.error);
                var data = (java.util.Map<?, ?>) result.value;
                assertEquals(1000, ((List<?>) data.get("files")).size());
                assertEquals(true, data.get("truncated"));
            } finally { executor.shutdownNow(); }
        }
    }

}
