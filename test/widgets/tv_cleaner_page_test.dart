import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/tv_cleaner.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/tv_cleaner_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> snapshot({bool enabled = true, bool saved = false}) => {
  'status': 'success',
  'identity': {
    'manufacturer': 'Test',
    'model': 'TV',
    'device': 'fixture',
    'fingerprint': 'exact',
  },
  'snapshotSaved': saved,
  'pendingRestore': saved ? 1 : 0,
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
  Map<String, dynamic>? profilesOverride, descriptionsOverride;
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
  Completer<Map<String, dynamic>>? pending;
  @override
  Future<Map<String, dynamic>> call(
    String action, {
    List<String>? packages,
    bool? enable,
  }) async {
    actions.add(action);
    if (action == 'cleanerInventory' && inventoryFailure) {
      return {'status': 'unavailable'};
    }
    if (pending != null) return pending!.future;
    if (action == 'cleanerApply') {
      applied = packages;
      if (partial) {
        enabled = enable!;
        saved = true;
        return {'status': 'partial'};
      }
      enabled = enable!;
      saved = true;
    }
    if (action == 'cleanerSnapshot') saved = true;
    if (action == 'cleanerRestore') {
      enabled = true;
      saved = false;
    }
    return snapshot(enabled: enabled, saved: saved);
  }

  @override
  Future<String?> importFile() async => imported;
}

Future<void> open(
  WidgetTester tester,
  FakeCleaner client,
  String locale,
) async {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
  await tester.tap(tile.first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'failed refresh is not repeated and keeps the previous inventory',
    (tester) async {
      final client = FakeCleaner();
      await open(tester, client, 'en');
      await click(tester, 'Refresh applications');
      client.inventoryFailure = true;
      await click(tester, 'Refresh applications');
      expect(client.actions, ['cleanerInventory', 'cleanerInventory']);
      expect(
        find.text(
          'Action did not complete. Check ADB connectivity and the list format.',
        ),
        findsOneWidget,
      );
      await click(tester, 'All applications');
      expect(find.text('Example video\norg.example.video'), findsOneWidget);
    },
  );
  testWidgets('project catalog matches all four identity fields', (
    tester,
  ) async {
    final client = FakeCleaner()
      ..profilesOverride = {
        'schemaVersion': 1,
        'profiles': [
          {
            'id': 'matching',
            'identity': snapshot()['identity'],
            'packages': ['org.example.video'],
            'verification': 'observedOnly',
          },
          {
            'id': 'wrong-firmware',
            'identity': {
              ...snapshot()['identity'] as Map,
              'fingerprint': 'other',
            },
            'packages': ['org.example.video'],
          },
          {
            'id': 'wrong-model',
            'identity': {...snapshot()['identity'] as Map, 'model': 'other'},
            'packages': ['org.example.video'],
          },
        ],
      };
    await open(tester, client, 'en');
    await click(tester, 'Refresh applications');
    await click(tester, 'Project catalog lists');
    expect(find.textContaining('matching —'), findsOneWidget);
    expect(find.textContaining('wrong-firmware'), findsNothing);
    expect(find.textContaining('wrong-model'), findsNothing);
    final title = tester.widget<Text>(find.textContaining('matching —')).data!;
    await click(tester, title);
    expect(client.actions, ['cleanerInventory']);
    await click(tester, 'Cancel');
    expect(client.applied, isNull);
  });
  for (final verified in [false, true]) {
    testWidgets(
      'recommendation requires reviewed firmware and package approval: $verified',
      (tester) async {
        final client = FakeCleaner()
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
        await click(tester, 'Disable verified applications');
        expect(client.applied, isNull);
        if (verified) {
          expect(find.text('Disable application'), findsOneWidget);
          await click(tester, 'OK');
          expect(client.applied, ['org.example.video']);
        } else {
          expect(
            find.text(
              'This firmware has no verified list that preserves all features.',
            ),
            findsOneWidget,
          );
          expect(client.actions, ['cleanerInventory']);
        }
      },
    );
  }
  testWidgets('remote navigation and Back preserve the application list', (
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
    expect(client.actions.last, 'cleanerSnapshot');
    await click(tester, 'All applications');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Application not identified.'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Example video\norg.example.video'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('TV cleanup manager'), findsOneWidget);
    expect(client.actions, ['cleanerInventory', 'cleanerSnapshot']);
  });
  for (final locale in ['ru', 'en']) {
    final ru = locale == 'ru';
    testWidgets(
      'explicit collection, manual details and confirmed change $locale',
      (tester) async {
        final client = FakeCleaner();
        await open(tester, client, locale);
        expect(client.actions, isEmpty);
        await click(
          tester,
          ru ? 'Обновить список приложений' : 'Refresh applications',
        );
        expect(client.actions, ['cleanerInventory']);
        await click(tester, ru ? 'Все приложения' : 'All applications');
        await click(tester, 'Example video\norg.example.video');
        expect(
          find.text(
            ru ? 'Приложение не опознано.' : 'Application not identified.',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            ru
                ? 'Назначение и зависимости не подтверждены. Риск отключения неизвестен.'
                : 'Purpose and dependencies are unconfirmed. Disabling risk is unknown.',
          ),
          findsOneWidget,
        );
        expect(
          find.text(ru ? 'Риск отключения' : 'Disabling risk'),
          findsOneWidget,
        );
        await click(
          tester,
          ru ? 'Отключить приложение' : 'Disable application',
        );
        expect(client.actions, ['cleanerInventory']);
        await click(tester, ru ? 'Отмена' : 'Cancel');
        expect(client.actions, ['cleanerInventory']);
        await click(
          tester,
          ru ? 'Отключить приложение' : 'Disable application',
        );
        await click(tester, ru ? 'ОК' : 'OK');
        expect(client.applied, ['org.example.video']);
        expect(
          find.text(ru ? 'Включить приложение' : 'Enable application'),
          findsOneWidget,
        );
        await click(tester, ru ? 'Включить приложение' : 'Enable application');
        await click(tester, ru ? 'ОК' : 'OK');
        expect(client.enabled, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('protected apps have visible description and no disable action', (
    tester,
  ) async {
    final client = FakeCleaner();
    await open(tester, client, 'en');
    await click(tester, 'Refresh applications');
    await click(tester, 'All applications');
    await click(tester, 'System UI\ncom.android.systemui');
    expect(find.text('Protected from disabling'), findsOneWidget);
    final tile = tester.widget<FocusableSettingsTile>(
      find.ancestor(
        of: find.text('Disable application'),
        matching: find.byType(FocusableSettingsTile),
      ),
    );
    expect(tile.enabled, isFalse);
    expect(client.actions, ['cleanerInventory']);
  });
  testWidgets('local list previews skips and rejects firmware mismatch', (
    tester,
  ) async {
    final client = FakeCleaner()
      ..imported =
          'org.example.video\ncom.android.systemui\norg.example.missing';
    await open(tester, client, 'en');
    await click(tester, 'Refresh applications');
    await click(tester, 'Disable using a local list');
    expect(
      find.text(
        'Skipped: protected, missing or already in the requested state',
      ),
      findsOneWidget,
    );
    expect(client.actions, ['cleanerInventory']);
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
    expect(client.actions.where((a) => a == 'cleanerApply').length, 1);
  });
  testWidgets(
    'partial mutation refreshes inventory and retains recovery controls',
    (tester) async {
      final client = FakeCleaner()
        ..partial = true
        ..imported = 'org.example.video';
      await open(tester, client, 'en');
      await click(tester, 'Refresh applications');
      await click(tester, 'Disable using a local list');
      await click(tester, 'OK');
      expect(client.actions, [
        'cleanerInventory',
        'cleanerApply',
        'cleanerInventory',
      ]);
      final restore = tester.widget<FocusableSettingsTile>(
        find.ancestor(
          of: find.text('Restore manager changes'),
          matching: find.byType(FocusableSettingsTile),
        ),
      );
      expect(restore.enabled, isTrue);
    },
  );
  testWidgets(
    'no safe recommendation triggers no mutation; copy disabled list explicitly',
    (tester) async {
      final client = FakeCleaner()..enabled = false;
      await open(tester, client, 'en');
      await click(tester, 'Refresh applications');
      await click(tester, 'Disable verified applications');
      expect(client.actions, ['cleanerInventory']);
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await click(tester, 'Export disabled applications');
      await tester.tap(find.text('Copy report'));
      await tester.pumpAndSettle();
      final copy = calls.singleWhere(
        (call) => call.method == 'Clipboard.setData',
      );
      final data = jsonDecode(copy.arguments['text'] as String) as Map;
      expect(data['reportType'], 'tvDisableList');
      expect(data['packages'], ['org.example.video']);
    },
  );
  testWidgets(
    'busy prevents duplicate work and disposing pending request is safe',
    (tester) async {
      final client = FakeCleaner()..pending = Completer<Map<String, dynamic>>();
      await open(tester, client, 'en');
      await tester.tap(find.text('Refresh applications'));
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(client.actions, ['cleanerInventory']);
      await tester.pumpWidget(const SizedBox());
      client.pending!.complete(snapshot());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
