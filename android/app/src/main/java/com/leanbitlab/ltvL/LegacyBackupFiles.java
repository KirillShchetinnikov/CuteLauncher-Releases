package com.leanbitlab.ltvL;

import java.io.*;
import java.nio.file.Files;
import java.util.*;

/** Bounded Android 9 Downloads backend. Partial writes never enter the backup listing. */
final class LegacyBackupFiles {
    static final long LIMIT = 64L * 1024 * 1024;
    static final String NAME = "^cute-(backup|sync)-(shared|[a-f0-9]{32})-[a-f0-9]{32}-[0-9]+-[a-f0-9]{16}\\.json$";
    private final File directory;

    LegacyBackupFiles(File directory) throws IOException {
        this.directory = directory.getCanonicalFile();
        if (!this.directory.equals(new File(directory.getParentFile().getCanonicalFile(), directory.getName())))
            throw new IOException("Invalid Downloads directory");
        if (!this.directory.isDirectory() && !this.directory.mkdirs()) throw new IOException("Downloads unavailable");
    }

    private File child(String name) throws IOException {
        File child = new File(directory, name);
        if (!child.getCanonicalFile().equals(child.getAbsoluteFile())) throw new IOException("Invalid file path");
        return child;
    }

    private static void copy(InputStream input, OutputStream output) throws IOException {
        byte[] buffer = new byte[16384];
        long size = 0;
        int count;
        while ((count = input.read(buffer)) != -1) {
            if (Thread.currentThread().isInterrupted() || (size += count) > LIMIT) throw new IOException("Transfer limit");
            output.write(buffer, 0, count);
        }
    }

    private void publish(String name, File source) throws IOException {
        File target = child(name);
        if (target.exists()) throw new IOException("Backup already exists");
        if (source != null && (!source.isFile() || source.length() > LIMIT)) throw new IOException("Invalid source");
        File partial = File.createTempFile("cute-", ".partial", directory);
        try {
            try (OutputStream output = new FileOutputStream(partial)) {
                if (source == null) output.write(new byte[]{123, 125});
                else try (InputStream input = new FileInputStream(source)) { copy(input, output); }
            }
            Files.move(partial.toPath(), target.toPath()); // No REPLACE_EXISTING: immutable backups.
        } finally { Files.deleteIfExists(partial.toPath()); }
    }

    synchronized Object operate(String operation, String name, File staging) throws IOException {
        if ("verify".equals(operation)) {
            String probe = "cute-probe-" + UUID.randomUUID() + ".check";
            publish(probe, null);
            Files.delete(child(probe).toPath());
            return true;
        }
        if ("list".equals(operation)) {
            List<Map<String, String>> entries = new ArrayList<>();
            // Stream the directory: do not allocate an unbounded File[] on a shared volume.
            try (var files = Files.newDirectoryStream(directory.toPath())) {
                int count = 0;
                for (var path : files) {
                    if (++count > 4096) throw new IOException("Too many files");
                    String filename = path.getFileName().toString();
                    if (filename.matches(NAME) && child(filename).isFile())
                        entries.add(Map.of("name", filename, "id", child(filename).toURI().toString()));
                }
            }
            return entries;
        }
        if (name == null || !name.matches(NAME)) throw new IOException("Invalid backup name");
        File file = child(name);
        switch (operation) {
            case "upload" -> {
                if (staging == null) throw new IOException("Missing staging file");
                publish(name, staging);
            }
            case "download" -> {
                if (staging == null) throw new IOException("Missing staging file");
                if (!file.isFile() || file.length() > LIMIT) throw new IOException("Invalid backup");
                try (InputStream input = new FileInputStream(file); OutputStream output = new FileOutputStream(staging)) {
                    copy(input, output);
                }
            }
            case "delete" -> Files.deleteIfExists(file.toPath());
            default -> throw new IOException("Unknown operation");
        }
        return true;
    }

    synchronized void export(String name, File source) throws IOException {
        if (name == null || !name.matches("cutelauncher_backup_[0-9]+_[a-f0-9-]+\\.json"))
            throw new IOException("Invalid export name");
        publish(name, source);
    }
}
