import 'package:flutter/services.dart';

import 'diagnostics_store.dart';

/// A failed operation is distinct from a successful query returning false/empty.
enum BridgeStatus { success, denied, unsupported, error, cancelled }

class BridgeResult<T> {
  final BridgeStatus status;
  final String code;
  final T? value;
  final bool hasResponse;
  final String? exceptionCode;
  const BridgeResult(
    this.status,
    this.code,
    this.value, {
    this.hasResponse = true,
    this.exceptionCode,
  });
  bool get isSuccess => status == BridgeStatus.success;

  T? unwrap() {
    if (!hasResponse) throw BridgeException(status, exceptionCode ?? code);
    return value;
  }
}

class BridgeException extends PlatformException {
  final BridgeStatus status;
  BridgeException(this.status, String code) : super(code: code);
}

/// Normalizes existing Android contracts without changing their payloads.
/// Error context is redacted separately for diagnostics; legacy return values stay intact.
class BridgeChannel extends MethodChannel {
  final bool preserveErrorCodes;
  const BridgeChannel(super.name, {this.preserveErrorCodes = false});

  BridgeResult<T> _finish<T>(
    String method,
    BridgeResult<T> result, [
    Map<String, Object?> context = const {},
  ]) {
    DiagnosticsStore.instance.record(
      name,
      method,
      result.status.name,
      result.code,
      context: context,
    );
    return result;
  }

  static const _booleanActions = {
    'requestExact',
    'sleep',
    'reboot',
    'port',
    'homeOverride',
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

  static (BridgeStatus, String) _failure(String code) => switch (code
      .toLowerCase()) {
    'document_too_large' => (BridgeStatus.error, 'document_too_large'),
    'permission_denied' ||
    'denied' ||
    'authorization' ||
    'permission' => (BridgeStatus.denied, 'permission_denied'),
    'unsupported' ||
    'document_unavailable' ||
    'notimplemented' ||
    'play' => (BridgeStatus.unsupported, 'unsupported'),
    'invalid_argument' || 'invalid' => (BridgeStatus.error, 'invalid_argument'),
    'already_requesting' || 'document_busy' => (BridgeStatus.error, 'busy'),
    'unavailable' ||
    'applications_unavailable' ||
    'memory_unavailable' ||
    'norecovery' => (BridgeStatus.error, 'unavailable'),
    _ => (BridgeStatus.error, 'operation_failed'),
  };

  Future<BridgeResult<T>> invokeResult<T>(
    String method, [
    dynamic arguments,
  ]) async {
    final timer = Stopwatch()..start();
    final context = <String, Object?>{};
    if (name == 'cutelauncher/adb' && arguments is Map) {
      // Project only fixed action names, never targets, commands or addresses.
      context['action'] = arguments['action'];
      context['requestedOperation'] = arguments['operation'];
    }
    BridgeResult<T> finish(BridgeResult<T> result) {
      context['durationMs'] = timer.elapsedMilliseconds;
      if (!result.isSuccess) context['arguments'] = arguments;
      return _finish(method, result, context);
    }

    try {
      final raw = await super.invokeMethod<dynamic>(method, arguments);
      context['response'] = raw;
      if (raw is Map) {
        context['nativeCode'] = raw['status'];
        context['details'] = raw['diagnostic'];
      } else if (raw is String && name == 'cutelauncher/updates') {
        context['nativeCode'] = raw;
      }
      var status = BridgeStatus.success;
      var code = 'ok';
      if (_booleanActions.contains(method) && raw != true) {
        status = BridgeStatus.error;
        code = 'operation_failed';
      } else if ((method == 'pickImageDocument' ||
                  method == 'pickWallpaperDocument' ||
                  method == 'pickCleanerDocument' ||
                  method == 'pickBackupDocument' ||
                  method == 'pickWallpaperFolder') &&
              raw == null ||
          method == 'saveBackupDocument' && raw == false) {
        status = BridgeStatus.cancelled;
        code = 'cancelled';
      } else if (name == 'cutelauncher/adb' && method == 'action') {
        final nativeStatus = raw is Map ? raw['status'] : null;
        if (nativeStatus != 'success' && nativeStatus != 'ready') {
          final failure = _failure(
            nativeStatus is String ? nativeStatus : 'invalid',
          );
          status = failure.$1;
          code = failure.$2;
        }
      } else if (name == 'cutelauncher/auto_launch' && method == 'save') {
        final nativeStatus = raw is Map ? raw['status'] : null;
        if (nativeStatus != 'success') {
          final failure = _failure(
            nativeStatus is String ? nativeStatus : 'invalid',
          );
          status = failure.$1;
          code = failure.$2;
        }
      } else if (name == 'cutelauncher/updates' &&
          method == 'install' &&
          raw != 'launched') {
        final failure = _failure(raw is String ? raw : 'invalid');
        status = failure.$1;
        code = failure.$2;
      } else if (name == 'cutelauncher/tcl_blue_light' &&
          method == 'status' &&
          raw is Map &&
          raw['status'] == 'unsupported') {
        // A completed capability query on a non-TCL device is not a failure.
        // Keep the native payload so callers still hide the unavailable control.
        context['details'] = {'availability': 'unsupported'};
      } else if (raw is Map &&
          const {
            'denied',
            'authorization',
            'unavailable',
            'unsupported',
            'invalid',
            'failed',
            'error',
            'partial',
            'noSnapshot',
            'noRecovery',
            'changed',
            'wifiOwned',
            'wifiUnknown',
          }.contains(raw['status'])) {
        final failure = _failure(raw['status'] as String);
        status = failure.$1;
        code = failure.$2;
      } else if (raw is Map &&
          raw['error'] is String &&
          (raw['error'] as String).isNotEmpty) {
        context['nativeCode'] = raw['error'];
        final failure = _failure(raw['error'] as String);
        status = failure.$1;
        code = failure.$2;
      }
      return finish(BridgeResult<T>(status, code, raw as T?));
    } on MissingPluginException {
      return finish(
        BridgeResult<T>(
          BridgeStatus.unsupported,
          'unsupported',
          null,
          hasResponse: false,
        ),
      );
    } on PlatformException catch (error) {
      context['nativeCode'] = error.code;
      context['errorText'] = error.message;
      context['errorDetails'] = error.details;
      final failure = _failure(error.code);
      return finish(
        BridgeResult<T>(
          failure.$1,
          failure.$2,
          null,
          hasResponse: false,
          exceptionCode: preserveErrorCodes ? error.code : null,
        ),
      );
    } catch (error, stack) {
      context['errorText'] = error.toString();
      context['details'] = {'exception': DiagnosticsStore.exceptionKind(error)};
      context['frames'] = DiagnosticsStore.safeFrames(stack);
      return finish(
        BridgeResult<T>(
          BridgeStatus.error,
          'invalid_response',
          null,
          hasResponse: false,
        ),
      );
    }
  }

  @override
  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) async =>
      (await invokeResult<T>(method, arguments)).unwrap();
}
