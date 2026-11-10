package com.leanbitlab.ltvL;

import android.app.Activity;
import android.media.AudioManager;
import android.media.AudioDeviceInfo;
import android.media.MediaRouter;
import android.media.MediaRoute2Info;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;
import org.robolectric.Shadows;
import org.robolectric.shadows.AudioDeviceInfoBuilder;
import com.google.common.collect.ImmutableList;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class AudioStatusControllerTest {
    @Test @Config(sdk = 30) public void android11UsesFrameworkHdmiLabelInsteadOfRouteType() {
        try (var lifecycle = Robolectric.buildActivity(Activity.class).setup()) {
            var resources = lifecycle.get().getResources();
            int label = resources.getIdentifier("default_audio_route_name_hdmi", "string", "android");
            assertNotEquals(0, label);
            var hdmi = new MediaRoute2Info.Builder("hdmi", resources.getText(label))
                .addFeature(MediaRoute2Info.FEATURE_LIVE_AUDIO).build();
            var other = new MediaRoute2Info.Builder("speaker", "Speaker")
                .addFeature(MediaRoute2Info.FEATURE_LIVE_AUDIO).build();
            assertTrue(AudioStatusBridge.LegacyHdmiRoute.isHdmiRoute(hdmi, resources));
            assertFalse(AudioStatusBridge.LegacyHdmiRoute.isHdmiRoute(other, resources));
        }
    }
    @Test public void mediaLevelUsesAndroidScaleAndMuteIsIndependent() {
        try (var lifecycle = Robolectric.buildActivity(Activity.class).setup()) {
            var context = lifecycle.get();
            var audio = context.getSystemService(AudioManager.class);
            int max = audio.getStreamMaxVolume(AudioManager.STREAM_MUSIC);
            audio.setStreamVolume(AudioManager.STREAM_MUSIC, 2, 0);
            var controller = new AudioStatusController(context);
            assertEquals(Math.round(200f / max), controller.snapshot(null, false, null).get("percent"));
            audio.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_MUTE, 0);
            assertEquals(true, controller.snapshot(null, false, null).get("muted"));
        }
    }
    @Test @Config(sdk = {28, 30, 32}) public void legacyOutputFollowsSelectedBluetoothRoute() {
        try (var lifecycle = Robolectric.buildActivity(Activity.class).setup()) {
            var context = lifecycle.get();
            var router = Shadows.shadowOf(context.getSystemService(MediaRouter.class));
            var controller = new AudioStatusController(context);
            assertFalse(controller.snapshot(controller.legacyOutput(null), false, null).containsKey("outputs"));
            router.addBluetoothRoute();
            assertEquals(java.util.List.of("bluetooth"), controller.snapshot(controller.legacyOutput(null), false, null).get("outputs"));
            router.removeBluetoothRoute();
            assertFalse(controller.snapshot(controller.legacyOutput(null), false, null).containsKey("outputs"));
        }
    }
    @Test public void typesDistinguishArcFromHdmiAndNeverGuessUnknown() {
        assertEquals("tv", AudioStatusController.kind(AudioDeviceInfo.TYPE_BUILTIN_SPEAKER));
        assertEquals("arc", AudioStatusController.kind(AudioDeviceInfo.TYPE_HDMI_ARC));
        assertEquals("earc", AudioStatusController.kind(AudioDeviceInfo.TYPE_HDMI_EARC));
        assertEquals("hdmi", AudioStatusController.kind(AudioDeviceInfo.TYPE_HDMI));
        assertEquals("bluetooth", AudioStatusController.kind(AudioDeviceInfo.TYPE_BLUETOOTH_A2DP));
        assertEquals("unknown", AudioStatusController.kind(AudioDeviceInfo.TYPE_UNKNOWN));
    }
    @Test @Config(sdk = {30, 32}) public void selectedHdmiNeedsUnambiguousArcOutput() {
        try (var lifecycle = Robolectric.buildActivity(Activity.class).setup()) {
            var context = lifecycle.get();
            var audio = Shadows.shadowOf(context.getSystemService(AudioManager.class));
            var controller = new AudioStatusController(context);
            var arc = AudioDeviceInfoBuilder.newBuilder().setType(AudioDeviceInfo.TYPE_HDMI_ARC).build();
            var hdmi = AudioDeviceInfoBuilder.newBuilder().setType(AudioDeviceInfo.TYPE_HDMI).build();
            var tv = AudioDeviceInfoBuilder.newBuilder().setType(AudioDeviceInfo.TYPE_BUILTIN_SPEAKER).build();
            audio.setOutputDevices(java.util.List.of(tv, arc));
            assertEquals(java.util.List.of("arc"), controller.snapshot(null, true, null).get("outputs"));
            assertEquals(java.util.List.of("arc"), controller.snapshot("hdmi", false, null).get("outputs"));
            assertFalse(controller.snapshot(null, false, null).containsKey("outputs"));
            var diagnostic = new java.util.HashMap<String, Object>();
            var state = controller.snapshot(null, false, diagnostic);
            assertFalse(state.containsKey("outputs"));
            assertEquals(java.util.List.of(AudioDeviceInfo.TYPE_BUILTIN_SPEAKER, AudioDeviceInfo.TYPE_HDMI_ARC),
                diagnostic.get("availableOutputTypes"));
            assertEquals(java.util.List.of("bluetooth"), controller.snapshot("bluetooth", true, null).get("outputs"));
            audio.setOutputDevices(java.util.List.of(arc, hdmi));
            assertFalse(controller.snapshot(null, true, null).containsKey("outputs"));
            assertFalse(controller.snapshot("hdmi", false, null).containsKey("outputs"));
            if (android.os.Build.VERSION.SDK_INT >= 31) {
                var earc = AudioDeviceInfoBuilder.newBuilder().setType(AudioDeviceInfo.TYPE_HDMI_EARC).build();
                audio.setOutputDevices(java.util.List.of(arc, earc));
                assertFalse(controller.snapshot(null, true, null).containsKey("outputs"));
                audio.setOutputDevices(java.util.List.of(earc));
                assertEquals(java.util.List.of("earc"), controller.snapshot(null, true, null).get("outputs"));
            }
        }
    }
    @Test @Config(sdk = 36) public void selectedRouteIsIndependentOfConnectedBluetooth() {
        try (var lifecycle = Robolectric.buildActivity(Activity.class).setup()) {
            var context = lifecycle.get();
            var audio = Shadows.shadowOf(context.getSystemService(AudioManager.class));
            var tv = AudioDeviceInfoBuilder.newBuilder().setType(AudioDeviceInfo.TYPE_BUILTIN_SPEAKER).build();
            var bt = AudioDeviceInfoBuilder.newBuilder().setType(AudioDeviceInfo.TYPE_BLUETOOTH_A2DP).build();
            audio.setOutputDevices(java.util.List.of(tv, bt));
            audio.setAudioDevicesForAttributes(AudioStatusController.MEDIA, ImmutableList.of(tv));
            var controller = new AudioStatusController(context);
            assertEquals(java.util.List.of("tv"), controller.snapshot("bluetooth", false, null).get("outputs"));
            audio.setAudioDevicesForAttributes(AudioStatusController.MEDIA, ImmutableList.of(bt));
            assertEquals(java.util.List.of("bluetooth"), controller.snapshot(null, false, null).get("outputs"));
            audio.setAudioDevicesForAttributes(AudioStatusController.MEDIA, ImmutableList.of());
            assertEquals(java.util.List.of(), controller.snapshot(null, false, null).get("outputs"));
            audio.setAudioDevicesForAttributes(AudioStatusController.MEDIA, ImmutableList.of(tv, bt));
            assertEquals(java.util.List.of("tv", "bluetooth"), controller.snapshot(null, false, null).get("outputs"));
        }
    }
    @Test public void screenOffSkipsAudioAndZeroIsAValidLevel() {
        try (var lifecycle = Robolectric.buildActivity(Activity.class).setup()) {
            var context = lifecycle.get();
            context.getSystemService(AudioManager.class).setStreamVolume(AudioManager.STREAM_MUSIC, 0, 0);
            var controller = new AudioStatusController(context);
            assertEquals(0, controller.snapshot(null, false, null).get("percent"));
            Shadows.shadowOf(context.getSystemService(android.os.PowerManager.class)).setIsInteractive(false);
            var state = controller.snapshot("bluetooth", false, null);
            assertEquals(false, state.get("screenOn"));
            assertFalse(state.containsKey("percent")); assertFalse(state.containsKey("outputs"));
        }
    }
}
