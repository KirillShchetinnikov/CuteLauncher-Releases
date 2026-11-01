import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/background_startup_service.dart';
import 'package:flauncher/widgets/application_info_panel.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/background_startup_page.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../mocks.dart';
import '../mocks.mocks.dart';

void main() {
  const channel = MethodChannel('cutelauncher/auto_launch');
  for (final fails in [false, true]) {
    testWidgets('list and real app menu share selection; write failure=$fails', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1100, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final selected = <String>{'org.example.other'};
      final writes = <Map>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'backgroundSetApp') {
          final args = call.arguments as Map;
          writes.add(args);
          expect(args.keys.toSet(), {'app', 'enabled'});
          if (fails) return {'status': 'unavailable'};
          if (args['enabled'] == true) {
            selected.add(args['app'] as String);
          } else {
            selected.remove(args['app']);
          }
          return {'status': 'success', 'selected': selected.toList()};
        }
        return {
          'apps': [
            {
              'packageName': 'org.example.app',
              'name': 'Example',
              'available': true,
              'selected': selected.contains('org.example.app'),
            },
            {
              'packageName': 'org.example.other',
              'name': 'Other',
              'available': true,
              'selected': true,
            },
          ],
        };
      });
      const adb = MethodChannel('cutelauncher/adb');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        adb,
        (_) async => {'status': 'success', 'running': false},
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          adb,
          null,
        );
      });
      final apps = MockAppsService();
      final app = fakeApp(
        packageName: 'org.example.app',
        name: 'Example',
        version: '1',
      );
      when(apps.categories).thenReturn([]);
      when(apps.applications).thenReturn([app]);
      when(apps.isTileHidden(any)).thenReturn(false);
      when(apps.hasCustomBanner(any)).thenAnswer((_) async => false);
      when(apps.getAppIcon(any)).thenAnswer((_) async => Uint8List(0));
      final service = BackgroundStartupService();
      addTearDown(service.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppsService>.value(value: apps),
            ChangeNotifierProvider<BackgroundStartupService>.value(
              value: service,
            ),
          ],
          child: MaterialApp(
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Row(
                children: [
                  const Expanded(child: BackgroundStartupPage()),
                  Expanded(
                    child: ApplicationInfoPanel(
                      embedded: true,
                      category: null,
                      application: app,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final menuToggle = find.byKey(const ValueKey('app_background_startup'));
      bool menuValue() =>
          tester.widget<RoundedSwitchListTile>(menuToggle).value;
      final list = find.byType(BackgroundStartupPage);
      Finder listName() =>
          find.descendant(of: list, matching: find.text('Example'));
      Finder checkboxes() =>
          find.descendant(of: list, matching: find.byIcon(Icons.check_box));
      expect(menuValue(), isFalse);
      await tester.tap(listName());
      await tester.pumpAndSettle();
      expect(menuValue(), !fails);
      expect(checkboxes(), findsNWidgets(fails ? 1 : 2));
      // An unrelated native selection added after catalog loading must survive.
      selected.add('org.example.external');
      await tester.ensureVisible(menuToggle);
      await tester.tap(
        find.descendant(
          of: menuToggle,
          matching: find.text('Автозагрузка в фоне'),
        ),
      );
      await tester.pumpAndSettle();
      expect(menuValue(), isFalse);
      expect(checkboxes(), findsOneWidget);
      expect(selected, contains('org.example.other'));
      expect(selected, contains('org.example.external'));
      expect(writes.length, 2);
      expect(writes.last['enabled'], fails);
      // Opening a fresh selection reader sees the same persisted value.
      final reopened = BackgroundStartupService();
      await reopened.refresh();
      expect(reopened.selected('org.example.app'), isFalse);
      reopened.dispose();
      expect(tester.takeException(), isNull);
    });
  }
}
