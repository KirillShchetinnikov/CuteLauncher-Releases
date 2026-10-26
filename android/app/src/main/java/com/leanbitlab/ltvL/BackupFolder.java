package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.Intent;
import android.content.ContentValues;
import android.content.ContentUris;
import android.database.Cursor;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.os.Build;
import android.os.Environment;
import android.provider.DocumentsContract;
import android.provider.MediaStore;
import io.flutter.plugin.common.MethodChannel;
import java.io.*;
import java.util.*;
import java.util.concurrent.ExecutorService;

/** Persisted SAF tree, bounded streaming and direct children only. */
final class BackupFolder {
    static final int REQUEST = 4109;
    private static final long LIMIT = 64L * 1024 * 1024;
    private static final String DOWNLOADS = "cutelauncher://downloads/CuteLauncher";
    private static final String NAME = "^cute-(backup|sync)-(shared|[a-f0-9]{32})-[a-f0-9]{32}-[0-9]+-[a-f0-9]{16}\\.json$";
    private final Activity activity;
    private final ExecutorService executor;
    private MethodChannel.Result pending;
    BackupFolder(Activity activity, ExecutorService executor) { this.activity = activity; this.executor = executor; }
    void pick(MethodChannel.Result result) {
        if (pending != null) { result.error("document_busy", "Picker busy", null); return; }
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(
            Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION | Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION);
        Intent selected = DocumentFiles.compatibleIntent(intent, activity.getPackageManager().queryIntentActivities(intent, 0));
        if (selected == null) { result.error("document_unavailable", "No folder provider", null); return; }
        pending = result;
        try { activity.startActivityForResult(selected, REQUEST); }
        catch (Exception error) { pending = null; result.error("document_unavailable", "Cannot open folder provider", DiagnosticErrorDetails.from(error)); }
    }
    void complete(int code, Intent data) {
        MethodChannel.Result result = pending; pending = null;
        if (result == null) return;
        if (code != Activity.RESULT_OK || data == null || data.getData() == null) { result.success(null); return; }
        try {
            int flags = Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION;
            if ((data.getFlags() & flags) != flags) throw new SecurityException("Read/write access required");
            activity.getContentResolver().takePersistableUriPermission(data.getData(), flags);
            operate("verify", data.getData().toString(), null, null, result);
        } catch (Exception error) { result.error("document_failed", "Cannot retain folder access", DiagnosticErrorDetails.from(error)); }
    }
    private List<Map<String, String>> children(Uri tree) throws Exception {
        List<Map<String, String>> files = new ArrayList<>(); int count = 0;
        Uri children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree));
        try (Cursor cursor = activity.getContentResolver().query(children, new String[]{
            DocumentsContract.Document.COLUMN_DOCUMENT_ID, DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE}, null, null, null)) {
            if (cursor == null) throw new IOException("Folder unavailable");
            while (cursor.moveToNext()) {
                if (++count > 4096) throw new IOException("Too many files");
                String name = cursor.getString(1);
                if (name != null && name.matches(NAME) && !DocumentsContract.Document.MIME_TYPE_DIR.equals(cursor.getString(2))) {
                    Map<String, String> item = new HashMap<>(); item.put("name", name);
                    item.put("id", DocumentsContract.buildDocumentUriUsingTree(tree, cursor.getString(0)).toString()); files.add(item);
                }
            }
        }
        return files;
    }
    private File privateFile(String path) throws Exception {
        File file = new File(path).getCanonicalFile();
        String root = new File(activity.getApplicationInfo().dataDir).getCanonicalPath() + File.separator;
        if (!file.getPath().startsWith(root)) throw new SecurityException("Private staging required");
        return file;
    }
    private void copy(InputStream input, OutputStream output) throws Exception {
        if (input == null || output == null) throw new IOException("Stream unavailable");
        byte[] buffer = new byte[16384]; long size = 0; int count;
        while ((count = input.read(buffer)) != -1) {
            if (Thread.currentThread().isInterrupted() || (size += count) > LIMIT) throw new IOException("Transfer limit");
            output.write(buffer, 0, count);
        }
    }
    void operate(String operation, String value, String name, String path, MethodChannel.Result result) {
        executor.execute(() -> {
            if (DOWNLOADS.equals(value)) {
                try {
                    Object reply = downloads(operation, name, path);
                    new Handler(Looper.getMainLooper()).post(() -> result.success(reply));
                } catch (Exception error) {
                    new Handler(Looper.getMainLooper()).post(() -> result.error("document_failed", "Downloads operation failed", DiagnosticErrorDetails.from(error)));
                }
                return;
            }
            Uri temporary = null;
            try {
                Uri tree = Uri.parse(value);
                if (!"content".equals(tree.getScheme()) || !DocumentsContract.isTreeUri(tree)) throw new SecurityException("Invalid tree");
                Uri parent = DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree));
                Object response = true;
                if ("list".equals(operation)) response = children(tree);
                else if ("verify".equals(operation)) {
                    children(tree);
                    temporary = DocumentsContract.createDocument(activity.getContentResolver(), parent, "application/json", "cute-probe-" + UUID.randomUUID() + ".partial");
                    if (temporary == null) throw new IOException("Create failed");
                    try (OutputStream output = activity.getContentResolver().openOutputStream(temporary, "wt")) {
                        if (output == null) throw new IOException("Write unavailable"); output.write(new byte[]{123, 125});
                    }
                    Uri renamed = DocumentsContract.renameDocument(activity.getContentResolver(), temporary, "cute-probe-" + UUID.randomUUID() + ".check");
                    if (renamed == null) throw new IOException("Rename unavailable");
                    temporary = renamed;
                    if (!DocumentsContract.deleteDocument(activity.getContentResolver(), temporary)) throw new IOException("Delete unavailable");
                    temporary = null; response = value;
                } else {
                    if (name == null || !name.matches(NAME)) throw new SecurityException("Invalid backup name");
                    List<Map<String, String>> files = children(tree);
                    Uri existing = null;
                    for (Map<String, String> item : files) if (name.equals(item.get("name"))) {
                        if (existing != null) throw new IOException("Ambiguous backup name"); existing = Uri.parse(item.get("id"));
                    }
                    if ("upload".equals(operation)) {
                        if (existing != null) throw new IOException("Backup already exists");
                        File source = privateFile(path);
                        if (!source.isFile() || source.length() > LIMIT) throw new IOException("Invalid source");
                        temporary = DocumentsContract.createDocument(activity.getContentResolver(), parent, "application/json", name + ".partial");
                        if (temporary == null) throw new IOException("Create failed");
                        try (InputStream input = new FileInputStream(source); OutputStream output = activity.getContentResolver().openOutputStream(temporary, "wt")) { copy(input, output); }
                        Uri published = DocumentsContract.renameDocument(activity.getContentResolver(), temporary, name);
                        if (published == null) throw new IOException("Publish failed");
                        temporary = null;
                    } else if ("download".equals(operation)) {
                        if (existing == null) throw new IOException("Backup missing");
                        File target = privateFile(path);
                        try (InputStream input = activity.getContentResolver().openInputStream(existing); OutputStream output = new FileOutputStream(target)) { copy(input, output); }
                    } else if ("delete".equals(operation)) {
                        if (existing != null && !DocumentsContract.deleteDocument(activity.getContentResolver(), existing)) throw new IOException("Delete failed");
                    } else throw new IllegalArgumentException("Unknown operation");
                }
                Object reply = response;
                new Handler(Looper.getMainLooper()).post(() -> result.success(reply));
            } catch (Exception error) {
                new Handler(Looper.getMainLooper()).post(() -> result.error("document_failed", "Backup folder operation failed", DiagnosticErrorDetails.from(error)));
            } finally {
                if (temporary != null) try { DocumentsContract.deleteDocument(activity.getContentResolver(), temporary); } catch (Exception ignored) {}
            }
        });
    }

    /** App-owned Downloads entries need no broad storage permission. IS_PENDING publishes atomically. */
    private Object downloads(String operation, String name, String path) throws Exception {
        if (Build.VERSION.SDK_INT < 29) throw new IOException("Downloads unavailable");
        final String folder = Environment.DIRECTORY_DOWNLOADS + "/CuteLauncher/";
        final Uri collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI;
        final android.content.ContentResolver resolver = activity.getContentResolver();
        if (!"list".equals(operation) && !"verify".equals(operation)
            && (name == null || !name.matches(NAME))) throw new SecurityException("Invalid backup name");
        List<Map<String, String>> files = new ArrayList<>();
        try (Cursor cursor = resolver.query(collection,
                new String[]{MediaStore.MediaColumns._ID, MediaStore.MediaColumns.DISPLAY_NAME},
                MediaStore.MediaColumns.RELATIVE_PATH + "=? AND " + MediaStore.MediaColumns.IS_PENDING + "=0 AND "
                    + MediaStore.MediaColumns.OWNER_PACKAGE_NAME + "=?",
                new String[]{folder, activity.getPackageName()}, null)) {
            if (cursor == null) throw new IOException("Downloads unavailable");
            int count = 0;
            while (cursor.moveToNext()) {
                if (++count > 4096) throw new IOException("Too many files");
                String filename = cursor.getString(1);
                if (filename == null || !filename.matches(NAME)) continue;
                Map<String, String> file = new HashMap<>();
                file.put("name", filename);
                file.put("id", ContentUris.withAppendedId(collection, cursor.getLong(0)).toString());
                files.add(file);
            }
        }
        if ("list".equals(operation)) return files;
        Uri existing = null;
        for (Map<String, String> file : files) if (file.get("name").equals(name)) {
            if (existing != null) throw new IOException("Ambiguous backup name");
            existing = Uri.parse(file.get("id"));
        }
        if ("verify".equals(operation) || "upload".equals(operation)) {
            if (existing != null) throw new IOException("Backup already exists");
            boolean probe = "verify".equals(operation);
            File source = probe ? null : privateFile(path);
            if (!probe && (!source.isFile() || source.length() > LIMIT)) throw new IOException("Invalid source");
            ContentValues values = new ContentValues();
            values.put(MediaStore.MediaColumns.DISPLAY_NAME, probe ? "cute-probe-" + UUID.randomUUID() + ".json" : name);
            values.put(MediaStore.MediaColumns.MIME_TYPE, "application/json");
            values.put(MediaStore.MediaColumns.RELATIVE_PATH, folder);
            values.put(MediaStore.MediaColumns.IS_PENDING, 1);
            Uri pending = resolver.insert(collection, values);
            if (pending == null) throw new IOException("Create failed");
            try {
                try (OutputStream output = resolver.openOutputStream(pending, "wt")) {
                    if (output == null) throw new IOException("Write unavailable");
                    if (probe) output.write(new byte[]{123, 125});
                    else try (InputStream input = new FileInputStream(source)) { copy(input, output); }
                }
                if (probe) return DOWNLOADS;
                ContentValues published = new ContentValues();
                published.put(MediaStore.MediaColumns.IS_PENDING, 0);
                if (resolver.update(pending, published, null, null) != 1) throw new IOException("Publish failed");
                pending = null;
                return true;
            } finally {
                if (pending != null && resolver.delete(pending, null, null) != 1) throw new IOException("Cleanup failed");
            }
        }
        if ("download".equals(operation)) {
            if (existing == null) throw new IOException("Backup missing");
            File target = privateFile(path);
            try (InputStream input = resolver.openInputStream(existing); OutputStream output = new FileOutputStream(target)) {
                copy(input, output);
            }
            return true;
        }
        if ("delete".equals(operation)) {
            if (existing != null && resolver.delete(existing, null, null) != 1) throw new IOException("Delete failed");
            return true;
        }
        throw new IllegalArgumentException("Unknown operation");
    }
}
