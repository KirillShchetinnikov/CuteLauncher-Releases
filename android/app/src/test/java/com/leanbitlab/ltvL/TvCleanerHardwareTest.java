package com.leanbitlab.ltvL;
import android.content.Intent;
import android.content.pm.*;
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
public class TvCleanerHardwareTest {
    @Test public void permissionOwnersAndUnpublishedInputServicesRemainProtected() {
        var pm = RuntimeEnvironment.getApplication().getPackageManager();
        var driver = new PackageInfo(); driver.packageName = "vendor.video.driver";
        driver.requestedPermissions = new String[]{"android.permission.TV_INPUT_HARDWARE"};
        var sibling = new PackageInfo(); sibling.packageName = "vendor.media.player";
        sibling.requestedPermissions = new String[]{"android.permission.INTERNET"};
        var service = new ResolveInfo(); service.serviceInfo = new ServiceInfo();
        service.serviceInfo.packageName = "vendor.video.service";
        service.serviceInfo.name = "vendor.video.service.Input";
        service.serviceInfo.applicationInfo = new ApplicationInfo();
        service.serviceInfo.applicationInfo.packageName = service.serviceInfo.packageName;
        Shadows.shadowOf(pm).addResolveInfoForIntent(new Intent("android.media.tv.TvInputService"), service);
        var names = TvCleanerHardware.collect(pm, List.of(driver, sibling));
        assertTrue(names.containsAll(List.of(driver.packageName, service.serviceInfo.packageName)));
        assertFalse(names.contains(sibling.packageName));
        try { TvCleanerHardware.collect(pm, null); fail("Missing permission snapshot accepted"); }
        catch (IllegalStateException expected) { }
    }
}
