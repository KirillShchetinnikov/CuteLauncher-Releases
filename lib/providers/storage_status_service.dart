import '../diagnostics_store.dart';
import '../bridge_result.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'foreground_work.dart';

typedef StorageStatus = ({bool nasSupported, bool nas, bool usb});
const noStorageStatus = (nasSupported: false, nas: false, usb: false);

/// One coalesced snapshot for both panels, only while a visible owner needs it.
class StorageStatusService extends ChangeNotifier with WidgetsBindingObserver {
  final MethodChannel channel;
  final ForegroundWork? work;
  final Duration interval;
  final _owners = <Object>{};
  StorageStatus state = noStorageStatus;
  Timer? _timer;
  bool _disposed = false, _running = false, _again = false;
  bool _foreground = true, _screenOn = true;
  int _generation = 0;

  StorageStatusService({
    this.work,
    this.channel = const BridgeChannel('cutelauncher/storage_status'),
    this.interval = const Duration(seconds: 5),
  }) {
    final binding = WidgetsBinding.instance;
    _foreground =
        binding.lifecycleState == null ||
        binding.lifecycleState == AppLifecycleState.resumed;
    binding.addObserver(this);
    channel.setMethodCallHandler((call) async {
      if (call.method != 'changed' || !_enabled) return;
      _screenOn = call.arguments != false;
      if (_screenOn) {
        _schedule();
      } else {
        _generation++;
        _timer?.cancel();
        work?.cancel(this);
      }
    });
  }
  bool get _enabled => !_disposed && _foreground && _owners.isNotEmpty;
  void setVisible(Object owner, bool visible) {
    if (_disposed) return;
    final was = _enabled;
    visible ? _owners.add(owner) : _owners.remove(owner);
    if (was != _enabled) _visibilityChanged();
  }

  void _visibilityChanged() {
    _generation++;
    _timer?.cancel();
    work?.cancel(this);
    unawaited(_watch(_enabled));
    if (_enabled) {
      _screenOn = true;
      _schedule();
    }
  }

  Future<void> _watch(bool enabled) async {
    try {
      await channel.invokeMethod<void>('watch', enabled);
    } on PlatformException catch (diagnosticError, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'storageStatusService', diagnosticError, diagnosticStack,
      );
      /* Snapshot fallback. */
    } on MissingPluginException catch (diagnosticError, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'storageStatusService', diagnosticError, diagnosticStack,
      );
      /* Unsupported host. */
    }
  }

  void _schedule() {
    if (!_enabled || !_screenOn) return;
    _timer?.cancel();
    if (work == null) {
      // A second engine has no Home queue. Debounce bursts without polling builds.
      _timer = Timer(const Duration(milliseconds: 100), _sample);
    } else {
      unawaited(work!.schedule(this, _sample));
    }
  }

  Future<void> _sample() async {
    if (!_enabled || !_screenOn) return;
    _timer?.cancel();
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    final generation = _generation;
    try {
      final data = await channel
          .invokeMapMethod<String, dynamic>('snapshot')
          .timeout(const Duration(seconds: 3));
      if (!_enabled || generation != _generation) return;
      _screenOn = data?['screenOn'] != false;
      final supported = data?['nasSupported'] == true;
      _setState(
        _screenOn
            ? (
                nasSupported: supported,
                nas: supported && data?['nas'] == true,
                usb: data?['usb'] == true,
              )
            : noStorageStatus,
      );
    } on Object catch (diagnosticError, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'storageStatusService', diagnosticError, diagnosticStack,
      );
      if (_enabled && generation == _generation) _setState(noStorageStatus);
    } finally {
      _running = false;
      if (_enabled && _screenOn) {
        if (_again || generation != _generation) {
          _again = false;
          _schedule();
        } else {
          _timer = Timer(interval, _schedule);
        }
      } else {
        _again = false;
      }
    }
  }

  Future<bool> open(bool nas) async {
    if (_disposed || (nas ? !state.nas : !state.usb)) return false;
    try {
      return await channel.invokeMethod<bool>(nas ? 'openNas' : 'openUsb') ==
          true;
    } on PlatformException catch (diagnosticError, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'storageStatusService', diagnosticError, diagnosticStack,
      );
      return false;
    } on MissingPluginException catch (diagnosticError, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'storageStatusService', diagnosticError, diagnosticStack,
      );
      return false;
    }
  }

  Future<void> prepare(Object owner) async {
    setVisible(owner, true);
    _timer?.cancel();
    await _sample();
  }

  void _setState(StorageStatus next) {
    if (_disposed || state == next) return;
    state = next;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (_disposed || _foreground == foreground) return;
    _foreground = foreground;
    if (!foreground) _setState(noStorageStatus);
    _visibilityChanged();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _timer?.cancel();
    work?.cancel(this);
    _owners.clear();
    WidgetsBinding.instance.removeObserver(this);
    channel.setMethodCallHandler(null);
    unawaited(_watch(false));
    super.dispose();
  }
}
