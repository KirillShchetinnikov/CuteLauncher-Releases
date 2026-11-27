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
import android.content.SharedPreferences;
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
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ExecutorService;
import java.util.regex.Pattern;

/** Reads a remote already present in Android's input list. */
final class RemoteBatteryBridge implements AutoCloseable {
    static final int PERMISSION_REQUEST = 2403;
    private static final String PERMISSION_PREFS = "remote_battery_permissions";
    private static final int SAMPLE_TIMEOUT_MS = 6000;
    private static final int BLE_ATTEMPT_TIMEOUT_MS = 1800;
    private static final int MAX_BLE_ATTEMPTS = 3;
    private static final int DIAGNOSTIC_INPUT_LIMIT = 24;
    private static final UUID BATTERY_SERVICE = UUID.fromString("0000180f-0000-1000-8000-00805f9b34fb");
    private static final UUID BATTERY_LEVEL = UUID.fromString("00002a19-0000-1000-8000-00805f9b34fb");
    private static final Pattern HID_CONTROL_SUFFIX = Pattern.compile(
        "\\s+(?:Consumer Control|System Control)$", Pattern.CASE_INSENSITIVE);
    private final Context context;
    private final ExecutorService worker;
    private final MethodChannel channel;
    private final SharedPreferences selection;
    private List<Target> lastTargets = List.of();
    private final Handler main = new Handler(Looper.getMainLooper());
    private InputManager inputs;
    private boolean watching, closed, screenRegistered, inputRegistered;
    private Sample active;
    private MethodChannel.Result pendingPermission;
    private final SharedPreferences.OnSharedPreferenceChangeListener selectionChanges =
        (preferences, key) -> {
            if ("id".equals(key)) invalidateDevices();
        };

    private final BroadcastReceiver screen = new BroadcastReceiver() {
        @Override public void onReceive(Context unused, Intent intent) {
            if (!watching) return;
            boolean on = Intent.ACTION_SCREEN_ON.equals(intent.getAction());
            if (!on && active != null) active.finish(null, false, "screenOff");
            channel.invokeMethod("changed", on);
        }
    };
    private final InputManager.InputDeviceListener inputChanges = new InputManager.InputDeviceListener() {
        @Override public void onInputDeviceAdded(int id) { devicesChanged(); }
        @Override public void onInputDeviceRemoved(int id) { invalidateDevices(); }
        @Override public void onInputDeviceChanged(int id) { devicesChanged(); }
    };

    private void devicesChanged() {
        if (watching) channel.invokeMethod("changed", null);
    }

    private void invalidateDevices() {
        if (active != null) active.finish(null, true, "cancelled");
        devicesChanged();
    }

    RemoteBatteryBridge(Context context, BinaryMessenger messenger, ExecutorService worker) {
        this.context = context;
        this.worker = worker;
        selection = context.getSharedPreferences("remote_battery_selection", Context.MODE_PRIVATE);
        channel = new MethodChannel(messenger, "cutelauncher/remote_battery");
        channel.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "bluetoothPermission" -> result.success(
                    Build.VERSION.SDK_INT >= 31 ? hasBluetoothPermission() : null);
                case "requestBluetoothPermission" -> requestBluetoothPermission(result);
                case "selectDevice" -> result.success(selectDevice(call.arguments));
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
                    main.postDelayed(sample.timeout, SAMPLE_TIMEOUT_MS);
                    worker.execute(sample::start);
                }
                default -> result.notImplemented();
            }
        });
    }

    private boolean selectDevice(@Nullable Object value) {
        if (value == null) {
            selection.edit().remove("id").remove("name").apply();
            return true;
        }
        for (var target : lastTargets) {
            if (!target.id().equals(value)) continue;
            selection.edit().putString("id", target.id()).putString("name", target.name()).apply();
            return true;
        }
        return false;
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
            selection.registerOnSharedPreferenceChangeListener(selectionChanges);
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
            selection.unregisterOnSharedPreferenceChangeListener(selectionChanges);
            if (screenRegistered) {
                screenRegistered = false;
                try { context.unregisterReceiver(screen); } catch (RuntimeException ignored) { }
            }
            if (inputRegistered) {
                inputRegistered = false;
                try { inputs.unregisterInputDeviceListener(inputChanges); } catch (RuntimeException ignored) { }
            }
            if (active != null) active.finish(null, true, "cancelled");
        }
    }

    @Override public void close() {
        watch(false);
        onPermissionResult();
        closed = true;
        channel.setMethodCallHandler(null);
        main.removeCallbacksAndMessages(null);
    }

    private List<InputDevice> devices() {
        var devices = new ArrayList<InputDevice>();
        if (inputs == null) return devices;
        for (int id : inputs.getInputDeviceIds()) {
            var device = inputs.getInputDevice(id);
            if (device != null) devices.add(device);
        }
        return devices;
    }

    static boolean isRemote(InputDevice device) {
        if (!isPhysicalInput(device) || device.getKeyboardType() == InputDevice.KEYBOARD_TYPE_ALPHABETIC) return false;
        if (device.supportsSource(InputDevice.SOURCE_DPAD)) return true;
        for (boolean present : device.hasKeys(KeyEvent.KEYCODE_DPAD_UP, KeyEvent.KEYCODE_DPAD_DOWN,
            KeyEvent.KEYCODE_DPAD_LEFT, KeyEvent.KEYCODE_DPAD_RIGHT)) {
            if (!present) return false;
        }
        return true;
    }

    private static boolean isPhysicalInput(InputDevice device) {
        return !device.isVirtual() && device.getControllerNumber() == 0
            && !device.supportsSource(InputDevice.SOURCE_GAMEPAD);
    }

    private static boolean isKeyboard(InputDevice device) {
        return isPhysicalInput(device) && (Build.VERSION.SDK_INT < 29 || device.isExternal())
            && device.getKeyboardType() == InputDevice.KEYBOARD_TYPE_ALPHABETIC;
    }

    @RequiresApi(31)
    @Nullable private static Integer inputBattery(InputDevice device) {
        var battery = device.getBatteryState();
        return battery.isPresent() ? capacityPercent(battery.getCapacity()) : null;
    }

    @Nullable static Integer capacityPercent(float capacity) {
        return capacity >= 0f && capacity <= 1f ? Math.round(capacity * 100f) : null;
    }

    private record BondedDevice(BluetoothDevice device, String name, boolean ble) {}

    private record BondedDevices(List<BondedDevice> devices, String unavailable) {}

    @SuppressLint("MissingPermission")
    private BondedDevices bondedDevices() {
        if (!hasBluetoothPermission()) return new BondedDevices(List.of(), "bluetoothPermissionDenied");
        try {
            var manager = context.getSystemService(BluetoothManager.class);
            var adapter = manager == null ? null : manager.getAdapter();
            if (adapter == null) return new BondedDevices(List.of(), "noBluetoothAdapter");
            if (!adapter.isEnabled()) return new BondedDevices(List.of(), "bluetoothDisabled");
            var devices = new ArrayList<BondedDevice>();
            for (var device : adapter.getBondedDevices()) {
                var name = device.getName();
                if (name == null || name.trim().isEmpty()) continue;
                int type = device.getType();
                devices.add(new BondedDevice(device, name.trim(),
                    type == BluetoothDevice.DEVICE_TYPE_LE || type == BluetoothDevice.DEVICE_TYPE_DUAL));
            }
            return new BondedDevices(devices, "noMatchingBondedRemote");
        } catch (RuntimeException unavailable) {
            return new BondedDevices(List.of(), "platformError");
        }
    }

    private record Target(InputDevice input, boolean keyboard, int index,
                          List<BondedDevice> matches, @Nullable Integer inputLevel) {
        String id() { return input.getDescriptor(); }
        String name() { return input.getName(); }

        Map<String, Object> describe() {
            var info = new HashMap<String, Object>();
            info.put("id", id());
            info.put("name", name());
            if (matches.size() == 1) info.put("address", matches.get(0).device().getAddress());
            return info;
        }
    }

    private record Probe(Target target, @Nullable Integer level, @Nullable BluetoothDevice device) {}

    private static boolean matchesRemoteName(String bluetoothName, @Nullable String inputName, boolean keyboard) {
        if (inputName == null) return false;
        var name = inputName.trim();
        if (bluetoothName.equalsIgnoreCase(name)) return true;
        if (keyboard && name.toLowerCase(java.util.Locale.ROOT).endsWith(" keyboard")
            && bluetoothName.equalsIgnoreCase(name.substring(0, name.length() - " keyboard".length()))) return true;
        // Android can expose a separate input device named after a HID collection.
        var suffix = HID_CONTROL_SUFFIX.matcher(name);
        return suffix.find() && bluetoothName.equalsIgnoreCase(name.substring(0, suffix.start()));
    }

    @SuppressLint("MissingPermission") // GATT is only opened using permitted bonded devices.
    private final class Sample {
        private final MethodChannel.Result result;
        private final Runnable timeout = this::finishOnTimeout;
        private volatile boolean finished;
        private volatile int inputCandidates = -1;
        private volatile List<Target> targets;
        private volatile Map<String, Object> deviceInfo = Map.of();
        private volatile Target manualTarget;
        private volatile Probe knownCharge;
        private List<Probe> plan = List.of();
        private int nextProbe, startedReads;
        private String lastOutcome;
        private final List<Map<String, Object>> attempts = new ArrayList<>();
        private GattRead pending;

        Sample(MethodChannel.Result result) { this.result = result; }

        void start() {
            if (finished) return;
            try {
                var power = context.getSystemService(PowerManager.class);
                if (power != null && !power.isInteractive()) {
                    finish(null, false, "screenOff");
                    return;
                }

                String selected = selection.getString("id", null);
                var inputs = devices();
                var bonded = inputs.isEmpty() ? new BondedDevices(List.of(), "noInputRemote") : bondedDevices();
                var entries = new ArrayList<Target>();
                var descriptions = new ArrayList<Map<String, Object>>();
                var observations = new ArrayList<Map<String, Object>>();
                var candidates = new ArrayList<Target>();
                for (int index = 0; index < inputs.size(); index++) {
                    var input = inputs.get(index);
                    boolean keyboard = isKeyboard(input);
                    boolean eligible = keyboard || isRemote(input);
                    boolean consider = eligible && (selected == null || selected.equals(input.getDescriptor()));
                    var matches = new ArrayList<BondedDevice>();
                    if (eligible) {
                        for (var device : bonded.devices()) {
                            if (matchesRemoteName(device.name(), input.getName(), keyboard)) matches.add(device);
                        }
                    }
                    Integer level = null;
                    String inputRead = consider ? "unsupported" : "skipped";
                    if (consider && Build.VERSION.SDK_INT >= 31) {
                        try {
                            level = inputBattery(input);
                            inputRead = level == null ? "unavailable" : "inputDevice";
                        } catch (RuntimeException unavailable) {
                            inputRead = "platformError";
                        }
                    }
                    int bleMatches = 0;
                    for (var match : matches) if (match.ble()) bleMatches++;
                    if (index < DIAGNOSTIC_INPUT_LIMIT) {
                        var row = new HashMap<String, Object>();
                        row.put("index", index);
                        row.put("name", input.getName());
                        row.put("kind", keyboard ? "keyboard" : eligible ? "remote" : "other");
                        row.put("considered", consider);
                        row.put("sources", input.getSources());
                        row.put("keyboardType", input.getKeyboardType());
                        row.put("controllerNumber", input.getControllerNumber());
                        row.put("virtual", input.isVirtual());
                        if (Build.VERSION.SDK_INT >= 29) row.put("external", input.isExternal());
                        row.put("bondedMatches", matches.size());
                        row.put("bleMatches", bleMatches);
                        row.put("inputRead", inputRead);
                        if (level != null) row.put("inputPercent", level);
                        observations.add(row);
                    }
                    if (!eligible) continue;
                    var target = new Target(input, keyboard, index, matches, level);
                    entries.add(target);
                    descriptions.add(target.describe());
                    if (consider) candidates.add(target);
                }
                var info = new HashMap<String, Object>();
                info.put("devices", descriptions);
                info.put("selectionMode", selected == null ? "auto" : "manual");
                info.put("inputDeviceCount", inputs.size());
                info.put("batteryInputs", observations);
                var bondedNames = new ArrayList<String>();
                int bondedBleCount = 0;
                for (var device : bonded.devices()) {
                    if (!device.ble()) continue;
                    bondedBleCount++;
                    if (bondedNames.size() < DIAGNOSTIC_INPUT_LIMIT) bondedNames.add(device.name());
                }
                info.put("bondedBleCount", bondedBleCount);
                info.put("batteryBondedNames", bondedNames);
                info.put("bluetoothLookup", bonded.unavailable().equals("noMatchingBondedRemote")
                    ? "ready" : bonded.unavailable());
                if (selected != null) {
                    info.put("selectedId", selected);
                    info.put("selectedName", selection.getString("name", ""));
                    if (candidates.size() == 1) {
                        manualTarget = candidates.get(0);
                        info.put("selectedInput", manualTarget.index());
                    }
                }
                deviceInfo = info;
                targets = entries;
                inputCandidates = candidates.size();
                if (candidates.isEmpty()) {
                    finish(null, true, selected == null ? "noInputRemote" : "selectedDeviceUnavailable");
                    return;
                }
                if (selected != null && candidates.size() != 1) {
                    finish(null, true, "ambiguousInputBattery");
                    return;
                }

                lastOutcome = bonded.unavailable();
                plan = readPlan(candidates);
                for (var probe : plan) {
                    if (probe.level() != null) {
                        knownCharge = probe;
                        break;
                    }
                }
                advance();
            } catch (RuntimeException unavailable) {
                finish(null, true, "platformError");
            }
        }

        private List<Probe> readPlan(List<Target> candidates) {
            candidates.sort(Comparator.comparing(Target::keyboard)
                .thenComparing(Target::name, String.CASE_INSENSITIVE_ORDER)
                .thenComparing(Target::id));
            var probes = new ArrayList<Probe>();
            var seen = new LinkedHashSet<BluetoothDevice>();
            for (boolean keyboard : new boolean[]{false, true}) {
                for (var target : candidates) {
                    if (target.keyboard() == keyboard && target.inputLevel() != null) {
                        probes.add(new Probe(target, target.inputLevel(), null));
                    }
                }
                for (var target : candidates) {
                    if (target.keyboard() != keyboard || target.inputLevel() != null) continue;
                    BluetoothDevice matched = null;
                    for (var device : target.matches()) {
                        if (!device.ble()) continue;
                        if (matched != null) {
                            lastOutcome = "ambiguousBondedRemotes";
                            matched = null;
                            break;
                        }
                        matched = device.device();
                    }
                    if (matched != null && seen.add(matched)) probes.add(new Probe(target, null, matched));
                }
            }
            return probes;
        }

        private void advance() {
            while (!finished && nextProbe < plan.size()) {
                var probe = plan.get(nextProbe++);
                if (probe.level() != null) {
                    finish(probe.level(), true, "inputDevice", probe.target());
                    return;
                }
                if (startedReads == MAX_BLE_ATTEMPTS) continue;
                var read = new GattRead(probe);
                synchronized (this) {
                    if (finished) return;
                    startedReads++;
                    pending = read;
                }
                read.start();
                return;
            }
            finish(null, true, lastOutcome);
        }

        private void finishOnTimeout() {
            var fallback = knownCharge;
            if (fallback == null) finish(null, true, "timeout", null, true);
            else finish(fallback.level(), true, "inputDevice", fallback.target(), true);
        }

        private void readCompleted(GattRead read, @Nullable Integer level, String outcome) {
            synchronized (this) {
                if (finished || pending != read) return;
                pending = null;
                attempts.add(Map.of("input", read.probe.target().index(), "result", outcome));
            }
            if (level != null) {
                finish(level, true, "ble", read.probe.target());
            } else {
                lastOutcome = outcome;
                try {
                    worker.execute(this::advance);
                } catch (java.util.concurrent.RejectedExecutionException unavailable) {
                    finish(null, true, "platformError");
                }
            }
        }

        void finish(@Nullable Integer level, boolean screenOn, String outcome) {
            finish(level, screenOn, outcome, null);
        }

        private void finish(@Nullable Integer level, boolean screenOn, String outcome, @Nullable Target source) {
            finish(level, screenOn, outcome, source, false);
        }

        private void finish(@Nullable Integer level, boolean screenOn, String outcome,
                            @Nullable Target source, boolean timedOut) {
            GattRead reading;
            List<Map<String, Object>> diagnostics;
            synchronized (this) {
                if (finished) return;
                finished = true;
                reading = pending;
                pending = null;
                if (timedOut && reading != null) {
                    attempts.add(Map.of("input", reading.probe.target().index(), "result", "timeout"));
                }
                diagnostics = new ArrayList<>(attempts);
            }
            if (reading != null) reading.close();
            main.post(() -> {
                if (closed || active != this) return;
                active = null;
                main.removeCallbacks(timeout);
                Map<String, Object> snapshot = new HashMap<>();
                snapshot.put("screenOn", screenOn);
                if (level != null) snapshot.put("percent", level);
                snapshot.put("batteryRead", outcome);
                snapshot.put("bluetoothPermission", hasBluetoothPermission());
                if (inputCandidates >= 0) snapshot.put("inputCandidates", inputCandidates);
                if (!"cancelled".equals(outcome) && screenOn && targets != null) {
                    lastTargets = targets;
                    snapshot.putAll(deviceInfo);
                    snapshot.put("bleAttempts", diagnostics);
                    Target shown = source == null ? manualTarget : source;
                    if (shown != null) {
                        snapshot.put("activeId", shown.id());
                        snapshot.put("activeInput", shown.index());
                        snapshot.put("activeName", shown.name());
                    }
                }
                result.success(snapshot);
            });
        }

        private final class GattRead extends BluetoothGattCallback {
            final Probe probe;
            private final Runnable deadline = () -> complete(null, "timeout");
            private volatile boolean closed;
            private BluetoothGatt connection;

            GattRead(Probe probe) { this.probe = probe; }

            void start() {
                if (closed || finished) return;
                if (startedReads < MAX_BLE_ATTEMPTS && nextProbe < plan.size()
                    && plan.get(nextProbe).level() == null) {
                    main.postDelayed(deadline, BLE_ATTEMPT_TIMEOUT_MS);
                }
                try {
                    var opened = probe.device().connectGatt(context, false, this, BluetoothDevice.TRANSPORT_LE);
                    if (opened == null) {
                        complete(null, "gattConnectionFailed");
                        return;
                    }
                    synchronized (this) {
                        if (!closed) {
                            connection = opened;
                            return;
                        }
                    }
                    closeGatt(opened);
                } catch (RuntimeException unavailable) {
                    complete(null, "platformError");
                }
            }

            @Override public void onConnectionStateChange(BluetoothGatt gatt, int status, int state) {
                if (closed) return;
                try {
                    if (status != BluetoothGatt.GATT_SUCCESS || state == BluetoothProfile.STATE_DISCONNECTED
                        || (state == BluetoothProfile.STATE_CONNECTED && !gatt.discoverServices())) {
                        complete(null, "gattConnectionFailed");
                    }
                } catch (RuntimeException unavailable) { complete(null, "platformError"); }
            }

            @Override public void onServicesDiscovered(BluetoothGatt gatt, int status) {
                if (closed) return;
                try {
                    var service = status == BluetoothGatt.GATT_SUCCESS ? gatt.getService(BATTERY_SERVICE) : null;
                    var level = service == null ? null : service.getCharacteristic(BATTERY_LEVEL);
                    if (status != BluetoothGatt.GATT_SUCCESS || (level != null && !gatt.readCharacteristic(level))) {
                        complete(null, "gattReadFailed");
                    } else if (level == null) {
                        complete(null, "noBatteryCharacteristic");
                    }
                } catch (RuntimeException unavailable) { complete(null, "platformError"); }
            }

            @Override public void onCharacteristicRead(BluetoothGatt gatt, BluetoothGattCharacteristic value, int status) {
                onCharacteristicRead(gatt, value, value.getValue(), status);
            }

            @Override public void onCharacteristicRead(BluetoothGatt gatt, BluetoothGattCharacteristic value,
                                                       byte[] bytes, int status) {
                var level = status == BluetoothGatt.GATT_SUCCESS && BATTERY_LEVEL.equals(value.getUuid())
                    && bytes != null && bytes.length == 1 ? levelPercent(bytes[0]) : null;
                complete(level, level == null ? "gattReadFailed" : "ble");
            }

            private void complete(@Nullable Integer level, String outcome) {
                if (close()) readCompleted(this, level, outcome);
            }

            boolean close() {
                BluetoothGatt opened;
                synchronized (this) {
                    if (closed) return false;
                    closed = true;
                    opened = connection;
                    connection = null;
                }
                main.removeCallbacks(deadline);
                if (opened != null) closeGatt(opened);
                return true;
            }
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
