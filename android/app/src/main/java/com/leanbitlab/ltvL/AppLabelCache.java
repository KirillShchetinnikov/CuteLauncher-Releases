package com.leanbitlab.ltvL;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.function.Supplier;

/** Reconstructible Android labels. Only used by catalog workers. */
final class AppLabelCache {
    private static final int FORMAT = 1;
    private static final int MAX_ENTRIES = 2048;
    private static final int MAX_BYTES = 512 * 1024;
    private static AppLabelCache shared;

    private record Key(String source, String revision) {}

    private final File file;
    private final Map<Key, String> entries = new LinkedHashMap<>(16, 0.75f, true);
    private String environment;
    private boolean loaded;

    AppLabelCache(File directory) {
        file = new File(directory, "app-labels-v1");
    }

    static synchronized AppLabelCache forDirectory(File directory) {
        if (shared == null || !shared.file.getParentFile().equals(directory)) {
            shared = new AppLabelCache(directory);
        }
        return shared;
    }

    Batch batch(String environment) { return new Batch(environment); }

    final class Batch {
        private final String environment;
        private final Map<Key, String> additions = new LinkedHashMap<>();
        private int pendingBytes;

        private Batch(String environment) { this.environment = environment; }

        String resolve(String source, String revision, Supplier<String> load) {
            if (revision == null || !validKey(source, revision)) return load.get();
            Key key = new Key(source, revision);
            String value = additions.get(key);
            if (value == null) value = AppLabelCache.this.find(environment, key);
            if (value != null) return value;
            value = load.get();
            int bytes = entrySize(key, value);
            if (value.length() <= 1024 && additions.size() < MAX_ENTRIES
                    && pendingBytes + bytes <= MAX_BYTES) {
                additions.put(key, value);
                pendingBytes += bytes;
            }
            return value;
        }

        void save(Supplier<String> currentEnvironment) {
            AppLabelCache.this.save(environment, additions, currentEnvironment);
        }
    }

    private synchronized String find(String environment, Key key) {
        load();
        return environment.equals(this.environment) ? entries.get(key) : null;
    }

    private void load() {
        if (loaded) return;
        loaded = true;
        try (var stream = new FileInputStream(file);
             var input = new DataInputStream(new BufferedInputStream(stream))) {
            if (stream.getChannel().size() > MAX_BYTES || input.readInt() != FORMAT) return;
            String scope = input.readUTF();
            int count = input.readInt();
            if (scope.length() > 1024 || count < 0 || count > MAX_ENTRIES) return;
            for (int i = 0; i < count; i++) {
                String source = input.readUTF();
                String revision = input.readUTF();
                String label = input.readUTF();
                if (!validKey(source, revision) || label.length() > 1024) throw new IOException();
                entries.put(new Key(source, revision), label);
            }
            if (input.read() != -1) throw new IOException();
            environment = scope;
        } catch (IOException ignored) {
            entries.clear();
            environment = null;
        }
    }

    private synchronized void save(String scope, Map<Key, String> additions,
                                   Supplier<String> currentEnvironment) {
        if (additions.isEmpty() || scope.length() > 1024 || !scope.equals(currentEnvironment.get())) return;
        if (!scope.equals(environment)) {
            entries.clear();
            environment = scope;
        }
        entries.putAll(additions);
        trim(scope);
        Path pending = file.toPath().resolveSibling("app-labels-v1.pending");
        try {
            try (var output = new DataOutputStream(new BufferedOutputStream(Files.newOutputStream(pending)))) {
                output.writeInt(FORMAT);
                output.writeUTF(scope);
                output.writeInt(entries.size());
                for (var entry : entries.entrySet()) {
                    output.writeUTF(entry.getKey().source());
                    output.writeUTF(entry.getKey().revision());
                    output.writeUTF(entry.getValue());
                }
            }
            Files.move(pending, file.toPath(), StandardCopyOption.ATOMIC_MOVE, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException ignored) {
            // Reading names still works when cache storage is unavailable.
        } finally {
            try { Files.deleteIfExists(pending); } catch (IOException ignored) {}
        }
    }

    private void trim(String scope) {
        // Modified UTF-8 takes at most three bytes per UTF-16 unit.
        int bytes = 10 + 3 * scope.length();
        for (var entry : entries.entrySet()) bytes += entrySize(entry.getKey(), entry.getValue());
        var oldest = entries.entrySet().iterator();
        while (entries.size() > MAX_ENTRIES || bytes > MAX_BYTES) {
            var entry = oldest.next();
            bytes -= entrySize(entry.getKey(), entry.getValue());
            oldest.remove();
        }
    }

    private static int entrySize(Key key, String name) {
        return 6 + 3 * (key.source().length() + key.revision().length() + name.length());
    }

    private static boolean validKey(String source, String revision) {
        return !source.isEmpty() && source.length() <= 1024
                && !revision.isEmpty() && revision.length() <= 256;
    }
}
