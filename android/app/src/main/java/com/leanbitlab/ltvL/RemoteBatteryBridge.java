package com.leanbitlab.ltvL;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothProfile;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.hardware.input.InputManager;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.PowerManager;
import android.provider.Settings;
import android.view.InputDevice;
import android.view.KeyEvent;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.core.content.ContextCompat;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ExecutorService;
import java.util.regex.Pattern;

/** Reads a remote already present in Android's input list. */
final class RemoteBatteryBridge implements AutoCloseable {
    static final int PERMISSION_REQUEST = 2403;
    private static final String PERMISSION_PREFS = "remote_battery_permissions";
    private static final UUID BATTERY_SERVICE = UUID.fromString("0000180f-0000-1000-8000-00805f9b34fb");
    private static final UUID BATTERY_LEVEL = UUID.fromString("00002a19-0000-1000-8000-00805f9b34fb");
    private static final Pattern HID_CONTROL_SUFFIX = Pattern.compile(
        "\\s+(?:Consumer Control|System Control)$", Pattern.CASE_INSENSITIVE);
    private final Context context;
    private final ExecutorService worker;
    private final MethodChannel channel;
    private final Handler main = new Handler(Looper.getMainLooper());
    private InputManager inputs;
    private boolean watching, closed, screenRegistered, inputRegistered;
    private Sample active;
    private MethodChannel.Result pendingPermission;

    private final BroadcastReceiver screen = new BroadcastReceiver() {
        @Override public void onReceive(Context unused, Intent intent) {
            if (!watching) return;
            boolean on = Intent.ACTION_SCREEN_ON.equals(intent.getAction());
            if (!on && active != null) active.finish(null, false);
            channel.invokeMethod("changed", on);
        }
    };
    private final InputManager.InputDeviceListener inputChanges = new InputManager.InputDeviceListener() {
        @Override public void onInputDeviceAdded(int id) { changed(); }
        @Override public void onInputDeviceRemoved(int id) { changed(); }
        @Override public void onInputDeviceChanged(int id) { changed(); }
        private void changed() { if (watching) channel.invokeMethod("changed", null); }
    };

    RemoteBatteryBridge(Context context, BinaryMessenger messenger, ExecutorService worker) {
        this.context = context;
        this.worker = worker;
        channel = new MethodChannel(messenger, "cutelauncher/remote_battery");
        channel.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "bluetoothPermission" -> result.success(
                    Build.VERSION.SDK_INT >= 31 ? hasBluetoothPermission() : null);
                case "requestBluetoothPermission" -> requestBluetoothPermission(result);
                case "watch" -> {
                    watch(Boolean.TRUE.equals(call.arguments));
                    result.success(null);
                }
                case "snapshot" -> {
                    if (!watching || active != null) {
                        result.error("unavailable", "Remote battery read unavailable", null);
                        return;
                    }
                    var sample = new Sample(result);
                    active = sample;
                    main.postDelayed(sample.timeout, 6000);
                    worker.execute(sample::start);
                }
                default -> result.notImplemented();
            }
        });
    }

    private boolean hasBluetoothPermission() {
        String permission = Build.VERSION.SDK_INT >= 31
            ? Manifest.permission.BLUETOOTH_CONNECT : Manifest.permission.BLUETOOTH;
        return context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED;
    }

    private void requestBluetoothPermission(MethodChannel.Result result) {
        if (Build.VERSION.SDK_INT < 31 || pendingPermission != null) {
            result.success(null);
            return;
        }
        try {
            if (context instanceof Activity activity && !hasBluetoothPermission()) {
                var preferences = context.getSharedPreferences(PERMISSION_PREFS, Context.MODE_PRIVATE);
                if (!preferences.getBoolean("requested", false)
                    || activity.shouldShowRequestPermissionRationale(Manifest.permission.BLUETOOTH_CONNECT)) {
                    pendingPermission = result;
                    activity.requestPermissions(new String[]{Manifest.permission.BLUETOOTH_CONNECT}, PERMISSION_REQUEST);
                    preferences.edit().putBoolean("requested", true).apply();
                    return;
                }
            }
            context.startActivity(new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.fromParts("package", context.getPackageName(), null)));
            result.success(null);
        } catch (RuntimeException unavailable) {
            pendingPermission = null;
            result.error("unavailable", "Bluetooth permission settings unavailable", null);
        }
    }

    void onPermissionResult() {
        var result = pendingPermission;
        pendingPermission = null;
        if (result != null) result.success(null);
    }

    private void watch(boolean enabled) {
        if (closed || watching == enabled) return;
        watching = enabled;
        if (enabled) {
            if (inputs == null) inputs = context.getSystemService(InputManager.class);
            var filter = new IntentFilter(Intent.ACTION_SCREEN_ON);
            filter.addAction(Intent.ACTION_SCREEN_OFF);
            try {
                ContextCompat.registerReceiver(context, screen, filter, ContextCompat.RECEIVER_NOT_EXPORTED);
                screenRegistered = true;
            } catch (RuntimeException unavailable) { /* Bounded snapshots remain available. */ }
            if (inputs != null) {
                try {
                    inputs.registerInputDeviceListener(inputChanges, main);
                    inputRegistered = true;
                } catch (RuntimeException unavailable) { /* Bounded snapshots remain available. */ }
            }
        } else {
            if (screenRegistered) {
                screenRegistered = false;
                try { context.unregisterReceiver(screen); } catch (RuntimeException ignored) { }
            }
            if (inputRegistered) {
                inputRegistered = false;
                try { inputs.unregisterInputDeviceListener(inputChanges); } catch (RuntimeException ignored) { }
            }
            if (active != null) active.finish(null, true);
        }
    }

    @Override public void close() {
        watch(false);
        onPermissionResult();
        closed = true;
        channel.setMethodCallHandler(null);
        main.removeCallbacksAndMessages(null);
    }

    private List<InputDevice> remotes() {
        var devices = new ArrayList<InputDevice>();
        if (inputs == null) return devices;
        for (int id : inputs.getInputDeviceIds()) {
            var device = inputs.getInputDevice(id);
            if (device != null && isRemote(device)) devices.add(device);
        }
        return devices;
    }

    static boolean isRemote(InputDevice device) {
        if (device.isVirtual() || device.getControllerNumber() != 0
            || device.supportsSource(InputDevice.SOURCE_GAMEPAD)
            || device.getKeyboardType() == InputDevice.KEYBOARD_TYPE_ALPHABETIC) return false;
        if (device.supportsSource(InputDevice.SOURCE_DPAD)) return true;
        for (boolean present : device.hasKeys(KeyEvent.KEYCODE_DPAD_UP, KeyEvent.KEYCODE_DPAD_DOWN,
            KeyEvent.KEYCODE_DPAD_LEFT, KeyEvent.KEYCODE_DPAD_RIGHT)) {
            if (!present) return false;
        }
        return true;
    }

    @RequiresApi(31)
    @Nullable private static Integer inputBattery(InputDevice device) {
        var battery = device.getBatteryState();
        return battery.isPresent() ? capacityPercent(battery.getCapacity()) : null;
    }

    @Nullable static Integer capacityPercent(float capacity) {
        return capacity >= 0f && capacity <= 1f ? Math.round(capacity * 100f) : null;
    }

    @SuppressLint("MissingPermission") // Both platform permission variants are checked below.
    @Nullable private BluetoothDevice bondedRemote(List<InputDevice> remotes) {
        if (remotes.isEmpty() || !hasBluetoothPermission()) return null;
        var manager = context.getSystemService(BluetoothManager.class);
        var adapter = manager == null ? null : manager.getAdapter();
        if (adapter == null || !adapter.isEnabled()) return null;
        BluetoothDevice candidate = null;
        for (var device : adapter.getBondedDevices()) {
            int type = device.getType();
            if (type != BluetoothDevice.DEVICE_TYPE_LE && type != BluetoothDevice.DEVICE_TYPE_DUAL) continue;
            var bluetoothName = device.getName();
            if (bluetoothName == null || bluetoothName.trim().isEmpty()) continue;
            var name = bluetoothName.trim();
            if (remotes.stream().noneMatch(remote -> matchesRemoteName(name, remote.getName()))) continue;
            if (candidate != null) return null;
            candidate = device;
        }
        return candidate;
    }

    private static boolean matchesRemoteName(String bluetoothName, @Nullable String inputName) {
        if (inputName == null) return false;
        var name = inputName.trim();
        if (bluetoothName.equalsIgnoreCase(name)) return true;
        // Android can expose a separate input device named after a HID collection.
        var suffix = HID_CONTROL_SUFFIX.matcher(name);
        return suffix.find() && bluetoothName.equalsIgnoreCase(name.substring(0, suffix.start()));
    }

    @SuppressLint("MissingPermission") // GATT is only opened after the permission check in bondedRemote.
    private final class Sample extends BluetoothGattCallback {
        private final MethodChannel.Result result;
        private final Runnable timeout = () -> finish(null, true);
        private volatile boolean finished;
        private BluetoothGatt connection;

        Sample(MethodChannel.Result result) { this.result = result; }

        void start() {
            if (finished) return;
            try {
                var power = context.getSystemService(PowerManager.class);
                if (power != null && !power.isInteractive()) {
                    finish(null, false);
                    return;
                }
                var remotes = remotes();
                if (Build.VERSION.SDK_INT >= 31) {
                    Integer percent = null;
                    for (var device : remotes) {
                        var level = inputBattery(device);
                        if (level == null) continue;
                        if (percent != null) {
                            finish(null, true);
                            return;
                        }
                        percent = level;
                    }
                    if (percent != null) {
                        finish(percent, true);
                        return;
                    }
                }
                var remote = bondedRemote(remotes);
                if (remote == null || finished) {
                    finish(null, true);
                    return;
                }
                var opened = remote.connectGatt(context, false, this, BluetoothDevice.TRANSPORT_LE);
                if (opened == null) {
                    finish(null, true);
                    return;
                }
                synchronized (this) {
                    if (!finished) {
                        connection = opened;
                        return;
                    }
                }
                closeGatt(opened);
            } catch (RuntimeException unavailable) {
                finish(null, true);
            }
        }

        @Override public void onConnectionStateChange(BluetoothGatt gatt, int status, int state) {
            if (finished) return;
            try {
                if (status != BluetoothGatt.GATT_SUCCESS || state == BluetoothProfile.STATE_DISCONNECTED
                    || (state == BluetoothProfile.STATE_CONNECTED && !gatt.discoverServices())) finish(null, true);
            } catch (RuntimeException unavailable) { finish(null, true); }
        }

        @Override public void onServicesDiscovered(BluetoothGatt gatt, int status) {
            if (finished) return;
            try {
                var service = status == BluetoothGatt.GATT_SUCCESS ? gatt.getService(BATTERY_SERVICE) : null;
                var level = service == null ? null : service.getCharacteristic(BATTERY_LEVEL);
                if (level == null || !gatt.readCharacteristic(level)) finish(null, true);
            } catch (RuntimeException unavailable) { finish(null, true); }
        }

        @Override public void onCharacteristicRead(BluetoothGatt gatt, BluetoothGattCharacteristic value, int status) {
            onCharacteristicRead(gatt, value, value.getValue(), status);
        }

        @Override public void onCharacteristicRead(BluetoothGatt gatt, BluetoothGattCharacteristic value,
                                                   byte[] bytes, int status) {
            finish(status == BluetoothGatt.GATT_SUCCESS && BATTERY_LEVEL.equals(value.getUuid())
                && bytes != null && bytes.length == 1 ? levelPercent(bytes[0]) : null, true);
        }

        void finish(@Nullable Integer level, boolean screenOn) {
            BluetoothGatt opened;
            synchronized (this) {
                if (finished) return;
                finished = true;
                opened = connection;
                connection = null;
            }
            if (opened != null) closeGatt(opened);
            main.post(() -> {
                if (closed || active != this) return;
                active = null;
                main.removeCallbacks(timeout);
                Map<String, Object> snapshot = new HashMap<>();
                snapshot.put("screenOn", screenOn);
                if (level != null) snapshot.put("percent", level);
                result.success(snapshot);
            });
        }
    }

    @Nullable static Integer levelPercent(byte value) {
        int percent = Byte.toUnsignedInt(value);
        return percent <= 100 ? percent : null;
    }

    @SuppressLint("MissingPermission")
    private static void closeGatt(BluetoothGatt connection) {
        try { connection.close(); } catch (RuntimeException unavailable) { /* The stack is gone. */ }
    }
}
