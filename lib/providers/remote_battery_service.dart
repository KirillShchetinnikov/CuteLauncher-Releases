import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../bridge_result.dart';
import '../diagnostics_store.dart';
import 'foreground_work.dart';

typedef RemoteBatteryDevice = ({String id, String name, String? address});

/// One bounded read for the enabled widgets in this Flutter engine.
class RemoteBatteryService extends ChangeNotifier with WidgetsBindingObserver {
  final MethodChannel channel;
  final ForegroundWork? work;
  final Duration interval;
  final _owners = <Object>{};
  Timer? _timer;
  bool _disposed = false, _foreground = true, _screenOn = true;
  bool _reading = false, _readAgain = false;
  int _generation = 0;
  int? _percent;
  bool? _bluetoothPermission;
  List<RemoteBatteryDevice> _devices = const [];
  String? _selectedId, _selectedName, _activeId;
  bool _selectedUnavailable = false;

  int? get percent => _percent;
  bool? get bluetoothPermission => _bluetoothPermission;
  List<RemoteBatteryDevice> get devices => _devices;
  String? get selectedId => _selectedId;
  String? get selectedName => _selectedName;
  bool get selectedUnavailable => _selectedUnavailable;
  RemoteBatteryDevice? get activeDevice =>
      _devices.where((device) => device.id == _activeId).firstOrNull;

  RemoteBatteryService({
    this.channel = const BridgeChannel('cutelauncher/remote_battery'),
    this.work,
    this.interval = const Duration(minutes: 5),
  }) {
    final binding = WidgetsBinding.instance;
    _foreground =
        binding.lifecycleState == null ||
        binding.lifecycleState == AppLifecycleState.resumed;
    binding.addObserver(this);
    channel.setMethodCallHandler((call) async {
      if (call.method != 'changed' || !_active) return;
      if (call.arguments case final bool screenOn) _screenOn = screenOn;
      if (_screenOn) {
        _generation++;
        _schedule();
      } else {
        _cancel();
        _setPercent(null);
      }
    });
  }

  bool get _active => !_disposed && _foreground && _owners.isNotEmpty;
  bool get _canRead => _active && _screenOn;

  void setVisible(Object owner, bool visible) {
    if (_disposed) return;
    final wasActive = _active;
    visible ? _owners.add(owner) : _owners.remove(owner);
    if (wasActive != _active) _updateWatch();
  }

  void _updateWatch() {
    _cancel();
    unawaited(_watch(_active));
    if (_active) {
      _screenOn = true;
      _schedule();
    }
  }

  void _cancel() {
    _generation++;
    _readAgain = false;
    _timer?.cancel();
    work?.cancel(this);
  }

  Future<void> _watch(bool enabled) async {
    try {
      await channel.invokeMethod<void>('watch', enabled);
    } on Object catch (error, stack) {
      DiagnosticsStore.instance.recordException('remoteBattery', error, stack);
    }
  }

  Future<void> refreshBluetoothPermission() async {
    try {
      final granted = await channel.invokeMethod<bool>('bluetoothPermission');
      if (_disposed || granted == _bluetoothPermission) return;
      _bluetoothPermission = granted;
      notifyListeners();
      if (granted == true) _schedule();
    } on Object catch (error, stack) {
      DiagnosticsStore.instance.recordException('remoteBattery', error, stack);
    }
  }

  Future<void> requestBluetoothPermission() async {
    try {
      await channel.invokeMethod<void>('requestBluetoothPermission');
      await refreshBluetoothPermission();
    } on Object catch (error, stack) {
      DiagnosticsStore.instance.recordException('remoteBattery', error, stack);
    }
  }

  Future<bool> selectDevice(RemoteBatteryDevice? device) async {
    try {
      final saved = await channel.invokeMethod<bool>(
        'selectDevice',
        device?.id,
      );
      if (_disposed || saved != true) return false;
      if (_selectedId != device?.id) {
        _selectedId = device?.id;
        _selectedName = device?.name;
        _activeId = null;
        _selectedUnavailable = false;
        _generation++;
        _setPercent(null, detailsChanged: true);
        _schedule();
      }
      return true;
    } on Object catch (error, stack) {
      DiagnosticsStore.instance.recordException('remoteBattery', error, stack);
      return false;
    }
  }

  void _schedule() {
    if (!_canRead) return;
    _timer?.cancel();
    if (_reading) {
      _readAgain = true;
    } else if (work case final work?) {
      unawaited(work.schedule(this, _sample, priority: -1));
    } else {
      _timer = Timer(const Duration(milliseconds: 150), _sample);
    }
  }

  Future<void> _sample() async {
    if (!_canRead || _reading) return;
    _reading = true;
    final generation = _generation;
    try {
      final data = await channel
          .invokeMapMethod<String, dynamic>('snapshot')
          .timeout(const Duration(seconds: 8));
      if (!_canRead || generation != _generation) return;
      _screenOn = data?['screenOn'] != false;
      final raw = data?['percent'];
      _setPercent(
        _screenOn && raw is int && raw >= 0 && raw <= 100 ? raw : null,
        detailsChanged: _updateDevices(data),
      );
    } on Object catch (error, stack) {
      DiagnosticsStore.instance.recordException('remoteBattery', error, stack);
      if (_canRead && generation == _generation) _setPercent(null);
    } finally {
      _reading = false;
      if (_canRead) {
        if (_readAgain) {
          _readAgain = false;
          _schedule();
        } else {
          _timer = Timer(interval, _schedule);
        }
      }
    }
  }

  bool _updateDevices(Map<String, dynamic>? data) {
    if (data == null || data['devices'] is! List) return false;
    final devices =
        <RemoteBatteryDevice>[
          for (final device in data['devices'] as List)
            if (device case {'id': final String id, 'name': final String name})
              (id: id, name: name, address: device['address'] as String?),
        ]..sort((a, b) {
          final byName = a.name.compareTo(b.name);
          return byName == 0 ? a.id.compareTo(b.id) : byName;
        });
    final selected = data['selectedId'] as String?;
    final name = data['selectedName'] as String?;
    final active = data['activeId'] as String?;
    final unavailable = data['batteryRead'] == 'selectedDeviceUnavailable';
    final changed =
        !listEquals(_devices, devices) ||
        _selectedId != selected ||
        _selectedName != name ||
        _activeId != active ||
        _selectedUnavailable != unavailable;
    if (!changed) return false;
    _devices = List.unmodifiable(devices);
    _selectedId = selected;
    _selectedName = name;
    _activeId = active;
    _selectedUnavailable = unavailable;
    return true;
  }

  void _setPercent(int? next, {bool detailsChanged = false}) {
    if (_percent == next && !detailsChanged) return;
    _percent = next;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasActive = _active;
    _foreground = state == AppLifecycleState.resumed;
    if (wasActive != _active) {
      if (!_active) _setPercent(null);
      _updateWatch();
    }
    if (_foreground && _bluetoothPermission != null) {
      unawaited(refreshBluetoothPermission());
    }
  }

  @override
  void dispose() {
    if (_active) unawaited(_watch(false));
    _disposed = true;
    _cancel();
    _owners.clear();
    channel.setMethodCallHandler(null);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
