import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'diagnostic_redactor.dart';
import 'diagnostic_settings.dart';

/// Bounded diagnostics with structured causes and redacted technical excerpts.
class DiagnosticsStore {
  static final instance = DiagnosticsStore();
  static const capacity = 50;
  static const failureCapacity = 100;
  static const _channels = {
    'me.efesser.flauncher/method': 'android',
    'cutelauncher/adb': 'adb',
    'cutelauncher/night': 'night',
    'cutelauncher/updates': 'updates',
    'cutelauncher/auto_launch': 'autoLaunch',
    'cutelauncher/cloud_account': 'cloudAccount',
    'cutelauncher/drive_account': 'driveAccount',
    'cutelauncher/weather_location': 'weatherLocation',
    'cutelauncher/tcl_blue_light': 'tclBlueLight',
    'cutelauncher/remote_buttons': 'remoteButtons',
    'cutelauncher/remote_mappings': 'remoteMappings',
    'cutelauncher/media': 'media',
    'cutelauncher/sleep_timer': 'sleepTimer',
    'cutelauncher/tv_power': 'tvPower',
    'cutelauncher/tv_ime_editor': 'tvImeEditor',
    'cutelauncher/remote_panel': 'remotePanel',
    'dart': 'dart',
  };
  static const _methods = {
    'pickCleanerDocument',
    'getDiagnosticEnvironment',
    'getTvCompatibilityDiagnostics',
    'getProcessMemoryUsage',
    'getApplications',
    'getDiagnosticApplications',
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
    'pickWallpaperDocument',
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
    'actionNotice',
    'cloudTransfer',
    'backupTransfer',
    'driveConnect',
    'getNativeShellDiagnostics',
    'clearNativeShellDiagnostics',
    'framework',
    'unhandled',
    'startup',
    'weatherFetch',
    'weatherInitialize',
    'backgroundVideoValidate',
    'backgroundVideoPlayback',
    'backgroundVideoNative',
    'backgroundVideoRecovery',
    'enableBackgroundVideoCompatibility',
    'getVideoPlaybackLog',
    'weatherParse',
    'updateInitialize',
    'updateCheck',
    'updateDownloadInstall',
    'authorization',
    'batterySettings',
    'cancel',
    'cancelLearn',
    'cities',
    'close',
    'closed',
    'disconnect',
    'editing',
    'fatal',
    'focus',
    'getScreensaverCapabilities',
    'getTrafficUsage',
    'homeOverride',
    'info',
    'invalidate',
    'learn',
    'listWallpaperFolder',
    'locate',
    'next',
    'pause',
    'pickCleanerListDocument',
    'pickWallpaperFolder',
    'pictureMode',
    'play',
    'port',
    'read',
    'readWallpaperFolderImage',
    'ready',
    'reboot',
    'releaseWallpaperFolder',
    'requestExact',
    'save',
    'saveDiagnosticsDocument',
    'set',
    'setNotificationPopupPresentation',
    'show',
    'sleep',
    'snapshot',
    'solarCache',
    'solarRefresh',
    'start',
    'startDuration',
    'startTest',
    'state',
    'status',
    'usagePermission',
  };
  static const _statuses = {
    'success',
    'denied',
    'unsupported',
    'error',
    'cancelled',
  };
  // Values must be fixed protocol enums, never exception messages or payload text.
  static const nativeCodes = {
    'wifiOwned',
    'wifiUnknown',
    'authorization',
    'denied',
    'invalid',
    'noRecovery',
    'changed',
    'unavailable',
    'unsupported',
    'success',
    'ready',
    'permission',
    'launched',
    'play',
    'invalid_argument',
    'permission_denied',
    'PERMISSION_DENIED',
    'document_too_large',
    'document_unavailable',
    'document_busy',
    'already_requesting',
    'applications_unavailable',
    'memory_unavailable',
    'diagnostics_unavailable',
    'operation_failed',
    'noSnapshot',
    'snapshotFailed',
    'partial',
    'failed',
    'cancelled',
  };
  static const adbActions = {
    'appProcessStatus',
    'stopApp',
    'cleanerInventory',
    'cleanerSnapshot',
    'cleanerApply',
    'cleanerRestore',
    'cleanerManualSave',
    'cleanerManualDelete',
    'cleanerManualRestore',
    'cleanerManualExport',
    'check',
    'preview',
    'disableSystem',
    'enableSystem',
    'home',
    'accessibility',
    'disableAccessibility',
    'restoreAccessibility',
    'overlay',
    'notifications',
    'watchNext',
    'usage',
    'writeSettings',
    'restore',
  };
  static const _detailEnums = {
    'recovery': {'enabled', 'unavailable', 'succeeded', 'failed'},
    'availability': {'unsupported'},
    'stage': {
      'connect',
      'dispatch',
      'plan',
      'apply',
      'wifiSafety',
      'verify',
      'rollback',
      'videoInitialize',
      'videoMetadata',
      'videoConfigure',
      'videoPlay',
      'videoPause',
      'videoDispose',
    },
    'command': {
      'wifi_configurations',
      'current_user',
      'shell_identity',
      'resolve_home',
      'query_home',
      'package_state',
      'set_home',
      'settings',
      'appops',
      'notification',
      'permission',
      'process',
      'other',
    },
    'reason': {
      'wifi_owner_setup',
      'wifi_safe',
      'wifi_not_required',
      'wifi_dump_missing',
      'wifi_section_missing',
      'wifi_section_incomplete',
      'wifi_section_duplicate',
      'wifi_no_records',
      'wifi_owner_missing',
      'wifi_owner_invalid',
      'wifi_owner_ambiguous',
      'wifi_query_failed',
      'weather_coordinates',
      'weather_cityNotFound',
      'weather_keyRequired',
      'weather_authorization',
      'weather_rateLimit',
      'weather_unavailable',
      'weather_invalidResponse',
      'video_timeout',
      'video_player',
      'video_metadata',
      'video_resolution',
    },
    'exception': {
      'timeout',
      'connection',
      'io',
      'security',
      'argument',
      'state',
      'format',
      'type',
      'assertion',
      'unsupported',
      'linkage',
      'other',
    },
  };
  static const _codes = {
    'ok',
    'permission_denied',
    'unsupported',
    'invalid_argument',
    'busy',
    'unavailable',
    'operation_failed',
    'document_too_large',
    'invalid_response',
    'cancelled',
  };
  final Stopwatch _clock = Stopwatch()..start();
  int _generation = 0;
  int get generation => _generation;
  final List<Map<String, Object>> _events = [];
  final List<Map<String, Object>> _failures = [];
  final Map<String, int> _counts = {};
  Map<dynamic, dynamic> Function()? settingsProvider;
  final Map<int, Map<String, Object>> _settings = {};
  int _settingsSequence = 0;
  String? _lastSettingsValue;
  int? _lastSettingsId;

  Map<String, Object>? _captureSettings() {
    try {
      final raw = settingsProvider?.call();
      return raw == null ? null : DiagnosticSettings.sanitize(raw);
    } catch (_) {
      return null;
    }
  }

  void record(
    String channel,
    String method,
    String status,
    String code, {
    Map<String, Object?> context = const {},
  }) {
    final scope = _channels[channel];
    if (scope == null) return;
    final safeStatus = _statuses.contains(status) ? status : 'error';
    _counts[safeStatus] = (_counts[safeStatus] ?? 0) + 1;
    final event = <String, Object>{
      'elapsedMs': _clock.elapsedMilliseconds,
      'operation': '$scope.${_methods.contains(method) ? method : 'unknown'}',
      'status': safeStatus,
      'code': _codes.contains(code) ? code : 'operation_failed',
    };
    for (final key in ['action', 'requestedOperation']) {
      if (scope == 'adb' && adbActions.contains(context[key])) {
        event[key] = context[key]!;
      }
    }
    final nativeCode = context['nativeCode'];
    if (nativeCode is String &&
        (nativeCodes.contains(nativeCode) ||
            RegExp(r'^[A-Za-z][A-Za-z0-9_]{0,63}$').hasMatch(nativeCode))) {
      event['nativeCode'] = DiagnosticRedactor.text(nativeCode);
    }
    final duration = context['durationMs'];
    if (duration is int && duration >= 0 && duration <= 86400000) {
      event['durationMs'] = duration;
    }
    final details = context['details'];
    if (details is Map) {
      final safe = <String, Object>{};
      for (final entry in _detailEnums.entries) {
        if (entry.value.contains(details[entry.key])) {
          safe[entry.key] = details[entry.key];
        }
      }
      for (final key in [
        'networkCount',
        'knownOwnerCount',
        'setupOwnerCount',
        'exitCode',
      ]) {
        final value = details[key];
        if (value is int && value >= -1 && value <= 65535) safe[key] = value;
      }
      if (safe.isNotEmpty) event['details'] = safe;
      if (method.startsWith('backgroundVideo')) {
        for (final key in [
          'fileBytes',
          'width',
          'height',
          'durationMs',
          'positionMs',
          'attempt',
        ]) {
          final value = details[key];
          if (value is int && value >= 0 && value <= 9007199254740991) {
            safe[key] = value;
          }
        }
        for (final key in [
          'playing',
          'buffering',
          'initialized',
          'visible',
          'resumed',
        ]) {
          if (details[key] is bool) safe[key] = details[key];
        }
        if (safe.isNotEmpty) event['details'] = safe;
      }
      if (details['shell'] is List) {
        event['shell'] = (details['shell'] as List)
            .take(8)
            .whereType<Map>()
            .map(
              (item) => {
                for (final key in ['command', 'stdout', 'stderr'])
                  if (item[key] is String)
                    key: DiagnosticRedactor.text(item[key] as String),
                if (item['exitCode'] is int) 'exitCode': item['exitCode'],
              },
            )
            .toList();
      }
      if (details['exceptionText'] is String) {
        event['nativeException'] = DiagnosticRedactor.text(
          details['exceptionText'] as String,
        );
      }
    }
    if (safeStatus != 'success' && safeStatus != 'cancelled') {
      for (final key in [
        'arguments',
        'response',
        'errorText',
        'errorDetails',
      ]) {
        if (context.containsKey(key)) {
          event[key] = DiagnosticRedactor.excerpt(context[key]);
        }
      }
    }
    final frames = context['frames'];
    if (frames is List<String>) {
      final safe = frames
          .where(
            (frame) => RegExp(
              r'^(?:package:(?:flauncher|flutter)/[a-zA-Z0-9_/]+\.dart|dart:[a-z_]+)(?::\d{1,7}){1,2}$',
            ).hasMatch(frame),
          )
          .take(12)
          .toList();
      if (safe.isNotEmpty) event['frames'] = safe;
    }
    _events.add(event);
    if (safeStatus != 'success' && safeStatus != 'cancelled') {
      final settings = _captureSettings();
      if (settings != null) {
        final encoded = jsonEncode(settings);
        if (_lastSettingsValue != encoded ||
            !_settings.containsKey(_lastSettingsId)) {
          _lastSettingsId = ++_settingsSequence;
          _lastSettingsValue = encoded;
          _settings[_lastSettingsId!] = {
            'id': _lastSettingsId!,
            'capturedElapsedMs': _clock.elapsedMilliseconds,
            'values': settings,
          };
        }
        event['settingsRef'] = _lastSettingsId!;
      } else {
        event['settingsStatus'] = 'unavailable';
      }
      _failures.add(event);
      if (_failures.length > failureCapacity) _failures.removeAt(0);
    }
    if (_events.length > capacity) _events.removeAt(0);
    final retained = {
      ..._events,
      ..._failures,
    }.map((event) => event['settingsRef']).toSet();
    _settings.removeWhere((id, _) => !retained.contains(id));
  }

  static String exceptionKind(Object error) => switch (error) {
    TimeoutException() => 'timeout',
    SocketException() => 'connection',
    IOException() => 'io',
    FormatException() => 'format',
    ArgumentError() => 'argument',
    StateError() => 'state',
    TypeError() => 'type',
    AssertionError() => 'assertion',
    UnsupportedError() => 'unsupported',
    _ => 'other',
  };

  void recordException(
    String operation,
    Object error,
    StackTrace? stack, {
    String? reason,
  }) {
    record(
      'dart',
      operation,
      'error',
      'operation_failed',
      context: {
        'details': {'exception': exceptionKind(error), 'reason': reason},
        'frames': safeFrames(stack),
        'errorText': error.toString(),
      },
    );
  }

  static List<String> safeFrames(StackTrace? stack) => stack == null
      ? []
      : RegExp(
              r'(?:package:(?:flauncher|flutter)/[a-zA-Z0-9_/]+\.dart|dart:[a-z_]+)(?::\d{1,7}){1,2}',
            )
            .allMatches(stack.toString())
            .take(12)
            .map((m) => m.group(0)!)
            .toList();

  void clear() {
    _generation++;
    _events.clear();
    _failures.clear();
    _counts.clear();
    _settings.clear();
    _lastSettingsId = null;
    _lastSettingsValue = null;
    _clock.reset();
  }

  Map<String, Object> snapshot({
    String? version,
    String? build,
    Map<dynamic, dynamic>? environment,
    Map<dynamic, dynamic>? nativeShell,
    Map<dynamic, dynamic>? memory,
  }) {
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
      'watchNextAllowed',
    ]) {
      final value = environment?[key];
      if (value is bool) system[key] = value;
    }
    final metrics = <String, num>{};
    final device = <String, String>{};
    final rawDevice = environment?['device'];
    if (rawDevice is Map) {
      for (final key in [
        'manufacturer',
        'model',
        'androidRelease',
        'buildId',
      ]) {
        final value = rawDevice[key];
        if (value is String &&
            RegExp(r'^[A-Za-z0-9][A-Za-z0-9 ._()+/-]{0,95}$').hasMatch(value) &&
            !RegExp(r'\b\d{1,3}(?:\.\d{1,3}){3}\b').hasMatch(value)) {
          device[key] = value;
        }
      }
    }
    for (final key in ['pssBytes', 'rssBytes', 'graphicsBytes']) {
      final value = memory?[key];
      if (value is num && value.isFinite && value >= 0 && value <= (1 << 50)) {
        metrics[key] = value;
      }
    }
    return {
      'schemaVersion': 2,
      'privacy': {
        'redaction': 'best_effort',
        'sharing': 'direct_message',
        'automaticUpload': false,
      },
      'scope': 'current_session',
      'sessionElapsedMs': _clock.elapsedMilliseconds,
      'app': {
        'version':
            version != null &&
                RegExp(r'^\d{1,6}(\.\d{1,6}){1,3}$').hasMatch(version)
            ? version
            : 'unknown',
        'build': build != null && RegExp(r'^\d{1,10}$').hasMatch(build)
            ? build
            : 'unknown',
      },
      'system': system,
      'device': device,
      'memory': metrics,
      'settingsAtExport': _captureSettings() ?? {'status': 'unavailable'},
      'settingsSnapshots': jsonDecode(jsonEncode(_settings.values.toList())),
      'operationCounts': Map<String, int>.from(_counts),
      'recentOperations': jsonDecode(jsonEncode(_events)),
      'failures': jsonDecode(jsonEncode(_failures)),
      'nativeShell': {
        for (final key in ['recent', 'failures'])
          key:
              (nativeShell?[key] is List ? nativeShell![key] as List : const [])
                  .take(key == 'recent' ? 30 : 50)
                  .whereType<Map>()
                  .map(
                    (item) => {
                      for (final field in [
                        'command',
                        'stdout',
                        'stderr',
                        'errorText',
                      ])
                        if (item[field] is String)
                          field: DiagnosticRedactor.text(item[field] as String),
                      for (final field in [
                        'exitCode',
                        'elapsedMs',
                        'durationMs',
                      ])
                        if (item[field] is int) field: item[field],
                      if (const {
                        'adb',
                        'recovery',
                        'cleanerRecovery',
                        'sleepTimer',
                        'tvPower',
                        'networkUsage',
                      }.contains(item['source']))
                        'source': item['source'],
                      if (const {'success', 'error'}.contains(item['status']))
                        'status': item['status'],
                      if (_detailEnums['exception']!.contains(
                        item['exception'],
                      ))
                        'exception': item['exception'],
                    },
                  )
                  .toList(),
      },
    };
  }

  String encode(Map<String, Object> report) =>
      const JsonEncoder.withIndent('  ').convert(report);
}
