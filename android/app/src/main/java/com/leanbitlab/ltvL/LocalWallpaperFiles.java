package com.leanbitlab.ltvL;

import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import io.flutter.plugin.common.MethodChannel;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ExecutorService;

/** Shared-storage access for the built-in picker, independent of DocumentsUI. */
final class LocalWallpaperFiles {
    static final int REQUEST = 4117;
    private final Activity activity;
    private final ExecutorService executor;
    private MethodChannel.Result pending;
    private boolean pendingWrite;

    LocalWallpaperFiles(Activity activity, ExecutorService executor) {
        this.activity = activity;
        this.executor = executor;
    }

    boolean granted() {
        return Build.VERSION.SDK_INT >= 30 ? Environment.isExternalStorageManager()
            : activity.checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED;
    }

    boolean granted(boolean write) {
        return granted() && (!write || Build.VERSION.SDK_INT >= 30
            || activity.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED);
    }

    void request(MethodChannel.Result result) { request(false, result); }

    void request(boolean write, MethodChannel.Result result) {
        if (pending != null) { result.error("document_busy", "Storage request already open", null); return; }
        if (granted(write)) { result.success(true); return; }
        pendingWrite = write;
        pending = result;
        try {
            if (Build.VERSION.SDK_INT >= 30) {
                if (!AllFilesAccessSettings.open(activity, REQUEST)) {
                    pending = null;
                    result.error("storage_settings_unavailable", "All-files access settings unavailable", null);
                }
            } else activity.requestPermissions(write ? new String[]{Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE}
                : new String[]{Manifest.permission.READ_EXTERNAL_STORAGE}, REQUEST);
        } catch (RuntimeException error) {
            pending = null;
            result.error("document_unavailable", "Storage permission settings unavailable", DiagnosticErrorDetails.from(error));
        }
    }

    void complete() {
        MethodChannel.Result result = pending;
        pending = null;
        if (result != null) result.success(granted(pendingWrite));
    }

    void close() {
        MethodChannel.Result result = pending;
        pending = null;
        if (result != null) result.success(false);
    }

    static File sharedFile(String value) throws IOException {
        if (value == null || value.trim().isEmpty()) throw new IOException("Empty folder path");
        String path = value.trim();
        if (path.startsWith("file:")) {
            try { path = new File(java.net.URI.create(path)).getPath(); }
            catch (IllegalArgumentException error) { throw new IOException("Invalid file URI", error); }
        }
        if (path == null || !new File(path).isAbsolute()) throw new IOException("Absolute path required");
        File file = new File(path).getCanonicalFile();
        String resolved = file.getPath();
        String external = Environment.getExternalStorageDirectory().getCanonicalPath();
        if (!(resolved.equals("/storage") || resolved.startsWith("/storage/")
            || resolved.equals(external) || resolved.startsWith(external + File.separator)))
            throw new SecurityException("Shared storage path required");
        if (resolved.contains("/Android/data/") || resolved.endsWith("/Android/data")
            || resolved.contains("/Android/obb/") || resolved.endsWith("/Android/obb"))
            throw new SecurityException("Private app storage excluded");
        return file;
    }

    static File directory(String path) throws IOException {
        File file = sharedFile(path);
        if (!file.isDirectory() || !file.canRead()) throw new IOException("Folder unavailable");
        return file;
    }

    static boolean image(File file) {
        String name = file.getName().toLowerCase(Locale.ROOT);
        return name.endsWith(".jpg") || name.endsWith(".jpeg") || name.endsWith(".png")
            || name.endsWith(".webp") || name.endsWith(".gif") || name.endsWith(".bmp");
    }

    static List<String> images(File root, boolean recursive) throws IOException {
        ArrayList<String> images = new ArrayList<>();
        ArrayDeque<File> directories = new ArrayDeque<>();
        HashSet<String> visited = new HashSet<>();
        directories.add(root);
        int entries = 0;
        while (!directories.isEmpty() && entries < 4000 && images.size() < 1000) {
            File current = directories.removeFirst();
            if (!visited.add(current.getCanonicalPath())) continue;
            File[] children = current.listFiles();
            if (children == null) {
                if (current.equals(root)) throw new IOException("Folder unavailable");
                continue;
            }
            Arrays.sort(children, Comparator.comparing(File::getName));
            for (File child : children) {
                if (entries++ >= 4000 || images.size() >= 1000) break;
                try {
                    File safe = sharedFile(child.getPath());
                    // Do not follow a link outside the selected directory.
                    if (!safe.getPath().startsWith(root.getCanonicalPath() + File.separator)) continue;
                    if (safe.isDirectory()) { if (recursive) directories.add(safe); }
                    else if (safe.isFile() && image(safe)) images.add(safe.toURI().toASCIIString());
                } catch (SecurityException ignored) { }
            }
        }
        java.util.Collections.sort(images);
        return images;
    }

    static boolean matches(File file, String kind) {
        String name = file.getName().toLowerCase(Locale.ROOT);
        return switch (kind) {
            case "image" -> image(file);
            case "media" -> image(file) || name.matches(".*\\.(mp4|m4v|mkv|webm|mov|avi|3gp)$");
            case "text" -> name.endsWith(".txt") || name.endsWith(".json");
            case "document" -> name.endsWith(".json");
            default -> false;
        };
    }

    static Map<String, Object> fileEntry(File file, String name) {
        long size = -1, created = 0, modified = 0;
        try {
            BasicFileAttributes attributes = Files.readAttributes(file.toPath(), BasicFileAttributes.class);
            size = attributes.size();
            modified = attributes.lastModifiedTime().toMillis();
            long birth = attributes.creationTime().toMillis();
            // Android may substitute mtime when the filesystem has no birth time.
            // Do not present that ambiguous value as an actual creation date.
            if (birth > 0 && birth != modified) created = birth;
        } catch (IOException | SecurityException ignored) { }
        return Map.of("name", name, "path", file.getPath(), "size", size,
            "created", created, "modified", modified);
    }

    void browse(String path, MethodChannel.Result result) { browse(path, "folder", result); }

    void browse(String path, String kind, MethodChannel.Result result) {
        if (!granted()) { result.error("permission_denied", "Storage access required", null); return; }
        executor.execute(() -> {
            try {
                File folder = directory(path == null || path.isBlank() ? Environment.getExternalStorageDirectory().getPath() : path);
                File[] children = folder.listFiles();
                if (children == null) throw new IOException("Folder unavailable");
                Arrays.sort(children, Comparator.comparing(File::getName, String.CASE_INSENSITIVE_ORDER));
                ArrayList<Map<String, String>> directories = new ArrayList<>();
                ArrayList<Map<String, Object>> files = new ArrayList<>();
                HashSet<String> seen = new HashSet<>();
                int entries = 0;
                boolean truncated = false;
                for (File child : children) {
                    if (++entries > 4000 || directories.size() + files.size() >= 1000) {
                        truncated = true;
                        break;
                    }
                    try {
                        File safe = sharedFile(child.getPath());
                        if (!seen.add(safe.getPath())) continue;
                        if (safe.isDirectory()) directories.add(Map.of("name", child.getName(), "path", safe.getPath()));
                        else if (safe.isFile() && matches(safe, kind))
                            files.add(fileEntry(safe, child.getName()));
                    } catch (SecurityException ignored) { }
                }
                String parent = "";
                try { parent = directory(folder.getParent()).getPath(); } catch (IOException | SecurityException ignored) { }
                Map<String, Object> reply = Map.of("path", folder.getPath(), "uri", folder.toURI().toASCIIString(),
                    "parent", parent, "folders", directories, "files", files, "truncated", truncated);
                new Handler(Looper.getMainLooper()).post(() -> result.success(reply));
            } catch (Exception error) {
                new Handler(Looper.getMainLooper()).post(() -> result.error("document_failed", "Folder unavailable", DiagnosticErrorDetails.from(error)));
            }
        });
    }
}
