package com.leanbitlab.ltvL;
import android.content.Context;
import org.json.JSONObject;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;
import java.util.Map;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class NativeSyncBridgeTest {
    @Test public void yandexTokenRotationPreservesSyncIdentityButReconnectChangesIt() throws Exception {
        JSONObject payload = new JSONObject().put("connectionId", "a".repeat(32)).put("refreshToken", "old");
        JSONObject account = new JSONObject().put("user", "client").put("password", payload.toString());
        String identity = NativeSyncBridge.accountIdentity("yandex", account);
        payload.put("refreshToken", "rotated");
        account.put("password", payload.toString());
        assertEquals(identity, NativeSyncBridge.accountIdentity("yandex", account));
        payload.put("connectionId", "b".repeat(32));
        account.put("password", payload.toString());
        assertNotEquals(identity, NativeSyncBridge.accountIdentity("yandex", account));
        assertFalse(identity.contains("rotated"));
    }
    static final class MemoryStore extends SyncPrivateStore {
        JSONObject value = new JSONObject();
        MemoryStore(Context c) { super(c, "test"); }
        @Override JSONObject read() throws Exception { return new JSONObject(value.toString()); }
        @Override void write(JSONObject next) throws Exception { value = new JSONObject(next.toString()); }
        @Override void delete() { value = new JSONObject(); }
    }
    @Test public void nativeTransactionRestoresOldSettingsAfterRestart() throws Exception {
        Context c = RuntimeEnvironment.getApplication();
        var vault = new MemoryStore(c); var journal = new MemoryStore(c);
        var sync = new NativeSyncBridge(c, vault, journal);
        var prefs = c.getSharedPreferences("recent_apps", 0);
        prefs.edit().putString("mode", "custom").putLong("runtime", 123).commit();
        sync.begin(Map.of("native_config_recent_apps", "{\"mode\":\"system\"}"));
        assertEquals("system", prefs.getString("mode", ""));
        assertEquals(123, prefs.getLong("runtime", 0));
        new NativeSyncBridge(c, vault, journal).rollback();
        assertEquals("custom", prefs.getString("mode", ""));
        assertEquals(0, journal.read().length());
    }
    @Test public void validatesWholePacketBeforeAnyMutation() throws Exception {
        Context c = RuntimeEnvironment.getApplication();
        var vault = new MemoryStore(c); var journal = new MemoryStore(c);
        var sync = new NativeSyncBridge(c, vault, journal);
        c.getSharedPreferences("recent_apps", 0).edit().putString("mode", "custom").commit();
        assertThrows(Exception.class, () -> sync.begin(Map.of("native_config_recent_apps", "{\"mode\":\"system\"}",
            "native_config_vpn_widget", "{\"runtime\":true}")));
        assertEquals("custom", c.getSharedPreferences("recent_apps", 0).getString("mode", ""));
        assertEquals(0, journal.read().length());
        assertThrows(Exception.class, () -> NativeSyncBridge.validateSettings("auto_launch", new JSONObject("{\"delay\":100}")));
        assertThrows(Exception.class, () -> NativeSyncBridge.validateSettings("adb_connection", new JSONObject()));
    }
    @Test public void portableCredentialsAreStableAndLegacyWrongKeyCannotWrite() throws Exception {
        Context c = RuntimeEnvironment.getApplication(); var vault = new MemoryStore(c); var journal = new MemoryStore(c);
        String key = SyncCipher.generate(); vault.write(new JSONObject().put("key", key));
        var sync = new NativeSyncBridge(c, vault, journal);
        var first = sync.capture(); var second = sync.capture();
        assertEquals(first, second);
        assertTrue(first.containsKey("native_secret_remote_mappings"));
        assertFalse(first.containsKey("native_secret_drive"));
        assertFalse(first.containsKey("native_secret_webdav"));
        String token = SyncCipher.seal(key, "weather_yandex", "\"test-only-key\"");
        assertEquals("test-only-key", sync.decodePacket(Map.of("native_secret_weather_yandex", token)).getString("native_secret_weather_yandex"));
        assertThrows(Exception.class, () -> sync.begin(Map.of("native_secret_weather_yandex",
            SyncCipher.seal(SyncCipher.generate(), "weather_yandex", "\"test-only-key\""))));
        assertEquals(0, journal.read().length());
    }
    @Test public void storageCredentialsAreIgnoredEvenInOldPacketsAndPlainTokensNeedNoKey() throws Exception {
        Context c=RuntimeEnvironment.getApplication();var sync=new NativeSyncBridge(c,new MemoryStore(c),new MemoryStore(c));
        var packet=sync.decodePacket(Map.of("native_secret_drive","old-or-invalid-ciphertext","native_secret_webdav","old-or-invalid-ciphertext",
            "native_secret_weather_yandex","{\"plainVersion\":1,\"value\":\"test-only\"}"));
        assertEquals(1,packet.length());assertEquals("test-only",packet.getString("native_secret_weather_yandex"));
        assertTrue(sync.capture().containsKey("native_secret_weather_yandex"));
        assertThrows(Exception.class,()->sync.decodePacket(Map.of("native_secret_unknown","{\"plainVersion\":1,\"value\":null}")));
    }
}
