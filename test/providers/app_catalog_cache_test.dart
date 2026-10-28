import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/providers/app_catalog_cache.dart';

void main() {
  test('cache preserves launch metadata and ignores corrupt or oversized files', () async {
    final root = await Directory.systemTemp.createTemp('cute-catalog-');
    final cache = AppCatalogCache(directory: () async => root);
    final file = File('${root.path}/app_catalog_v1.json');
    try {
      expect(await cache.read(), isNull);
      await cache.save([{'packageName': 'example.app', 'name': 'App', 'version': '1',
        'sideloaded': true, 'system': true, 'launchable': false, 'action': 'settings'}]);
      final apps = (await cache.read())!;
      expect(apps.single['launchable'], false);
      expect(apps.single['sideloaded'], true);
      expect(apps.single['action'], 'settings');
      await file.writeAsString(jsonEncode({'version': 1, 'apps': [apps.single, apps.single]}));
      expect(await cache.read(), isNull);
      await file.writeAsString('{');
      expect(await cache.read(), isNull);
      await file.writeAsString(' ' * (1024 * 1024 + 1));
      expect(await cache.read(), isNull);
      await Future.wait([cache.save(apps), cache.save([{...apps.single, 'version': '2'}])]);
      expect((await cache.read())!.single['version'], '2');
      expect(await File('${file.path}.partial').exists(), false);
    } finally { await root.delete(recursive: true); }
  });
}
