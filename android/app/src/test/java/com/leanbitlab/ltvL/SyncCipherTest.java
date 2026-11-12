package com.leanbitlab.ltvL;
import org.junit.Test;
import static org.junit.Assert.*;

public class SyncCipherTest {
    @Test public void roundTripAuthenticatesRecordAndKey() throws Exception {
        String key = SyncCipher.generate();
        String a = SyncCipher.seal(key, "weather_token", "test-only-token");
        assertEquals("test-only-token", SyncCipher.open(key, "weather_token", a));
        assertNotEquals(a, SyncCipher.seal(key, "weather_token", "test-only-token"));
        assertFalse(a.contains("test-only-token"));
        assertThrows(Exception.class, () -> SyncCipher.open(SyncCipher.generate(), "weather_token", a));
        assertThrows(Exception.class, () -> SyncCipher.open(key, "drive", a));
        String[] parts = a.split("\\.");
        byte[] bytes = java.util.Base64.getDecoder().decode(parts[2]); bytes[0] ^= 1;
        String tampered = parts[0] + "." + parts[1] + "." + java.util.Base64.getEncoder().encodeToString(bytes);
        assertThrows(Exception.class, () -> SyncCipher.open(key, "weather_token", tampered));
        assertThrows(Exception.class, () -> SyncCipher.open(key, "weather_token", a + ".extra"));
    }
    @Test public void rejectsPasswordsAndMalformedKeys() {
        assertThrows(IllegalArgumentException.class, () -> SyncCipher.key("password"));
        assertThrows(IllegalArgumentException.class, () -> SyncCipher.key("z".repeat(64)));
        assertEquals(32, SyncCipher.key(SyncCipher.generate()).length);
    }
}
