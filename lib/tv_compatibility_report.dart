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
