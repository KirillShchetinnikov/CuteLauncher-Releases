import 'package:flutter/widgets.dart';

import '../bridge_result.dart';
import 'service_lifecycle.dart';
import 'foreground_work.dart';

class ScreensaverCapabilities {
  final bool canChoose;
  final bool canStart;
  const ScreensaverCapabilities({
    this.canChoose = false,
    this.canStart = false,
  });

  factory ScreensaverCapabilities.fromNative(Object? value) => value is Map
      ? ScreensaverCapabilities(
          canChoose: value['canChoose'] == true,
          canStart: value['canStart'] == true,
        )
      : const ScreensaverCapabilities();
}

/// Device capabilities are refreshed on resume, never saved in a backup.
class ScreensaverService extends ChangeNotifier
    with WidgetsBindingObserver, ServiceLifecycle {
  static const _channel = BridgeChannel('me.efesser.flauncher/method');
  ScreensaverCapabilities _capabilities = const ScreensaverCapabilities();
  int _generation = 0;
  final ForegroundWork? work;
  ScreensaverCapabilities get capabilities => _capabilities;

  ScreensaverService({this.work}) {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> refresh() async {
    if (work != null) return work!.schedule(this, _refresh, maxAge: const Duration(seconds: 10));
    return _refresh();
  }

  Future<void> _refresh() async {
    if (isDisposed) return;
    final generation = ++_generation;
    final result = await _channel.invokeResult<Object?>(
      'getScreensaverCapabilities',
    );
    if (isDisposed || generation != _generation) return;
    final next = ScreensaverCapabilities.fromNative(
      result.isSuccess ? result.value : null,
    );
    if (next.canChoose != _capabilities.canChoose ||
        next.canStart != _capabilities.canStart) {
      _capabilities = next;
      notifyListeners();
    }
  }

  Future<bool> openSettings() async {
    if (work != null) await _refresh();
    if (isDisposed || !_capabilities.canChoose) return false;
    final result = await _channel.invokeResult<bool>('openScreensaverSettings');
    if (!result.isSuccess) await _refresh();
    return result.isSuccess;
  }

  Future<bool> startAmbientMode() async {
    if (work != null) await _refresh();
    if (isDisposed || !_capabilities.canStart) return false;
    final result = await _channel.invokeResult<bool>('startAmbientMode');
    if (!result.isSuccess) await _refresh();
    return result.isSuccess;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  @override
  void dispose() {
    work?.cancel(this);
    WidgetsBinding.instance.removeObserver(this);
    ++_generation;
    super.dispose();
  }
}
