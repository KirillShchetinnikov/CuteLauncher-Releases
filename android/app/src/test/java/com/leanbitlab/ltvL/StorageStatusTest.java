package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.provider.Settings;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.Shadows;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 29, 36})
public class StorageStatusTest {
    public static class Host extends Activity {
        Intent started;
        boolean rejectCard, rejectAll;
        @Override public void startActivity(Intent intent) {
            if (rejectAll || (rejectCard && Settings.ACTION_MEMORY_CARD_SETTINGS.equals(intent.getAction())))
                throw new ActivityNotFoundException();
            started = intent;
        }
    }
    private static void install(Host host, boolean exported, String permission) {
        var app = new ApplicationInfo(); app.packageName = StorageStatusController.NAS.getPackageName(); app.enabled = true;
        var activity = new ActivityInfo(); activity.packageName = app.packageName;
        activity.name = StorageStatusController.NAS.getClassName(); activity.applicationInfo = app;
        activity.enabled = true; activity.exported = exported; activity.permission = permission;
        var pkg = new PackageInfo(); pkg.packageName = app.packageName; pkg.applicationInfo = app;
        pkg.activities = new ActivityInfo[]{activity};
        Shadows.shadowOf(host.getPackageManager()).installPackage(pkg);
    }
    @Test public void nasRequiresAccessibleActivityAndUsesExactConfirmedComponent() {
        try (var lifecycle = Robolectric.buildActivity(Host.class).setup()) {
            var host = lifecycle.get(); var controller = new StorageStatusController(host);
            assertFalse(controller.nasSupported());
            assertFalse(controller.open(true));
            install(host, false, null); assertFalse(controller.nasSupported());
            install(host, true, "vendor.signature.only"); assertFalse(controller.nasSupported());
            install(host, true, null); assertTrue(controller.nasSupported());
            assertTrue(controller.open(true));
            assertEquals(StorageStatusController.NAS, host.started.getComponent());
            host.rejectAll = true; assertFalse(controller.open(true));
        }
    }
    @Test public void usbOpensPublicStorageSettingsWithSafeFallback() {
        try (var lifecycle = Robolectric.buildActivity(Host.class).setup()) {
            var host = lifecycle.get(); var controller = new StorageStatusController(host);
            assertTrue(controller.open(false));
            assertEquals(Settings.ACTION_MEMORY_CARD_SETTINGS, host.started.getAction());
            host.rejectCard = true; assertTrue(controller.open(false));
            assertEquals(Settings.ACTION_INTERNAL_STORAGE_SETTINGS, host.started.getAction());
            host.rejectAll = true; assertFalse(controller.open(false));
        }
    }
    @Test public void networkMountIsNotUsbAndFilesystemTypeDoesNotOverrideCifsPath() {
        assertTrue(StorageStatusPolicy.nasMount("/mnt/cifs/example", "vfat"));
        assertTrue(StorageStatusPolicy.nasMount("/mnt/example", "cifs"));
        assertFalse(StorageStatusPolicy.nasMount("/storage/example", "ntfs"));
        assertTrue(StorageStatusPolicy.mounted("mounted_ro"));
        assertFalse(StorageStatusPolicy.mounted("unmounted"));
        assertTrue(StorageStatusPolicy.usbPath("/sys/devices/usb1/1-1/block/sda"));
        assertFalse(StorageStatusPolicy.usbPath("/sys/devices/mmc0/mmcblk1"));
        assertFalse(StorageStatusPolicy.usbPath("/sys/devices/soc/usb-controller/mmcblk1"));
        assertEquals("8:1", StorageStatusPolicy.blockId("/dev/block/vold/public:8,1"));
        assertNull(StorageStatusPolicy.blockId("/dev/fuse"));
    }
}
