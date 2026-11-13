package com.leanbitlab.ltvL;

import java.nio.file.Files;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import static org.junit.Assert.*;

public class AppArtworkCacheTest {
    @Rule public final TemporaryFolder temporary = new TemporaryFolder();

    @Test public void readsArtworkAndAbsentBannerAfterRecreatingTheCache() {
        var root = temporary.getRoot();
        var first = new AppArtworkCache(root);
        byte[] icon = {1, 2, 3};
        first.save("example.app", false, "1", icon);
        first.save("example.app", true, "1", new byte[0]);

        var next = new AppArtworkCache(root);
        assertArrayEquals(icon, next.read("example.app", false, "1"));
        assertArrayEquals(new byte[0], next.read("example.app", true, "1"));
        assertNull(next.read("example.app", false, "2"));
        assertNull(next.read("example.app", true, "2"));

        byte[] banner = {4, 5};
        next.save("example.app", true, "2", banner);
        assertArrayEquals(banner, first.read("example.app", true, "2"));
        assertNull(first.read("example.app", true, "1"));
    }

    @Test public void ignoresTruncatedAndDamagedArtwork() throws Exception {
        var root = temporary.getRoot();
        var cache = new AppArtworkCache(root);
        cache.save("example.app", true, "1", new byte[]{1, 2, 3});
        var file = root.toPath().resolve("app-artwork-v1/example.app.banner");
        byte[] stored = Files.readAllBytes(file);
        stored[stored.length - 1] ^= 1;
        Files.write(file, stored);
        assertNull(cache.read("example.app", true, "1"));

        Files.write(file, new byte[]{1, 2});
        assertNull(cache.read("example.app", true, "1"));
    }

    @Test public void limitsTheCombinedSizeAndEntryCount() throws Exception {
        var root = temporary.getRoot();
        var cache = new AppArtworkCache(root);
        byte[] large = new byte[4 * 1024 * 1024];
        for (int i = 0; i < 9; i++) cache.save("large.app" + i, true, "1", large);
        var directory = root.toPath().resolve("app-artwork-v1").toFile();
        long total = 0;
        for (var file : directory.listFiles()) total += file.length();
        assertTrue(total <= 32 * 1024 * 1024);
        assertArrayEquals(large, cache.read("large.app8", true, "1"));

        for (int i = 0; i < 385; i++) cache.save("empty.app" + i, true, "1", new byte[0]);
        assertEquals(384, directory.list().length);
        assertArrayEquals(new byte[0], cache.read("empty.app384", true, "1"));
    }
}
