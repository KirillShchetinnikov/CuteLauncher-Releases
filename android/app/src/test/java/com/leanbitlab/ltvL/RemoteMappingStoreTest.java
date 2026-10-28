package com.leanbitlab.ltvL;

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
}
