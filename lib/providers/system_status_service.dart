import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'foreground_work.dart';

typedef SystemStatus = ({
  int? cpu,
  int? ramTotal,
  int? ramAvailable,
  int? storageTotal,
  int? storageAvailable,
  int? uptimeMinutes,
  int? temperature,
});
const unknownSystemStatus = (
  cpu: null,
  ramTotal: null,
  ramAvailable: null,
  storageTotal: null,
  storageAvailable: null,
  uptimeMinutes: null,
  temperature: null,
);

double? ramPercent(SystemStatus state) =>
    state.ramTotal == null || state.ramAvailable == null
    ? null
    : 100 * (state.ramTotal! - state.ramAvailable!) / state.ramTotal!;

/// One minute of actual observations. Segment changes prevent lines across pauses.
class SystemHistoryMinute {
  final int minute, segment;
  double _cpuSum = 0, _ramSum = 0;
  int _cpuCount = 0, _ramCount = 0;
  double? cpuPeak, ramPeak;
  SystemHistoryMinute(this.minute, this.segment);
  double? get cpu => _cpuCount == 0 ? null : _cpuSum / _cpuCount;
  double? get ram => _ramCount == 0 ? null : _ramSum / _ramCount;
  void add(SystemStatus state) {
    final cpu = state.cpu?.toDouble(), ram = ramPercent(state);
    if (cpu != null) {
      _cpuSum += cpu;
      _cpuCount++;
      cpuPeak = cpuPeak == null || cpu > cpuPeak! ? cpu : cpuPeak;
    }
    if (ram != null) {
      _ramSum += ram;
      _ramCount++;
      ramPeak = ramPeak == null || ram > ramPeak! ? ram : ramPeak;
    }
  }
}

/// Shared, lazy, bounded sampling for visible panels only; no disk persistence.
class SystemStatusService extends ChangeNotifier with WidgetsBindingObserver {
  final ForegroundWork? work;
  final MethodChannel channel;
  final DateTime Function() now;
  final Duration interval;
  final _owners = <Object>{};
  final _history = <SystemHistoryMinute>[];
  SystemStatus state = unknownSystemStatus;
  List<SystemHistoryMinute> get history => List.unmodifiable(_history);
  Timer? _timer;
  bool _disposed = false,
      _running = false,
      _foreground = true,
      _screenOn = true;
  int _generation = 0;
  bool _resetCpu = true;

  SystemStatusService({
    this.work,
    this.channel = const MethodChannel('cutelauncher/system_status'),
    DateTime Function()? now,
    this.interval = const Duration(seconds: 5),
  }) : now = now ?? DateTime.now {
    final binding = WidgetsBinding.instance;
    _foreground =
        binding.lifecycleState == null ||
        binding.lifecycleState == AppLifecycleState.resumed;
    binding.addObserver(this);
    channel.setMethodCallHandler((call) async {
      if (call.method != 'changed' || !_enabled || call.arguments is! bool) {
        return;
      }
      final screenOn = call.arguments as bool;
      if (screenOn == _screenOn) return;
      _screenOn = screenOn;
      _generation++;
      _resetCpu = true;
      _timer?.cancel();
      work?.cancel(this);
      if (_screenOn) unawaited(refresh());
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
    _resetCpu = true;
    _timer?.cancel();
    work?.cancel(this);
    unawaited(_watch(_enabled));
    if (_enabled) {
      _screenOn = true;
      unawaited(refresh());
    }
  }

  Future<void> _watch(bool enabled) async {
    try {
      await channel.invokeMethod<void>('watch', enabled);
    } on PlatformException {
      /* Snapshot checks screen state too. */
    } on MissingPluginException {
      /* Unsupported host. */
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (_disposed || foreground == _foreground) return;
    _foreground = foreground;
    _visibilityChanged();
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
    final resetCpu = _resetCpu;
    var failed = false;
    try {
      final data = await channel
          .invokeMapMethod<String, dynamic>('snapshot', resetCpu)
          .timeout(const Duration(seconds: 3));
      if (_disposed || generation != _generation || !_enabled) return;
      _screenOn = data?['screenOn'] != false;
      if (!_screenOn) {
        _generation++;
        _resetCpu = true;
        return;
      }
      _resetCpu = false;
      int? integer(String key, {int min = 0, int? max}) {
        final value = data?[key];
        return value is num &&
                value.isFinite &&
                value >= min &&
                (max == null || value <= max)
            ? value.round()
            : null;
      }

      final total = integer('ramTotalBytes', min: 1),
          disk = integer('storageTotalBytes', min: 1);
      final next = (
        cpu: integer('cpuPercent', max: 100),
        ramTotal: total,
        ramAvailable: total == null
            ? null
            : integer('ramAvailableBytes', max: total),
        storageTotal: disk,
        storageAvailable: disk == null
            ? null
            : integer('storageAvailableBytes', max: disk),
        uptimeMinutes: integer('uptimeMinutes'),
        temperature: integer('temperatureCelsius', min: -49, max: 199),
      );
      final minute = now().millisecondsSinceEpoch ~/ 60000;
      _history.removeWhere(
        (point) => point.minute < minute - 59 || point.minute > minute,
      );
      if (_history.isNotEmpty &&
          _history.last.minute == minute &&
          _history.last.segment != generation) {
        _history.removeLast();
      }
      final newMinute = _history.isEmpty || _history.last.minute != minute;
      if (newMinute) _history.add(SystemHistoryMinute(minute, generation));
      final point = _history.last;
      final before = (point.cpu, point.ram, point.cpuPeak, point.ramPeak);
      point.add(next);
      final changed =
          state != next ||
          newMinute ||
          before != (point.cpu, point.ram, point.cpuPeak, point.ramPeak);
      state = next;
      if (changed) notifyListeners();
    } on Object {
      failed = true;
      if (!_disposed && generation == _generation && _enabled) {
        _generation++;
        _resetCpu = true;
        if (state != unknownSystemStatus) {
          state = unknownSystemStatus;
          notifyListeners();
        }
      }
    } finally {
      _running = false;
      if (_enabled && _screenOn) {
        _timer = Timer(
          failed || generation == _generation ? interval : Duration.zero,
          refresh,
        );
      }
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _timer?.cancel();
    _owners.clear();
    work?.cancel(this);
    WidgetsBinding.instance.removeObserver(this);
    channel.setMethodCallHandler(null);
    unawaited(_watch(false));
    super.dispose();
  }
}
