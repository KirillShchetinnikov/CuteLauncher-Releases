import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:path_provider/path_provider.dart';

/// Reconstructible system metadata, separate from user layout and backups.
/// Never includes image bytes. Corrupt, oversized or foreign versions are ignored.
class AppCatalogCache {
  final Future<Directory> Function() directory;
  Future<void> _write = Future.value();
  AppCatalogCache({Future<Directory> Function()? directory})
      : directory = directory ?? getApplicationSupportDirectory;

  Future<File> _file() async => File('${(await directory()).path}/app_catalog_v1.json');

  Future<List<Map<dynamic, dynamic>>?> read() async {
    try {
      final file = await _file();
      if (!await file.exists() || await file.length() > 1024 * 1024) return null;
      final source = await file.readAsString();
      return await _decodeInBackground(source);
    } catch (_) { return null; }
  }

  static Future<List<Map<dynamic, dynamic>>?> _decodeInBackground(String source) =>
      Isolate.run(() => _decode(source));
  static Future<String> _encodeInBackground(List<Map<String, dynamic>> values) =>
      Isolate.run(() => jsonEncode({'version': 1, 'apps': values}));

  static List<Map<dynamic, dynamic>>? _decode(String source) {
    final data = jsonDecode(source);
    if (data is! Map || data['version'] != 1 || data['apps'] is! List) return null;
    final list = data['apps'] as List;
    if (list.isEmpty || list.length > 5000) return null;
    final result = <Map<dynamic, dynamic>>[];
    final packages = <String>{};
    for (final item in list) {
      if (item is! Map || item['packageName'] is! String || item['name'] is! String ||
          item['version'] is! String || item['sideloaded'] is! bool ||
          item['system'] is! bool || item['launchable'] is! bool ||
          !(item['action'] == null || item['action'] is String) ||
          !packages.add(item['packageName'] as String)) { return null; }
      result.add(Map.of(item));
    }
    return result;
  }

  Future<void> save(List<Map<dynamic, dynamic>> apps) {
    // Capture before another catalog refresh mutates its models.
    final values = [for (final app in apps) {
      'packageName': app['packageName'], 'name': app['name'],
      'version': app['version'] ?? '', 'sideloaded': app['sideloaded'] == true,
      'system': app['system'] == true, 'launchable': app['launchable'] != false,
      if (app['action'] != null) 'action': app['action'],
    }];
    return _write = _write.then((_) async {
      try {
        final encoded = await _encodeInBackground(values);
        if (utf8.encode(encoded).length > 1024 * 1024) return;
        final file = await _file();
        await file.parent.create(recursive: true);
        final pending = File('${file.path}.partial');
        await pending.writeAsString(encoded, flush: true);
        await pending.rename(file.path);
      } catch (_) { /* A cache failure cannot block the launcher. */ }
    });
  }
}
