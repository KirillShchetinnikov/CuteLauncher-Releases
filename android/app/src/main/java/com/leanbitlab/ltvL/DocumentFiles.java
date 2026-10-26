package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.Intent;
import android.content.ClipData;
import android.content.ComponentName;
import android.content.pm.ResolveInfo;
import androidx.core.content.FileProvider;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import android.content.ContentValues;
import android.provider.MediaStore;
import android.os.Environment;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.concurrent.ExecutorService;
import io.flutter.plugin.common.MethodChannel;

/** One document operation at a time; content URIs never become filesystem paths. */
final class DocumentFiles {
    static final int REQUEST = 4107;
    private final Activity activity;
    private final ExecutorService executor;
    private MethodChannel.Result pending;
    private String savePath;
    private long limit;
    private boolean includeDisplayName;

    DocumentFiles(Activity activity, ExecutorService executor) {
        this.activity = activity;
        this.executor = executor;
    }

    private Intent readIntent(String mime) {
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT).setType(mime).addCategory(Intent.CATEGORY_OPENABLE);
        if (compatibleIntent(intent) == null)
            intent = new Intent(Intent.ACTION_GET_CONTENT).setType(mime).addCategory(Intent.CATEGORY_OPENABLE);
        return intent;
    }

    boolean imageAvailable() { return readIntent("image/*").resolveActivity(activity.getPackageManager()) != null; }

    void openNamed(String mime, long maximumBytes, MethodChannel.Result result) {
        if (pending != null) { result.error("document_busy", "Document operation in progress", null); return; }
        open(mime, maximumBytes, result);
        if (pending == result) includeDisplayName = true;
    }
    void open(String mime, long maximumBytes, MethodChannel.Result result) {
        begin(readIntent(mime), null, maximumBytes, result);
    }

    void openWallpaper(MethodChannel.Result result) {
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT).setType("*/*")
            .putExtra(Intent.EXTRA_MIME_TYPES, new String[]{"image/*", "video/*"})
            .addCategory(Intent.CATEGORY_OPENABLE);
        if (compatibleIntent(intent) == null) intent.setAction(Intent.ACTION_GET_CONTENT);
        begin(intent, null, 256L * 1024 * 1024, result);
    }

    void save(String source, String name, MethodChannel.Result result) {
        try {
            File file = new File(source).getCanonicalFile();
            String root = new File(activity.getApplicationInfo().dataDir).getCanonicalPath() + File.separator;
            if (!file.getPath().startsWith(root) || !file.isFile() || file.length() > 64L * 1024 * 1024)
                throw new IllegalArgumentException("Invalid export file");
            begin(new Intent(Intent.ACTION_CREATE_DOCUMENT).setType("application/json")
                .addCategory(Intent.CATEGORY_OPENABLE).putExtra(Intent.EXTRA_TITLE, name), file.getPath(), 64L * 1024 * 1024, result);
        } catch (Exception error) { result.error("document_failed", "Unable to export document", DiagnosticErrorDetails.from(error)); }
    }

    void saveDownloads(String source, MethodChannel.Result result) {
        executor.execute(() -> {
            Uri uri = null;
            try {
                File file = new File(source).getCanonicalFile();
                String root = new File(activity.getApplicationInfo().dataDir).getCanonicalPath() + File.separator;
                if (!file.getPath().startsWith(root) || !file.isFile() || file.length() > 64L * 1024 * 1024)
                    throw new IllegalArgumentException("Invalid export file");
                String name = "cutelauncher_backup_" + System.currentTimeMillis() + ".json";
                ContentValues values = new ContentValues();
                values.put(MediaStore.MediaColumns.DISPLAY_NAME, name);
                values.put(MediaStore.MediaColumns.MIME_TYPE, "application/json");
                values.put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS);
                values.put(MediaStore.MediaColumns.IS_PENDING, 1);
                uri = activity.getContentResolver().insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values);
                if (uri == null) throw new IllegalStateException("Downloads unavailable");
                try (InputStream input = new FileInputStream(file);
                     OutputStream output = activity.getContentResolver().openOutputStream(uri)) {
                    copy(input, output, 64L * 1024 * 1024);
                }
                values.clear(); values.put(MediaStore.MediaColumns.IS_PENDING, 0);
                activity.getContentResolver().update(uri, values, null, null);
                new Handler(Looper.getMainLooper()).post(() -> result.success("Download/" + name));
            } catch (Exception error) {
                if (uri != null) activity.getContentResolver().delete(uri, null, null);
                new Handler(Looper.getMainLooper()).post(() -> result.error("document_failed", "Unable to save backup to Downloads", DiagnosticErrorDetails.from(error)));
            }
        });
    }

    /** TV document stubs are not pickers. Some file managers instead offer SEND -> Save. */
    private Intent compatibleIntent(Intent intent) {
        return compatibleIntent(intent, activity.getPackageManager().queryIntentActivities(intent, 0));
    }

    static Intent compatibleIntent(Intent intent, List<ResolveInfo> candidates) {
        ArrayList<Intent> targets = new ArrayList<>();
        Intent system = null;
        for (ResolveInfo info : candidates) {
            if (info.activityInfo == null || !info.activityInfo.enabled || !info.activityInfo.exported
                || info.activityInfo.packageName.contains("frameworkpackagestubs")) continue;
            Intent target = new Intent(intent).setComponent(new ComponentName(
                info.activityInfo.packageName, info.activityInfo.name));
            if (info.activityInfo.applicationInfo != null
                && (info.activityInfo.applicationInfo.flags & android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0
                && info.activityInfo.packageName.toLowerCase(java.util.Locale.ROOT).contains("documentsui")) system = target;
            else targets.add(target);
        }
        if (system != null) return system;
        if (targets.isEmpty()) return null;
        if (targets.size() == 1) return targets.get(0);
        Intent chooser = Intent.createChooser(targets.remove(0), null);
        chooser.putExtra(Intent.EXTRA_INITIAL_INTENTS, targets.toArray(new Intent[0]));
        return chooser;
    }

    void saveReport(String source, String name, MethodChannel.Result result) {
        if (pending != null) { result.error("document_busy", "Another document picker is open", null); return; }
        try {
            File file = new File(source).getCanonicalFile();
            String root = new File(activity.getApplicationInfo().dataDir).getCanonicalPath() + File.separator;
            if (!file.getPath().startsWith(root) || !file.isFile() || file.length() > 64L * 1024 * 1024
                || !ReportExportPolicy.validName(name))
                throw new IllegalArgumentException("Invalid report file");
            Intent picker = compatibleIntent(new Intent(Intent.ACTION_CREATE_DOCUMENT).setType("application/json")
                .addCategory(Intent.CATEGORY_OPENABLE).putExtra(Intent.EXTRA_TITLE, name));
            if (picker != null) {
                begin(picker, file.getPath(), 64L * 1024 * 1024, new MethodChannel.Result() {
                    public void success(Object value) { result.success(Boolean.TRUE.equals(value) ? "saved" : null); }
                    public void error(String code, String message, Object details) { result.error(code, message, details); }
                    public void notImplemented() { result.notImplemented(); }
                });
                return;
            }
            if (compatibleIntent(new Intent(Intent.ACTION_SEND).setType("application/json")) == null) {
                result.error("document_unavailable", "No compatible report export application", null);
                return;
            }
            executor.execute(() -> {
                File exported = null;
                try {
                    File directory = new File(activity.getCacheDir(), "report_exports");
                    if (!directory.isDirectory() && !directory.mkdirs()) throw new IllegalStateException("Cache unavailable");
                    // Retain at most four exports: the receiver may read after returning to the launcher.
                    File[] previous = directory.listFiles();
                    if (previous != null) {
                        Arrays.sort(previous, Comparator.comparingLong(File::lastModified).reversed());
                        for (int i = 3; i < previous.length; i++) previous[i].delete();
                    }
                    exported = new File(directory, name);
                    try (InputStream input = new FileInputStream(file); OutputStream output = new FileOutputStream(exported)) {
                        copy(input, output, 64L * 1024 * 1024);
                    }
                    Uri uri = FileProvider.getUriForFile(activity, activity.getPackageName() + ".reports", exported);
                    Intent send = new Intent(Intent.ACTION_SEND).setType("application/json")
                        .putExtra(Intent.EXTRA_STREAM, uri).putExtra(Intent.EXTRA_TITLE, name)
                        .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                    send.setClipData(ClipData.newRawUri(name, uri));
                    final Intent target = compatibleIntent(send);
                    final File retained = exported;
                    new Handler(Looper.getMainLooper()).post(() -> {
                        try {
                            if (target == null) throw new IllegalStateException("Export application unavailable");
                            activity.startActivity(target);
                            // SEND has no save confirmation contract; don't claim the file was saved.
                            result.success("opened");
                        } catch (Exception error) {
                            retained.delete();
                            result.error("document_unavailable", "Unable to open report export application", DiagnosticErrorDetails.from(error));
                        }
                    });
                } catch (Exception error) {
                    if (exported != null) exported.delete();
                    new Handler(Looper.getMainLooper()).post(() -> result.error("document_failed", "Unable to export report", DiagnosticErrorDetails.from(error)));
                }
            });
        } catch (Exception error) { result.error("document_failed", "Unable to export report", DiagnosticErrorDetails.from(error)); }
    }

    private void begin(Intent intent, String source, long maximumBytes, MethodChannel.Result result) {
        if (pending != null) { result.error("document_busy", "Another document picker is open", null); return; }
        Intent selected = compatibleIntent(intent);
        if (selected == null) {
            result.error("document_unavailable", "No compatible document provider", null); return;
        }
        pending = result;
        includeDisplayName = false;
        savePath = source;
        limit = maximumBytes;
        try { activity.startActivityForResult(selected, REQUEST); }
        catch (Exception error) {
            List<ResolveInfo> alternatives = new ArrayList<>(activity.getPackageManager().queryIntentActivities(intent, 0));
            ComponentName failed = selected.getComponent();
            if (failed != null) alternatives.removeIf(info -> info.activityInfo != null
                && failed.getPackageName().equals(info.activityInfo.packageName)
                && failed.getClassName().equals(info.activityInfo.name));
            Intent fallback = compatibleIntent(intent, alternatives);
            if (fallback == null && source == null && failed != null) {
                Intent content = new Intent(Intent.ACTION_GET_CONTENT).setType(intent.getType()).addCategory(Intent.CATEGORY_OPENABLE);
                if (intent.hasExtra(Intent.EXTRA_MIME_TYPES))
                    content.putExtra(Intent.EXTRA_MIME_TYPES, intent.getStringArrayExtra(Intent.EXTRA_MIME_TYPES));
                List<ResolveInfo> readers = new ArrayList<>(activity.getPackageManager().queryIntentActivities(content, 0));
                readers.removeIf(info -> info.activityInfo != null && failed.getPackageName().equals(info.activityInfo.packageName));
                fallback = compatibleIntent(content, readers);
            }
            try {
                if (failed == null || fallback == null) throw new IllegalStateException();
                activity.startActivityForResult(fallback, REQUEST);
            } catch (Exception fallbackError) {
                pending = null; result.error("document_unavailable", "Unable to open document provider", DiagnosticErrorDetails.from(fallbackError));
            }
        }
    }

    void complete(int resultCode, Intent data) {
        final MethodChannel.Result result = pending;
        pending = null;
        if (result == null) return;
        if (resultCode != Activity.RESULT_OK || data == null || data.getData() == null) { result.success(null); return; }
        final Uri uri = data.getData();
        final String source = savePath;
        final long maximumBytes = limit;
        final boolean named = includeDisplayName;
        executor.execute(() -> {
            File temporary = null;
            try {
                if (source == null) {
                    temporary = File.createTempFile("selected-document-", ".bin", activity.getCacheDir());
                    try (InputStream input = activity.getContentResolver().openInputStream(uri);
                         OutputStream output = new FileOutputStream(temporary)) { copy(input, output, maximumBytes); }
                    final String path = temporary.getPath();
                    String displayName = "";
                    if (named) {
                        try (var cursor = activity.getContentResolver().query(uri,
                                new String[]{android.provider.OpenableColumns.DISPLAY_NAME}, null, null, null)) {
                            if (cursor != null && cursor.moveToFirst()) displayName = cursor.getString(0);
                        } catch (Exception ignored) { /* The file remains usable without provider metadata. */ }
                    }
                    final Object output = named ? java.util.Map.of("path", path, "name", displayName == null ? "" : displayName) : path;
                    new Handler(Looper.getMainLooper()).post(() -> result.success(output));
                } else {
                    try (InputStream input = new FileInputStream(source);
                         OutputStream output = activity.getContentResolver().openOutputStream(uri, "wt")) { copy(input, output, maximumBytes); }
                    new Handler(Looper.getMainLooper()).post(() -> result.success(true));
                }
            } catch (Exception error) {
                if (temporary != null) temporary.delete();
                String code = error instanceof DocumentTooLargeException ? "document_too_large" : "document_failed";
                new Handler(Looper.getMainLooper()).post(() -> result.error(code, "Unable to read or write document", DiagnosticErrorDetails.from(error)));
            }
        });
    }

    private static void copy(InputStream input, OutputStream output, long maximumBytes) throws Exception {
        if (input == null || output == null) throw new IllegalArgumentException("Document stream unavailable");
        byte[] buffer = new byte[16 * 1024];
        long total = 0;
        int count;
        while ((count = input.read(buffer)) != -1) {
            total += count;
            if (total > maximumBytes) throw new DocumentTooLargeException();
            output.write(buffer, 0, count);
        }
        output.flush();
    }

    private static final class DocumentTooLargeException extends java.io.IOException {}
}
