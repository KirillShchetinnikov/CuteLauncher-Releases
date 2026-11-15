package com.leanbitlab.ltvL;

import android.view.KeyEvent;
import java.util.Map;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;
import org.robolectric.shadows.ShadowToast;

import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class RemotePanelRemapperTest {
    private static final int KEY = 4514;

    @Test public void blockedPanelOnHomeDoesNotShowAnErrorToast() {
        var service = Robolectric.buildService(LauncherAccessibilityService.class).get();
        var launcher = new Object();
        var policy = MainActivity.remotePanelPolicy;
        policy.started(launcher);
        try (var remapper = new RemoteButtonRemapper(service)) {
            pressPanelButton(remapper);
            assertNull(ShadowToast.getTextOfLatestToast());
            assertEquals("blocked", RemoteButtonRemapper.status);
        } finally {
            policy.stopped(launcher);
        }
    }

    @Test public void failedPanelToggleStillShowsAnErrorToast() {
        var service = Robolectric.buildService(FailingPanelService.class).get();
        try (var remapper = new RemoteButtonRemapper(service)) {
            pressPanelButton(remapper);
            assertEquals(service.getString(R.string.remap_error_unavailable), ShadowToast.getTextOfLatestToast());
            assertEquals("unavailable", RemoteButtonRemapper.status);
        }
    }

    public static class FailingPanelService extends LauncherAccessibilityService {
        @Override RemotePanelLaunchPolicy.ToggleResult togglePanel() {
            return RemotePanelLaunchPolicy.ToggleResult.FAILED;
        }
    }

    private static void pressPanelButton(RemoteButtonRemapper remapper) {
        var binding = new RemoteMappingConfiguration.Binding(KEY, true, "panel", "");
        RemoteButtonRemapper.editing = false;
        RemoteButtonRemapper.updated(new RemoteMappingConfiguration(true, Map.of(binding.slot(), binding)));
        assertTrue(remapper.event(new KeyEvent(100, 100, KeyEvent.ACTION_DOWN, KEY, 0)));
        assertTrue(remapper.event(new KeyEvent(100, 110, KeyEvent.ACTION_UP, KEY, 0)));
    }
}
