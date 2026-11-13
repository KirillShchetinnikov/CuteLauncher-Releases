package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.provider.DocumentsContract;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import io.flutter.plugin.common.MethodChannel;

/** SAF tree access; bounded enumeration and reads run off the main thread. */
final class WallpaperFolder {
    static final int REQUEST = 4108;
    private final Activity activity;
    private final ExecutorService executor;
    private MethodChannel.Result pending;
    final LocalWallpaperFiles local;
    WallpaperFolder(Activity activity, ExecutorService executor) {
        this.activity = activity;
        this.executor = executor;
        local = new LocalWallpaperFiles(activity, executor);
    }
    void pick(MethodChannel.Result result) {
        if (pending != null) { result.error("document_busy", "Folder picker already open", null); return; }
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION);
        // TV firmware can resolve this action to a stub even with a real picker installed.
        Intent selected = DocumentFiles.compatibleIntent(intent, activity.getPackageManager().queryIntentActivities(intent, 0));
        if (selected == null) {
            result.error("document_unavailable", "No folder provider", null); return;
        }
        pending = result;
        try { activity.startActivityForResult(selected, REQUEST); }
        catch (Exception error) { pending = null; result.error("document_unavailable", "Unable to open folder", DiagnosticErrorDetails.from(error)); }
    }
    void complete(int code, Intent data) {
        MethodChannel.Result result = pending;
        pending = null;
        if (result == null) return;
        if (code != Activity.RESULT_OK || data == null || data.getData() == null) { result.success(null); return; }
        try {
            Uri uri = data.getData();
            activity.getContentResolver().takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION);
            result.success(uri.toString());
        } catch (Exception error) { result.error("document_failed", "Unable to retain folder access", DiagnosticErrorDetails.from(error)); }
    }
    void release(String value, MethodChannel.Result result) {
        if (value != null && value.startsWith("file:")) { result.success(null); return; }
        try { activity.getContentResolver().releasePersistableUriPermission(Uri.parse(value), Intent.FLAG_GRANT_READ_URI_PERMISSION); }
        catch (Exception ignored) { }
        result.success(null);
    }
    void list(String value, boolean recursive, MethodChannel.Result result) {
        executor.execute(() -> {
            try {
                Uri tree = Uri.parse(value);
                if ("file".equals(tree.getScheme())) {
                    if (!local.granted()) throw new SecurityException("Storage access required");
                    var files = LocalWallpaperFiles.images(LocalWallpaperFiles.directory(value), recursive);
                    new Handler(Looper.getMainLooper()).post(() -> result.success(files));
                    return;
                }
                ArrayList<String> files = new ArrayList<>();
                ArrayDeque<String> directories = new ArrayDeque<>();
                HashSet<String> visited = new HashSet<>();
                directories.add(DocumentsContract.getTreeDocumentId(tree));
                int entries = 0;
                while (!directories.isEmpty() && entries < 4000 && files.size() < 1000) {
                    String id = directories.removeFirst();
                    if (!visited.add(id)) continue;
                    try (Cursor cursor = activity.getContentResolver().query(
                        DocumentsContract.buildChildDocumentsUriUsingTree(tree, id),
                        new String[]{DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                            DocumentsContract.Document.COLUMN_MIME_TYPE}, null, null, null)) {
                        if (cursor == null) throw new IllegalStateException("Folder unavailable");
                        while (cursor.moveToNext() && entries++ < 4000 && files.size() < 1000) {
                            String child = cursor.getString(0);
                            String mime = cursor.getString(1);
                            if (DocumentsContract.Document.MIME_TYPE_DIR.equals(mime)) {
                                if (recursive) directories.add(child);
                            } else if (mime != null && mime.startsWith("image/")) {
                                files.add(DocumentsContract.buildDocumentUriUsingTree(tree, child).toString());
                            }
                        }
                    }
                }
                java.util.Collections.sort(files);
                new Handler(Looper.getMainLooper()).post(() -> result.success(files));
            } catch (Exception error) {
                new Handler(Looper.getMainLooper()).post(() -> result.error("document_failed", "Unable to enumerate folder", DiagnosticErrorDetails.from(error)));
            }
        });
    }
    void listVideos(String value, MethodChannel.Result result) {
        executor.execute(() -> {
            try {
                Uri tree = Uri.parse(value);
                List<Map<String, Object>> files = new ArrayList<>();
                if ("file".equals(tree.getScheme())) {
                    if (!local.granted()) throw new SecurityException("Storage access required");
                    java.io.File folder = LocalWallpaperFiles.directory(value);
                    java.io.File[] children = folder.listFiles();
                    if (children == null) throw new IllegalStateException("Folder unavailable");
                    int entries = 0;
                    for (java.io.File child : children) {
                        if (entries++ >= 4000 || files.size() >= 1000) break;
                        if (!isVideoName(child.getName())) continue;
                        try {
                            java.io.File file = LocalWallpaperFiles.sharedFile(child.getPath());
                            if (folder.equals(file.getParentFile()) && file.isFile() && file.canRead()) {
                                files.add(video(file.toURI().toASCIIString(), child.getName(),
                                    file.lastModified(), file.length()));
                            }
                        } catch (SecurityException | java.io.IOException ignored) {
                            // A single inaccessible file must not hide the rest of the folder.
                        }
                    }
                } else {
                    listDocumentVideos(tree, files);
                }
                new Handler(Looper.getMainLooper()).post(() -> result.success(files));
            } catch (Exception error) {
                new Handler(Looper.getMainLooper()).post(() -> result.error(
                    "document_failed", "Unable to enumerate folder videos", DiagnosticErrorDetails.from(error)));
            }
        });
    }

    private void listDocumentVideos(Uri tree, List<Map<String, Object>> files) {
        String id = DocumentsContract.getTreeDocumentId(tree);
        try (Cursor cursor = activity.getContentResolver().query(
                DocumentsContract.buildChildDocumentsUriUsingTree(tree, id),
                new String[]{DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                    DocumentsContract.Document.COLUMN_MIME_TYPE,
                    DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                    DocumentsContract.Document.COLUMN_LAST_MODIFIED,
                    DocumentsContract.Document.COLUMN_SIZE}, null, null, null)) {
            if (cursor == null) throw new IllegalStateException("Folder unavailable");
            int entries = 0;
            while (entries++ < 4000 && files.size() < 1000 && cursor.moveToNext()) {
                String name = cursor.getString(2);
                if (DocumentsContract.Document.MIME_TYPE_DIR.equals(cursor.getString(1))
                        || !isVideoName(name)) continue;
                Uri uri = DocumentsContract.buildDocumentUriUsingTree(tree, cursor.getString(0));
                files.add(video(uri.toString(), name, cursor.getLong(3),
                    cursor.isNull(4) ? -1 : cursor.getLong(4)));
            }
        }
    }

    private static boolean isVideoName(String name) {
        return name != null && name.toLowerCase(java.util.Locale.ROOT).matches(".*\\.(mp4|m4v|webm|mkv)$");
    }

    private static Map<String, Object> video(String uri, String name, long modified, long size) {
        return Map.of("uri", uri, "name", name, "modified", Math.max(0, modified), "size", size);
    }

    void read(String value, MethodChannel.Result result) {
        executor.execute(() -> {
            try (InputStream input = openImage(value);
                 ByteArrayOutputStream output = new ByteArrayOutputStream()) {
                if (input == null) throw new IllegalStateException("Image unavailable");
                byte[] buffer = new byte[16384];
                int count;
                while ((count = input.read(buffer)) != -1) {
                    if (output.size() + count > 8 * 1024 * 1024) throw new IllegalArgumentException("Image too large");
                    output.write(buffer, 0, count);
                }
                byte[] bytes = output.toByteArray();
                new Handler(Looper.getMainLooper()).post(() -> result.success(bytes));
            } catch (Exception error) {
                new Handler(Looper.getMainLooper()).post(() -> result.error("document_failed", "Unable to read folder image", DiagnosticErrorDetails.from(error)));
            }
        });
    }

    private InputStream openImage(String value) throws Exception {
        if (value != null && value.startsWith("file:")) {
            if (!local.granted()) throw new SecurityException("Storage access required");
            return new java.io.FileInputStream(LocalWallpaperFiles.sharedFile(value));
        }
        return activity.getContentResolver().openInputStream(Uri.parse(value));
    }
}
