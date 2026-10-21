import 'package:package_info_plus/package_info_plus.dart';

import 'bridge_result.dart';
import 'tv_compatibility_report.dart';

Future<Map<String, Object>> collectTvCompatibility() async {
  const channel = BridgeChannel('me.efesser.flauncher/method');
  // A failed whole snapshot must not look like a completed check.
  final raw = await channel
      .invokeMapMethod('getTvCompatibilityDiagnostics')
      .timeout(const Duration(seconds: 15));
  if (raw == null || raw['identity'] is! Map || raw['checks'] is! Map) {
    throw StateError('Compatibility snapshot unavailable');
  }
  String? version, build;
  try {
    final app = await PackageInfo.fromPlatform();
    version = app.version;
    build = app.buildNumber;
  } catch (_) {
    /* No exception details enter the report. */
  }
  return createTvCompatibilityReport(
    raw,
    capturedAt: DateTime.now(),
    version: version,
    build: build,
  );
}
