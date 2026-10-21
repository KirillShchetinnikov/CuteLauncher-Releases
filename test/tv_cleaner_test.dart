import 'dart:convert';
import 'dart:io';

import 'package:flauncher/tv_cleaner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final kind in ['apps', 'disabled', 'restore']) {
    for (final outcome in ['saved', 'opened', 'cancelled', 'failed']) {
      test(
        'export $kind: $outcome, correct name/content and temporary cleanup',
        () async {
          final dir = await Directory.systemTemp.createTemp('tv-cleaner-test-');
          final messenger =
              TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
          const paths = MethodChannel('plugins.flutter.io/path_provider');
          const docs = MethodChannel('me.efesser.flauncher/method');
          String? exportPath;
          messenger.setMockMethodCallHandler(paths, (_) async => dir.path);
          messenger.setMockMethodCallHandler(docs, (call) async {
            expect(call.method, 'saveDiagnosticsDocument');
            expect(call.arguments['name'], startsWith('cutelauncher_${kind}_'));
            exportPath = call.arguments['path'] as String;
            expect(jsonDecode(await File(exportPath!).readAsString()), {
              'fixture': true,
            });
            if (outcome == 'failed') {
              throw PlatformException(code: 'document_unavailable');
            }
            return outcome == 'cancelled' ? null : outcome;
          });
          try {
            final operation = TvCleanerClient().export({'fixture': true}, kind);
            if (outcome == 'failed') {
              await expectLater(operation, throwsA(isA<PlatformException>()));
            } else {
              expect(await operation, outcome == 'cancelled' ? null : outcome);
            }
            expect(exportPath, isNotNull);
            expect(await File(exportPath!).exists(), isFalse);
            expect(await dir.list().isEmpty, isTrue);
          } finally {
            messenger.setMockMethodCallHandler(paths, null);
            messenger.setMockMethodCallHandler(docs, null);
            await dir.delete(recursive: true);
          }
        },
      );
    }
  }
  test(
    'plain lists accept BOM, CRLF, comments and deduplicate identifiers',
    () {
      expect(
        parseDisableList(
          '\uFEFF# example\r\norg.example.video # app\r\norg.example.video\norg.example.other',
        ),
        ['org.example.other', 'org.example.video'],
      );
    },
  );
  test(
    'JSON exported list can be reused, flags retain observed-only status',
    () {
      final source = disabledList({
        'identity': {'fingerprint': 'exact'},
        'packages': [
          for (var state = 0; state <= 4; state++)
            {'package': 'org.example.app$state', 'enabledSetting': state},
        ],
      });
      expect(source['verification'], 'observedOnly');
      expect(parseDisableList(jsonEncode(source)), [
        'org.example.app2',
        'org.example.app3',
        'org.example.app4',
      ]);
    },
  );
  test(
    'commands, paths, invalid JSON and non-identifiers cannot become input',
    () {
      for (final source in [
        'pm disable-user org.example.a',
        'org.example.a;reboot',
        'org.example.a\nreboot',
        'org.example.a/Activity',
        "org.example.a'",
        '../foo',
        r'org.example.a$(id)',
        'org.example.a && id',
        '{"packages": ["org.example.a"]}',
        '{"schemaVersion":1,"reportType":"tvDisableList","packages":[5]}',
        '# empty',
      ]) {
        expect(
          () => parseDisableList(source),
          throwsFormatException,
          reason: source,
        );
      }
    },
  );
  test('bounded count and byte length reject oversized source', () {
    expect(
      () => parseDisableList(
        List.generate(501, (i) => 'org.example.a$i').join('\n'),
      ),
      throwsFormatException,
    );
    expect(
      () => parseDisableList('#${'x' * (256 * 1024)}\norg.example.a'),
      throwsFormatException,
    );
  });
  test('every archived package has bundled description, no unverified recommendations', () {
    final descriptions = jsonDecode(
      File('catalog/app_descriptions.json').readAsStringSync(),
    ) as Map;
    final entries = descriptions['packages'] as Map;
    final seen = <String>{};
    for (final file in Directory(
      'catalog/inventories',
    ).listSync().whereType<File>()) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('192.168.1.')));
      final report = jsonDecode(source) as Map;
      expect(report['scope'], 'adbReadOnlyInventory');
      for (final app in report['packages'] as List) {
        final name = app['package'] as String;
        seen.add(name);
        expect(cleanerPackageId(name), isTrue);
        expect(app['enabledSetting'], inInclusiveRange(0, 4));
        final description = entries[name] as Map;
        for (final key in [
          'ru',
          'en',
          'riskRu',
          'riskEn',
          'confidence',
          'source',
        ]) {
          expect(description[key], isNotEmpty);
        }
        expect(description['safeToDisable'], isFalse);
      }
      expect(
        (report['diagnostics'] as Map)['packageCount'],
        (report['packages'] as List).length,
      );
      expect(
        ((report['diagnostics'] as Map)['launcher']
            as Map)['requestedPermissions'],
        contains('android.permission.INTERNET'),
      );
    }
    expect(entries.keys.toSet(), seen);
    final profiles = jsonDecode(
      File('catalog/cleaner_profiles.json').readAsStringSync(),
    ) as Map;
    for (final profile in profiles['profiles'] as List) {
      expect(profile['verification'], 'observedOnly');
      expect(profile['recommended'], isEmpty);
      expect((profile['identity'] as Map)['fingerprint'], isNotEmpty);
    }
  });
}
