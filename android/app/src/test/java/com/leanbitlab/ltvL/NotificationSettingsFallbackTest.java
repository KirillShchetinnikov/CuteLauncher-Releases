package com.leanbitlab.ltvL;

import android.content.ContextWrapper;
import android.content.Intent;
import android.content.ActivityNotFoundException;
import android.content.pm.ActivityInfo;
import android.content.pm.ResolveInfo;
import android.provider.Settings;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;
import static org.robolectric.Shadows.shadowOf;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {30, 36})
public class NotificationSettingsFallbackTest {
    private static class Host extends ContextWrapper {
        final List<String> attempted = new ArrayList<>();
        final HashSet<String> rejected = new HashSet<>();
        boolean securityFailure;
        Host() { super(RuntimeEnvironment.getApplication()); }
        @Override public void startActivity(Intent intent) {
            attempted.add(intent.getAction());
            if (rejected.contains(intent.getAction())) {
                if (securityFailure) throw new SecurityException("blocked");
                throw new ActivityNotFoundException("removed");
            }
        }
        void resolve(String action) {
            var info = new ResolveInfo();
            info.activityInfo = new ActivityInfo();
            info.activityInfo.packageName = "android";
            info.activityInfo.name = "Settings";
            shadowOf(getPackageManager()).addResolveInfoForIntent(new Intent(action), info);
        }
    }

    @Test public void deniedDetailPageFallsBackToListenerList() {
        var host = new Host();
        String detail = Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS;
        String list = "android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS";
        host.resolve(detail); host.resolve(list);
        host.rejected.add(detail); host.securityFailure = true;
        assertTrue(new NotificationBridge(host).requestNotificationListenerPermission());
        assertEquals(List.of(detail, list), host.attempted);
        host.attempted.clear(); host.rejected.add(list);
        assertFalse(new NotificationBridge(host).requestNotificationListenerPermission());
        assertEquals(List.of(detail, list), host.attempted);
    }

    @Test public void removedNotificationPageFallsBackToAppDetails() {
        var host = new Host();
        host.resolve(Settings.ACTION_APP_NOTIFICATION_SETTINGS);
        host.rejected.add(Settings.ACTION_APP_NOTIFICATION_SETTINGS);
        assertTrue(new NotificationBridge(host).openAppNotificationSettings());
        assertEquals(List.of(Settings.ACTION_APP_NOTIFICATION_SETTINGS,
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS), host.attempted);
    }

    @Test public void successfulFirstPageDoesNotLaunchAnother() {
        var host = new Host();
        host.resolve(Settings.ACTION_APP_NOTIFICATION_SETTINGS);
        assertTrue(new NotificationBridge(host).openAppNotificationSettings());
        assertEquals(List.of(Settings.ACTION_APP_NOTIFICATION_SETTINGS), host.attempted);
    }
}
