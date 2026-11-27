package com.leanbitlab.ltvL;

import android.Manifest;
import android.app.Activity;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.hardware.input.InputManager;
import android.os.Looper;
import android.os.PowerManager;
import android.provider.Settings;
import android.view.InputDevice;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.StandardMethodCodec;
import java.nio.ByteBuffer;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;
import org.robolectric.shadows.ShadowInputDevice;
import org.robolectric.util.ReflectionHelpers;
import static org.junit.Assert.*;
import static org.robolectric.Shadows.shadowOf;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {30, 36})
public class RemoteBatteryBridgeTest {
    @Test public void onlyPhysicalRemoteLikeDevicesAreCandidates() {
        var device = ShadowInputDevice.makeInputDeviceNamed("Remote");
        ReflectionHelpers.setField(device, "mId", 1);
        ReflectionHelpers.setField(device, "mSources", InputDevice.SOURCE_DPAD);
        assertTrue(RemoteBatteryBridge.isRemote(device));

        ReflectionHelpers.setField(device, "mSources", InputDevice.SOURCE_DPAD | InputDevice.SOURCE_JOYSTICK);
        assertTrue(RemoteBatteryBridge.isRemote(device));
        ReflectionHelpers.setField(device, "mControllerNumber", 1);
        assertFalse(RemoteBatteryBridge.isRemote(device));
        ReflectionHelpers.setField(device, "mControllerNumber", 0);
        ReflectionHelpers.setField(device, "mSources", InputDevice.SOURCE_JOYSTICK);
        assertFalse(RemoteBatteryBridge.isRemote(device));

        ReflectionHelpers.setField(device, "mSources", InputDevice.SOURCE_DPAD | InputDevice.SOURCE_GAMEPAD);
        assertFalse(RemoteBatteryBridge.isRemote(device));
        ReflectionHelpers.setField(device, "mSources", InputDevice.SOURCE_DPAD);
        ReflectionHelpers.setField(device, "mKeyboardType", InputDevice.KEYBOARD_TYPE_ALPHABETIC);
        assertFalse(RemoteBatteryBridge.isRemote(device));
        ReflectionHelpers.setField(device, "mKeyboardType", InputDevice.KEYBOARD_TYPE_NON_ALPHABETIC);
        ReflectionHelpers.setField(device, "mId", -1);
        assertFalse(RemoteBatteryBridge.isRemote(device));
    }

    @Test public void validatesInputCapacityAndGattPercentWithoutLosingZero() {
        assertEquals(Integer.valueOf(0), RemoteBatteryBridge.capacityPercent(0));
        assertEquals(Integer.valueOf(58), RemoteBatteryBridge.capacityPercent(0.58f));
        assertEquals(Integer.valueOf(100), RemoteBatteryBridge.capacityPercent(1));
        assertNull(RemoteBatteryBridge.capacityPercent(Float.NaN));
        assertNull(RemoteBatteryBridge.capacityPercent(-1));
        assertNull(RemoteBatteryBridge.capacityPercent(1.01f));
        assertEquals(Integer.valueOf(0), RemoteBatteryBridge.levelPercent((byte) 0));
        assertEquals(Integer.valueOf(100), RemoteBatteryBridge.levelPercent((byte) 100));
        assertNull(RemoteBatteryBridge.levelPercent((byte) 101));
        assertNull(RemoteBatteryBridge.levelPercent((byte) 255));
    }

    @Test @Config(sdk = 34)
    public void usesPairedBleRemoteWhenAndroidInputHasNoPercentage() throws Exception {
        verifiesPairedBleReading("BT_RC813A_C9", "BT_RC813A_C9", null, "ble");
    }

    @Test @Config(sdk = 34)
    public void matchesRemoteWithConsumerControlSuffix() throws Exception {
        verifiesPairedBleReading("BT_RC933B_B2 Consumer Control", "BT_RC933B_B2", "BT_RC933B", "ble");
    }

    @Test @Config(sdk = 34)
    public void matchesRemoteWithSystemControlSuffixIgnoringCase() throws Exception {
        verifiesPairedBleReading("Living Room system control", "Living Room", null, "ble");
    }

    @Test @Config(sdk = 34)
    public void skipsAmbiguousBluetoothDevices() throws Exception {
        verifiesPairedBleReading("Remote Consumer Control", "Remote", "Remote Consumer Control", "ambiguousBondedRemotes");
    }

    @Test @Config(sdk = 34)
    public void skipsUnrelatedBluetoothDevices() throws Exception {
        verifiesPairedBleReading("Remote Pro Consumer Control", "Remote", "Remote Pro Voice", "noMatchingBondedRemote");
    }

    private void verifiesPairedBleReading(String inputName, String bluetoothName, String otherName,
                                          String expectedOutcome) throws Exception {
        var app = RuntimeEnvironment.getApplication();
        var adapter = app.getSystemService(BluetoothManager.class).getAdapter();
        shadowOf(adapter).setEnabled(true);
        shadowOf(app.getSystemService(PowerManager.class)).setIsInteractive(true);
        var remote = adapter.getRemoteDevice("00:11:22:33:44:55");
        var bluetooth = shadowOf(remote);
        bluetooth.setName(bluetoothName);
        bluetooth.setType(BluetoothDevice.DEVICE_TYPE_LE);
        var other = adapter.getRemoteDevice("00:11:22:33:44:66");
        var otherBluetooth = shadowOf(other);
        if (otherName != null) {
            otherBluetooth.setName(otherName);
            otherBluetooth.setType(BluetoothDevice.DEVICE_TYPE_LE);
        }
        shadowOf(adapter).setBondedDevices(otherName == null ? Set.of(remote) : Set.of(remote, other));
        var input = ShadowInputDevice.makeInputDeviceNamed(inputName);
        ReflectionHelpers.setField(input, "mId", 7);
        ReflectionHelpers.setField(input, "mSources", InputDevice.SOURCE_DPAD | InputDevice.SOURCE_JOYSTICK);
        shadowOf(app.getSystemService(InputManager.class)).addInputDevice(input);

        var worker = Executors.newSingleThreadExecutor();
        var messenger = new BatteryMessenger();
        try (var bridge = new RemoteBatteryBridge(app, messenger, worker)) {
            messenger.call("watch", true).get(1, TimeUnit.SECONDS);
            var denied = messenger.call("snapshot", null);
            worker.submit(() -> {}).get(5, TimeUnit.SECONDS);
            shadowOf(Looper.getMainLooper()).idle();
            assertEquals(Map.of("screenOn", true, "bluetoothPermission", false, "inputCandidates", 1,
                "batteryRead", "bluetoothPermissionDenied"), denied.get(1, TimeUnit.SECONDS));
            assertTrue(bluetooth.getBluetoothGatts().isEmpty());

            shadowOf(app).grantPermissions(Manifest.permission.BLUETOOTH_CONNECT);
            var reading = messenger.call("snapshot", null);
            worker.submit(() -> {}).get(5, TimeUnit.SECONDS);
            assertTrue(otherBluetooth.getBluetoothGatts().isEmpty());
            if (!expectedOutcome.equals("ble")) {
                shadowOf(Looper.getMainLooper()).idle();
                assertEquals(Map.of("screenOn", true, "bluetoothPermission", true, "inputCandidates", 1,
                    "batteryRead", expectedOutcome),
                    reading.get(1, TimeUnit.SECONDS));
                assertTrue(bluetooth.getBluetoothGatts().isEmpty());
                return;
            }
            assertEquals(1, bluetooth.getBluetoothGatts().size());
            var gatt = bluetooth.getBluetoothGatts().get(0);
            var level = new BluetoothGattCharacteristic(
                UUID.fromString("00002a19-0000-1000-8000-00805f9b34fb"),
                BluetoothGattCharacteristic.PROPERTY_READ, BluetoothGattCharacteristic.PERMISSION_READ);
            shadowOf(gatt).getGattCallback().onCharacteristicRead(gatt, level, new byte[]{89}, BluetoothGatt.GATT_SUCCESS);
            shadowOf(Looper.getMainLooper()).idle();
            assertEquals(Map.of("screenOn", true, "percent", 89, "bluetoothPermission", true,
                "inputCandidates", 1, "batteryRead", "ble"), reading.get(1, TimeUnit.SECONDS));
            assertTrue(shadowOf(gatt).isClosed());
        } finally {
            worker.shutdownNow();
        }
    }

    @Test @Config(sdk = 34)
    public void asksForConnectPermissionAndCanOpenAppSettingsAfterDenial() throws Exception {
        var worker = Executors.newSingleThreadExecutor();
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            var messenger = new BatteryMessenger();
            try (var bridge = new RemoteBatteryBridge(activity, messenger, worker)) {
                assertEquals(false, messenger.call("bluetoothPermission", null).get(1, TimeUnit.SECONDS));
                assertNull(shadowOf(activity).getLastRequestedPermission());
                var request = messenger.call("requestBluetoothPermission", null);
                var systemRequest = shadowOf(activity).getLastRequestedPermission();
                assertArrayEquals(new String[]{Manifest.permission.BLUETOOTH_CONNECT}, systemRequest.requestedPermissions);
                assertEquals(RemoteBatteryBridge.PERMISSION_REQUEST, systemRequest.requestCode);
                assertFalse(request.isDone());
                bridge.onPermissionResult();
                request.get(1, TimeUnit.SECONDS);
                messenger.call("requestBluetoothPermission", null).get(1, TimeUnit.SECONDS);
                var settings = shadowOf(activity).getNextStartedActivity();
                assertEquals(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, settings.getAction());
                assertEquals(activity.getPackageName(), settings.getData().getSchemeSpecificPart());
            }
        } finally {
            worker.shutdownNow();
        }
    }

    private static final class BatteryMessenger implements BinaryMessenger {
        private BinaryMessageHandler handler;

        @Override public void send(String channel, ByteBuffer message) {}
        @Override public void send(String channel, ByteBuffer message, BinaryReply reply) {}
        @Override public void setMessageHandler(String channel, BinaryMessageHandler handler) {
            this.handler = handler;
        }

        CompletableFuture<Object> call(String method, Object arguments) {
            var codec = StandardMethodCodec.INSTANCE;
            var message = codec.encodeMethodCall(new MethodCall(method, arguments));
            var result = new CompletableFuture<Object>();
            message.flip();
            handler.onMessage(message, response -> {
                response.flip();
                result.complete(codec.decodeEnvelope(response));
            });
            return result;
        }
    }
}
