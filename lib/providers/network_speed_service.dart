import '../diagnostics_store.dart';
import '../bridge_result.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'foreground_work.dart';
import 'settings_service.dart';

typedef NetworkSpeed = ({int? received, int? sent});
const unknownNetworkSpeed = (received: null, sent: null);

/// One bounded sampling loop shared by visible panels and their menus.
class NetworkSpeedService extends ChangeNotifier with WidgetsBindingObserver {
  final MethodChannel channel;
  final ForegroundWork? work;
  final SettingsService? settings;
  final _owners = <Object>{};
  NetworkSpeed state = unknownNetworkSpeed;
  Timer? _timer;
  ({int rx, int tx, int elapsed})? _previous;
  int _seconds, _generation = 0;
  bool _disposed = false,
      _running = false,
      _foreground = true,
      _screenOn = true;

  NetworkSpeedService({
    this.channel = const BridgeChannel('cutelauncher/network_speed'),
    this.work,
    this.settings,
    int seconds = 3,
  }) : _seconds = (settings?.networkSpeedInterval ?? seconds).clamp(1, 10) {
    final binding = WidgetsBinding.instance;
    _foreground =
        binding.lifecycleState == null ||
        binding.lifecycleState == AppLifecycleState.resumed;
    binding.addObserver(this);
    settings?.addListener(_settingsChanged);
    channel.setMethodCallHandler((call) async {
      if (call.method != 'changed' || !_enabled || call.arguments is! bool) {
        return;
      }
      final on = call.arguments as bool;
      if (on == _screenOn) return;
      _screenOn = on;
      _restart();
    });
  }

  bool get _enabled => !_disposed && _foreground && _owners.isNotEmpty;
  void _settingsChanged() {
    final seconds = settings?.networkSpeedInterval;
    if (seconds != null) setInterval(seconds);
  }

  void setInterval(int seconds) {
    final next = seconds.clamp(1, 10);
    if (_disposed || _seconds == next) return;
    _seconds = next;
    _restart();
  }

  void setVisible(Object owner, bool visible) {
    if (_disposed) return;
    final before = _enabled;
    visible ? _owners.add(owner) : _owners.remove(owner);
    if (before == _enabled) return;
    _screenOn = true;
    unawaited(_watch(_enabled));
    _restart();
  }

  void _restart() {
    _generation++;
    _previous = null;
    _timer?.cancel();
    work?.cancel(this);
    // Owners may be removed during widget disposal; publish on the next sample.
    if (_enabled && _screenOn) unawaited(refresh());
  }

  Future<void> _watch(bool enabled) async {
    try {
      await channel.invokeMethod<void>('watch', enabled);
    } on PlatformException catch (diagnosticError, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'networkSpeedService', diagnosticError, diagnosticStack,
      );
      // The snapshot also checks whether the screen is on.
    } on MissingPluginException catch (diagnosticError, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'networkSpeedService', diagnosticError, diagnosticStack,
      );
      // Unsupported host.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (_disposed || foreground == _foreground) return;
    _foreground = foreground;
    _screenOn = true;
    unawaited(_watch(_enabled));
    _restart();
  }

  Future<void> refresh() {
    if (!_enabled || !_screenOn || _running) return Future.value();
    return work?.schedule(this, _refresh, delay: Duration.zero) ?? _refresh();
  }

  Future<void> _refresh() async {
    if (!_enabled || !_screenOn || _running) return;
    _timer?.cancel();
    _running = true;
    final generation = _generation;
    try {
      final data = await channel
          .invokeMapMethod<String, dynamic>('snapshot')
          .timeout(const Duration(seconds: 3));
      if (!_enabled || generation != _generation) return;
      if (data?['screenOn'] == false) {
        _screenOn = false;
        _previous = null;
        _publish(unknownNetworkSpeed);
        return;
      }
      int? counter(String key) {
        final value = data?[key];
        return value is int && value >= 0 ? value : null;
      }

      final rx = counter('rxBytes'),
          tx = counter('txBytes'),
          elapsed = counter('elapsedMs');
      final before = _previous;
      _previous = rx == null || tx == null || elapsed == null
          ? null
          : (rx: rx, tx: tx, elapsed: elapsed);
      final after = _previous;
      if (before == null ||
          after == null ||
          after.elapsed <= before.elapsed ||
          after.rx < before.rx ||
          after.tx < before.tx) {
        _publish(unknownNetworkSpeed);
      } else {
        final duration = after.elapsed - before.elapsed;
        _publish((
          received: ((after.rx - before.rx) * 1000 / duration).round(),
          sent: ((after.tx - before.tx) * 1000 / duration).round(),
        ));
      }
    } on Object catch (diagnosticError, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'networkSpeedService', diagnosticError, diagnosticStack,
      );
      if (_enabled && generation == _generation) {
        _previous = null;
        _publish(unknownNetworkSpeed);
      }
    } finally {
      _running = false;
      if (_enabled && _screenOn) {
        _timer = Timer(
          generation == _generation
              ? Duration(seconds: _seconds)
              : Duration.zero,
          refresh,
        );
      }
    }
  }

  void _publish(NetworkSpeed next) {
    if (state == next) return;
    state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _timer?.cancel();
    _owners.clear();
    work?.cancel(this);
    settings?.removeListener(_settingsChanged);
    WidgetsBinding.instance.removeObserver(this);
    channel.setMethodCallHandler(null);
    unawaited(_watch(false));
    super.dispose();
  }
}
