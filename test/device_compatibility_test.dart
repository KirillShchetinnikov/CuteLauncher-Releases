import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../scripts/device_compatibility.dart' as catalog;

void main() {
  late Map<String, dynamic> data;
  late String evidence;
  setUp(() {
    data = catalog.readJson('catalog/devices.json');
    evidence = File('docs/TESTING_RU.md').readAsStringSync();
  });

  test('catalog schema and all local evidence headings exist', () {
    expect(catalog.validateCatalog(data, evidence), isEmpty);
  });
  test('identity matches only an exact model, device, firmware and device type', () {
    final entry = (data['devices'] as List).first as Map;
    final profile = {'schemaVersion': 1, 'kind': entry['kind'], 'identity': entry['identity']};
    expect(catalog.matchingDevices(data, profile).single['id'], entry['id']);
    for (final key in catalog.identityKeys) {
      expect(catalog.matchingDevices(data, {...profile, 'identity': {...entry['identity'] as Map, key: 'other'}}), isEmpty);
    }
    expect(catalog.matchingDevices(data, {...profile, 'kind': 'emulator'}), isEmpty);
    expect(catalog.matchingDevices(data, {...profile, 'schemaVersion': 2}), isEmpty);
    final historical = (data['devices'] as List)[1] as Map;
    expect(catalog.matchingDevices(data, {'schemaVersion': 1, 'kind': 'physical', 'identity': historical['identity']}), isEmpty);
  });
  test('invalid evidence, dates, duplicate records and incomplete exact identities fail', () {
    Map<String, dynamic> copy() => jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (c) => c['schemaVersion'] = 2,
      (c) => c['devices'].add(c['devices'].first),
      (c) => c['devices'].first['identity']['fingerprint'] = null,
      (c) => c['devices'].first['results'].first['date'] = '2026-02-30',
      (c) => c['devices'].first['results'].first['evidenceSection'] = 'No such result',
      (c) => c['devices'].first['results'].first['appBuild'] = '',
      (c) => c['devices'].first['results'].first['status'] = 'probably-safe',
    ]) {
      final changed = copy(); mutate(changed);
      expect(catalog.validateCatalog(changed, evidence), isNotEmpty);
    }
  });
  test('capture runs only whitelisted read-only commands and omits connection identifiers', () async {
    final commands = <List<String>>[];
    final profile = await catalog.captureProfile((args) async {
      commands.add(args);
      if (args[1] == 'getprop') return args.last == 'ro.kernel.qemu' ? '0' : 'test-property';
      return 'versionCode=73 minSdk=30\nversionName=1.0.24\n';
    }, DateTime.utc(2026, 10, 21));
    expect(commands.length, catalog.propertyNames.length + 1);
    expect(commands.every((c) => c.first == 'shell' && (c[1] == 'getprop' || c[1].startsWith('dumpsys package '))), isTrue);
    expect(profile['installedLauncher'], {'versionName': '1.0.24', 'versionCode': '73'});
    expect(profile['kind'], 'physical');
    for (final forbidden in ['serial', 'ip', 'ssid', 'mac', 'accounts']) {
      expect(profile.containsKey(forbidden), isFalse);
      expect((profile['identity'] as Map).containsKey(forbidden), isFalse);
    }
    expect(profile.containsKey('results'), isFalse);
  });
  test('failed or empty device reads never produce a compatibility claim', () async {
    await expectLater(catalog.captureProfile((_) async => '', DateTime.utc(2026)), throwsFormatException);
    await expectLater(catalog.captureProfile((_) async => throw const ProcessException('adb', []), DateTime.utc(2026)), throwsA(isA<ProcessException>()));
  });
}
