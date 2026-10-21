import 'dart:convert';

/// Allowlisted, bounded session diagnostics. Never accepts call arguments/payloads.
class DiagnosticsStore {
  static final instance = DiagnosticsStore();
  static const capacity = 50;
  static const _channels = {
    'me.efesser.flauncher/method': 'android',
    'cutelauncher/adb': 'adb',
    'cutelauncher/night': 'night',
    'cutelauncher/updates': 'updates',
  };
  static const _methods = {
    'pickCleanerDocument',
    'getDiagnosticEnvironment',
    'getTvCompatibilityDiagnostics',
    'getProcessMemoryUsage',
    'getApplications',
    'getApplicationIcon',
    'getApplicationBanner',
    'launchApp',
    'launchActivityFromAction',
    'openUrl',
    'openSettings',
    'openScreensaverSettings',
    'openAppInfo',
    'uninstallApp',
    'isDefaultLauncher',
    'checkForGetContentAvailability',
    'startAmbientMode',
    'getActiveNetworkInformation',
    'getDailyDataUsage',
    'getWeeklyDataUsage',
    'getMonthlyDataUsage',
    'checkUsageStatsPermission',
    'requestUsageStatsPermission',
    'checkWriteSettingsPermission',
    'requestWriteSettingsPermission',
    'restoreSystemBrightness',
    'setSystemBrightness',
    'openDefaultLauncherSettings',
    'openWifiSettings',
    'openVpnSettings',
    'getTvInputs',
    'launchTvInput',
    'checkNotificationListenerPermission',
    'requestNotificationListenerPermission',
    'openAppNotificationSettings',
    'getActiveNotifications',
    'dismissNotification',
    'dismissAllNotifications',
    'checkOverlayPermission',
    'requestOverlayPermission',
    'checkAccessibilityPermission',
    'requestAccessibilityPermission',
    'checkWatchNextPermission',
    'requestWatchNextPermission',
    'getWatchNextPrograms',
    'deleteWatchNextProgram',
    'getWatchNextPoster',
    'launchWatchNextProgram',
    'getLatestWeatherData',
    'isBreezyWeatherInstalled',
    'openBreezyWeather',
    'getPackageName',
    'playClickSound',
    'pickImageDocument',
    'pickBackupDocument',
    'saveBackupDocument',
    'saveBackupDownloads',
    'pickBackupFolder',
    'backupFolderOperation',
    'action',
    'configure',
    'permission',
    'notifications',
    'environment',
    'install',
  };
  static const _statuses = {
    'success',
    'denied',
    'unsupported',
    'error',
    'cancelled'
  };
  static const _codes = {
    'ok',
    'permission_denied',
    'unsupported',
    'invalid_argument',
    'busy',
    'unavailable',
    'operation_failed',
    'invalid_response',
    'cancelled'
  };
  final Stopwatch _clock = Stopwatch()..start();
  final List<Map<String, Object>> _events = [];
  final Map<String, int> _counts = {};

  void record(String channel, String method, String status, String code) {
    final scope = _channels[channel];
    if (scope == null) return;
    final safeStatus = _statuses.contains(status) ? status : 'error';
    _counts[safeStatus] = (_counts[safeStatus] ?? 0) + 1;
    _events.add({
      'elapsedMs': _clock.elapsedMilliseconds,
      'operation': '$scope.${_methods.contains(method) ? method : 'unknown'}',
      'status': safeStatus,
      'code': _codes.contains(code) ? code : 'operation_failed',
    });
    if (_events.length > capacity) _events.removeAt(0);
  }

  void clear() {
    _events.clear();
    _counts.clear();
    _clock.reset();
  }

  Map<String, Object> snapshot(
      {String? version,
      String? build,
      Map<dynamic, dynamic>? environment,
      Map<dynamic, dynamic>? memory}) {
    final system = <String, Object>{};
    final api = environment?['androidApi'];
    if (api is int && api >= 1 && api <= 1000) system['androidApi'] = api;
    for (final key in [
      'defaultHome',
      'overlayAllowed',
      'notificationsAllowed',
      'notificationListenerAllowed',
      'accessibilityEnabled',
      'writeSettingsAllowed',
      'watchNextAllowed'
    ]) {
      final value = environment?[key];
      if (value is bool) system[key] = value;
    }
    final metrics = <String, num>{};
    for (final key in ['pssBytes', 'rssBytes', 'graphicsBytes']) {
      final value = memory?[key];
      if (value is num && value.isFinite && value >= 0 && value <= (1 << 50)) {
        metrics[key] = value;
      }
    }
    return {
      'schemaVersion': 1,
      'app': {
        'version': version != null &&
                RegExp(r'^\d{1,6}(\.\d{1,6}){1,3}$').hasMatch(version)
            ? version
            : 'unknown',
        'build': build != null && RegExp(r'^\d{1,10}$').hasMatch(build)
            ? build
            : 'unknown',
      },
      'system': system,
      'memory': metrics,
      'operationCounts': Map<String, int>.from(_counts),
      'recentOperations':
          _events.map((event) => Map<String, Object>.from(event)).toList(),
    };
  }

  String encode(Map<String, Object> report) =>
      const JsonEncoder.withIndent('  ').convert(report);
}
