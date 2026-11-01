package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.ApplicationInfo;
import android.content.pm.ResolveInfo;
import io.flutter.plugin.common.MethodChannel;
import java.util.List;
import java.util.concurrent.Executors;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.Shadows;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class WallpaperFolderTest {
    private static ResolveInfo picker(String packageName, boolean system) {
        var info = new ResolveInfo();
        info.activityInfo = new ActivityInfo();
        info.activityInfo.packageName = packageName;
        info.activityInfo.name = packageName + ".Picker";
        info.activityInfo.enabled = true;
        info.activityInfo.exported = true;
        info.activityInfo.applicationInfo = new ApplicationInfo();
        info.activityInfo.applicationInfo.flags = system ? ApplicationInfo.FLAG_SYSTEM : 0;
        return info;
    }

    private static final class Reply implements MethodChannel.Result {
        int calls;
        String error;
        Object value;
        public void success(Object value) { calls++; this.value = value; }
        public void error(String code, String message, Object details) { calls++; error = code; }
        public void notImplemented() { fail("Not implemented"); }
    }

    @Test public void skipsTvStubAndOpensRealFolderPickerWithReadGrant() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            var action = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE);
            var pm = Shadows.shadowOf(activity.getPackageManager());
            pm.addResolveInfoForIntent(action, List.of(
                picker("com.google.android.tv.frameworkpackagestubs", true),
                picker("test.filemanager", false)));
            var executor = Executors.newSingleThreadExecutor();
            try {
                var folder = new WallpaperFolder(activity, executor);
                var reply = new Reply();
                folder.pick(reply);
                var started = Shadows.shadowOf(activity).getNextStartedActivityForResult();
                assertNotNull(started);
                assertEquals("test.filemanager", started.intent.getComponent().getPackageName());
                assertEquals(Intent.ACTION_OPEN_DOCUMENT_TREE, started.intent.getAction());
                assertEquals(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
                    started.intent.getFlags());
                assertEquals(WallpaperFolder.REQUEST, started.requestCode);
                assertEquals(0, reply.calls);

                var busy = new Reply();
                folder.pick(busy);
                assertEquals("document_busy", busy.error);
                folder.complete(Activity.RESULT_CANCELED, null);
                assertEquals(1, reply.calls);
                assertNull(reply.value);
                assertNull(reply.error);
                folder.pick(new Reply());
                assertNotNull(Shadows.shadowOf(activity).getNextStartedActivityForResult());
            } finally { executor.shutdownNow(); }
        }
    }

    @Test public void stubAloneIsUnavailableWithoutLaunchingItOrLeavingPickerBusy() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            var action = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE);
            var pm = Shadows.shadowOf(activity.getPackageManager());
            pm.addResolveInfoForIntent(action, picker("com.google.android.tv.frameworkpackagestubs", true));
            var executor = Executors.newSingleThreadExecutor();
            try {
                var folder = new WallpaperFolder(activity, executor);
                for (int i = 0; i < 2; i++) {
                    var reply = new Reply();
                    folder.pick(reply);
                    assertEquals("document_unavailable", reply.error);
                    assertEquals(1, reply.calls);
                    assertNull(Shadows.shadowOf(activity).getNextStartedActivityForResult());
                }
            } finally { executor.shutdownNow(); }
        }
    }

    @Test public void workingSystemDocumentsUiTakesPriorityOverFileManager() {
        var intent = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE);
        var selected = DocumentFiles.compatibleIntent(intent, List.of(
            picker("test.filemanager", false), picker("com.android.documentsui", true)));
        assertNotNull(selected);
        assertEquals("com.android.documentsui", selected.getComponent().getPackageName());
    }
}
