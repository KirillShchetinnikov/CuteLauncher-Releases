import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'document_files.dart';
import 'bridge_result.dart';
import 'diagnostics_store.dart';

Future<String?> saveDiagnosticsReport(Map<String, Object> report, {bool compatibility = false}) async {
  final directory = await (await getTemporaryDirectory()).createTemp(
    'diagnostics-',
  );
  try {
    final file = File('${directory.path}/report.json');
    await file.writeAsString(DiagnosticsStore.instance.encode(report));
    return await DocumentFiles.saveDiagnostics(
      file,
      name: 'cutelauncher_${compatibility ? 'compatibility' : 'errors'}_${DateTime.now().millisecondsSinceEpoch}.json',
    );
  } finally {
    await directory.delete(recursive: true);
  }
}

Future<Map<String, Object>> collectDiagnostics() async {
  const channel = BridgeChannel('me.efesser.flauncher/method');
  String? version, build;
  Map<dynamic, dynamic>? environment, memory;
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
  return DiagnosticsStore.instance.snapshot(
    version: version,
    build: build,
    environment: environment,
    memory: memory,
  );
}
