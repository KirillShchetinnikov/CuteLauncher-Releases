package com.leanbitlab.ltvL;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.util.Arrays;
import java.util.Comparator;
import java.util.zip.CRC32;

/** Bounded disk cache of Android artwork. Use it from the image worker pool. */
final class AppArtworkCache {
    private static final int MAX_IMAGE_BYTES = 4 * 1024 * 1024;
    private static final int MAX_BYTES = 32 * 1024 * 1024;
    private static final int MAX_FILES = 384;
    private static final Object WRITE_LOCK = new Object();
    private final File directory;

    AppArtworkCache(File cacheDirectory) {
        directory = new File(cacheDirectory, "app-artwork-v1");
    }

    byte[] read(String packageName, boolean banner, String revision) {
        try (var input = new DataInputStream(new BufferedInputStream(
                new FileInputStream(file(packageName, banner))))) {
            if (!revision.equals(input.readUTF())) return null;
            int length = input.readInt();
            if (length < 0 || length > MAX_IMAGE_BYTES) return null;
            int expectedChecksum = input.readInt();
            byte[] bytes = new byte[length];
            input.readFully(bytes);
            return expectedChecksum == checksum(bytes) && input.read() == -1 ? bytes : null;
        } catch (IOException ignored) {
            return null;
        }
    }

    void save(String packageName, boolean banner, String revision, byte[] bytes) {
        if (bytes.length > MAX_IMAGE_BYTES) return;
        synchronized (WRITE_LOCK) {
            File pending = new File(directory, "pending");
            try {
                Files.createDirectories(directory.toPath());
                try (var output = new DataOutputStream(new BufferedOutputStream(new FileOutputStream(pending)))) {
                    output.writeUTF(revision);
                    output.writeInt(bytes.length);
                    output.writeInt(checksum(bytes));
                    output.write(bytes);
                }
                trim(file(packageName, banner), pending.length());
                Files.move(pending.toPath(), file(packageName, banner).toPath(),
                        StandardCopyOption.ATOMIC_MOVE, StandardCopyOption.REPLACE_EXISTING);
            } catch (IOException ignored) {
                // Cache storage is optional. The caller still receives the generated artwork.
            } finally {
                pending.delete();
            }
        }
    }

    private File file(String packageName, boolean banner) {
        return new File(directory, packageName + (banner ? ".banner" : ".icon"));
    }

    private void trim(File replacement, long incomingBytes) throws IOException {
        File[] files = directory.listFiles((dir, name) ->
                (name.endsWith(".banner") || name.endsWith(".icon")) && !name.equals(replacement.getName()));
        if (files == null) throw new IOException("Artwork cache directory unavailable");
        long bytes = incomingBytes;
        int count = files.length + 1;
        for (File file : files) bytes += file.length();
        if (bytes <= MAX_BYTES && count <= MAX_FILES) return;

        Arrays.sort(files, Comparator.comparingLong(File::lastModified));
        for (File file : files) {
            long length = file.length();
            Files.deleteIfExists(file.toPath());
            bytes -= length;
            count--;
            if (bytes <= MAX_BYTES && count <= MAX_FILES) break;
        }
    }

    private static int checksum(byte[] bytes) {
        CRC32 crc = new CRC32();
        crc.update(bytes);
        return (int) crc.getValue();
    }
}
