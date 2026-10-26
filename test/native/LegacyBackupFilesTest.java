package com.leanbitlab.ltvL;

import java.io.*;
import java.nio.file.*;
import java.util.*;

public final class LegacyBackupFilesTest {
    private static int checks;
    private static final String NAME = "cute-backup-shared-" + "a".repeat(32) + "-123-" + "b".repeat(16) + ".json";
    private interface Operation { void run() throws Exception; }
    private static void check(boolean value) { checks++; if (!value) throw new AssertionError("Check " + checks); }
    private static void fails(Operation operation) throws Exception {
        checks++;
        try { operation.run(); } catch (IOException expected) { return; }
        throw new AssertionError("Expected IOException");
    }
    public static void main(String[] args) throws Exception {
        Path root = Files.createTempDirectory("legacy-backup-test-");
        try {
            File directory = root.resolve("Downloads/CuteLauncher").toFile();
            Files.createDirectories(directory.toPath().getParent());
            var storage = new LegacyBackupFiles(directory);
            File source = root.resolve("staging.json").toFile();
            Files.writeString(source.toPath(), "{\"backup\":true}");
            check(Boolean.TRUE.equals(storage.operate("verify", null, null)));
            check(directory.list().length == 0);
            storage.operate("upload", NAME, source);
            var entries = (List<?>) storage.operate("list", null, null);
            check(entries.size() == 1);
            check(NAME.equals(((Map<?, ?>)entries.get(0)).get("name")));
            File output = root.resolve("download.json").toFile();
            storage.operate("download", NAME, output);
            check(Files.readString(source.toPath()).equals(Files.readString(output.toPath())));
            fails(() -> storage.operate("upload", NAME, source));
            fails(() -> storage.operate("delete", "../staging.json", null));
            fails(() -> storage.operate("download", NAME, null));
            Files.writeString(directory.toPath().resolve("unrelated.txt"), "keep");
            Files.writeString(directory.toPath().resolve(NAME + ".partial"), "partial");
            check(((List<?>)storage.operate("list", null, null)).size() == 1);
            storage.operate("delete", NAME, null);
            storage.operate("delete", NAME, null); // Repeated removal is safe.
            check(Files.readString(directory.toPath().resolve("unrelated.txt")).equals("keep"));
            check(((List<?>)storage.operate("list", null, null)).isEmpty());
            fails(() -> storage.operate("download", NAME, output));
            try (var file = new RandomAccessFile(source, "rw")) { file.setLength(LegacyBackupFiles.LIMIT + 1); }
            fails(() -> storage.operate("upload", NAME, source));
            check(!new File(directory, NAME).exists());
            check(Arrays.stream(directory.list()).noneMatch(n -> n.startsWith("cute-") && n.endsWith(".partial") && !n.equals(NAME + ".partial")));
            Files.writeString(source.toPath(), "{}");
            String export = "cutelauncher_backup_123_" + UUID.randomUUID() + ".json";
            storage.export(export, source);
            check(Files.readString(directory.toPath().resolve(export)).equals("{}"));
            fails(() -> storage.export(export, source));
            fails(() -> storage.export("../export.json", source));
            check(((List<?>)storage.operate("list", null, null)).isEmpty());
            System.out.println("Legacy Downloads: " + checks + " checks passed");
        } finally {
            // Only the test-created temporary directory, with no symlink traversal.
            try (var paths = Files.walk(root)) {
                for (Path path : paths.sorted(Comparator.reverseOrder()).toList()) Files.delete(path);
            }
        }
    }
}
