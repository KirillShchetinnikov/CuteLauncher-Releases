package com.leanbitlab.ltvL;

import android.content.Intent;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.media.AudioManager;
import android.os.Looper;
import android.os.PowerManager;
import android.view.Gravity;
import android.view.WindowManager;
import android.widget.TextView;
import java.time.Duration;
import java.util.concurrent.atomic.AtomicBoolean;
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
public class VolumeOverlayTest {
    @Test public void optInMediaEventsReuseOneNonInteractiveWindowAndExtendItsTimeout() {
        var context = Robolectric.buildService(LauncherAccessibilityService.class).get();
        var prefs = context.getSharedPreferences("FlutterSharedPreferences", 0);
        var audio = context.getSystemService(AudioManager.class);
        var main = shadowOf(Looper.getMainLooper());
        ShadowWindowManagerImpl windows = Shadow.extract(context.getSystemService(WindowManager.class));
        shadowOf(context.getSystemService(PowerManager.class)).setIsInteractive(true);
        OverlayPanelStyle.record(context, """
            {"foreground":4294901760,"background":4278190335,"gradientEnd":null,
             "border":0,"borderWidth":2,"radius":12,"textSize":22,"height":45,
             "horizontalPadding":10,"font":null}
            """);

        try (var layout = new OverlayReadoutLayout(context);
             var overlay = new VolumeOverlay(context, () -> false, layout.volume)) {
            context.sendBroadcast(volume(AudioManager.STREAM_MUSIC));
            main.idle();
            assertTrue(windows.getViews().isEmpty());

            prefs.edit().putBoolean(VolumeOverlay.ENABLED, true).commit();
            context.sendBroadcast(volume(AudioManager.STREAM_RING));
            main.idle();
            assertTrue(windows.getViews().isEmpty());

            audio.setStreamVolume(AudioManager.STREAM_MUSIC, 0, 0);
            context.sendBroadcast(volume(AudioManager.STREAM_MUSIC));
            main.idle();
            assertEquals(1, windows.getViews().size());
            var label = (TextView) windows.getViews().getFirst();
            assertEquals("0%", label.getText().toString());
            assertEquals(Color.RED, label.getCurrentTextColor());
            assertEquals(Color.BLUE, ((GradientDrawable) label.getBackground()).getColor().getDefaultColor());
            prefs.edit().putString(VolumeOverlay.APPEARANCE, "dark").commit();
            assertSame(label, windows.getViews().getFirst());
            assertEquals(Color.WHITE, label.getCurrentTextColor());
            assertEquals(0xF2252525, ((GradientDrawable) label.getBackground()).getColor().getDefaultColor());
            var params = (WindowManager.LayoutParams) label.getLayoutParams();
            assertEquals(WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY, params.type);
            assertTrue(params.width > 0);
            assertTrue(params.height > 0);
            assertEquals(Gravity.TOP | Gravity.LEFT, params.gravity);
            assertTrue((params.flags & WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE) != 0);
            assertTrue((params.flags & WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE) != 0);

            main.idleFor(Duration.ofMillis(1_500));
            audio.setStreamVolume(AudioManager.STREAM_MUSIC,
                audio.getStreamMaxVolume(AudioManager.STREAM_MUSIC), 0);
            context.sendBroadcast(volume(AudioManager.STREAM_MUSIC));
            main.idle();
            assertEquals(1, windows.getViews().size());
            assertSame(label, windows.getViews().getFirst());
            assertEquals("100%", label.getText().toString());
            main.idleFor(Duration.ofMillis(1_500));
            assertEquals(1, windows.getViews().size());
            main.idleFor(Duration.ofMillis(600));
            assertTrue(windows.getViews().isEmpty());
        }
    }

    @Test public void blockedScreenDisableAndCloseDismissAndSuppressEvents() {
        var context = Robolectric.buildService(LauncherAccessibilityService.class).get();
        var prefs = context.getSharedPreferences("FlutterSharedPreferences", 0);
        var main = shadowOf(Looper.getMainLooper());
        var power = shadowOf(context.getSystemService(PowerManager.class));
        var blocked = new AtomicBoolean(true);
        ShadowWindowManagerImpl windows = Shadow.extract(context.getSystemService(WindowManager.class));
        power.setIsInteractive(true);
        prefs.edit().putBoolean(VolumeOverlay.ENABLED, true).commit();
        var event = volume(AudioManager.STREAM_MUSIC);

        try (var layout = new OverlayReadoutLayout(context);
             var overlay = new VolumeOverlay(context, blocked::get, layout.volume)) {
            context.sendBroadcast(event);
            main.idle();
            assertTrue(windows.getViews().isEmpty());

            blocked.set(false);
            context.sendBroadcast(event);
            main.idle();
            assertEquals(1, windows.getViews().size());
            power.setIsInteractive(false);
            context.sendBroadcast(new Intent(Intent.ACTION_SCREEN_OFF));
            context.sendBroadcast(event);
            main.idle();
            assertTrue(windows.getViews().isEmpty());

            power.setIsInteractive(true);
            context.sendBroadcast(event);
            main.idle();
            assertEquals(1, windows.getViews().size());
            prefs.edit().putBoolean(VolumeOverlay.ENABLED, false).commit();
            assertTrue(windows.getViews().isEmpty());

            prefs.edit().putBoolean(VolumeOverlay.ENABLED, true).commit();
            context.sendBroadcast(event);
            main.idle();
            assertEquals(1, windows.getViews().size());
        }
        context.sendBroadcast(event);
        main.idle();
        assertTrue(windows.getViews().isEmpty());
    }

    private static Intent volume(int stream) {
        return new Intent(VolumeOverlay.VOLUME_CHANGED).putExtra(VolumeOverlay.STREAM_TYPE, stream);
    }
}
