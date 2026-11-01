package com.leanbitlab.ltvL;

import android.app.Activity;
import android.os.Handler;
import android.os.Looper;
import io.flutter.plugin.common.MethodChannel;
import java.io.*;
import java.nio.file.Files;
import java.nio.file.FileAlreadyExistsException;
import java.nio.file.StandardCopyOption;
import java.util.Map;
import java.util.concurrent.ExecutorService;

/** Local selections use the same staging and size contracts as SAF documents. */
final class LocalDocumentFiles {
    private final Activity activity;
    private final ExecutorService executor;
    private final LocalWallpaperFiles storage;

    LocalDocumentFiles(Activity activity, ExecutorService executor, LocalWallpaperFiles storage) {
        this.activity = activity;
        this.executor = executor;
        this.storage = storage;
    }

    static long limit(String operation) {
        return switch (operation) {
            case "pickImageDocument" -> 8L * 1024 * 1024;
            case "pickWallpaperDocument" -> 256L * 1024 * 1024;
            case "pickWebhookDocument" -> 64L * 1024;
            case "pickCleanerDocument", "pickCleanerListDocument" -> 256L * 1024;
            case "pickBackupDocument", "saveBackupDocument", "saveDiagnosticsDocument" -> 64L * 1024 * 1024;
            default -> throw new IllegalArgumentException("Unknown document operation");
        };
    }

    static String kind(String operation) {
        return switch (operation) {
            case "pickImageDocument" -> "image";
            case "pickWallpaperDocument" -> "media";
            case "pickWebhookDocument", "pickCleanerDocument", "pickCleanerListDocument" -> "text";
            case "pickBackupDocument" -> "document";
            default -> throw new IllegalArgumentException("Unknown import operation");
        };
    }

    static void copy(File source, File target, long limit) throws IOException {
        try (InputStream input = new FileInputStream(source); OutputStream output = new FileOutputStream(target)) {
            byte[] buffer = new byte[16384];
            long size = 0;
            int count;
            while ((count = input.read(buffer)) != -1) {
                if (Thread.currentThread().isInterrupted()) throw new IOException("Interrupted");
                if ((size += count) > limit) throw new TooLargeException();
                output.write(buffer, 0, count);
            }
        }
    }

    File privateFile(String path) throws IOException {
        File file = new File(path).getCanonicalFile();
        String root = new File(activity.getApplicationInfo().dataDir).getCanonicalPath() + File.separator;
        if (!file.getPath().startsWith(root)) throw new SecurityException("Private staging required");
        return file;
    }

    void operate(String operation, String selected, String source, String name, MethodChannel.Result result) {
        boolean save = "saveBackupDocument".equals(operation) || "saveDiagnosticsDocument".equals(operation);
        if (!storage.granted(save)) { result.error("permission_denied", "Storage access required", null); return; }
        executor.execute(() -> {
            File temporary = null;
            File reserved = null;
            try {
                long maximum = limit(operation);
                Object reply;
                if (save) {
                    if (name == null || !name.matches("[a-zA-Z0-9_.-]{1,180}\\.json"))
                        throw new IllegalArgumentException("Invalid export name");
                    if ("saveDiagnosticsDocument".equals(operation) && !ReportExportPolicy.validName(name))
                        throw new IllegalArgumentException("Invalid report name");
                    File folder = LocalWallpaperFiles.directory(selected);
                    File input = privateFile(source);
                    if (!input.isFile()) throw new IOException("Source unavailable");
                    temporary = File.createTempFile(".cute-export-", ".partial", folder);
                    copy(input, temporary, maximum);
                    // Reserve a fresh name: exporting never overwrites a user's document.
                    for (int index = 0; index < 1000; index++) {
                        String candidate = index == 0 ? name : name.substring(0, name.length() - 5) + "-" + index + ".json";
                        File target = LocalWallpaperFiles.sharedFile(new File(folder, candidate).getPath());
                        if (!folder.equals(target.getParentFile())) throw new SecurityException("Direct child required");
                        try { Files.createFile(target.toPath()); reserved = target; break; }
                        catch (FileAlreadyExistsException ignored) { }
                    }
                    if (reserved == null) throw new IOException("No free export name");
                    Files.move(temporary.toPath(), reserved.toPath(), StandardCopyOption.REPLACE_EXISTING);
                    reply = Map.of("result", "saveBackupDocument".equals(operation) ? true : "saved",
                        "path", reserved.getPath());
                    reserved = null;
                } else {
                    File input = LocalWallpaperFiles.sharedFile(selected);
                    if (!input.isFile() || !input.canRead()) throw new IOException("File unavailable");
                    if (!LocalWallpaperFiles.matches(input, kind(operation)))
                        throw new IOException("Unsupported file type");
                    temporary = File.createTempFile("selected-document-", ".bin", activity.getCacheDir());
                    copy(input, temporary, maximum);
                    reply = "pickCleanerListDocument".equals(operation)
                        ? Map.of("path", temporary.getPath(), "name", input.getName()) : temporary.getPath();
                    temporary = null; // Ownership passes to the Dart caller.
                }
                Object value = reply;
                new Handler(Looper.getMainLooper()).post(() -> result.success(value));
            } catch (Exception error) {
                String code = error instanceof TooLargeException ? "document_too_large" : "document_failed";
                new Handler(Looper.getMainLooper()).post(() -> result.error(code, "Local document operation failed", DiagnosticErrorDetails.from(error)));
            } finally {
                if (temporary != null) temporary.delete();
                if (reserved != null) reserved.delete();
            }
        });
    }

    private static final class TooLargeException extends IOException { }
}
