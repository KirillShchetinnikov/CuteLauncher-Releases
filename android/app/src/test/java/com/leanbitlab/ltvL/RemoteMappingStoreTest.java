package com.leanbitlab.ltvL;

import java.util.List;
import java.util.Map;
import org.json.JSONObject;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = 28)
public class RemoteMappingStoreTest {
    @Test public void reloadPreservesNamesAndActionsAcrossSubsequentSaves() throws Exception {
        var press = new RemoteMappingConfiguration.Binding(83, true, "app", "com.android.tv.settings", "press", "Настройки ТВ");
        var hold = new RemoteMappingConfiguration.Binding(83, true, "home", "", "hold", "Домой 🏠");
        var saved = new RemoteMappingConfiguration(true, Map.of(press.slot(), press, hold.slot(), hold));
        for (int i = 0; i < 2; i++) {
            saved = RemoteMappingStore.decode(new JSONObject(new JSONObject(saved.toMap()).toString()));
            assertEquals(press, saved.binding(83, "press"));
            assertEquals(hold, saved.binding(83, "hold"));
        }
    }

    @Test public void olderMappingsWithoutNameOrTriggerStillLoad() throws Exception {
        var saved = RemoteMappingStore.decode(new JSONObject("{\"enabled\":true,\"bindings\":[{\"keyCode\":83,\"enabled\":true,\"action\":\"home\",\"target\":\"\"}]}"));
        assertEquals("", saved.binding(83).name());
        assertEquals("press", saved.binding(83).trigger());
        assertEquals("home", saved.binding(83).action());
    }

    @Test public void customShellCommandsRoundTripLocallyAndCannotBeRestoredFromSync() throws Exception {
        String script = "printf '%s\\n' \"a b\"\ntrue";
        var local = new RemoteMappingConfiguration.Binding(83, true, "adb_shell", script);
        var portable = new RemoteMappingConfiguration.Binding(190, true, "tcl_epg", "");
        var configuration = new RemoteMappingConfiguration(true, Map.of(local.slot(), local, portable.slot(), portable));
        var encoded = new JSONObject(configuration.toMap());
        assertEquals(local, RemoteMappingStore.decode(encoded).binding(83));
        assertThrows(IllegalArgumentException.class, () -> RemoteMappingStore.decodePortable(encoded));
        var exported = RemoteMappingStore.decodePortable(new JSONObject(configuration.toMap(false)));
        assertNull(exported.binding(83));
        assertEquals(portable, exported.binding(190));
        assertTrue(RemoteAdbCommand.bounded(script).contains("printf '\\''%s\\n'\\'' \"a b\"\ntrue"));
        for (String invalid : List.of("", "\n\t", "true\u0000", "x".repeat(4097))) {
            assertFalse(RemoteMappingConfiguration.adbTarget(invalid));
        }
    }

    @Test public void retiredBlackScreenAssignmentIsSkippedOnlyOnLoad() throws Exception {
        var retired = new RemoteMappingConfiguration.Binding(83, true, "black_screen", "", "hold");
        var press = new RemoteMappingConfiguration.Binding(83, true, "black_overlay", "", "press", "Чёрный экран");
        var raw = Map.of("enabled", true, "bindings", List.of(retired.toMap(), press.toMap()),
            "volumeMode", "timed", "volumePauseSeconds", 10);

        var loaded = RemoteMappingStore.decode(new JSONObject(new JSONObject(raw).toString()));
        assertTrue(loaded.enabled);
        assertEquals(press, loaded.binding(83));
        assertNull(loaded.binding(83, "hold"));
        assertEquals("timed", loaded.volumeMode);
        assertEquals(10, loaded.volumePauseSeconds);
        assertThrows(IllegalArgumentException.class, () -> RemoteMappingConfiguration.fromMap(raw));
    }
}
