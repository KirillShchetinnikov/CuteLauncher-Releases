import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Android owns the alarm; this clock only paints the foreground countdown.
class SleepTimerService extends ChangeNotifier with WidgetsBindingObserver {
  static const channel = MethodChannel('cutelauncher/sleep_timer');
  static const durations = [
    10,
    20,
    30,
    40,
    50,
    60,
    90,
    120,
    180,
    240,
    300,
    360,
  ];
  final Stopwatch _clock = Stopwatch();
  final int Function()? elapsedMilliseconds;
  int _sampledAt = 0;
  int _remainingMs = 0;
  Timer? _ticker;
  bool _foreground = true, _disposed = false, busy = false;
  int _revision = 0;
  bool exactAllowed = true;
  String error = '';

  SleepTimerService({this.elapsedMilliseconds}) {
    _clock.start();
    final binding = WidgetsBinding.instance;
    _foreground =
        binding.lifecycleState == null ||
        binding.lifecycleState == AppLifecycleState.resumed;
    binding.addObserver(this);
  }

  int get _elapsed => elapsedMilliseconds?.call() ?? _clock.elapsedMilliseconds;
  int get remainingSeconds =>
      ((_remainingMs - (_elapsed - _sampledAt)) / 1000).ceil().clamp(0, 21600);
  bool get active => remainingSeconds > 0;
  String get countdown {
    final s = remainingSeconds;
    final minutes = (s ~/ 60 % 60).toString().padLeft(2, '0');
    final seconds = (s % 60).toString().padLeft(2, '0');
    return s >= 3600 ? '${s ~/ 3600}:$minutes:$seconds' : '$minutes:$seconds';
  }

  void _accept(Object? value) {
    if (value is! Map) throw const FormatException('Invalid timer state');
    _remainingMs = (value['remainingMs'] as num?)?.toInt() ?? 0;
    _sampledAt = _elapsed;
    exactAllowed = value['exactAllowed'] == true;
    error = value['error'] as String? ?? '';
    _restartTicker();
    notifyListeners();
  }

  void _restartTicker() {
    _ticker?.cancel();
    _ticker = null;
    if (!_foreground || !active) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!active) {
        _ticker?.cancel();
        _ticker = null;
        refresh();
      }
      notifyListeners();
    });
  }

  Future<void> refresh() async {
    if (_disposed || busy) return;
    final revision = ++_revision;
    try {
      final value = await channel.invokeMethod<Object?>('state');
      if (!_disposed && revision == _revision) _accept(value);
    } catch (_) {
      if (!_disposed && revision == _revision) {
        error = 'unavailable';
        notifyListeners();
      }
    }
  }

  Future<bool> select(int minutes) async {
    if (_disposed || busy || (minutes != 0 && !durations.contains(minutes))) {
      return false;
    }
    return _select(
      minutes == 0 ? 'cancel' : 'start',
      minutes == 0 ? null : {'minutes': minutes},
    );
  }

  Future<bool> selectTestTimer() => _select('startTest', null);

  Future<bool> _select(String method, Map<String, int>? arguments) async {
    if (_disposed || busy) return false;
    busy = true;
    ++_revision;
    notifyListeners();
    try {
      final value = await channel.invokeMethod<Object?>(method, arguments);
      if (_disposed) return false;
      _accept(value);
      return true;
    } catch (e) {
      if (!_disposed) error = e is PlatformException ? e.code : 'unavailable';
      return false;
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> requestExact() async {
    try {
      return await channel.invokeMethod<bool>('requestExact') ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _restartTicker();
    if (_foreground) refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_revision;
    _ticker?.cancel();
    _clock.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
