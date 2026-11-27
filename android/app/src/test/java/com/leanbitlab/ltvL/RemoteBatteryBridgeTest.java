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
import java.util.List;
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
        verifiesPairedBleReading("BT_RC813A_C9", "BT_RC813A_C9", null, "ble", false);
    }

    @Test @Config(sdk = 34)
    public void matchesRemoteWithConsumerControlSuffix() throws Exception {
        verifiesPairedBleReading("BT_RC933B_B2 Consumer Control", "BT_RC933B_B2", "BT_RC933B", "ble", false);
    }

    @Test @Config(sdk = 34)
    public void matchesRemoteWithSystemControlSuffixIgnoringCase() throws Exception {
        verifiesPairedBleReading("Living Room system control", "Living Room", null, "ble", false);
    }

    @Test @Config(sdk = 34)
    public void skipsAmbiguousBluetoothDevices() throws Exception {
        verifiesPairedBleReading("Remote Consumer Control", "Remote", "Remote Consumer Control", "ambiguousBondedRemotes", false);
    }

    @Test @Config(sdk = 34)
    public void skipsUnrelatedBluetoothDevices() throws Exception {
        verifiesPairedBleReading("Remote Pro Consumer Control", "Remote", "Remote Pro Voice", "noMatchingBondedRemote", false);
    }

    @Test @Config(sdk = 34)
    public void usesAlphabeticKeyboardAndMatchesItsBluetoothNameWhenNoRemotesExist() throws Exception {
        verifiesPairedBleReading("UR02 Keyboard", "UR02", null, "ble", true);
    }

    private void verifiesPairedBleReading(String inputName, String bluetoothName, String otherName,
                                          String expectedOutcome, boolean keyboard) throws Exception {
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
        ReflectionHelpers.setField(input, "mDescriptor", "device-7");
        ReflectionHelpers.setField(input, "mSources", InputDevice.SOURCE_DPAD | InputDevice.SOURCE_JOYSTICK);
        if (keyboard) {
            ReflectionHelpers.setField(input, "mIsExternal", true);
            ReflectionHelpers.setField(input, "mKeyboardType", InputDevice.KEYBOARD_TYPE_ALPHABETIC);
        }
        shadowOf(app.getSystemService(InputManager.class)).addInputDevice(input);

        var worker = Executors.newSingleThreadExecutor();
        var messenger = new BatteryMessenger();
        try (var bridge = new RemoteBatteryBridge(app, messenger, worker)) {
            messenger.call("watch", true).get(1, TimeUnit.SECONDS);
            var denied = messenger.call("snapshot", null);
            worker.submit(() -> {}).get(5, TimeUnit.SECONDS);
            shadowOf(Looper.getMainLooper()).idle();
            assertSnapshot(denied, "bluetoothPermissionDenied", false, null);
            assertTrue(bluetooth.getBluetoothGatts().isEmpty());

            shadowOf(app).grantPermissions(Manifest.permission.BLUETOOTH_CONNECT);
            var reading = messenger.call("snapshot", null);
            worker.submit(() -> {}).get(5, TimeUnit.SECONDS);
            assertTrue(otherBluetooth.getBluetoothGatts().isEmpty());
            if (!expectedOutcome.equals("ble")) {
                shadowOf(Looper.getMainLooper()).idle();
                assertSnapshot(reading, expectedOutcome, true, null);
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
            assertSnapshot(reading, "ble", true, 89);
            assertEquals(java.util.List.of(Map.of("id", "device-7", "name", inputName,
                "address", "00:11:22:33:44:55")), ((Map<?, ?>) reading.get()).get("devices"));
            assertTrue(shadowOf(gatt).isClosed());
        } finally {
            worker.shutdownNow();
        }
    }

    private static void assertSnapshot(CompletableFuture<Object> result, String outcome,
                                       boolean permitted, Integer percent) throws Exception {
        var snapshot = (Map<?, ?>) result.get(1, TimeUnit.SECONDS);
        assertEquals(true, snapshot.get("screenOn"));
        assertEquals(permitted, snapshot.get("bluetoothPermission"));
        assertEquals(1, snapshot.get("inputCandidates"));
        assertEquals(outcome, snapshot.get("batteryRead"));
        assertEquals(percent == null ? null : "device-7", snapshot.get("activeId"));
        assertEquals(percent, snapshot.get("percent"));
    }

    @Test @Config(sdk = 34)
    public void prefersRemotesInAutoAndKeepsManualKeyboardChoiceAcrossDisconnect() throws Exception {
        var app = RuntimeEnvironment.getApplication();
        shadowOf(app.getSystemService(PowerManager.class)).setIsInteractive(true);
        var inputs = shadowOf(app.getSystemService(InputManager.class));
        var remote = ShadowInputDevice.makeInputDeviceNamed("TV remote");
        ReflectionHelpers.setField(remote, "mId", 7);
        ReflectionHelpers.setField(remote, "mDescriptor", "remote");
        ReflectionHelpers.setField(remote, "mSources", InputDevice.SOURCE_DPAD);
        inputs.addInputDevice(remote);
        var keyboard = ShadowInputDevice.makeInputDeviceNamed("UR02 Keyboard");
        ReflectionHelpers.setField(keyboard, "mId", 8);
        ReflectionHelpers.setField(keyboard, "mDescriptor", "keyboard");
        ReflectionHelpers.setField(keyboard, "mSources", InputDevice.SOURCE_KEYBOARD | InputDevice.SOURCE_DPAD);
        ReflectionHelpers.setField(keyboard, "mKeyboardType", InputDevice.KEYBOARD_TYPE_ALPHABETIC);
        ReflectionHelpers.setField(keyboard, "mIsExternal", true);
        inputs.addInputDevice(keyboard);
        var worker = Executors.newSingleThreadExecutor();
        var messenger = new BatteryMessenger();
        try (var bridge = new RemoteBatteryBridge(app, messenger, worker)) {
            messenger.call("watch", true).get(1, TimeUnit.SECONDS);
            assertNull(snapshot(messenger, worker).get("activeId"));
            assertEquals(true, messenger.call("selectDevice", "keyboard").get(1, TimeUnit.SECONDS));
            assertEquals("keyboard", snapshot(messenger, worker).get("activeId"));
            inputs.removeInputDevice(8);
            var unavailable = snapshot(messenger, worker);
            assertEquals("keyboard", unavailable.get("selectedId"));
            assertEquals("selectedDeviceUnavailable", unavailable.get("batteryRead"));
            assertNull(unavailable.get("activeId"));
            inputs.addInputDevice(keyboard);
            assertEquals("keyboard", snapshot(messenger, worker).get("activeId"));
            assertEquals(true, messenger.call("selectDevice", null).get(1, TimeUnit.SECONDS));
            assertNull(snapshot(messenger, worker).get("activeId"));
        } finally {
            worker.shutdownNow();
        }
    }

    @Test @Config(sdk = 28)
    public void autoSkipsAmlKeypadAndReadsTheBleKeyboard() throws Exception {
        var app = RuntimeEnvironment.getApplication();
        shadowOf(app).grantPermissions(Manifest.permission.BLUETOOTH);
        shadowOf(app.getSystemService(PowerManager.class)).setIsInteractive(true);
        var inputs = shadowOf(app.getSystemService(InputManager.class));
        inputs.addInputDevice(input("aml_keypad", 7, false));
        inputs.addInputDevice(input("UR02 Keyboard", 8, true));
        var adapter = app.getSystemService(BluetoothManager.class).getAdapter();
        shadowOf(adapter).setEnabled(true);
        var keyboard = paired(adapter, "UR02", "00:11:22:33:44:55");
        shadowOf(adapter).setBondedDevices(Set.of(keyboard));
        var worker = Executors.newSingleThreadExecutor();
        var messenger = new BatteryMessenger();
        try (var bridge = new RemoteBatteryBridge(app, messenger, worker)) {
            messenger.call("watch", true).get(1, TimeUnit.SECONDS);
            var reading = messenger.call("snapshot", null);
            worker.submit(() -> {}).get(5, TimeUnit.SECONDS);
            assertEquals(1, shadowOf(keyboard).getBluetoothGatts().size());
            sendLevel(shadowOf(keyboard).getBluetoothGatts().get(0), 66);
            shadowOf(Looper.getMainLooper()).idle();
            var result = (Map<?, ?>) reading.get(1, TimeUnit.SECONDS);
            assertEquals("auto", result.get("selectionMode"));
            assertEquals(2, result.get("inputCandidates"));
            assertEquals("device-8", result.get("activeId"));
            assertEquals(66, result.get("percent"));
            var report = (List<?>) result.get("batteryInputs");
            assertTrue(report.stream().anyMatch(row -> row instanceof Map<?, ?> data
                && "aml_keypad".equals(data.get("name")) && data.get("bleMatches").equals(0)));
        } finally {
            worker.shutdownNow();
        }
    }

    @Test @Config(sdk = 28)
    public void autoPrefersAReadableRemoteAndFallsBackWhenItsBleReadTimesOut() throws Exception {
        var app = RuntimeEnvironment.getApplication();
        shadowOf(app).grantPermissions(Manifest.permission.BLUETOOTH);
        shadowOf(app.getSystemService(PowerManager.class)).setIsInteractive(true);
        var inputs = shadowOf(app.getSystemService(InputManager.class));
        inputs.addInputDevice(input("Z Remote", 7, false));
        inputs.addInputDevice(input("A Keyboard", 8, true));
        var adapter = app.getSystemService(BluetoothManager.class).getAdapter();
        shadowOf(adapter).setEnabled(true);
        var remote = paired(adapter, "Z Remote", "00:11:22:33:44:55");
        var keyboard = paired(adapter, "A Keyboard", "00:11:22:33:44:66");
        shadowOf(adapter).setBondedDevices(Set.of(remote, keyboard));
        var worker = Executors.newSingleThreadExecutor();
        var messenger = new BatteryMessenger();
        try (var bridge = new RemoteBatteryBridge(app, messenger, worker)) {
            messenger.call("watch", true).get(1, TimeUnit.SECONDS);
            var first = messenger.call("snapshot", null);
            worker.submit(() -> {}).get(5, TimeUnit.SECONDS);
            assertTrue(shadowOf(keyboard).getBluetoothGatts().isEmpty());
            sendLevel(shadowOf(remote).getBluetoothGatts().get(0), 40);
            shadowOf(Looper.getMainLooper()).idle();
            assertEquals("device-7", ((Map<?, ?>) first.get(1, TimeUnit.SECONDS)).get("activeId"));

            var fallback = messenger.call("snapshot", null);
            worker.submit(() -> {}).get(5, TimeUnit.SECONDS);
            var timedOut = shadowOf(remote).getBluetoothGatts().get(1);
            shadowOf(Looper.getMainLooper()).idleFor(1800, TimeUnit.MILLISECONDS);
            worker.submit(() -> {}).get(5, TimeUnit.SECONDS);
            assertTrue(shadowOf(timedOut).isClosed());
            sendLevel(timedOut, 41);
            assertFalse(fallback.isDone());
            sendLevel(shadowOf(keyboard).getBluetoothGatts().get(0), 51);
            shadowOf(Looper.getMainLooper()).idle();
            var result = (Map<?, ?>) fallback.get(1, TimeUnit.SECONDS);
            assertEquals("device-8", result.get("activeId"));
            assertEquals(51, result.get("percent"));
            assertEquals(List.of("timeout", "ble"), ((List<?>) result.get("bleAttempts")).stream()
                .map(row -> ((Map<?, ?>) row).get("result")).toList());
        } finally {
            worker.shutdownNow();
        }
    }

    private static InputDevice input(String name, int id, boolean keyboard) {
        var input = ShadowInputDevice.makeInputDeviceNamed(name);
        ReflectionHelpers.setField(input, "mId", id);
        ReflectionHelpers.setField(input, "mDescriptor", "device-" + id);
        ReflectionHelpers.setField(input, "mSources", InputDevice.SOURCE_DPAD | InputDevice.SOURCE_KEYBOARD);
        ReflectionHelpers.setField(input, "mKeyboardType",
            keyboard ? InputDevice.KEYBOARD_TYPE_ALPHABETIC : InputDevice.KEYBOARD_TYPE_NON_ALPHABETIC);
        return input;
    }

    private static BluetoothDevice paired(android.bluetooth.BluetoothAdapter adapter, String name, String address) {
        var device = adapter.getRemoteDevice(address);
        shadowOf(device).setName(name);
        shadowOf(device).setType(BluetoothDevice.DEVICE_TYPE_LE);
        return device;
    }

    private static void sendLevel(BluetoothGatt gatt, int percent) {
        var level = new BluetoothGattCharacteristic(
            UUID.fromString("00002a19-0000-1000-8000-00805f9b34fb"),
            BluetoothGattCharacteristic.PROPERTY_READ, BluetoothGattCharacteristic.PERMISSION_READ);
        level.setValue(new byte[]{(byte) percent});
        shadowOf(gatt).getGattCallback().onCharacteristicRead(gatt, level, BluetoothGatt.GATT_SUCCESS);
    }

    private static Map<?, ?> snapshot(BatteryMessenger messenger, java.util.concurrent.ExecutorService worker)
        throws Exception {
        var result = messenger.call("snapshot", null);
        worker.submit(() -> {}).get(5, TimeUnit.SECONDS);
        shadowOf(Looper.getMainLooper()).idle();
        return (Map<?, ?>) result.get(1, TimeUnit.SECONDS);
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
