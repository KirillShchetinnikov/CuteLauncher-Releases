import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/tv_cleaner.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/tv_cleaner_page.dart';
import 'package:flauncher/widgets/settings/settings_panel_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> snapshot({bool enabled = true, bool saved = false}) => {
  'status': 'success',
  'schemaVersion': 1,
  'reportType': 'tvCleanerInventory',
  'identity': {
    'manufacturer': 'Test',
    'model': 'TV',
    'device': 'fixture',
    'fingerprint': 'exact',
  },
  'snapshotSaved': saved,
  'pendingRestore': enabled ? 0 : 1,
  'baselineCreatedAt': saved ? 1700000000000 : 0,
  'manualStates': <Map<String, dynamic>>[],
  'snapshot': saved
      ? '{"schemaVersion":1,"fingerprint":"exact","states":{"org.example.video":0}}'
      : '',
  'packages': [
    {
      'package': 'org.example.video',
      'name': 'Example video',
      'versionName': '1',
      'versionCode': 1,
      'enabled': enabled,
      'enabledSetting': enabled ? 0 : 3,
      'system': false,
      'protected': false,
    },
    {
      'package': 'com.android.systemui',
      'name': 'System UI',
      'versionName': '1',
      'versionCode': 1,
      'enabled': true,
      'enabledSetting': 0,
      'system': true,
      'protected': true,
    },
  ],
};

class FakeCleaner extends TvCleanerClient {
  Map<String, dynamic>? profilesOverride, descriptionsOverride, cached;
  bool cacheFailure = false,
      failApply = false,
      failSnapshot = false,
      githubFailure = false;
  List<Map<String, dynamic>>? packagesOverride;
  final githubCalls = <Uri>[];
  final githubResponses = <String, String>{};
  String? appliedScope;
  @override
  Future<String> github(Uri uri) async {
    githubCalls.add(uri);
    if (githubFailure) throw const FormatException();
    return githubResponses[uri.path] ??
        jsonEncode({'schemaVersion': 1, ...?profilesOverride});
  }

  @override
  Future<Map<String, dynamic>?> loadInventory() async => cached;
  @override
  Future<void> saveInventory(Map<String, dynamic> report) async {
    if (cacheFailure) throw const FileSystemException('fixture');
    cached = jsonDecode(jsonEncode(report)) as Map<String, dynamic>;
  }

  @override
  Future<void> clearInventory() async => cached = null;
  @override
  Future<Map<String, dynamic>> catalog(String path) async =>
      (path.endsWith('cleaner_profiles.json')
          ? profilesOverride
          : descriptionsOverride) ??
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  final actions = <String>[];
  List<String>? applied;
  bool enabled = true, saved = false, partial = false, inventoryFailure = false;
  String? imported;
  final copies = <Map<String, dynamic>>[];
  Map<String, dynamic>? exported;
  String? exportKind;
  @override
  Future<String?> export(Map<String, dynamic> value, String kind) async {
    exported = value;
    exportKind = kind;
    return 'saved';
  }

  Completer<Map<String, dynamic>>? pending;
  @override
  Future<Map<String, dynamic>> call(
    String action, {
    List<String>? packages,
    bool? enable,
    String? stateId,
    String? stateName,
    String? listName,
    String? listScope,
  }) async {
    actions.add(action);
    if (action == 'cleanerInventory' && inventoryFailure) {
      return {'status': 'unavailable'};
    }
    if (pending != null) return pending!.future;
    if (action == 'cleanerApply') {
      if (failApply) throw StateError('fixture interruption');
      if (!enable! && listName != null) {
        if (failSnapshot) return {'status': 'snapshotFailed'};
        copies.add({
          'id': 'auto-${copies.length}',
          'name': listName,
          'description': listName,
          'capturedAt': DateTime.now().millisecondsSinceEpoch,
          'states': {for (final name in packages!) name: 0},
          'enabled': true,
        });
      }
      applied = packages;
      appliedScope = listScope;
      for (final app in packagesOverride ?? <Map<String, dynamic>>[]) {
        if (packages!.contains(app['package'])) {
          app['enabled'] = enable;
          app['enabledSetting'] = enable ? 1 : 3;
        }
      }
      if (partial) {
        enabled = enable;
        saved = true;
        return {'status': 'partial'};
      }
      enabled = enable;
      saved = true;
    }
    if (action == 'cleanerSnapshot' || action == 'cleanerInventory') {
      saved = true;
    }
    if (action == 'cleanerManualSave') {
      copies.add({
        'id': 'id-${copies.length}',
        'name': stateName,
        'capturedAt': DateTime.now().millisecondsSinceEpoch,
        'enabled': enabled,
      });
    }
    if (action == 'cleanerManualDelete') {
      copies.removeWhere((copy) => copy['id'] == stateId);
    }
    if (action == 'cleanerManualRestore') {
      enabled =
          copies.singleWhere((copy) => copy['id'] == stateId)['enabled']
              as bool;
    }
    if (action == 'cleanerManualExport') {
      return {
        'status': 'success',
        'manualSnapshot': jsonEncode({
          'schemaVersion': 1,
          'reportType': 'tvCleanerState',
          'fingerprint': 'exact',
          'name': copies.singleWhere((copy) => copy['id'] == stateId)['name'],
          'states': {'org.example.video': enabled ? 0 : 3},
        }),
      };
    }
    if (action == 'cleanerRestore') {
      enabled = true;
      saved = true;
    }
    final value = snapshot(enabled: enabled, saved: saved)
      ..['manualStates'] = List<Map<String, dynamic>>.from(copies);
    if (packagesOverride != null) value['packages'] = packagesOverride;
    return value;
  }

  @override
  Future<String?> importFile() async => imported;
}

Future<void> open(
  WidgetTester tester,
  FakeCleaner client,
  String locale, {
  bool compact = false,
}) async {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        final content = SettingsPanelStyle(builder: (_) => child!);
        return compact
            ? MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.6)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(width: 380, child: content),
                ),
              )
            : content;
      },
      home: Scaffold(body: TvCleanerPage(client: client)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> click(WidgetTester tester, String title) async {
  final tile = find.ancestor(
    of: find.text(title),
    matching: find.byType(FocusableSettingsTile),
  );
  if (tile.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      tile,
      220,
      scrollable: find.byType(Scrollable).last,
    );
  }
  await tester.ensureVisible(tile.first);
  await tester.pumpAndSettle();
  await tester.tap(tile.first);
  await tester.pumpAndSettle();
}

Future<void> back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {
  for (final submenu in [
    'Preinstalled applications',
    'Project catalog lists',
    'CleanYourTV examples',
  ]) {
    for (final pointer in [false, true]) {
      testWidgets(
        'disable lists restore opener after $submenu (pointer: $pointer)',
        (tester) async {
          final client = FakeCleaner()..cached = snapshot(saved: true);
          await open(tester, client, 'en');
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          final finder = find.ancestor(
            of: find.text(submenu),
            matching: find.byType(FocusableSettingsTile),
          );
          final focus = Focus.of(
            tester.element(
              find
                  .descendant(
                    of: finder,
                    matching: find.byType(GestureDetector),
                  )
                  .first,
            ),
          );
          if (submenu == 'Preinstalled applications') {
            client.pending = Completer<Map<String, dynamic>>();
          }
          if (pointer) {
            await tester.tap(finder);
          } else {
            final moves = submenu == 'Preinstalled applications'
                ? 1
                : submenu == 'Project catalog lists'
                ? 3
                : 4;
            for (var i = 0; i < moves; i++) {
              await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
            }
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          }
          await tester.pump();
          if (client.pending != null) {
            await tester.pump(const Duration(milliseconds: 100));
            client.pending!.complete(snapshot(saved: true));
            client.pending = null;
          }
          await tester.pumpAndSettle();
          if (submenu != 'Preinstalled applications') {
            await click(tester, 'Refresh catalog from GitHub');
          }
          await back(tester);
          expect(focus.hasPrimaryFocus, isTrue);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          expect(find.text(submenu), findsOneWidget);
        },
      );
    }
  }

  testWidgets('delayed inventory keeps remote navigation and return focus', (
    tester,
  ) async {
    final client = FakeCleaner()..cached = snapshot(saved: true);
    await open(tester, client, 'en');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    client.pending = Completer<Map<String, dynamic>>();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    client.pending!.complete(snapshot(saved: true));
    client.pending = null;
    await tester.pumpAndSettle();
    final first = FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<FocusableSettingsTile>();
    expect((first?.title as Text?)?.data, 'Search by name');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('org.example.video'), findsWidgets);
    await back(tester);
    await back(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Example video\norg.example.video'), findsOneWidget);
  });

  testWidgets(
    'recovery menus use cached inventory and return to their opener',
    (tester) async {
      final client = FakeCleaner()..cached = snapshot(saved: true);
      await open(tester, client, 'en');
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(client.actions, isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Save current state'), findsOneWidget);
      expect(client.actions, isEmpty);
      await back(tester);
      await back(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Baseline original state'), findsOneWidget);
    },
  );

  testWidgets(
    'first collection unlocks groups, reentry restores cached state without ADB',
    (tester) async {
      final client = FakeCleaner();
      await open(tester, client, 'en');
      for (final name in [
        'All applications',
        'Disable lists',
        'Backup and recovery',
        'Reports',
      ]) {
        final tile = tester.widget<FocusableSettingsTile>(
          find.ancestor(
            of: find.text(name),
            matching: find.byType(FocusableSettingsTile),
          ),
        );
        expect(tile.enabled, isFalse);
      }
      expect(client.actions, isEmpty);
      await click(tester, 'Refresh applications');
      expect(client.cached, isNotNull);
      await tester.pumpWidget(const SizedBox());
      await open(tester, client, 'en');
      expect(client.actions, ['cleanerInventory']);
      final group = tester.widget<FocusableSettingsTile>(
        find.ancestor(
          of: find.text('Disable lists'),
          matching: find.byType(FocusableSettingsTile),
        ),
      );
      expect(group.enabled, isTrue);
      expect(find.text('Save original state'), findsNothing);
    },
  );

  testWidgets(
    'list opens only after notified background refresh; duplicate presses blocked',
    (tester) async {
      final client = FakeCleaner();
      await open(tester, client, 'en');
      await click(tester, 'Refresh applications');
      client.pending = Completer<Map<String, dynamic>>();
      await tester.tap(find.text('All applications'));
      await tester.pump();
      expect(find.text('Updating application list…'), findsOneWidget);
      expect(find.text('Example video\norg.example.video'), findsNothing);
      await tester.tap(find.text('All applications'));
      expect(client.actions, ['cleanerInventory', 'cleanerInventory']);
      client.pending!.complete(snapshot());
      await tester.pumpAndSettle();
      expect(find.text('Example video\norg.example.video'), findsOneWidget);
      expect(find.text('Updating application list…'), findsNothing);
    },
  );

  testWidgets('failed refresh keeps cache and prevents stale list opening', (
    tester,
  ) async {
    final client = FakeCleaner();
    await open(tester, client, 'en');
    await click(tester, 'Refresh applications');
    client.inventoryFailure = true;
    await click(tester, 'All applications');
    expect(client.actions.length, 2);
    expect(client.cached, isNotNull);
    expect(find.text('Example video\norg.example.video'), findsNothing);
    expect(find.text('TV cleanup manager'), findsOneWidget);
    client.inventoryFailure = false;
    await click(tester, 'All applications');
    expect(find.text('Example video\norg.example.video'), findsOneWidget);
  });

  for (final locale in ['ru', 'en']) {
    final ru = locale == 'ru';
    testWidgets(
      'user applications have minimal risk, confirmed changes and Back: $locale',
      (tester) async {
        final client = FakeCleaner();
        await open(tester, client, locale);
        await click(
          tester,
          ru ? 'Обновить список приложений' : 'Refresh applications',
        );
        await click(tester, ru ? 'Все приложения' : 'All applications');
        await click(tester, 'Example video\norg.example.video');
        expect(
          find.text(
            ru
                ? 'Это не системное приложение.'
                : 'This is not a system application.',
          ),
          findsOneWidget,
        );
        expect(find.text(ru ? 'Минимальный' : 'Minimal'), findsOneWidget);
        expect(
          find.text(
            ru ? 'Приложение не опознано.' : 'Application not identified.',
          ),
          findsNothing,
        );
        await click(
          tester,
          ru ? 'Отключить приложение' : 'Disable application',
        );
        expect(client.applied, isNull);
        await click(tester, ru ? 'Отмена' : 'Cancel');
        await click(
          tester,
          ru ? 'Отключить приложение' : 'Disable application',
        );
        await click(tester, ru ? 'ОК' : 'OK');
        expect(client.applied, ['org.example.video']);
        expect(client.cached!['snapshotSaved'], isTrue);
        await click(tester, ru ? 'Включить приложение' : 'Enable application');
        await click(tester, ru ? 'ОК' : 'OK');
        expect(client.enabled, isTrue);
        await back(tester);
        expect(find.text('Example video\norg.example.video'), findsOneWidget);
        await back(tester);
        expect(
          find.text(ru ? 'Менеджер очистки ТВ' : 'TV cleanup manager'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'preinstalled consumer app is separate from system; protected system description remains',
    (tester) async {
      final report = snapshot();
      (report['packages'] as List).add({
        'package': 'com.amazon.amazonvideo.livingroom',
        'name': 'Prime Video',
        'versionName': '1',
        'versionCode': 1,
        'enabled': true,
        'enabledSetting': 0,
        'system': true,
        'protected': false,
      });
      final client = FakeCleaner()..cached = report;
      await open(tester, client, 'en');
      client.pending = Completer<Map<String, dynamic>>()..complete(report);
      await click(tester, 'All applications');
      expect(find.text('User applications'), findsOneWidget);
      expect(find.text('Preinstalled applications'), findsOneWidget);
      expect(find.text('System applications'), findsOneWidget);
      await click(tester, 'Prime Video\ncom.amazon.amazonvideo.livingroom');
      expect(find.text('Preinstalled application'), findsOneWidget);
      expect(find.text('Minimal'), findsOneWidget);
      expect(find.text('Application not identified.'), findsNothing);
      await back(tester);
      await click(tester, 'System UI\ncom.android.systemui');
      expect(find.text('System application'), findsOneWidget);
      expect(find.text('Application not identified.'), findsOneWidget);
      expect(find.text('Protected from disabling'), findsOneWidget);
      final tile = tester.widget<FocusableSettingsTile>(
        find.ancestor(
          of: find.text('Disable application'),
          matching: find.byType(FocusableSettingsTile),
        ),
      );
      expect(tile.enabled, isFalse);
    },
  );

  testWidgets(
    'project catalog matches all identity fields and previews without applying',
    (tester) async {
      final client = FakeCleaner()
        ..profilesOverride = {
          'profiles': [
            {
              'id': 'matching',
              'identity': snapshot()['identity'],
              'packages': ['org.example.video'],
            },
            {
              'id': 'wrong',
              'identity': {...snapshot()['identity'] as Map, 'model': 'other'},
              'packages': ['org.example.video'],
            },
            for (final field in ['manufacturer', 'device', 'fingerprint'])
              {
                'id': 'wrong-$field',
                'identity': {...snapshot()['identity'] as Map, field: 'other'},
                'packages': ['org.example.video'],
              },
            {
              'id': 'incomplete',
              'identity': {'model': 'TV'},
              'packages': ['org.example.video'],
            },
          ],
        };
      await open(tester, client, 'en');
      await click(tester, 'Refresh applications');
      await click(tester, 'Disable lists');
      await click(tester, 'Project catalog lists');
      expect(find.text('Refresh catalog from GitHub'), findsOneWidget);
      final initial = tester.widget<FocusableSettingsTile>(
        find.ancestor(
          of: find.textContaining('matching ·'),
          matching: find.byType(FocusableSettingsTile),
        ),
      );
      expect(initial.enabled, isFalse);
      expect(initial.leading, isA<Icon>());
      await click(tester, 'Refresh catalog from GitHub');
      expect(find.textContaining('wrong ·'), findsOneWidget);
      final mark = tester.widget<Icon>(find.byIcon(Icons.check_circle));
      expect(mark.color, Colors.green);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      for (final id in [
        'wrong',
        'wrong-manufacturer',
        'wrong-device',
        'wrong-fingerprint',
        'incomplete',
      ]) {
        final tile = tester.widget<FocusableSettingsTile>(
          find.ancestor(
            of: find.textContaining('$id ·'),
            matching: find.byType(FocusableSettingsTile),
          ),
        );
        expect(tile.leading, isNull);
      }
      final title = tester
          .widget<Text>(find.textContaining('matching ·'))
          .data!;
      await click(tester, title);
      expect(client.applied, isNull);
      await click(tester, 'Cancel');
    },
  );

  for (final verified in [false, true]) {
    testWidgets(
      'recommendation still requires firmware verification and package approval: $verified',
      (tester) async {
        final client = FakeCleaner()
          ..packagesOverride = [
            {
              ...((snapshot()['packages'] as List).first
                  as Map<String, dynamic>),
              'system': true,
            },
          ]
          ..descriptionsOverride = {
            'packages': {
              'org.example.video': {'safeToDisable': true},
            },
          }
          ..profilesOverride = {
            'profiles': [
              {
                'identity': snapshot()['identity'],
                'verification': verified
                    ? 'verifiedFunctionsPreserved'
                    : 'observedOnly',
                'recommended': ['org.example.video'],
              },
            ],
          };
        await open(tester, client, 'en');
        await click(tester, 'Refresh applications');
        await click(tester, 'Disable lists');
        await click(tester, 'Disable verified applications');
        expect(client.applied, isNull);
        if (verified) {
          await click(tester, 'OK');
          expect(client.applied, ['org.example.video']);
        } else {
          expect(
            find.text(
              'No matching system application list exists for this model and firmware.',
            ),
            findsOneWidget,
          );
        }
      },
    );
  }

  testWidgets('import refreshes and previews skips, mismatch is rejected', (
    tester,
  ) async {
    final client = FakeCleaner()
      ..imported =
          'org.example.video\ncom.android.systemui\norg.example.missing';
    await open(tester, client, 'en');
    await click(tester, 'Refresh applications');
    await click(tester, 'Disable lists');
    await click(tester, 'Disable using a local list');
    expect(
      find.text(
        'Skipped: protected, missing or already in the requested state',
      ),
      findsOneWidget,
    );
    expect(client.applied, isNull);
    await click(tester, 'OK');
    expect(client.applied, ['org.example.video']);
    client.imported = jsonEncode({
      'schemaVersion': 1,
      'reportType': 'tvDisableList',
      'identity': {'fingerprint': 'different'},
      'packages': ['org.example.video'],
    });
    await click(tester, 'Disable using a local list');
    expect(
      find.text(
        'The list belongs to a different firmware and will not be applied.',
      ),
      findsOneWidget,
    );
    expect(
      client.actions.where((action) => action == 'cleanerApply').length,
      1,
    );
  });

  testWidgets(
    'partial mutation refreshes and recovery remains available with current cache',
    (tester) async {
      final client = FakeCleaner()
        ..partial = true
        ..imported = 'org.example.video';
      await open(tester, client, 'en');
      await click(tester, 'Refresh applications');
      await click(tester, 'Disable lists');
      await click(tester, 'Disable using a local list');
      await click(tester, 'OK');
      expect(client.actions.last, 'cleanerInventory');
      expect(client.cached!['pendingRestore'], 1);
      await back(tester);
      await click(tester, 'Backup and recovery');
      final restore = tester.widget<FocusableSettingsTile>(
        find.ancestor(
          of: find.text('Restore baseline state'),
          matching: find.byType(FocusableSettingsTile),
        ),
      );
      expect(restore.enabled, isTrue);
      await click(tester, 'Restore baseline state');
      expect(client.actions.last, 'cleanerInventory');
      await click(tester, 'OK');
      expect(client.actions.last, 'cleanerRestore');
    },
  );

  testWidgets('remote enters refresh first and Back returns focus to group', (
    tester,
  ) async {
    final client = FakeCleaner();
    await open(tester, client, 'en');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(client.actions, ['cleanerInventory']);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Example video\norg.example.video'), findsOneWidget);
    await back(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Example video\norg.example.video'), findsOneWidget);
  });

  testWidgets(
    'reports refreshes current disabled apps and exports directly to file',
    (tester) async {
      final client = FakeCleaner();
      await open(tester, client, 'en');
      await click(tester, 'Refresh applications');
      await click(tester, 'Reports');
      client.enabled = false;
      await click(tester, 'Export disabled-app report to file');
      expect(client.exportKind, 'disabled');
      expect(client.exported!['packages'], ['org.example.video']);
      expect(client.exported!['identity'], snapshot()['identity']);
      expect(client.exported!['applications'], hasLength(1));
      expect(find.text('Copy report'), findsNothing);
    },
  );

  testWidgets(
    'closing settings during background refresh is safe and removes notice',
    (tester) async {
      final client = FakeCleaner();
      await open(tester, client, 'en');
      await click(tester, 'Refresh applications');
      client.pending = Completer<Map<String, dynamic>>();
      await tester.tap(find.text('All applications'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      client.pending!.complete(snapshot());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cache write failure is visible and does not report persistence success',
    (tester) async {
      final client = FakeCleaner()..cacheFailure = true;
      await open(tester, client, 'en');
      await click(tester, 'Refresh applications');
      expect(
        find.text('Could not save the list for the next visit.'),
        findsOneWidget,
      );
      expect(client.cached, isNull);
    },
  );
  testWidgets(
    'first refresh creates protected baseline; backup page exposes date and no replace/delete',
    (tester) async {
      final client = FakeCleaner();
      await open(tester, client, 'en');
      await click(tester, 'Refresh applications');
      expect(client.cached!['snapshotSaved'], isTrue);
      await click(tester, 'Backup and recovery');
      expect(find.text('Baseline original state'), findsOneWidget);
      expect(find.textContaining('2023-11-'), findsOneWidget);
      expect(find.text('Save original state'), findsNothing);
      expect(find.text('Delete'), findsNothing);
      expect(find.text('Restore baseline state'), findsOneWidget);
      expect(find.text('Manage manual states'), findsOneWidget);
    },
  );

  testWidgets(
    'manual states: date name, custom name, restore, file export, deletion cancellation and deletion',
    (tester) async {
      final client = FakeCleaner();
      await open(tester, client, 'en');
      await click(tester, 'Refresh applications');
      final baselineDate = client.cached!['baselineCreatedAt'];
      await click(tester, 'Backup and recovery');
      await click(tester, 'Manage manual states');
      await click(tester, 'Save current state');
      await tester.tap(find.text('Use date and time'));
      await tester.pumpAndSettle();
      expect(client.copies, hasLength(1));
      expect(
        client.copies.first['name'],
        matches(RegExp(r'^\d{4}-\d{2}-\d{2} ')),
      );
      await click(tester, 'Save current state');
      await tester.tap(find.text('Enter a name'));
      await tester.pumpAndSettle();
      await click(tester, 'Name');
      await tester.enterText(find.byType(TextField), 'Before cleanup');
      await tester.tap(find.text('Save').last);
      await tester.pumpAndSettle();
      await click(tester, 'Save');
      expect(client.copies, hasLength(2));
      expect(client.copies.last['name'], 'Before cleanup');
      Future<void> choose() async {
        final title = tester
            .widget<Text>(find.textContaining('Before cleanup').first)
            .data!;
        await click(tester, title);
      }

      await choose();
      await click(tester, 'Export saved state to file');
      expect(client.exportKind, 'state');
      expect(client.exported!['name'], 'Before cleanup');
      client.enabled = false;
      await choose();
      await click(tester, 'Restore this backup');
      expect(client.enabled, isFalse);
      await click(tester, 'OK');
      expect(client.enabled, isTrue);
      await choose();
      await click(tester, 'Delete');
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();
      expect(client.copies, hasLength(2));
      await choose();
      await click(tester, 'Delete');
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(client.copies, hasLength(1));
      expect(client.cached!['baselineCreatedAt'], baselineDate);
      expect(
        client.actions.where((action) => action == 'cleanerSnapshot'),
        isEmpty,
      );
    },
  );

  testWidgets('uncertain mutation invalidates persisted and displayed states', (
    tester,
  ) async {
    final client = FakeCleaner()
      ..failApply = true
      ..imported = 'org.example.video';
    await open(tester, client, 'en');
    await click(tester, 'Refresh applications');
    await click(tester, 'Disable lists');
    await click(tester, 'Disable using a local list');
    await click(tester, 'OK');
    expect(client.cached, isNull);
    await back(tester);
    final group = tester.widget<FocusableSettingsTile>(
      find.ancestor(
        of: find.text('All applications'),
        matching: find.byType(FocusableSettingsTile),
      ),
    );
    expect(group.enabled, isFalse);
    expect(find.text('Refresh the application list first.'), findsOneWidget);
  });

  testWidgets(
    'Russian subgroups and cards fit a narrow panel with enlarged text',
    (tester) async {
      final client = FakeCleaner();
      await open(tester, client, 'ru', compact: true);
      await click(tester, 'Обновить список приложений');
      await click(tester, 'Списки отключения');
      expect(tester.takeException(), isNull);
      await back(tester);
      await click(tester, 'Бэкап и восстановление');
      expect(tester.takeException(), isNull);
      await back(tester);
      await click(tester, 'Все приложения');
      await click(tester, 'Example video\norg.example.video');
      expect(find.text('org.example.video'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Минимальный'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Минимальный'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'list snapshot contains only chosen packages and failed snapshot prevents disabling',
    (tester) async {
      final client = FakeCleaner()
        ..imported =
            'org.example.video\norg.example.missing\ncom.android.systemui';
      client.importedFileName = 'My TV.txt';
      await open(tester, client, 'en');
      await click(tester, 'Refresh applications');
      await click(tester, 'Disable lists');
      await click(tester, 'Disable using a local list');
      await click(tester, 'Cancel');
      expect(client.copies, isEmpty);
      await click(tester, 'Disable using a local list');
      await click(tester, 'OK');
      expect((client.copies.single['states'] as Map).keys, [
        'org.example.video',
      ]);
      expect(
        client.copies.single['description'],
        'Before applying list: My TV.txt',
      );
      client.enabled = true;
      client.failSnapshot = true;
      client.applied = null;
      await click(tester, 'Disable using a local list');
      await click(tester, 'OK');
      expect(client.applied, isNull);
      expect(client.enabled, isTrue);
      expect(client.copies, hasLength(1));
      expect(
        find.text(
          'Could not save the snapshot. No applications were disabled.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'user-approved TV union disables system only and survives a remote catalog refresh',
    (tester) async {
      final user = Map<String, dynamic>.from(
        (snapshot()['packages'] as List).first as Map,
      );
      final system = {
        ...user,
        'package': 'org.example.system',
        'name': 'System feature',
        'system': true,
      };
      final prime = {
        ...user,
        'package': 'com.amazon.amazonvideo.livingroom',
        'name': 'Prime',
        'system': true,
      };
      final client = FakeCleaner()
        ..packagesOverride = [user, system, prime]
        ..profilesOverride = {
          'profiles': [
            {
              'identity': {'fingerprint': 'another TV'},
              'approval': 'userRequestedObservedSystemList',
              'userApprovedSystemPackages': [
                'org.example.video',
                'org.example.system',
                'com.amazon.amazonvideo.livingroom',
                'org.example.missing',
              ],
            },
          ],
        };
      await open(tester, client, 'en');
      await click(tester, 'Refresh applications');
      await click(tester, 'Disable lists');
      await click(tester, 'Disable verified applications');
      await click(tester, 'OK');
      expect(client.applied, ['org.example.system']);
      expect(client.appliedScope, 'system');
      expect(user['enabled'], isTrue);
      expect(prime['enabled'], isTrue);
      expect((client.copies.single['states'] as Map).keys, [
        'org.example.system',
      ]);
    },
  );

  for (final locale in ['ru', 'en']) {
    testWidgets('preinstalled menu reads cache; only list entry refreshes: $locale', (tester) async {
      final ru = locale == 'ru';
      final client = FakeCleaner()..cached = snapshot(saved: true);
      await open(tester, client, locale);
      await click(tester, ru ? 'Списки отключения' : 'Disable lists');
      await click(tester, ru ? 'Предустановленные приложения' : 'Preinstalled applications');
      expect(client.actions, isEmpty);

      final listTitle = ru ? 'Список предустановленных приложений' : 'Preinstalled application list';
      client.pending = Completer<Map<String, dynamic>>();
      await tester.tap(find.text(listTitle));
      await tester.pump();
      expect(client.actions, ['cleanerInventory']);
      expect(find.text(ru ? 'Обновляется список приложений…' : 'Updating application list…'), findsOneWidget);
      expect(find.text('Prime Video\ncom.amazon.amazonvideo.livingroom'), findsNothing);
      client.pending!.complete(snapshot(saved: true)..['packages'] = [
        {
          'package': 'com.amazon.amazonvideo.livingroom',
          'name': 'Prime Video',
          'system': true,
          'enabled': true,
          'protected': false,
        },
      ]);
      await tester.pumpAndSettle();
      client.pending = null;
      expect(find.text('Prime Video\ncom.amazon.amazonvideo.livingroom'), findsOneWidget);
      await back(tester);
      expect(client.actions, ['cleanerInventory']);

      client.inventoryFailure = true;
      await click(tester, listTitle);
      expect(client.actions, ['cleanerInventory', 'cleanerInventory']);
      expect(find.text('Prime Video\ncom.amazon.amazonvideo.livingroom'), findsNothing);
      expect(find.text(listTitle), findsOneWidget);
      expect(client.cached, isNotNull);
    });
  }

  testWidgets(
    'preinstalled menu supports batch disable/enable and searchable per-app status',
    (tester) async {
      final user = Map<String, dynamic>.from(
        (snapshot()['packages'] as List).first as Map,
      );
      final system = {
        ...user,
        'package': 'org.example.system',
        'name': 'System feature',
        'system': true,
      };
      final prime = {
        ...user,
        'package': 'com.amazon.amazonvideo.livingroom',
        'name': 'Prime Video',
        'system': true,
      };
      final netflix = {
        ...user,
        'package': 'com.netflix.ninja',
        'name': 'Netflix',
        'system': true,
      };
      final client = FakeCleaner()
        ..packagesOverride = [user, system, prime, netflix];
      await open(tester, client, 'en');
      await click(tester, 'Refresh applications');
      await click(tester, 'Disable lists');
      await click(tester, 'Preinstalled applications');
      await click(tester, 'Disable all preinstalled apps');
      await click(tester, 'OK');
      expect(client.applied, [
        'com.amazon.amazonvideo.livingroom',
        'com.netflix.ninja',
      ]);
      expect(client.appliedScope, 'preinstalled');
      expect(user['enabled'], isTrue);
      expect(system['enabled'], isTrue);
      await click(tester, 'Enable all preinstalled apps');
      await click(tester, 'OK');
      expect(prime['enabled'], isTrue);
      expect(netflix['enabled'], isTrue);
      expect(client.copies, hasLength(1));
      await click(tester, 'Preinstalled application list');
      expect(find.text('Example video\norg.example.video'), findsNothing);
      await click(tester, 'Search by name');
      await tester.enterText(find.byType(TextField), 'prime');
      await tester.tap(find.text('Save').last);
      await tester.pumpAndSettle();
      expect(
        find.text('Prime Video\ncom.amazon.amazonvideo.livingroom'),
        findsOneWidget,
      );
      expect(find.text('Netflix\ncom.netflix.ninja'), findsNothing);
      expect(find.text('Enabled'), findsOneWidget);
      await click(tester, 'Prime Video\ncom.amazon.amazonvideo.livingroom');
      await click(tester, 'Disable application');
      await click(tester, 'OK');
      expect(client.applied, ['com.amazon.amazonvideo.livingroom']);
      expect(netflix['enabled'], isTrue);
      expect(client.copies, hasLength(2));
    },
  );

  testWidgets(
    'catalog tells apart already-disabled and missing packages; failed update leaves it locked',
    (tester) async {
      final client = FakeCleaner()
        ..enabled = false
        ..githubFailure = true
        ..profilesOverride = {
          'profiles': [
            {
              'id': 'My TV',
              'identity': snapshot()['identity'],
              'packages': ['org.example.video', 'org.example.missing'],
            },
            {
              'id': 'Absent',
              'identity': snapshot()['identity'],
              'packages': ['org.example.missing'],
            },
          ],
        };
      await open(tester, client, 'en');
      await click(tester, 'Refresh applications');
      await click(tester, 'Disable lists');
      await click(tester, 'Project catalog lists');
      await click(tester, 'Refresh catalog from GitHub');
      final label = tester.widget<Text>(find.textContaining('My TV ·')).data!;
      final tile = tester.widget<FocusableSettingsTile>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(FocusableSettingsTile),
        ),
      );
      expect(tile.enabled, isFalse);
      client.githubFailure = false;
      await click(tester, 'Refresh catalog from GitHub');
      await click(tester, label);
      expect(
        find.text(
          'All applications from this list present on this TV are already disabled.',
        ),
        findsOneWidget,
      );
      final absent = tester.widget<Text>(find.textContaining('Absent ·')).data!;
      await click(tester, absent);
      expect(
        find.text(
          'No matching applications from this list are installed on this TV.',
        ),
        findsOneWidget,
      );
      expect(client.copies, isEmpty);
      expect(client.applied, isNull);
    },
  );

  testWidgets(
    'CleanYourTV update and name search precede preview and targeted snapshot',
    (tester) async {
      final client = FakeCleaner();
      client.githubResponses['/repos/Gathin23/cleanyourtv/contents/examples'] =
          jsonEncode([
            {'type': 'dir', 'name': 'TCL_G10'},
            {'type': 'dir', 'name': 'Other'},
            {'type': 'file', 'name': 'ignore'},
          ]);
      client.githubResponses['/Gathin23/cleanyourtv/main/examples/TCL_G10/debloat.txt'] =
          'org.example.video';
      await open(tester, client, 'en');
      await click(tester, 'Refresh applications');
      await click(tester, 'Disable lists');
      await click(tester, 'CleanYourTV examples');
      expect(
        find.text('Refresh the catalog from GitHub first.'),
        findsOneWidget,
      );
      await click(tester, 'Refresh catalog from GitHub');
      await click(tester, 'Search by name');
      await tester.enterText(find.byType(TextField), 'tcl');
      await tester.tap(find.text('Save').last);
      await tester.pumpAndSettle();
      expect(find.text('Other'), findsNothing);
      await click(tester, 'TCL_G10');
      expect(client.applied, isNull);
      await click(tester, 'OK');
      expect(
        client.copies.single['description'],
        'Before applying list: CleanYourTV: TCL_G10',
      );
    },
  );
}
