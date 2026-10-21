import 'package:flutter/services.dart';
import 'diagnostics_store.dart';

/// A failed operation is distinct from a successful query returning false/empty.
enum BridgeStatus { success, denied, unsupported, error, cancelled }

class BridgeResult<T> {
  final BridgeStatus status;
  final String code;
  final T? value;
  final bool hasResponse;
  const BridgeResult(this.status, this.code, this.value,
      {this.hasResponse = true});
  bool get isSuccess => status == BridgeStatus.success;

  T? unwrap() {
    if (!hasResponse) throw BridgeException(status, code);
    return value;
  }
}

class BridgeException extends PlatformException {
  final BridgeStatus status;
  BridgeException(this.status, String code) : super(code: code);
}

/// Normalizes existing Android contracts without changing their payloads.
/// No exception text or native error details cross this boundary.
class BridgeChannel extends MethodChannel {
  const BridgeChannel(super.name);

  BridgeResult<T> _finish<T>(String method, BridgeResult<T> result) {
    DiagnosticsStore.instance
        .record(name, method, result.status.name, result.code);
    return result;
  }

  static const _booleanActions = {
    'launchActivityFromAction',
    'launchApp',
    'openUrl',
    'openSettings',
    'openScreensaverSettings',
    'openAppInfo',
    'uninstallApp',
    'startAmbientMode',
    'requestWriteSettingsPermission',
    'restoreSystemBrightness',
    'setSystemBrightness',
    'openDefaultLauncherSettings',
    'openWifiSettings',
    'openVpnSettings',
    'launchTvInput',
    'requestNotificationListenerPermission',
    'openAppNotificationSettings',
    'requestOverlayPermission',
    'requestAccessibilityPermission',
    'dismissNotification',
    'dismissAllNotifications',
    'requestWatchNextPermission',
    'deleteWatchNextProgram',
    'launchWatchNextProgram',
    'openBreezyWeather',
  };

  static (BridgeStatus, String) _failure(String code) =>
      switch (code.toLowerCase()) {
        'permission_denied' || 'denied' || 'authorization' || 'permission' => (
            BridgeStatus.denied,
            'permission_denied'
          ),
        'unsupported' ||
        'document_unavailable' ||
        'notimplemented' ||
        'play' =>
          (BridgeStatus.unsupported, 'unsupported'),
        'invalid_argument' || 'invalid' => (
            BridgeStatus.error,
            'invalid_argument'
          ),
        'already_requesting' || 'document_busy' => (BridgeStatus.error, 'busy'),
        'unavailable' ||
        'applications_unavailable' ||
        'memory_unavailable' ||
        'norecovery' =>
          (BridgeStatus.error, 'unavailable'),
        _ => (BridgeStatus.error, 'operation_failed'),
      };

  Future<BridgeResult<T>> invokeResult<T>(String method,
      [dynamic arguments]) async {
    try {
      final raw = await super.invokeMethod<dynamic>(method, arguments);
      var status = BridgeStatus.success;
      var code = 'ok';
      if (_booleanActions.contains(method) && raw != true) {
        status = BridgeStatus.error;
        code = 'operation_failed';
      } else if ((method == 'pickImageDocument' ||
                  method == 'pickCleanerDocument' ||
                  method == 'pickBackupDocument' || method == 'pickWallpaperFolder') &&
              raw == null ||
          method == 'saveBackupDocument' && raw == false) {
        status = BridgeStatus.cancelled;
        code = 'cancelled';
      } else if (name == 'cutelauncher/adb' && method == 'action') {
        final nativeStatus = raw is Map ? raw['status'] : null;
        if (nativeStatus != 'success' && nativeStatus != 'ready') {
          final failure =
              _failure(nativeStatus is String ? nativeStatus : 'invalid');
          status = failure.$1;
          code = failure.$2;
        }
      } else if (name == 'cutelauncher/auto_launch' && method == 'save') {
        final nativeStatus = raw is Map ? raw['status'] : null;
        if (nativeStatus != 'success') {
          final failure = _failure(nativeStatus is String ? nativeStatus : 'invalid');
          status = failure.$1;
          code = failure.$2;
        }
      } else if (name == 'cutelauncher/updates' &&
          method == 'install' &&
          raw != 'launched') {
        final failure = _failure(raw is String ? raw : 'invalid');
        status = failure.$1;
        code = failure.$2;
      }
      return _finish(method, BridgeResult<T>(status, code, raw as T?));
    } on MissingPluginException {
      return _finish(
          method,
          BridgeResult<T>(BridgeStatus.unsupported, 'unsupported', null,
              hasResponse: false));
    } on PlatformException catch (error) {
      final failure = _failure(error.code);
      return _finish(method,
          BridgeResult<T>(failure.$1, failure.$2, null, hasResponse: false));
    } catch (_) {
      return _finish(
          method,
          BridgeResult<T>(BridgeStatus.error, 'invalid_response', null,
              hasResponse: false));
    }
  }

  @override
  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) async =>
      (await invokeResult<T>(method, arguments)).unwrap();
}
