import 'night_mode_configuration.dart';
export 'night_mode_configuration.dart';
import 'package:flauncher/bridge_result.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const nightModeKey = 'night_mode_configuration';

class NightModeService extends ChangeNotifier with WidgetsBindingObserver {
  final SharedPreferences preferences;
  final bool remotePanel;
  bool _presentationReady = false;
  bool _panelInitialReadComplete = false;
  bool _foregroundExcluded = false;
  NightModeConfiguration configuration;
  StreamSubscription<dynamic>? _visibility;
  Timer? _timer;
  Timer? _nativeCheck;
  Timer? _pictureCheck;
  bool _active = false;
  double intensity = 0;
  bool overlayPermission = false;
  bool overlayPermissionKnown = false;
  bool notificationsAllowed = false;
  bool? batteryExempt;
  bool batterySettingsUnavailable = false;
  bool usagePermission = false;
  bool localExcluded = false;
  int? pictureMode;
  bool pictureModeKnown = false;
  bool _foreground = true;
  bool get pictureModeExcluded =>
      pictureMode != null && configuration.ignoredPictureModes.contains(pictureMode);

  Future<void> refreshPictureMode() async {
    final previous = (pictureMode, pictureModeKnown);
    try {
      final mode = await _channel.invokeMethod<int>('pictureMode');
      if (_disposed) return;
      pictureMode = mode != null && mode >= 0 && mode <= 255 ? mode : null;
    } catch (_) {
      if (_disposed) return;
      pictureMode = null;
    }
    pictureModeKnown = true;
    if ((pictureMode, pictureModeKnown) != previous) notifyListeners();
  }

  bool systemFilter = false;
  bool _nativeRunning = false;
  bool _disposed = false;
  bool _configuring = true;
  Future<void> _operation = Future.value();
  Future<void>? _pendingOperation;
  NightModeConfiguration? _pendingConfiguration;
  bool get localFilter =>
      !remotePanel && active && !systemFilter &&
      !(_configuring && overlayPermission);
  bool get panelFilter => remotePanel && _presentationReady && active;
  /// The first frame must use both current configuration and resolved exclusions.
  bool get panelPresentationReady => !remotePanel ||
      _panelInitialReadComplete && _presentationReady;

  Future<Map<String, dynamic>> locate() async =>
      await const BridgeChannel('cutelauncher/weather_location')
          .invokeMapMethod<String, dynamic>('locate') ??
      (throw StateError('Location unavailable'));
  bool tclFilterAvailable = false;
  bool tclFilterEnabled = false;
  bool tclFilterBusy = false;
  String? tclFilterStatus;
  List<Map<String, dynamic>> solarDays = [];
  bool solarLoading = false;
  int solarUpdated = 0;
  DateTime? get nextStart =>
      configuration.nextBoundary(DateTime.now(), true,
          solarDays: solarDays, skipStartedTransition: true);
  DateTime? get nextEnd =>
      configuration.nextBoundary(DateTime.now(), false, solarDays: solarDays);

  Future<List<Map<String, dynamic>>> searchCities(
      String query, String language) async {
    final result = await _channel.invokeListMethod<dynamic>(
        'cities', {'query': query, 'language': language});
    return (result ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> refreshSolar() async {
    await _readNativeStatus('solarRefresh');
    _scheduleNativeCheck();
  }

  Future<void> temporaryMode(bool enabled) async {
    final start = nextStart;
    final end = nextEnd;
    // Hand control back as soon as the schedule takes over the manual state.
    // A transition already in progress still belongs to the skipped night.
    final until = start == null
        ? end
        : end == null || start.isBefore(end)
            ? start
            : end;
    if (until == null) return;
    await configure(configuration.copyWith(
        enabled: true,
        overrideMode: enabled ? 'on' : 'off',
        overrideUntil: until.millisecondsSinceEpoch));
  }

  Future<void> clearTemporaryMode() =>
      configure(configuration.copyWith(overrideMode: 'none', overrideUntil: 0));
  static const _tclChannel = BridgeChannel('cutelauncher/tcl_blue_light');

  Future<void> refreshTclFilter() => _tclFilterOperation(null);
  Future<void> setTclFilter(bool enabled) async {
    await _tclFilterOperation(enabled);
    if (_disposed || tclFilterStatus != 'success') return;
    if (configuration.scheduled && configuration.tclScheduled) {
      final until = (enabled ? nextEnd : nextStart) ??
          DateTime.now().add(const Duration(days: 1));
      await configure(configuration.copyWith(
          tclOverrideMode: enabled ? 'on' : 'off',
          tclOverrideUntil: until.millisecondsSinceEpoch));
    }
  }

  Future<void> _tclFilterOperation(bool? enabled) async {
    if (_disposed || tclFilterBusy) return;
    tclFilterBusy = true;
    notifyListeners();
    try {
      final result = await _tclChannel.invokeMapMethod<String, dynamic>(
          enabled == null ? 'status' : 'set',
          enabled == null ? null : {'enabled': enabled});
      if (_disposed) return;
      tclFilterStatus = result?['status'] as String? ?? 'unsupported';
      if (tclFilterStatus == 'success' && result?['enabled'] is bool) {
        tclFilterAvailable = true;
        tclFilterEnabled = result!['enabled'] as bool;
      } else {
        tclFilterAvailable = false;
        if (tclFilterStatus == 'success') tclFilterStatus = 'error';
      }
    } catch (_) {
      if (!_disposed) {
        tclFilterAvailable = false;
        tclFilterStatus = 'unsupported';
      }
    } finally {
      if (!_disposed) {
        tclFilterBusy = false;
        notifyListeners();
      }
    }
  }

  static const _channel = BridgeChannel('cutelauncher/night');
  bool get active => _active &&
      !(remotePanel ? _foregroundExcluded : localExcluded) && !pictureModeExcluded;
  NightModeService(this.preferences, {this.remotePanel = false})
    : configuration = NightModeConfiguration.decode(
        preferences.getString(nightModeKey),
      ) {
    WidgetsBinding.instance.addObserver(this);
    _visibility = EventChannel(remotePanel
        ? 'cutelauncher/night_panel_state' : 'cutelauncher/night_visibility')
        .receiveBroadcastStream()
        .listen((visible) {
          if (_disposed) return;
          final previous = (systemFilter, _presentationReady, _foregroundExcluded, _configuring);
          if (remotePanel && visible is Map) {
            _presentationReady = visible['presentationReady'] == true;
            _foregroundExcluded = visible['excluded'] == true;
            systemFilter = visible['visible'] == true;
          } else {
            systemFilter = visible == true;
          }
          if (systemFilter) _configuring = false;
          if ((systemFilter, _presentationReady, _foregroundExcluded, _configuring) != previous) {
            notifyListeners();
          }
        }, onError: (Object _) {});
    _start();
    if (remotePanel) { refreshSystem(); } else { syncSystem(); }
    refreshTclFilter();
  }
  Future<void> syncSystem() async {
    if (_disposed) return;
    // Keep an established fallback until native visibility confirms the handoff.
    _configuring = !localFilter;
    if (!_disposed) notifyListeners();
    await _readNativeStatus('configure', configuration.toJson());
    _scheduleNativeCheck();
    _schedulePictureCheck();
  }

  void _scheduleNativeCheck() {
    if (_disposed) return;
    _nativeCheck?.cancel();
    _nativeCheck = Timer(const Duration(milliseconds: 500), () async {
      await _readNativeStatus('status');
      _configuring = false;
      if (!_disposed) notifyListeners();
      await refreshTclFilter();
      if (!_disposed && solarLoading) _scheduleNativeCheck();
    });
  }

  void _schedulePictureCheck() {
    _pictureCheck?.cancel();
    if (_disposed || !_foreground || !_active ||
        configuration.ignoredPictureModes.isEmpty) { return; }
    _pictureCheck = Timer(const Duration(seconds: 2), () async {
      await refreshPictureMode();
      _schedulePictureCheck();
    });
  }

  Future<void> _readNativeStatus(String method,
      [Map<String, dynamic>? arguments]) async {
    if (_disposed) return;
    try {
      if (configuration.ignoredPictureModes.isNotEmpty) { await refreshPictureMode(); }
      final result =
          await _channel.invokeMapMethod<String, dynamic>(method, arguments);
      if (_disposed) return;
      overlayPermissionKnown = result?['permission'] is bool;
      overlayPermission = result?['permission'] == true;
      notificationsAllowed = result?['notifications'] == true;
      batteryExempt = result?['batteryExempt'] is bool
          ? result!['batteryExempt'] as bool : null;
      usagePermission = result?['usagePermission'] == true;
      localExcluded = result?['localExcluded'] == true;
      if (remotePanel) {
        _presentationReady = result?['presentationReady'] == true;
        _foregroundExcluded = result?['excluded'] == true;
      }
      systemFilter = overlayPermission && result?['visible'] == true;
      _nativeRunning = result?['running'] == true;
      solarLoading = result?['solarLoading'] == true;
      solarUpdated =
          result?['solarUpdated'] is int ? result!['solarUpdated'] as int : 0;
      if (result?['solarDays'] is List) {
        solarDays = (result!['solarDays'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      _tick();
      notifyListeners();
    } catch (_) {
      if (!_disposed) {
        systemFilter = false;
        _nativeRunning = false;
        overlayPermission = false;
        overlayPermissionKnown = false;
        batteryExempt = null;
        localExcluded = false;
        _presentationReady = false;
        notifyListeners();
      }
    }
  }

  Future<String> openBatterySettings({Map<String, Object>? guide, bool withoutOverlay = false}) async {
    var status = 'unavailable';
    try {
      status = await _channel.invokeMethod<String>('batterySettings', {
        'guide': guide, 'withoutOverlay': withoutOverlay,
      }) ?? 'unavailable';
      if (_disposed) return status;
      batterySettingsUnavailable = status != 'opened' && status != 'hintRequired';
    } catch (_) {
      if (_disposed) return status;
      batterySettingsUnavailable = true;
    }
    notifyListeners();
    return status;
  }

  Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod<void>('permission');
    } catch (_) {}
  }

  Future<void> requestUsagePermission() async {
    try {
      await _channel.invokeMethod<void>('usagePermission');
    } catch (_) {}
  }

  Future<void> requestNotificationPermission() async {
    try {
      await _channel.invokeMethod<void>('notifications');
      await syncSystem();
    } catch (_) {}
  }

  Future<void> refreshSystem() async {
    final previous = jsonEncode(configuration.toJson());
    await preferences.reload();
    if (_disposed) return;
    configuration =
        NightModeConfiguration.decode(preferences.getString(nightModeKey));
    _tick();
    if (remotePanel) {
      await _readNativeStatus('status');
      if (_disposed) return;
      _panelInitialReadComplete = true;
      notifyListeners();
      _schedulePictureCheck();
    } else if (jsonEncode(configuration.toJson()) != previous) {
      await syncSystem();
    } else {
      await _readNativeStatus('status');
      if (_disposed) return;
      // Recover a service stopped by Android, without reapplying a healthy one
      // on every short return to Home.
      if (configuration.enabled && !_nativeRunning &&
          (overlayPermission || configuration.tclScheduled || !overlayPermissionKnown)) {
        await syncSystem();
      }
      _schedulePictureCheck();
    }
    await refreshTclFilter();
  }

  void _tick() {
    final level = configuration.intensityAt(
      DateTime.now(),
      solarDays: solarDays,
    );
    final next = level > 0;
    if (next != _active || level != intensity) {
      intensity = level;
      _active = next;
      _schedulePictureCheck();
      notifyListeners();
    }
  }

  void _start() {
    _timer?.cancel();
    _tick();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _tick();
      _readNativeStatus('status');
      refreshTclFilter();
    });
  }

  Future<void> configure(NightModeConfiguration value) async {
    if (_disposed) return;
    final encoded = jsonEncode(value.toJson());
    if (jsonEncode(NightModeConfiguration.decode(encoded).toJson()) != encoded) {
      throw ArgumentError('Invalid night mode');
    }
    _pendingConfiguration = value;
    if (_pendingOperation != null) return _pendingOperation!;
    // One running apply and one replaceable pending snapshot. All callers of
    // the pending operation await the final snapshot, including its failures.
    final next = _operation.then((_) {
      final latest = _pendingConfiguration!;
      _pendingConfiguration = null;
      _pendingOperation = null;
      return _configure(latest);
    });
    _pendingOperation = next;
    _operation = next.catchError((Object _) {});
    return next;
  }

  Future<void> _configure(NightModeConfiguration value) async {
    if (_disposed) return;
    final encoded = jsonEncode(value.toJson());
    await preferences.setString(nightModeKey, encoded);
    if (_disposed) return;
    configuration = value;
    _tick();
    notifyListeners();
    try {
      await syncSystem();
    } finally {
      if (!overlayPermission) _configuring = false;
      if (!_disposed) notifyListeners();
    }
  }

  void reload() {
    configuration =
        NightModeConfiguration.decode(preferences.getString(nightModeKey));
    _tick();
    notifyListeners();
    syncSystem();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _start();
      refreshSystem();
    } else {
      _timer?.cancel();
      _timer = null;
      _nativeCheck?.cancel();
      _nativeCheck = null;
      _pictureCheck?.cancel();
      _pictureCheck = null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _nativeCheck?.cancel();
    _pictureCheck?.cancel();
    _visibility?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class NightModeFilter extends StatelessWidget {
  final Widget child;
  final NightModeService? service;
  const NightModeFilter({super.key, required this.child, this.service});
  @override
  Widget build(BuildContext context) {
    final night = service;
    if (night != null && night.remotePanel) {
      // Transform painted pixels only: fullscreen color layers would also tint HDMI.
      // Keep the wrapper mounted so changing exclusions preserves Navigator/focus.
      final intensity = night.panelFilter ? night.intensity : 0.0;
      final dim = night.configuration.dim / 100 * intensity;
      final warm = night.configuration.warmth / 100 * intensity;
      final scale = (1 - warm) * (1 - dim);
      final tint = warm * (1 - dim);
      final color = night.configuration.filterColor;
      return ColorFiltered(
        colorFilter: ColorFilter.matrix([
          scale, 0, 0, 0, color.r * 255 * tint,
          0, scale, 0, 0, color.g * 255 * tint,
          0, 0, scale, 0, color.b * 255 * tint,
          0, 0, 0, 1, 0,
        ]),
        child: child,
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (service?.localFilter == true)
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _AnimatedNightLayer(
                    color: service!.configuration.filterColor.withValues(
                      alpha:
                          service!.configuration.warmth /
                          100 *
                          service!.intensity,
                    ),
                  ),
                  _AnimatedNightLayer(
                    color: const Color(0xFF000000).withValues(
                      alpha:
                          service!.configuration.dim / 100 * service!.intensity,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AnimatedNightLayer extends StatelessWidget {
  final Color color;
  const _AnimatedNightLayer({required this.color});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<Color?>(
    tween: ColorTween(begin: color, end: color),
    duration: const Duration(milliseconds: 180),
    builder: (_, value, _) => ColoredBox(color: value!),
  );
}
