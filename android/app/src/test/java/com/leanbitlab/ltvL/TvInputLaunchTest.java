package com.leanbitlab.ltvL;

import android.content.*;
import android.media.tv.TvContract;
import java.util.*;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.Shadows;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class TvInputLaunchTest {
    final String id = "vendor.input/.Service/HW1";

    @Test public void vendorRoutesAreLimitedToVerifiedModelsAndInputs() {
        String tuner = "com.tcl.tvinput/.TDTVInputService/HW1413742848";
        var tcl = TvInputLaunch.candidates(tuner, "Smart TV Pro", "G03_4K_GB");
        assertEquals("com.tcl.tv", tcl.get(1).getPackage());
        assertEquals(TvContract.buildChannelUriForPassthroughInput(tuner), tcl.get(1).getData());
        assertEquals("com.tcl.tvinput", TvInputLaunch.candidates(tuner, "Smart TV Pro", "G10_4K_GB")
            .get(1).getPackage());
        String hdmi = "com.mediatek.tvinput/.hdmi.HDMIInputService/HW7";
        var xiaomi = TvInputLaunch.candidates(hdmi, "MiTV-MTEQ0", "baymax").get(0);
        assertEquals("com.xiaomi.mitv.tvplayer.EXTSRC_PLAY", xiaomi.getAction());
        assertEquals(25, xiaomi.getIntExtra("input", -1));
        assertNull(TvInputLaunch.candidates(hdmi, "other", "baymax").get(0).getComponent());
        assertNull(TvInputLaunch.candidates(id, "MiTV-MTEQ0", "baymax").get(0).getComponent());
    }
    @Test public void boundedRoutesRetainInputIdentityAndFirmwarePickerIsExact() {
        var routes = TvInputLaunch.candidates(id, "unknown");
        assertEquals(6, routes.size());
        assertEquals("live-tv", routes.get(0).getData().getScheme());
        assertNull(routes.get(0).getType());
        assertEquals("com.yandex.tv.live", routes.get(0).getPackage());
        assertEquals("vendor.input", routes.get(1).getPackage());
        assertEquals("vnd.android.cursor.item/channel", routes.get(1).getType());
        assertNull(routes.get(2).getPackage());
        assertNull(routes.get(4).getType());
        assertEquals("com.xgimi.action.hdmiPlayer", routes.get(5).getAction());
        for (var intent : routes) {
            assertEquals(TvContract.buildChannelUriForPassthroughInput(id).getEncodedPath(), intent.getData().getEncodedPath());
            assertTrue((intent.getFlags() & Intent.FLAG_ACTIVITY_NEW_TASK) != 0);
        }
        assertNotNull(TvInputLaunch.candidates(id, "MiTV-NSOP0").get(0).getComponent());
        assertNull(TvInputLaunch.candidates(id, "MiTV-NSOP0-other").get(0).getComponent());
    }
    @Test public void permissionAndMissingActivityFallBackAndStopOnFirstAcceptedRoute() {
        var attempted = new ArrayList<Intent>();
        var context = new ContextWrapper(RuntimeEnvironment.getApplication()) {
            @Override public void startActivity(Intent intent) {
                attempted.add(intent);
                if (intent.getPackage() != null) throw new SecurityException();
                if (intent.getType() != null) throw new ActivityNotFoundException();
            }
        };
        assertTrue(TvInputLaunch.open(context, id));
        assertEquals(4, attempted.size()); // YaOS has no matching handler and is not started.
        assertNull(attempted.get(3).getType());
        var denied = new ContextWrapper(context) {
            @Override public void startActivity(Intent intent) { throw new SecurityException(); }
        };
        assertFalse(TvInputLaunch.open(denied, id));
        assertFalse(TvInputLaunch.open(context, ""));
        attempted.clear();
        var projector = new ContextWrapper(context) {
            @Override public void startActivity(Intent intent) {
                attempted.add(intent);
                if (!"com.xgimi.action.hdmiPlayer".equals(intent.getAction())) throw new ActivityNotFoundException();
            }
        };
        assertTrue(TvInputLaunch.open(projector, id));
        assertEquals("com.xgimi.action.hdmiPlayer", attempted.get(attempted.size() - 1).getAction());
    }
    @Test public void vendorOnlyRoutesAreAlsoProtectedByCleaner() {
        var pm = RuntimeEnvironment.getApplication().getPackageManager();
        var shadow = Shadows.shadowOf(pm);
        shadow.addResolveInfoForIntent(new Intent(android.provider.Settings.ACTION_SETTINGS),
                TvCleanerHandlersTest.handler("vendor.settings"));
        var routes = TvInputLaunch.candidates(id, "unknown");
        shadow.addResolveInfoForIntent(routes.get(0), TvCleanerHandlersTest.handler("com.yandex.tv.live"));
        shadow.addResolveInfoForIntent(routes.get(5), TvCleanerHandlersTest.handler("vendor.projector"));
        assertTrue(TvCleanerHandlers.collect(pm, List.of(id)).containsAll(List.of("com.yandex.tv.live", "vendor.projector")));
        var launched = new ArrayList<Intent>();
        assertTrue(TvInputLaunch.open(new ContextWrapper(RuntimeEnvironment.getApplication()) {
            @Override public void startActivity(Intent intent) { launched.add(intent); }
        }, id));
        assertEquals("com.yandex.tv.live", launched.get(0).getPackage());
        assertEquals(1, launched.size());
    }
}
