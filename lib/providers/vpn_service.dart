import '../bridge_result.dart';
import '../diagnostics_store.dart';
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'network_service.dart';
import 'foreground_work.dart';

class VpnClient {
  final String app, name;
  final bool supported, permission, requiresProfile, alwaysOnSupported;
  const VpnClient(
    this.app,
    this.name,
    this.supported,
    this.permission, {
    this.requiresProfile = true,
    this.alwaysOnSupported = false,
  });
}

/// Shared state for both panels. Native preferences also serve the boot job.
/// VPN identifiers are deliberately kept out of diagnostic channel logging.
class VpnService extends ChangeNotifier with WidgetsBindingObserver {
  final NetworkService network;
  final ForegroundWork? work;
  final MethodChannel channel;
  Map<String, dynamic> _state = {};
  bool _disposed = false, _foreground = true, _again = false;
  int _generation = 0;
  Future<void>? _running;
  Timer? _debounce;
  Completer<void>? _confirmationResume;
  bool busy = false, failed = false;
  String result = '';
  late final Future<void> initialLoad;
  VpnService(
    this.network, {
    this.work,
    this.channel = const BridgeChannel('cutelauncher/vpn'),
  }) {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    network.addListener(_networkChanged);
    WidgetsBinding.instance.addObserver(this);
    // First frame and overlay readiness depend only on local configuration/connectivity.
    initialLoad = refresh(identify: false);
    unawaited(initialLoad.then((_) => _networkChanged()));
  }
  bool get active => _state['active'] == true;
  bool get initialized => _state.isNotEmpty;
  bool get statusUnknown => !initialized || failed;
  bool get indicatorVisible => !onlyActive || (active && !statusUnknown);
  String get selected => _state['selected'] as String? ?? '';
  String get target => _state['target'] as String? ?? '';
  String get owner => _state['owner'] as String? ?? '';
  String get profile => _state['profile'] as String? ?? '';
  String get bootApp => _state['bootApp'] as String? ?? '';
  bool get bootEnabled => _state['bootEnabled'] as bool? ?? bootApp.isNotEmpty;
  String get bootMode => _state['bootMode'] as String? ?? 'client';
  String get systemApp => _state['systemApp'] as String? ?? '';
  bool get restartRequired => _state['restartRequired'] == true;
  bool get managed => _state['managed'] == true;
  bool get requiresProfile => _state['requiresProfile'] != false;
  String get startupStatus => _state['startupStatus'] as String? ?? 'idle';
  bool get wake => _state['wake'] == true;
  int get delay => _state['delay'] as int? ?? 5;
  bool get onlyActive => _state['onlyActive'] != false;
  bool get showName => _state['showName'] == true;
  bool get color => _state['color'] != false;
  bool get notify => _state['notify'] != false;
  bool get supported => _state['supported'] == true;
  bool get permission => _state['permission'] == true;
  bool get canRequestPermission => _state['canRequestPermission'] == true;
  bool get canControl => !failed && _state['canControl'] == true;
  List<VpnClient> get clients => [
    for (final row in (_state['clients'] as List? ?? []))
      if (row is Map && row['app'] is String && row['name'] is String)
        VpnClient(
          row['app'] as String,
          row['name'] as String,
          row['supported'] == true,
          row['permission'] == true,
          requiresProfile: row['requiresProfile'] != false,
          alwaysOnSupported: row['alwaysOnSupported'] == true,
        ),
  ];
  String profileFor(String app) =>
      (_state['profiles'] as Map?)?[app] as String? ?? '';
  String name(String app) =>
      clients
          .where((client) => client.app == app)
          .map((client) => client.name)
          .firstOrNull ??
      app;
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void _networkChanged() {
    if (_disposed || !_foreground) return;
    _debounce?.cancel();
    if (work != null) {
      unawaited(work!.schedule(this, () => refresh()));
    } else {
      _debounce = Timer(const Duration(milliseconds: 300), refresh);
    }
  }

  Future<void> refresh({bool identify = true}) {
    if (_disposed || !_foreground) return Future.value();
    if (_running != null) {
      _again = true;
      return _running!;
    }
    return _running = _read(identify).whenComplete(() {
      _running = null;
      if (_again && !_disposed && _foreground) {
        _again = false;
        _networkChanged();
      }
    });
  }

  Future<void> _read(bool identify) async {
    final generation = _generation;
    try {
      final next = await channel.invokeMapMethod<String, dynamic>('snapshot', {
        'identify': identify,
      });
      if (_disposed || generation != _generation) return;
      if (next == null) throw StateError('VPN unavailable');
      if (!failed && const DeepCollectionEquality().equals(_state, next)) {
        return;
      }
      _state = next;
      failed = false;
    } catch (diagnosticError, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'vpnService', diagnosticError, diagnosticStack,
      );
      if (_disposed || generation != _generation) return;
      if (failed) return;
      failed = true;
    }
    _changed();
  }

  Future<bool> save(String key, Object value) async {
    if (busy || _disposed) return false;
    busy = true;
    _changed();
    var ok = false;
    try {
      ok =
          await channel.invokeMethod<bool>('save', {
            'key': key,
            'value': value,
          }) ==
          true;
      await refresh();
    } catch (diagnosticError, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'vpnService', diagnosticError, diagnosticStack,
      );
      ok = false;
    }
    if (!_disposed) {
      busy = false;
      result = ok ? '' : 'failed';
      _changed();
    }
    return ok;
  }

  Future<void> requestPermission(String app) async {
    try {
      await channel.invokeMethod<bool>('permission', {'app': app});
    } catch (diagnosticError, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'vpnService', diagnosticError, diagnosticStack,
      );
      result = 'permission';
      _changed();
    }
  }

  Future<bool> open() async {
    try {
      return await channel.invokeMethod<bool>('open', {'app': target}) == true;
    } catch (diagnosticError, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'vpnService', diagnosticError, diagnosticStack,
      );
      return false;
    }
  }

  Future<String> toggle() async {
    if (busy || _disposed || !canControl) return 'unavailable';
    final app = target, tunnel = profile, up = !active;
    busy = true;
    result = '';
    _changed();
    try {
      result =
          await channel.invokeMethod<String>('command', {
            'app': app,
            'profile': tunnel,
            'up': up,
          }) ??
          'failed';
      if (result == 'sent') {
        result = 'pending';
        var deadline = DateTime.now().add(const Duration(seconds: 15));
        while (!_disposed) {
          if (app == 'com.mantaray.vpn' && !_foreground) {
            await (_confirmationResume ??= Completer<void>()).future;
            if (_disposed) break;
            deadline = DateTime.now().add(const Duration(seconds: 15));
          }
          if (!DateTime.now().isBefore(deadline)) break;
          await Future<void>.delayed(const Duration(milliseconds: 750));
          if (_disposed) break;
          // Happ's no-UI activity briefly pauses the launcher. Resume confirmation afterwards.
          if (!_foreground) continue;
          await refresh();
          if (!failed &&
              (up
                  ? active &&
                        owner == app &&
                        (!requiresProfile || profile == tunnel)
                  : !active)) {
            result = up ? 'connected' : 'disconnected';
            break;
          }
        }
        if (result == 'pending') result = 'failed';
      }
    } catch (diagnosticError, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'vpnService', diagnosticError, diagnosticStack,
      );
      result = 'failed';
    }
    if (!_disposed) {
      busy = false;
      _changed();
    }
    return result;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _generation++;
    _debounce?.cancel();
    if (_foreground) {
      _confirmationResume?.complete();
      _confirmationResume = null;
      if (work == null) {
        refresh();
      } else {
        _networkChanged();
      }
    } else {
      work?.cancel(this);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _confirmationResume?.complete();
    _confirmationResume = null;
    _generation++;
    _debounce?.cancel();
    work?.cancel(this);
    network.removeListener(_networkChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
