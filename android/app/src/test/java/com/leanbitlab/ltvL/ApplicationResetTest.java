package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.ActivityManager;
import android.content.Context;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.Shadows;
import org.robolectric.annotation.Config;
import org.robolectric.annotation.Implementation;
import org.robolectric.annotation.Implements;
import org.robolectric.shadows.ShadowActivityManager;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class ApplicationResetTest {
    @Test public void requestsAndroidsCompleteOwnAppDataReset() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            Activity activity = controller.get();
            ActivityManager manager = activity.getSystemService(ActivityManager.class);
            assertFalse(Shadows.shadowOf(manager).isApplicationUserDataCleared());
            assertTrue(ApplicationReset.request(activity));
            assertTrue(Shadows.shadowOf(manager).isApplicationUserDataCleared());
        }
    }

    @Implements(ActivityManager.class)
    public static class RejectingActivityManager extends ShadowActivityManager {
        @Implementation protected boolean clearApplicationUserData() { return false; }
    }

    @Test @Config(shadows = RejectingActivityManager.class)
    public void rejectedRequestDoesNotPartiallyClearAnyPreferences() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            Activity activity = controller.get();
            for (String name : new String[]{"FlutterSharedPreferences", "remote_buttons", "adb_connection"}) {
                activity.getSharedPreferences(name, Context.MODE_PRIVATE).edit().putString("test", "saved").commit();
            }
            assertFalse(ApplicationReset.request(activity));
            for (String name : new String[]{"FlutterSharedPreferences", "remote_buttons", "adb_connection"}) {
                assertEquals("saved", activity.getSharedPreferences(name, Context.MODE_PRIVATE).getString("test", null));
            }
        }
    }
}
