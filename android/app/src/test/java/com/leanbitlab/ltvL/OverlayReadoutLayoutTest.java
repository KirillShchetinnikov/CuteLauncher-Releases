package com.leanbitlab.ltvL;

import android.content.Context;
import android.graphics.Color;
import android.graphics.Rect;
import android.view.WindowManager;
import android.widget.TextView;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;
import org.robolectric.annotation.GraphicsMode;
import org.robolectric.shadow.api.Shadow;
import org.robolectric.shadows.ShadowWindowManagerImpl;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36}, qualifiers = "w1280dp-h720dp-land")
public class OverlayReadoutLayoutTest {
    @Test public void bothReadoutsShareEitherCornerAndTheTimerReturnsWhenVolumeHides() {
        var context = Robolectric.buildService(LauncherAccessibilityService.class).get();
        var manager = context.getSystemService(WindowManager.class);
        ShadowWindowManagerImpl windows = Shadow.extract(manager);
        var screen = OverlayReadoutLayout.displaySize(manager);
        try (var layout = new OverlayReadoutLayout(context)) {
            for (String corner : new String[]{"topLeft", "bottomRight"}) {
                layout.timer.setPosition(corner);
                layout.volume.setPosition(corner);
                layout.timer.show("01:23");
                Rect original = bounds(windows, "01:23");
                assertEquals(corner.equals("topLeft"), original.centerX() < screen.x / 2);
                assertEquals(corner.equals("topLeft"), original.centerY() < screen.y / 2);

                layout.volume.show("25%");
                Rect volume = bounds(windows, "25%");
                Rect timer = bounds(windows, "01:23");
                assertEquals(original.top, timer.top);
                assertFalse(Rect.intersects(volume, timer));
                assertEquals(corner.equals("topLeft"), timer.left > volume.left);

                layout.volume.hide();
                assertEquals(original, bounds(windows, "01:23"));
            }
        }
        assertTrue(windows.getViews().isEmpty());
    }

    @Test public void widgetModeUsesTheSavedCenterAndFallsBackWhenThereIsNone() {
        var context = Robolectric.buildService(LauncherAccessibilityService.class).get();
        var manager = context.getSystemService(WindowManager.class);
        ShadowWindowManagerImpl windows = Shadow.extract(manager);
        var screen = OverlayReadoutLayout.displaySize(manager);
        try (var layout = new OverlayReadoutLayout(context)) {
            layout.volume.show("32%");
            Rect original = bounds(windows, "32%");
            layout.volume.setPosition("widget");
            assertEquals(original, bounds(windows, "32%"));

            context.getSharedPreferences("overlay_widget_anchors", Context.MODE_PRIVATE).edit()
                .putFloat("volume.x", .4f).putFloat("volume.y", .1f).commit();
            layout.refresh();
            Rect atWidget = bounds(windows, "32%");
            assertEquals(Math.round(screen.x * .4f), atWidget.centerX(), 1);
            assertEquals(Math.round(screen.y * .1f), atWidget.centerY(), 1);
        }
    }

    @Test @GraphicsMode(GraphicsMode.Mode.NATIVE)
    public void panelTimerUsesTheFullLabelWidthWithoutResizingText() {
        var context = Robolectric.buildService(LauncherAccessibilityService.class).get();
        var manager = context.getSystemService(WindowManager.class);
        ShadowWindowManagerImpl windows = Shadow.extract(manager);
        var screen = OverlayReadoutLayout.displaySize(manager);
        String label = "999999:59:59 · 11/12/2026 10:30:45 PM";
        try (var layout = new OverlayReadoutLayout(context)) {
            layout.setPanelStyle(panelStyle(48));
            layout.volume.setPosition("topLeft");
            layout.timer.show(label);
            var timer = readout(windows, label);
            var alone = bounds(windows, label);

            layout.volume.show("100%");
            var timerBounds = bounds(windows, label);
            assertTrue(timerBounds.width() > screen.x / 2);
            assertEquals(alone.width(), timerBounds.width());
            assertEquals(alone.top, timerBounds.top);
            assertFalse(Rect.intersects(timerBounds, bounds(windows, "100%")));
            assertFitsOnOneLine(timer, timerBounds, label);
            assertEquals(48f, timer.getTextSize(), 0);

            layout.setPanelStyle(panelStyle(62));
            timerBounds = bounds(windows, label);
            var volumeBounds = bounds(windows, "100%");
            assertFitsOnOneLine(timer, timerBounds, label);
            assertTrue(timerBounds.top > volumeBounds.bottom);
            assertEquals(62f, timer.getTextSize(), 0);
            assertEquals(Math.round(timer.getTextSize()), timer.getCompoundDrawablesRelative()[2].getBounds().width());

            layout.volume.hide();
            var restored = bounds(windows, label);
            assertEquals(timerBounds.width(), restored.width());
            assertEquals(alone.top, restored.top);
        }
    }

    private static void assertFitsOnOneLine(TextView view, Rect bounds, String label) {
        var text = view.getLayout();
        assertEquals(1, text.getLineCount());
        assertEquals(label.length(), text.getLineEnd(0));
        assertEquals(0, text.getEllipsisCount(0));
        int width = bounds.width() - view.getCompoundPaddingLeft() - view.getCompoundPaddingRight();
        assertTrue(text.getLineWidth(0) <= width);
        assertTrue(text.getHeight() <= bounds.height());
    }

    private static OverlayPanelStyle panelStyle(float size) {
        return new OverlayPanelStyle(Color.WHITE, Color.BLACK, null, Color.TRANSPARENT,
            2, 16, size, size * 1.5f + 12, 10, null);
    }

    private static Rect bounds(ShadowWindowManagerImpl windows, String text) {
        var params = (WindowManager.LayoutParams) readout(windows, text).getLayoutParams();
        return new Rect(params.x, params.y, params.x + params.width, params.y + params.height);
    }

    private static TextView readout(ShadowWindowManagerImpl windows, String text) {
        return windows.getViews().stream()
            .map(item -> (TextView) item)
            .filter(item -> text.contentEquals(item.getText()))
            .findFirst().orElseThrow();
    }
}
