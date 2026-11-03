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
    @Test public void numericCapabilitiesPreserveOrderAndBoundOutput() {
        assertEquals(java.util.List.of(), TvMediaCapabilities.numbers(new int[0]));
        assertEquals(java.util.List.of(48000, 44100, 48000),
                TvMediaCapabilities.numbers(new int[] {48000, 44100, 48000}));
        int[] values = new int[70];
        for (int i = 0; i < values.length; i++) values[i] = i;
        var numbers = TvMediaCapabilities.numbers(values);
        assertEquals(64, numbers.size());
        assertEquals(Integer.valueOf(0), numbers.get(0));
        assertEquals(Integer.valueOf(63), numbers.get(63));
        assertEquals(69, values[69]);
    }
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
