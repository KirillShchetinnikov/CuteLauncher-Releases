package com.leanbitlab.ltvL;

import android.content.Context;
import android.content.Intent;
import android.graphics.drawable.GradientDrawable;
import android.os.Looper;
import android.os.PowerManager;
import android.os.SystemClock;
import android.provider.Settings;
import android.view.Gravity;
import android.view.WindowManager;
import android.widget.TextView;
import java.time.Duration;
import java.util.concurrent.atomic.AtomicBoolean;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;
import org.robolectric.shadow.api.Shadow;
import org.robolectric.shadows.ShadowWindowManagerImpl;
import static org.junit.Assert.*;
import static org.robolectric.Shadows.shadowOf;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class SleepTimerOverlayTest {
    private Context context;
    private ShadowWindowManagerImpl windows;
    private static final int BOOT = 7;

    @Before public void setup() {
        context = Robolectric.buildService(LauncherAccessibilityService.class).get();
        windows = Shadow.extract(context.getSystemService(WindowManager.class));
        shadowOf(context.getSystemService(PowerManager.class)).setIsInteractive(true);
        Settings.Global.putInt(context.getContentResolver(), Settings.Global.BOOT_COUNT, BOOT);
    }

    @Test public void optInShowsCurrentTimerAndReplacementInOneWindowUntilDeadline() {
        setTimer(30_000, BOOT);
        try (var layout = new OverlayReadoutLayout(context);
             var overlay = new SleepTimerOverlay(context, () -> false, layout.timer)) {
            assertTrue(windows.getViews().isEmpty());
            configure(true, true, "remaining");
            var view = readout();
            assertEquals("00:30", view.getText().toString());
            assertEquals(0xFF242935, ((GradientDrawable) view.getBackground()).getColor().getDefaultColor());
            assertNotNull(view.getCompoundDrawablesRelative()[2]);
            assertNull(view.getEllipsize());
            configure(true, true, "remaining", "dark");
            assertSame(view, readout());
            assertEquals(0xF2252525, ((GradientDrawable) view.getBackground()).getColor().getDefaultColor());
            assertNull(view.getCompoundDrawablesRelative()[2]);
            var params = (WindowManager.LayoutParams) view.getLayoutParams();
            assertEquals(Gravity.TOP | Gravity.LEFT, params.gravity);
            assertEquals(WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY, params.type);
            assertTrue((params.flags & WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE) != 0);
            assertTrue((params.flags & WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE) != 0);

            idle(1_500);
            assertSame(view, readout());
            assertEquals("00:29", view.getText().toString());
            setTimer(60_000, BOOT);
            assertSame(view, readout());
            assertEquals("01:00", view.getText().toString());
            configure(true, false, "remaining");
            assertEquals("0:01", readout().getText().toString());
            idle(30_000);
            assertSame(view, readout());
            idle(31_000);
            assertTrue(windows.getViews().isEmpty());
        }
    }

    @Test public void wakingUsesOriginalDeadlineAndCancelOrDisablingHidesImmediately() {
        configure(true, true, "remaining");
        var blocked = new AtomicBoolean(false);
        try (var layout = new OverlayReadoutLayout(context);
             var overlay = new SleepTimerOverlay(context, blocked::get, layout.timer)) {
            assertTrue(windows.getViews().isEmpty());
            setTimer(30_000, BOOT);
            readout();
            blocked.set(true);
            overlay.refresh();
            assertTrue(windows.getViews().isEmpty());
            blocked.set(false);
            overlay.refresh();
            readout();

            context.sendBroadcast(new Intent(Intent.ACTION_SCREEN_OFF));
            idle(10_200);
            assertTrue(windows.getViews().isEmpty());
            context.sendBroadcast(new Intent(Intent.ACTION_SCREEN_ON));
            idle(0);
            assertEquals("00:20", readout().getText().toString());

            configure(false, true, "remaining");
            assertTrue(windows.getViews().isEmpty());
            assertTrue(SleepTimerBridge.activeDeadline(context) > SystemClock.elapsedRealtime());
            configure(true, true, "both");
            assertTrue(readout().getText().toString().startsWith("00:20 · "));
            SleepTimerBridge.cancel(context);
            assertTrue(windows.getViews().isEmpty());
            setTimer(30_000, BOOT);
            readout();
        }
        assertTrue(windows.getViews().isEmpty());
        setTimer(30_000, BOOT);
        idle(2_000);
        assertTrue(windows.getViews().isEmpty());
    }

    @Test public void refusesExpiredAndPreviousBootDeadlines() {
        configure(true, true, "remaining");
        try (var layout = new OverlayReadoutLayout(context);
             var overlay = new SleepTimerOverlay(context, () -> false, layout.timer)) {
            setTimer(30_000, BOOT - 1);
            assertTrue(windows.getViews().isEmpty());
            setTimer(-10, BOOT);
            assertTrue(windows.getViews().isEmpty());
        }
    }

    @Test public void launcherVisibilityHidesAndRestoresTheSameCountdownImmediately() {
        configure(true, true, "remaining");
        var launcherVisible = new AtomicBoolean();
        var launcher = new Object();
        try (var layout = new OverlayReadoutLayout(context);
             var overlay = new SleepTimerOverlay(context, launcherVisible::get, layout.timer)) {
            var policy = new RemotePanelLaunchPolicy(visible -> {
                launcherVisible.set(visible);
                overlay.refresh();
            });
            policy.started(launcher);
            setTimer(30_000, BOOT);
            long deadline = SleepTimerBridge.activeDeadline(context);
            assertTrue(windows.getViews().isEmpty());
            idle(10_200);
            policy.stopped(launcher);
            assertEquals("00:20", readout().getText().toString());
            policy.started(launcher);
            assertTrue(windows.getViews().isEmpty());
            assertEquals(deadline, SleepTimerBridge.activeDeadline(context));
            idle(10_000);
            policy.stopped(launcher);
            assertEquals("00:10", readout().getText().toString());
            policy.started(launcher);
            idle(10_000);
            policy.stopped(launcher);
            assertTrue(windows.getViews().isEmpty());
        }
    }

    private void setTimer(long remaining, int boot) {
        SleepTimerBridge.prefs(context).edit().putInt("boot", boot)
            .putLong("deadline", SystemClock.elapsedRealtime() + remaining).commit();
    }

    private void configure(boolean enabled, boolean seconds, String display) {
        configure(enabled, seconds, display, "topPanel");
    }

    private void configure(boolean enabled, boolean seconds, String display, String appearance) {
        context.getSharedPreferences("FlutterSharedPreferences", 0).edit()
            .putString("flutter.sleep_timer_configuration",
                "{\"showOverApps\":" + enabled + ",\"showSeconds\":" + seconds + ",\"display\":\"" + display
                    + "\",\"overlayAppearance\":\"" + appearance + "\"}")
            .commit();
    }

    private TextView readout() {
        assertEquals(1, windows.getViews().size());
        return (TextView) windows.getViews().getFirst();
    }

    private void idle(long milliseconds) {
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(milliseconds));
    }
}
