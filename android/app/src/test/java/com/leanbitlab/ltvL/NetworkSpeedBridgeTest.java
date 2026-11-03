package com.leanbitlab.ltvL;

import android.app.Activity;
import android.os.PowerManager;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;
import org.robolectric.shadows.ShadowTrafficStats;
import static org.junit.Assert.*;
import static org.robolectric.Shadows.shadowOf;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class NetworkSpeedBridgeTest {
    @Test public void samplesDeviceCountersWithoutUsageAccessAndStopsWhenScreenIsOff() {
        try (var lifecycle = Robolectric.buildActivity(Activity.class).setup()) {
            var context = lifecycle.get();
            var power = context.getSystemService(PowerManager.class);
            shadowOf(power).setIsInteractive(true);
            ShadowTrafficStats.setTotalRxBytes(12345);
            ShadowTrafficStats.setTotalTxBytes(6789);
            var state = NetworkSpeedBridge.snapshot(context);
            assertEquals(true, state.get("screenOn"));
            assertEquals(12345L, state.get("rxBytes"));
            assertEquals(6789L, state.get("txBytes"));
            assertTrue((Long) state.get("elapsedMs") >= 0);
            ShadowTrafficStats.setTotalRxBytes(-1);
            assertEquals(-1L, NetworkSpeedBridge.snapshot(context).get("rxBytes"));
            shadowOf(power).setIsInteractive(false);
            state = NetworkSpeedBridge.snapshot(context);
            assertEquals(false, state.get("screenOn"));
            assertFalse(state.containsKey("rxBytes"));
            assertFalse(state.containsKey("txBytes"));
        }
    }
}
