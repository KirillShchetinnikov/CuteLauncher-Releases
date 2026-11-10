import 'dart:convert';
import 'dart:io';

import 'package:flauncher/tv_cleaner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('TCL packages with firmware dependencies stay out of bulk approval', () {
    final profiles =
        (jsonDecode(
                  File('catalog/cleaner_profiles.json').readAsStringSync(),
                )['profiles']
                as List)
            .cast<Map>();
    final descriptions =
        jsonDecode(
              File('catalog/app_descriptions.json').readAsStringSync(),
            )['packages']
            as Map;
    final approved = {
      for (final profile in profiles)
        ...((profile['userApprovedSystemPackages'] as List?) ?? const []),
    };
    final observed = {
      for (final profile in profiles.where(
        (profile) => ['tcl-g08', 'tcl-g10'].contains(profile['id']),
      ))
        ...(profile['packages'] as List),
    };
    for (final package in [
      'com.realtek.airplay2',
      'com.tcl.dashboard',
      'com.tcl.exhibit',
      'com.tcl.guard',
      'com.tcl.partnercustomizer',
      'com.tcl.t_solo',
      'com.tcl.tv',
      'com.tcl.waterfall.overseas',
    ]) {
      expect(observed, contains(package));
      expect(approved, isNot(contains(package)));
      expect(descriptions[package]['safeToDisable'], isFalse);
    }
  });

  test('classification uses installation flag and explicit consumer catalog; helpers stay system', () {
    final entries =
        jsonDecode(
              File('catalog/app_descriptions.json').readAsStringSync(),
            )['packages']
            as Map;
    expect(cleanerAppKind({'system': false}, null), CleanerAppKind.user);
    expect(
      cleanerAppKind({
        'system': true,
      }, entries['com.amazon.amazonvideo.livingroom'] as Map),
      CleanerAppKind.preinstalled,
    );
    expect(
      cleanerAppKind({
        'system': false,
      }, entries['com.amazon.amazonvideo.livingroom'] as Map),
      CleanerAppKind.user,
    );
    expect(
      cleanerAppKind({
        'system': true,
      }, entries['com.netflix.tokenmanager'] as Map),
      CleanerAppKind.system,
    );
    expect(cleanerAppKind({'system': true}, null), CleanerAppKind.system);
  });

  test('inventory survives a new client, supports replacement and invalidation; corrupt cache rejected', () async {
    final dir = await Directory.systemTemp.createTemp('cleaner-cache-test-');
    addTearDown(() => dir.delete(recursive: true));
    TvCleanerClient client() =>
        TvCleanerClient(inventoryDirectory: () async => dir);
    final report = <String, dynamic>{
      'schemaVersion': 1,
      'reportType': 'tvCleanerInventory',
      'status': 'success',
      'identity': {'fingerprint': 'fixture'},
      'snapshotSaved': false,
      'pendingRestore': 0,
      'snapshot': '',
      'packages': [
        {
          'package': 'org.example.app',
          'name': 'Fixture',
          'system': false,
          'enabled': true,
          'protected': false,
        },
      ],
    };
    expect(await client().loadInventory(), isNull);
    await client().saveInventory(report);
    expect(await client().loadInventory(), report);
    report['pendingRestore'] = 1;
    await client().saveInventory(report);
    expect((await client().loadInventory())!['pendingRestore'], 1);
    await client().clearInventory();
    expect(await client().loadInventory(), isNull);
    final file = File('${dir.path}/tv-cleaner-inventory.json');
    for (final source in [
      'broken',
      '{}',
      jsonEncode({
        ...report,
        'packages': [42],
      }),
      jsonEncode({...report, 'identity': null}),
    ]) {
      await file.writeAsString(source);
      expect(await client().loadInventory(), isNull);
    }
  });

  test(
    'named imported list keeps provider name and deletes its temporary copy',
    () async {
      final dir = await Directory.systemTemp.createTemp('cleaner-import-test-');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/selected-document.bin');
      await file.writeAsString('org.example.video');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const channel = MethodChannel('me.efesser.flauncher/method');
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'pickCleanerListDocument');
        return {'path': file.path, 'name': 'My TV list.txt'};
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final client = TvCleanerClient();
      expect(await client.importFile(), 'org.example.video');
      expect(client.importedFileName, 'My TV list.txt');
      expect(await file.exists(), isFalse);
    },
  );
  for (final kind in ['apps', 'disabled', 'restore', 'state']) {
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
  test('one shared package catalog and inventory metadata contain no duplicate lists', () {
    final descriptions = jsonDecode(
      File('catalog/app_descriptions.json').readAsStringSync(),
    ) as Map;
    final entries = descriptions['packages'] as Map;
    for (final entry in entries.entries) {
      expect(cleanerPackageId(entry.key as String), isTrue);
      final description = entry.value as Map;
      for (final key in [
        if (!['preinstalled', 'user'].contains(description['category'])) ...[
          'ru',
          'en',
          'riskRu',
          'riskEn',
        ],
        'confidence',
        'source',
      ]) {
        expect(description[key], isNotEmpty, reason: '${entry.key}.$key');
      }
      final observedOn = description['observedOn'] as List;
      if (observedOn.isEmpty) {
        expect(
          description['confidence'],
          'identified',
          reason: entry.key as String,
        );
        expect(
          description['source'],
          matches(
            r'^https://github\.com/Gathin23/cleanyourtv/(?:pull/[0-9]+|blob/[a-f0-9]{40}/examples/[^/]+/debloat\.txt)$',
          ),
          reason:
              '${entry.key} needs a traceable external source without a local observation',
        );
      }
      expect(description['safeToDisable'], isFalse);
    }
    for (final file in Directory(
      'catalog/inventories',
    ).listSync().whereType<File>()) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('192.168.1.')));
      final report = jsonDecode(source) as Map;
      expect(report['reportType'], 'tvInventoryMetadata');
      expect(report['scope'], 'deviceMetadata');
      expect(report.containsKey('packages'), isFalse);
      expect(report.containsKey('applications'), isFalse);
      expect(report['packageListStorage'], 'catalog/app_descriptions.json');
      expect(report['observedPackageCount'], greaterThan(0));
      expect(
        report['sourceScope'],
        isIn([
          'adbReadOnlyInventory',
          'userProvidedDiagnosticInventory',
          'userProvidedPackageStates',
        ]),
      );
      if (report['sourceScope'] == 'userProvidedDiagnosticInventory') {
        expect(report['verification'], 'observedOnly');
        expect(report['sourceReport'], isNotEmpty);
        final completeness = report['completeness'] as Map;
        expect(completeness['truncated'], isA<bool>());
        expect(
          completeness['sourceCount'],
          greaterThanOrEqualTo(report['observedPackageCount']),
        );
        expect(completeness['skippedCount'], greaterThanOrEqualTo(0));
      }
    }
    final profiles = jsonDecode(
      File('catalog/cleaner_profiles.json').readAsStringSync(),
    ) as Map;
    for (final profile in profiles['profiles'] as List) {
      expect(profile['verification'], 'observedOnly');
      expect(profile['recommended'], isEmpty);
      expect((profile['identity'] as Map)['fingerprint'], isNotEmpty);
    }
  });

  test('X98Q user observations keep removed packages and protected services out of bulk approval', () {
    const id = 'droidlogic-x98q-android11-20261026';
    final inventory = jsonDecode(
      File('catalog/inventories/$id.json').readAsStringSync(),
    ) as Map;
    expect(inventory['observedPackageCount'], 118);
    expect(inventory['reportedCounts']['enabled'], 114);
    final example = File('catalog/examples/$id.json').readAsStringSync();
    final disabled = parseDisableList(example).toSet();
    expect(disabled, hasLength(3));
    expect(disabled, isNot(contains('com.droidlogic.miracast')));
    expect(disabled, isNot(contains('com.pittvandewitt.viperfx')));
    final profiles =
        jsonDecode(
              File('catalog/cleaner_profiles.json').readAsStringSync(),
            )['profiles']
            as List;
    final profile =
        profiles.singleWhere((profile) => profile['id'] == id) as Map;
    expect(profile['packages'].toSet(), disabled);
    expect(profile['recommended'], isEmpty);
    expect(profile['userApprovedSystemPackages'], [
      'com.google.android.tvlauncher',
    ]);
    expect(
      profile['userApprovedSystemPackages'],
      isNot(contains('com.google.android.tv.remote.service')),
    );
    expect(
      profile['userApprovedSystemPackages'],
      isNot(contains('com.android.bluetoothmidiservice')),
    );
  });
}
