package com.leanbitlab.ltvL;

import android.content.Intent;
import android.content.pm.*;
import android.media.tv.TvContract;
import android.provider.Settings;
import java.util.*;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.Shadows;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 29, 30, 36})
public class TvCleanerHandlersTest {
    static ResolveInfo handler(String pkg) {
        var info = new ResolveInfo(); info.activityInfo = new ActivityInfo();
        info.activityInfo.packageName = pkg; info.activityInfo.name = pkg + ".Screen";
        info.activityInfo.applicationInfo = new ApplicationInfo();
        info.activityInfo.applicationInfo.packageName = pkg;
        info.activityInfo.enabled = true; info.activityInfo.exported = true;
        return info;
    }
    @Test public void firmwareHandlersArePreservedAndEmptyQueriesFailClosed() {
        var pm = RuntimeEnvironment.getApplication().getPackageManager();
        var shadow = Shadows.shadowOf(pm);
        shadow.addResolveInfoForIntent(new Intent(Settings.ACTION_SETTINGS), handler("vendor.config.settings"));
        String id = "vendor.input/.Service/HW1";
        var input = new Intent(Intent.ACTION_VIEW).setDataAndType(TvContract.buildChannelUriForPassthroughInput(id),
                "vnd.android.cursor.item/channel");
        shadow.addResolveInfoForIntent(input, handler("vendor.player"));
        assertTrue(TvCleanerHandlers.collect(pm, List.of(id)).containsAll(List.of("vendor.config.settings", "vendor.player")));
        assertFalse(TvCleanerHandlers.collect(pm, List.of()).contains("vendor.player"));
        try { TvCleanerHandlers.collect(pm, List.of("unknown/.Service/HW2")); fail("Unverified input accepted"); }
        catch (IllegalStateException expected) { }
        shadow.removeResolveInfosForIntent(new Intent(Settings.ACTION_SETTINGS), "vendor.config.settings");
        try { TvCleanerHandlers.collect(pm, List.of()); fail("No Settings route accepted"); }
        catch (IllegalStateException expected) { }
        shadow.addResolveInfoForIntent(new Intent("android.settings.TV_SETTINGS"), handler("vendor.tv.settings"));
        assertTrue(TvCleanerHandlers.collect(pm, List.of()).contains("vendor.tv.settings"));
    }
}
