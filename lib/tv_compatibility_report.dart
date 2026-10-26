import 'diagnostic_redactor.dart';

/// Portable, allowlisted device observations. No functional compatibility claims.
const tvCompatibilityChecks = [
  'androidTv',
  'androidVersion',
  'homeRegistered',
  'defaultHome',
  'homeSelection',
  'overlay',
  'notifications',
  'notificationListener',
  'accessibility',
  'writeSettings',
  'usageStats',
  'watchNext',
  'tvInputs',
  'documentExport',
  'screensaverSelection',
];
const tvCompatibilityStatuses = [
  'available',
  'notGranted',
  'notConfigured',
  'restricted',
  'unsupported',
  'unknown',
];
const tvIdentityFields = [
  'manufacturer',
  'model',
  'device',
  'fingerprint',
  'firmware',
  'android',
  'sdk',
  'abis',
];

/// One shared device/app header for diagnostics and read-only capability checks.
Map<String, Object> combineDiagnosticsReport(
  Map<String, Object> diagnostics,
  Map<String, Object>? compatibility, {
  required DateTime capturedAt,
}) {
  final identity = compatibility?['identity'] as Map? ?? const {};
  final device = <String, Object>{
    ...?diagnostics['device'] as Map<String, Object>?,
  };
  for (final entry in const {
    'manufacturer': 'manufacturer',
    'model': 'model',
    'device': 'codename',
    'fingerprint': 'fingerprint',
    'firmware': 'firmware',
    'android': 'androidRelease',
    'abis': 'abis',
  }.entries) {
    final value = _safeText(identity[entry.key]);
    if (value != null) device[entry.value] = value;
  }
  device['kind'] = compatibility?['kind'] ?? 'unknown';
  final system = <String, Object>{
    ...?diagnostics['system'] as Map<String, Object>?,
  };
  final api = int.tryParse(identity['sdk']?.toString() ?? '');
  if (api != null && api >= 1 && api <= 1000) system['androidApi'] = api;
  final checks = compatibility?['checks'] as Map? ?? const {};
  return {
    ...diagnostics,
    'schemaVersion': 3,
    'reportType': 'diagnostics',
    'capturedAt': capturedAt.toUtc().toIso8601String(),
    'device': device,
    'system': system,
    'privacy': {
      ...?diagnostics['privacy'] as Map<String, Object>?,
      'compatibilityPublication':
          'sendingToAuthorPermitsAnonymizedCompatibilityOnly',
    },
    'compatibility': {
      'scope': 'readOnlyMetadata',
      'status': compatibility == null ? 'unavailable' : 'complete',
      'checks': {
        for (final key in tvCompatibilityChecks)
          key: tvCompatibilityStatuses.contains(checks[key])
              ? checks[key]
              : 'unknown',
      },
    },
  };
}

String? _safeText(dynamic value, {int limit = 512}) =>
    value is String &&
        value.isNotEmpty &&
        value.length <= limit &&
        !RegExp(r'[\x00-\x1f\x7f]').hasMatch(value)
    ? value
    : null;

Map<String, Object> createTvCompatibilityReport(
  Map<dynamic, dynamic> raw, {
  required DateTime capturedAt,
  String? version,
  String? build,
}) {
  final source = raw['identity'] is Map ? raw['identity'] as Map : const {};
  final identity = <String, Object>{};
  for (final key in tvIdentityFields) {
    final value = _safeText(source[key]);
    if (value != null) identity[key] = value;
  }
  final statuses = raw['checks'] is Map ? raw['checks'] as Map : const {};
  final checks = <String, String>{
    for (final key in tvCompatibilityChecks)
      key: tvCompatibilityStatuses.contains(statuses[key])
          ? statuses[key] as String
          : 'unknown',
  };
  final safeVersion =
      version != null && RegExp(r'^[a-zA-Z0-9.+_-]{1,64}$').hasMatch(version)
      ? version
      : 'unknown';
  final safeBuild = build != null && RegExp(r'^\d{1,10}$').hasMatch(build)
      ? build
      : 'unknown';
  return {
    'schemaVersion': 1,
    'reportType': 'tvCompatibility',
    'scope': 'readOnlyMetadata',
    'capturedAt': capturedAt.toUtc().toIso8601String(),
    'kind': ['physical', 'emulator', 'unknown'].contains(raw['kind'])
        ? raw['kind'] as String
        : 'unknown',
    'kindDetection': 'buildMetadata',
    'identity': identity,
    'installedLauncher': {'versionName': safeVersion, 'versionCode': safeBuild},
    'checks': checks,
  };
}

/// Accept only the exported schema when preparing a report for Git.
Map<String, Object> parseTvCompatibilityReport(Map<String, dynamic> report) {
  if (report['schemaVersion'] == 3 && report['reportType'] == 'diagnostics') {
    final compatibility = report['compatibility'];
    if (compatibility is! Map || compatibility['scope'] != 'readOnlyMetadata') {
      throw const FormatException(
        'Missing read-only compatibility observations',
      );
    }
    final device = report['device'] is Map ? report['device'] as Map : const {};
    final app = report['app'] is Map ? report['app'] as Map : const {};
    final system = report['system'] is Map ? report['system'] as Map : const {};
    return parseTvCompatibilityReport({
      'schemaVersion': 1,
      'reportType': 'tvCompatibility',
      'scope': 'readOnlyMetadata',
      'capturedAt': report['capturedAt'],
      'kind': device['kind'],
      'identity': {
        for (final entry in const {
          'manufacturer': 'manufacturer',
          'model': 'model',
          'codename': 'device',
          'fingerprint': 'fingerprint',
          'firmware': 'firmware',
          'androidRelease': 'android',
          'abis': 'abis',
        }.entries)
          entry.value: device[entry.key],
        'sdk': system['androidApi']?.toString(),
      },
      'installedLauncher': {
        'versionName': app['version'],
        'versionCode': app['build'],
      },
      'checks': compatibility['status'] == 'complete'
          ? compatibility['checks']
          : const {},
    });
  }
  if (report['schemaVersion'] != 1 ||
      report['reportType'] != 'tvCompatibility' ||
      report['scope'] != 'readOnlyMetadata') {
    throw const FormatException('Not a read-only TV compatibility report');
  }
  final date = report['capturedAt'];
  final captured = date is String ? DateTime.tryParse(date) : null;
  if (captured == null) throw const FormatException('Invalid report timestamp');
  final app = report['installedLauncher'] is Map
      ? report['installedLauncher'] as Map
      : const {};
  return createTvCompatibilityReport(
    report,
    capturedAt: captured,
    version: app['versionName'] is String ? app['versionName'] as String : null,
    build: app['versionCode'] is String ? app['versionCode'] as String : null,
  );
}

/// Publication boundary: never copies the diagnostic journal, commands or user settings.
Map<String, Object> publicTvCompatibilityReport(Map<String, dynamic> report) {
  final parsed = parseTvCompatibilityReport(report);
  final identity = parsed['identity'] as Map;
  final captured = DateTime.parse(parsed['capturedAt'] as String).toUtc();
  final source = <String, Object>{};
  for (final key in [
    'manufacturer',
    'model',
    'firmware',
    'android',
    'sdk',
    'abis',
  ]) {
    final value = identity[key];
    if (value is String &&
        value.length <= 128 &&
        RegExp(r'^[\p{L}\p{N} ._()+,/-]+$', unicode: true).hasMatch(value) &&
        !RegExp(r'\b\d{1,3}(?:\.\d{1,3}){3}\b').hasMatch(value) &&
        DiagnosticRedactor.text(value) == value) {
      source[key] = value;
    }
  }
  final checks = parsed['checks'] as Map;
  const userStateChecks = {
    'defaultHome',
    'overlay',
    'notifications',
    'notificationListener',
    'accessibility',
    'writeSettings',
    'usageStats',
    'watchNext',
  };
  return createTvCompatibilityReport(
    {
      'identity': source,
      'kind': parsed['kind'],
      'checks': {
        for (final key in tvCompatibilityChecks)
          // Grant/setup state belongs to the sender; it does not prove functional compatibility.
          key:
              ['notGranted', 'notConfigured'].contains(checks[key]) ||
                  userStateChecks.contains(key) && checks[key] == 'available'
              ? 'unknown'
              : checks[key],
      },
    },
    capturedAt: DateTime.utc(captured.year, captured.month, captured.day),
    version: (parsed['installedLauncher'] as Map)['versionName'] as String?,
    build: (parsed['installedLauncher'] as Map)['versionCode'] as String?,
  );
}
