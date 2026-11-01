package com.leanbitlab.ltvL;

import android.app.Activity;
import android.media.AudioManager;
import android.media.AudioDeviceInfo;
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
    @Test public void mediaLevelUsesAndroidScaleAndMuteIsIndependent() {
        try (var lifecycle = Robolectric.buildActivity(Activity.class).setup()) {
            var context = lifecycle.get();
            var audio = context.getSystemService(AudioManager.class);
            int max = audio.getStreamMaxVolume(AudioManager.STREAM_MUSIC);
            audio.setStreamVolume(AudioManager.STREAM_MUSIC, 2, 0);
            var controller = new AudioStatusController(context);
            assertEquals(Math.round(200f / max), controller.snapshot().get("percent"));
            audio.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_MUTE, 0);
            assertEquals(true, controller.snapshot().get("muted"));
            if (android.os.Build.VERSION.SDK_INT < 33) assertFalse(controller.snapshot().containsKey("outputs"));
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
    @Test @Config(sdk = 36) public void selectedRouteIsIndependentOfConnectedBluetooth() {
        try (var lifecycle = Robolectric.buildActivity(Activity.class).setup()) {
            var context = lifecycle.get();
            var audio = Shadows.shadowOf(context.getSystemService(AudioManager.class));
            var tv = AudioDeviceInfoBuilder.newBuilder().setType(AudioDeviceInfo.TYPE_BUILTIN_SPEAKER).build();
            var bt = AudioDeviceInfoBuilder.newBuilder().setType(AudioDeviceInfo.TYPE_BLUETOOTH_A2DP).build();
            audio.setOutputDevices(java.util.List.of(tv, bt));
            audio.setAudioDevicesForAttributes(AudioStatusController.MEDIA, ImmutableList.of(tv));
            var controller = new AudioStatusController(context);
            assertEquals(java.util.List.of("tv"), controller.snapshot().get("outputs"));
            audio.setAudioDevicesForAttributes(AudioStatusController.MEDIA, ImmutableList.of(bt));
            assertEquals(java.util.List.of("bluetooth"), controller.snapshot().get("outputs"));
            audio.setAudioDevicesForAttributes(AudioStatusController.MEDIA, ImmutableList.of());
            assertEquals(java.util.List.of(), controller.snapshot().get("outputs"));
            audio.setAudioDevicesForAttributes(AudioStatusController.MEDIA, ImmutableList.of(tv, bt));
            assertEquals(java.util.List.of("tv", "bluetooth"), controller.snapshot().get("outputs"));
        }
    }
    @Test public void screenOffSkipsAudioAndZeroIsAValidLevel() {
        try (var lifecycle = Robolectric.buildActivity(Activity.class).setup()) {
            var context = lifecycle.get();
            context.getSystemService(AudioManager.class).setStreamVolume(AudioManager.STREAM_MUSIC, 0, 0);
            var controller = new AudioStatusController(context);
            assertEquals(0, controller.snapshot().get("percent"));
            Shadows.shadowOf(context.getSystemService(android.os.PowerManager.class)).setIsInteractive(false);
            var state = controller.snapshot();
            assertEquals(false, state.get("screenOn"));
            assertFalse(state.containsKey("percent")); assertFalse(state.containsKey("outputs"));
        }
    }
}
