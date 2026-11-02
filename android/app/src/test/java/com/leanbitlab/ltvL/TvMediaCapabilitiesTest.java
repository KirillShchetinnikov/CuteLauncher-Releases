package com.leanbitlab.ltvL;

import java.util.Map;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 29, 30, 36})
public class TvMediaCapabilitiesTest {
    @Test public void metadataIsReadOnlyAndSectionFailuresAreIsolated() {
        var result = TvMediaCapabilities.collect(RuntimeEnvironment.getApplication());
        assertEquals("reportedCapabilitiesOnly", result.get("scope"));
        var display = (Map<?, ?>) result.get("display");
        assertEquals("available", display.get("status"));
        var current = (Map<?, ?>) ((Map<?, ?>) display.get("data")).get("currentMode");
        assertTrue(((Number) current.get("width")).intValue() > 0);
        assertTrue(result.containsKey("decoders"));
        assertTrue(result.containsKey("audioOutputs"));
        assertFalse(result.toString().contains("productName"));
        var missing = TvMediaCapabilities.collect(null);
        assertEquals(Map.of("status", "unavailable"), missing.get("display"));
        assertEquals(Map.of("status", "unavailable"), missing.get("audioOutputs"));
        assertTrue(missing.containsKey("decoders"));
    }
}
