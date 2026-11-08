package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.Intent;
import android.content.ComponentName;
import android.content.pm.ResolveInfo;
import java.util.ArrayList;
import java.util.List;
import android.content.ContentValues;
import android.provider.MediaStore;
import android.os.Environment;
import android.os.Build;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import java.io.File;
import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.concurrent.ExecutorService;
import io.flutter.plugin.common.MethodChannel;

/** One document operation at a time; content URIs never become filesystem paths. */
final class DocumentFiles {
    static final int REQUEST = 4107;
    static final int TOKEN_DOCUMENT_LIMIT = 4096;
    private final Activity activity;
    private final ExecutorService executor;
    private final LegacyStorageAccess storageAccess;
    private MethodChannel.Result pending;
    private String savePath;
    private long limit;
    private boolean includeDisplayName;
    private boolean tokenDocument;

    DocumentFiles(Activity activity, ExecutorService executor) {
        this(activity, executor, new LegacyStorageAccess(activity));
    }

    DocumentFiles(Activity activity, ExecutorService executor, LegacyStorageAccess storageAccess) {
        this.activity = activity;
        this.executor = executor;
        this.storageAccess = storageAccess;
    }

    private Intent readIntent(String mime) {
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT).setType(mime).addCategory(Intent.CATEGORY_OPENABLE);
        if (compatibleIntent(intent) == null)
            intent = new Intent(Intent.ACTION_GET_CONTENT).setType(mime).addCategory(Intent.CATEGORY_OPENABLE);
        return intent;
    }

    boolean pickerAvailable(String operation) {
        Intent intent = switch (operation) {
            case "pickWallpaperFolder", "pickBackupFolder" -> new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE);
            case "saveBackupDocument", "saveDiagnosticsDocument" -> new Intent(Intent.ACTION_CREATE_DOCUMENT)
                .setType("application/json").addCategory(Intent.CATEGORY_OPENABLE);
            case "pickImageDocument" -> readIntent("image/*");
            case "pickWallpaperDocument" -> wallpaperIntent();
            case "pickWebhookDocument", "pickWeatherTokenDocument", "pickWeatherServerDocument" -> readIntent("text/plain");
            case "pickDriveClientDocument", "pickBackupDocument", "pickCleanerDocument", "pickCleanerListDocument" -> readIntent("*/*");
            default -> throw new IllegalArgumentException("Unknown picker operation");
        };
        return compatibleIntent(intent) != null;
    }

    private Intent wallpaperIntent() {
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT).setType("*/*")
            .putExtra(Intent.EXTRA_MIME_TYPES, new String[]{"image/*", "video/*"})
            .addCategory(Intent.CATEGORY_OPENABLE);
        if (compatibleIntent(intent) == null) intent.setAction(Intent.ACTION_GET_CONTENT);
        return intent;
    }

    boolean imageAvailable() { return pickerAvailable("pickImageDocument"); }

    void openNamed(String mime, long maximumBytes, MethodChannel.Result result) {
        if (pending != null) { result.error("document_busy", "Document operation in progress", null); return; }
        open(mime, maximumBytes, result);
        if (pending == result) includeDisplayName = true;
    }
    void open(String mime, long maximumBytes, MethodChannel.Result result) {
        begin(readIntent(mime), null, maximumBytes, result);
    }

    void openWeatherToken(MethodChannel.Result result) {
        open("text/plain", TOKEN_DOCUMENT_LIMIT, result);
        if (pending == result) tokenDocument = true;
    }

    void openWallpaper(MethodChannel.Result result) {
        begin(wallpaperIntent(), null, 256L * 1024 * 1024, result);
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
        storageAccess.run(true, result, () -> saveDownloadsGranted(source, result));
    }

    @SuppressWarnings("deprecation") // Public Downloads on Android 9, gated by storage permission.
    private void saveDownloadsGranted(String source, MethodChannel.Result result) {
        executor.execute(() -> {
            Uri uri = null;
            try {
                File file = new File(source).getCanonicalFile();
                String root = new File(activity.getApplicationInfo().dataDir).getCanonicalPath() + File.separator;
                if (!file.getPath().startsWith(root) || !file.isFile() || file.length() > 64L * 1024 * 1024)
                    throw new IllegalArgumentException("Invalid export file");
                String name = "cutelauncher_backup_" + System.currentTimeMillis() + "_" + java.util.UUID.randomUUID() + ".json";
                if (Build.VERSION.SDK_INT < 29) {
                    new LegacyBackupFiles(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)).export(name, file);
                    new Handler(Looper.getMainLooper()).post(() -> result.success("Download/" + name));
                    return;
                }
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

    /** TV document stubs are not document pickers. */
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
            Intent picker = new Intent(Intent.ACTION_CREATE_DOCUMENT).setType("application/json")
                .addCategory(Intent.CATEGORY_OPENABLE).putExtra(Intent.EXTRA_TITLE, name);
            begin(picker, file.getPath(), 64L * 1024 * 1024, new MethodChannel.Result() {
                public void success(Object value) { result.success(Boolean.TRUE.equals(value) ? "saved" : null); }
                public void error(String code, String message, Object details) { result.error(code, message, details); }
                public void notImplemented() { result.notImplemented(); }
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
        tokenDocument = false;
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
        final boolean token = tokenDocument;
        executor.execute(() -> {
            File temporary = null;
            try {
                if (token) {
                    byte[] bytes = readWeatherToken(activity.getContentResolver().openInputStream(uri));
                    new Handler(Looper.getMainLooper()).post(() -> result.success(bytes));
                } else if (source == null) {
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

    static byte[] readWeatherToken(InputStream input) throws Exception {
        try (input; ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            copy(input, output, TOKEN_DOCUMENT_LIMIT);
            return output.toByteArray();
        }
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

    static final class DocumentTooLargeException extends java.io.IOException {}
}
