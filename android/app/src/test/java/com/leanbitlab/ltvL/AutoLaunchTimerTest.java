package com.leanbitlab.ltvL;

import android.os.Handler;
import android.os.Looper;
import java.time.Duration;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.Shadows;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class AutoLaunchTimerTest {
    @Test public void cancellationLeavesOtherHandlerWorkIntact() {
        var handler = new Handler(Looper.getMainLooper());
        var timer = new AutoLaunchBridge.Timer(handler);
        int[] ran = {0, 0};
        handler.post(() -> ran[0]++);
        timer.post(() -> ran[1]++, 100);
        timer.cancel();
        Shadows.shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(1));
        assertEquals(1, ran[0]); assertEquals(0, ran[1]);
    }
    @Test public void delayCanScheduleNetworkDeadlineAndReplaceItWithoutDuplicates() {
        var timer = new AutoLaunchBridge.Timer(new Handler(Looper.getMainLooper()));
        int[] ran = {0};
        timer.post(() -> timer.post(() -> ran[0]++, 100), 100);
        Shadows.shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(150));
        assertEquals(0, ran[0]);
        timer.post(() -> ran[0] += 10, 100);
        Shadows.shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(1));
        assertEquals(10, ran[0]);
    }
}
