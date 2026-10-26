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
import java.util.concurrent.ExecutorService;
import io.flutter.plugin.common.MethodChannel;

/** SAF tree access; bounded enumeration and reads run off the main thread. */
final class WallpaperFolder {
    static final int REQUEST = 4108;
    private final Activity activity;
    private final ExecutorService executor;
    private MethodChannel.Result pending;
    WallpaperFolder(Activity activity, ExecutorService executor) {
        this.activity = activity;
        this.executor = executor;
    }
    void pick(MethodChannel.Result result) {
        if (pending != null) { result.error("document_busy", "Folder picker already open", null); return; }
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION);
        if (intent.resolveActivity(activity.getPackageManager()) == null) {
            result.error("document_unavailable", "No folder provider", null); return;
        }
        pending = result;
        try { activity.startActivityForResult(intent, REQUEST); }
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
        try { activity.getContentResolver().releasePersistableUriPermission(Uri.parse(value), Intent.FLAG_GRANT_READ_URI_PERMISSION); }
        catch (Exception ignored) { }
        result.success(null);
    }
    void list(String value, boolean recursive, MethodChannel.Result result) {
        executor.execute(() -> {
            try {
                Uri tree = Uri.parse(value);
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
    void read(String value, MethodChannel.Result result) {
        executor.execute(() -> {
            try (InputStream input = activity.getContentResolver().openInputStream(Uri.parse(value));
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
}
