import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/models/app.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/night_mode_service.dart';
import 'package:flauncher/widgets/settings/night_mode_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/settings_help.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';

import '../../mocks.mocks.dart';

void main() {
  testWidgets(
    'picture exclusions work with remote and preserve selection on unsupported firmware',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      const channel = MethodChannel('cutelauncher/night');
      const tcl = MethodChannel('cutelauncher/tcl_blue_light');
      int? current = 19;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async => call.method == 'pictureMode'
            ? current
            : {'permission': false, 'usagePermission': false},
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        tcl,
        (_) async => {'status': 'unsupported'},
      );
      final service = NightModeService(await SharedPreferences.getInstance());
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: service,
          child: const MaterialApp(
            locale: Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: NightModePage(section: 'picture')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Текущий режим: Кино (HDR)'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Обычный'), 180);
      expect(find.text('Обычный'), findsOneWidget);
      final movie = find.text('Кино (HDR)');
      await tester.scrollUntilVisible(movie.hitTestable(), 180);
      Focus.of(tester.element(movie)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(service.configuration.ignoredPictureModes, [19]);
      expect(service.configuration.enabled, isFalse);
      expect(
        NightModeConfiguration.decode(
          (await SharedPreferences.getInstance()).getString(nightModeKey),
        ).ignoredPictureModes,
        [19],
      );
      current = null;
      await service.refreshPictureMode();
      await tester.pumpAndSettle();
      final outer = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
      outer.jumpTo(outer.minScrollExtent);
      await tester.pumpAndSettle();
      await toggleSettingsHelp(tester, 'Текущий режим изображения недоступен');
      expect(
        find.textContaining('Текущий режим изображения недоступен'),
        findsOneWidget,
      );
      expect(service.configuration.ignoredPictureModes, [19]);
      await toggleSettingsHelp(tester, 'Текущий режим изображения недоступен');
      await tester.scrollUntilVisible(movie.hitTestable(), 180);
      await tester.tap(movie);
      await tester.pumpAndSettle();
      expect(service.configuration.ignoredPictureModes, isEmpty);
      await tester.scrollUntilVisible(find.text('HDR'), -180);
      expect(find.text('HDR'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Dolby Vision'), 180);
      expect(find.text('Dolby Vision'), findsOneWidget);
      expect(service.configuration.ignoredPictureModes, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      service.dispose();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(tcl, null);
    },
  );

  testWidgets(
    'submenu offers only All apps and preserves stored exclusions with explicit access',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      const channel = MethodChannel('cutelauncher/night');
      const tcl = MethodChannel('cutelauncher/tcl_blue_light');
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        return {'permission': false, 'usagePermission': false};
      });
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        tcl,
        (_) async => {'status': 'unsupported'},
      );
      final service = NightModeService(await SharedPreferences.getInstance());
      await service.configure(
        const NightModeConfiguration(excludedPackages: ['com.absent.player']),
      );
      final apps = MockAppsService();
      when(apps.getAppIcon(any)).thenAnswer((_) async => kTransparentImage);
      final player = App(
          packageName: 'com.example.player',
          name: 'Плеер',
          version: '1',
          hidden: false,
        );
      final systemPlayer = App(packageName: 'com.example.systemplayer',
        name: 'Системный плеер', version: '1', hidden: false)..isSystem = true;
      final systemService = App(packageName: 'com.example.service',
        name: 'Системная служба', version: '1', hidden: false)
        ..isSystem = true
        ..isLaunchable = false;
      final hidden = App(packageName: 'com.example.hidden',
        name: 'Скрытый плеер', version: '1', hidden: true);
      when(apps.applications).thenReturn([player, systemPlayer, systemService, hidden]);
      when(apps.categories).thenReturn([
        Category.withApplications(name: 'All apps', systemKey: 'all_apps',
          applications: [player, systemPlayer]),
        Category.withApplications(name: 'Other', applications: [systemService, hidden]),
      ]);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppsService>.value(value: apps),
            ChangeNotifierProvider.value(value: service),
          ],
          child: const MaterialApp(
            locale: Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: NightModePage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Игнорирование входов'));
      await tester.pumpAndSettle();
      final ignoreHdmi = find.text('Игнорировать HDMI-входы');
      await tester.ensureVisible(ignoreHdmi);
      expect(service.configuration.ignoreHdmiInputs, isTrue);
      Focus.of(tester.element(ignoreHdmi)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(service.configuration.ignoreHdmiInputs, isFalse);
      expect(calls.where((c) => c.method == 'configure').last.arguments,
          containsPair('ignoreHdmiInputs', false));
      expect(NightModeConfiguration.decode((await SharedPreferences.getInstance())
          .getString('night_mode_configuration')).ignoreHdmiInputs, isFalse);
      await tester.tap(ignoreHdmi);
      await tester.pumpAndSettle();
      expect(service.configuration.ignoreHdmiInputs, isTrue);
      expect(service.configuration.excludedPackages, ['com.absent.player']);
      tester.state<NavigatorState>(find.byType(Navigator).last).pop();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Исключённые приложения (1)'));
      await tester.tap(find.text('Исключённые приложения (1)'));
      await tester.pumpAndSettle();
      expect(find.text('com.absent.player'), findsNothing);
      expect(find.text('Системная служба'), findsNothing);
      expect(find.text('Скрытый плеер'), findsNothing);
      expect(find.text('Системный плеер'), findsOneWidget);
      expect(find.byType(Image), findsNWidgets(2));
      verifyNever(apps.getAppIcon('com.absent.player'));
      verify(apps.getAppIcon('com.example.player')).called(1);
      Focus.of(tester.element(find.text('Плеер'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);

      await tester.pumpAndSettle();
      expect(service.configuration.excludedPackages.toSet(), {
        'com.absent.player',
        'com.example.player',
      });
      expect(service.configuration.enabled, isFalse);
      await tester.tap(find.text('Плеер'));
      await tester.pumpAndSettle();
      expect(
        service.configuration.excludedPackages,
        isNot(contains('com.example.player')),
      );
      await tester.ensureVisible(
        find.text('Разрешить доступ к истории использования'),
      );
      await tester.tap(find.text('Разрешить доступ к истории использования'));
      await tester.pumpAndSettle();
      expect(calls.last.method, 'usagePermission');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      service.dispose();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(tcl, null);
    },
  );
}
