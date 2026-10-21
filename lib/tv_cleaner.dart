import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'bridge_result.dart';
import 'document_files.dart';

final _packageId = RegExp(r'^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z0-9_]+)+$');
bool cleanerPackageId(String value) =>
    value.length <= 220 && (value == 'android' || _packageId.hasMatch(value));

/// Files contain identifiers, never shell commands. Unknown JSON formats fail closed.
List<String> parseDisableList(String source) {
  if (utf8.encode(source).length > 256 * 1024) {
    throw const FormatException('List too large');
  }
  source = source.replaceFirst(RegExp('^\uFEFF'), '').trim();
  Iterable<dynamic> values;
  if (source.startsWith('{')) {
    final decoded = jsonDecode(source);
    if (decoded is! Map ||
        decoded['schemaVersion'] != 1 ||
        decoded['reportType'] != 'tvDisableList' ||
        decoded['packages'] is! List) {
      throw const FormatException('Invalid list schema');
    }
    values = decoded['packages'] as List;
  } else {
    values = const LineSplitter()
        .convert(source)
        .map((line) => line.split('#').first.trim())
        .where((line) => line.isNotEmpty);
  }
  final packages = <String>{};
  for (final value in values) {
    if (value is! String || !cleanerPackageId(value)) {
      throw const FormatException('Expected package identifiers');
    }
    packages.add(value);
  }
  if (packages.isEmpty || packages.length > 500) {
    throw const FormatException('Invalid package count');
  }
  return packages.toList()..sort();
}

Map<String, Object?> disabledList(Map<String, dynamic> report) => {
  'schemaVersion': 1,
  'reportType': 'tvDisableList',
  'capturedAt': DateTime.now().toUtc().toIso8601String(),
  'identity': report['identity'],
  'verification': 'observedOnly',
  'packages':
      (report['packages'] as List)
          .whereType<Map>()
          .where((row) => [2, 3, 4].contains(row['enabledSetting']))
          .map((row) => row['package'] as String)
          .toList()
        ..sort(),
};

class TvCleanerClient {
  Future<Map<String, dynamic>> catalog(String path) async =>
      jsonDecode(await rootBundle.loadString(path)) as Map<String, dynamic>;
  static const channel = BridgeChannel('cutelauncher/adb');
  Future<Map<String, dynamic>> call(
    String action, {
    List<String>? packages,
    bool? enable,
  }) async {
    final info = await channel.invokeMapMethod<String, dynamic>('info');
    final result = await channel.invokeMapMethod<String, dynamic>('action', {
      'action': action,
      'port': info?['port'] ?? 5555,
      'tls': false,
      'packages': ?packages,
      'enable': ?enable,
    });
    if (result == null) throw const FormatException('Missing result');
    return result;
  }

  Future<String?> importFile() async {
    final path = await const BridgeChannel('me.efesser.flauncher/method')
        .invokeMethod<String>('pickCleanerDocument');
    if (path == null) return null;
    final file = File(path);
    try {
      if (await file.length() > 256 * 1024) {
        throw const FormatException('List too large');
      }
      return await file.readAsString();
    } finally {
      await file.delete();
    }
  }

  Future<String?> export(Map<String, dynamic> value, String kind) async {
    if (!['apps', 'disabled', 'restore'].contains(kind)) {
      throw ArgumentError.value(kind);
    }
    final dir = await (await getTemporaryDirectory()).createTemp('tv-cleaner-');
    try {
      final file = File('${dir.path}/report.json');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(value),
      );
      return await DocumentFiles.saveDiagnostics(
        file,
        name:
            'cutelauncher_${kind}_${DateTime.now().millisecondsSinceEpoch}.json',
      );
    } finally {
      await dir.delete(recursive: true);
    }
  }

  /// Only GitHub data; bounded responses, HTTPS, no redirects, credentials or scripts.
  Future<String> github(Uri uri) async {
    if (uri.scheme != 'https' ||
        !['api.github.com', 'raw.githubusercontent.com'].contains(uri.host) ||
        uri.userInfo.isNotEmpty ||
        uri.port != 443) {
      throw ArgumentError('Invalid source');
    }
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      return await (() async {
        final request = await client.getUrl(uri);
        request.followRedirects = false;
        request.headers.set('User-Agent', 'CuteLauncher-TV-Catalog');
        final response = await request.close();
        if (response.statusCode != 200) {
          throw const HttpException('Catalog unavailable');
        }
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
          if (bytes.length > 256 * 1024) {
            throw const FormatException('Catalog too large');
          }
        }
        return utf8.decode(bytes);
      })().timeout(const Duration(seconds: 20));
    } finally {
      client.close(force: true);
    }
  }
}
