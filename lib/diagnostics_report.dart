import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'document_files.dart';
import 'bridge_result.dart';
import 'diagnostics_store.dart';
import 'background_video_diagnostics.dart';
import 'tv_compatibility_report.dart';

Future<String?> saveDiagnosticsReport(Map<String, Object> report) async {
  final directory = await (await getTemporaryDirectory()).createTemp(
    'diagnostics-',
  );
  try {
    final file = File('${directory.path}/report.json');
    await file.writeAsString(DiagnosticsStore.instance.encode(report));
    return await DocumentFiles.saveDiagnostics(
      file,
      name:
          'cutelauncher_diagnostics_${DateTime.now().millisecondsSinceEpoch}.json',
    );
  } finally {
    await directory.delete(recursive: true);
  }
}

Future<Map<String, Object>> collectDiagnostics() async {
  const channel = BridgeChannel('me.efesser.flauncher/method');
  String? version, build;
  Map<dynamic, dynamic>? environment, memory, shell;
  Map<String, Object>? compatibility;
  try {
    final info = await PackageInfo.fromPlatform();
    version = info.version;
    build = info.buildNumber;
  } catch (_) {
    /* Unavailable metadata is omitted; never store exception text. */
  }
  try {
    environment = await channel.invokeMapMethod('getDiagnosticEnvironment');
  } catch (_) {}
  try {
    memory = await channel.invokeMapMethod('getProcessMemoryUsage');
  } catch (_) {}
  try {
    shell = await channel.invokeMapMethod('getNativeShellDiagnostics');
  } catch (_) {}
  final capturedAt = DateTime.now();
  try {
    final raw = await channel
        .invokeMapMethod('getTvCompatibilityDiagnostics')
        .timeout(const Duration(seconds: 15));
    if (raw == null || raw['identity'] is! Map || raw['checks'] is! Map) {
      throw StateError('Compatibility snapshot unavailable');
    }
    compatibility = createTvCompatibilityReport(
      raw,
      capturedAt: capturedAt,
      version: version,
      build: build,
    );
  } catch (error, stack) {
    DiagnosticsStore.instance.recordException(
      'getTvCompatibilityDiagnostics',
      error,
      stack,
    );
  }
  await BackgroundVideoDiagnostics.flush();
  final diagnostics = DiagnosticsStore.instance.snapshot(
    version: version,
    build: build,
    environment: environment,
    memory: memory,
    nativeShell: shell,
  );
  return combineDiagnosticsReport(
    diagnostics,
    compatibility,
    capturedAt: capturedAt,
  );
}

Future<void> clearDiagnostics() async {
  try {
    await const BridgeChannel('me.efesser.flauncher/method')
        .invokeMethod<bool>('clearNativeShellDiagnostics');
  } catch (_) {}
  DiagnosticsStore.instance.clear();
}
