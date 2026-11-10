import '../diagnostics_store.dart';
import '../bridge_result.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'settings_service.dart';

typedef AudioStatus = ({int? percent, bool? muted, bool fixed, String output});
const unknownAudioStatus = (
  percent: null,
  muted: null,
  fixed: false,
  output: 'unknown',
);

/// A bounded refresh for a visible panel; never intercepts volume buttons.
class AudioStatusService extends ChangeNotifier with WidgetsBindingObserver {
  static const _captureRoute = bool.fromEnvironment(
    'CUTE_AUDIO_ROUTE_DIAGNOSTICS',
  );
  final MethodChannel channel;
  final SettingsService? settings;
  Duration _interval;
  Duration get interval => _interval;
  final _owners = <Object>{};
  AudioStatus state = unknownAudioStatus;
  Timer? _timer;
  bool _disposed = false,
      _running = false,
      _foreground = true,
      _screenOn = true;
  bool _again = false;
  int _generation = 0;

  AudioStatusService({
    this.settings,
    this.channel = const BridgeChannel('cutelauncher/audio_status'),
    Duration interval = const Duration(seconds: 3),
  }) : _interval = settings == null
           ? interval
           : Duration(seconds: settings.volumeUpdateInterval) {
    final binding = WidgetsBinding.instance;
    _foreground =
        binding.lifecycleState == null ||
        binding.lifecycleState == AppLifecycleState.resumed;
    binding.addObserver(this);
    settings?.addListener(_settingsChanged);
    channel.setMethodCallHandler((call) async {
      if (call.method != 'changed' || !_enabled || _disposed) return;
      if (call.arguments is bool) _screenOn = call.arguments as bool;
      if (_screenOn) {
        unawaited(refresh());
      } else {
        _timer?.cancel();
        _generation++;
      }
    });
  }

  bool get _enabled => !_disposed && _foreground && _owners.isNotEmpty;
  void _settingsChanged() {
    final next = Duration(seconds: settings!.volumeUpdateInterval);
    if (_disposed || next == _interval) return;
    _interval = next;
    _timer?.cancel();
    // An active request keeps its result and uses the new interval afterwards.
    if (_enabled && _screenOn && !_running) {
      _timer = Timer(interval, refresh);
    }
  }

  void setVisible(Object owner, bool visible) {
    if (_disposed) return;
    final was = _enabled;
    visible ? _owners.add(owner) : _owners.remove(owner);
    if (was != _enabled) _visibilityChanged();
  }

  void _visibilityChanged() {
    _generation++;
    _timer?.cancel();
    unawaited(_watch(_enabled));
    if (_enabled) {
      _screenOn = true;
      unawaited(refresh());
    }
  }

  Future<void> _watch(bool enabled) async {
    try {
      await channel.invokeMethod<void>('watch', enabled);
    } on PlatformException catch (diagnosticError, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'audioStatusService', diagnosticError, diagnosticStack,
      );
      /* Snapshot can still succeed without notifications. */
    } on MissingPluginException catch (diagnosticError, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'audioStatusService', diagnosticError, diagnosticStack,
      );
      /* Widget tests and unsupported hosts. */
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _foreground || _disposed) return;
    _foreground = foreground;
    _visibilityChanged();
  }

  Future<void> refresh() async {
    if (!_enabled || !_screenOn) return;
    if (_running) {
      _again = true;
      return;
    }
    _timer?.cancel();
    _running = true;
    final generation = _generation;
    try {
      final data = await channel
          .invokeMapMethod<String, dynamic>(
            'snapshot',
            _captureRoute ? true : null,
          )
          .timeout(const Duration(seconds: 3));
      if (_disposed || generation != _generation || !_enabled) return;
      _screenOn = data?['screenOn'] != false;
      if (!_screenOn) return;
      final raw = data?['percent'];
      final percent = raw is int && raw >= 0 && raw <= 100 ? raw : null;
      final outputs = data?['outputs'];
      final output =
          outputs is List && outputs.length == 1 && outputs.single is String
          ? outputs.single as String
          : outputs is List && outputs.length > 1
          ? 'multiple'
          : 'unknown';
      final routeDiagnostics = data?['routeDiagnostics'];
      if (_captureRoute && routeDiagnostics is Map) {
        DiagnosticsStore.instance.recordAudioRouting(routeDiagnostics, output);
      }
      final next = (
        percent: data?['fixed'] == true ? null : percent,
        muted: data?['muted'] is bool ? data!['muted'] as bool : null,
        fixed: data?['fixed'] == true,
        output: output,
      );
      _setState(next);
    } on Object catch (diagnosticError, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'audioStatusService', diagnosticError, diagnosticStack,
      );
      if (!_disposed && generation == _generation && _enabled) {
        _setState(unknownAudioStatus);
      }
    } finally {
      _running = false;
      if (_enabled && _screenOn) {
        if (_again || generation != _generation) {
          _again = false;
          unawaited(refresh());
        } else {
          _timer = Timer(interval, refresh);
        }
      } else {
        _again = false;
      }
    }
  }

  void _setState(AudioStatus next) {
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
    settings?.removeListener(_settingsChanged);
    WidgetsBinding.instance.removeObserver(this);
    channel.setMethodCallHandler(null);
    unawaited(_watch(false));
    super.dispose();
  }
}
