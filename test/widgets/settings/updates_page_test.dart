import 'dart:async';
import 'dart:io';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/update_service.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/settings/updates_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final locale in [const Locale('ru', 'RU'), const Locale('de')]) {
    testWidgets('release notes open and scroll by remote in $locale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(350, 540);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      var notes = Completer<String?>();
      final requests = <(String, String)>[];
      final service = UpdateService(
        await SharedPreferences.getInstance(),
        environment: () async => {
          'play': false,
          'version': '1.0.0',
          'versionCode': 2,
          'abis': ['armeabi-v7a'],
          'directory': 'unused',
        },
        lookup: () async => null,
        releaseNotes: (tag, language) {
          requests.add((tag, language));
          return notes.future;
        },
      );
      addTearDown(service.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: service,
          child: MaterialApp(
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: UpdatesPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(UpdatesPage)))!;
      final opener = find.text(l.updateWhatsNew);
      expect(opener, findsNothing);

      const tag = 'v1.1.0+3';
      service.release = AppRelease(tag, Uri(), 3, null);
      service.notifyListeners();
      await tester.pumpAndSettle();
      expect(requests, isEmpty);
      Focus.of(tester.element(opener)).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      final dialog = find.byType(LauncherAlertDialog);
      expect(dialog, findsOneWidget);
      expect(find.text('${l.updateWhatsNew} · v1.1.0'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(requests, [(tag, locale.languageCode)]);

      final text = locale.languageCode == 'ru'
          ? 'Новая настройка'
          : 'New setting';
      notes.complete(
        List.generate(30, (index) => '- $text ${index + 1}').join('\n'),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('• $text 1'), findsOneWidget);
      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: dialog, matching: find.byType(Scrollable)),
      );
      expect(scrollable.position.pixels, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, greaterThan(0));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, 0);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(dialog, findsNothing);
      expect(Focus.of(tester.element(opener)).hasFocus, isTrue);

      notes = Completer<String?>();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      notes.completeError(const FormatException('offline'));
      await tester.pumpAndSettle();
      expect(find.text(l.updateNotesUnavailable), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(dialog, findsNothing);
      expect(service.failed, isFalse);
      expect(service.release?.version, tag);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('each APK rejection displays its reason on the narrow page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(350, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final service = UpdateService(
      await SharedPreferences.getInstance(),
      environment: () async => {
        'play': false,
        'version': '1.6.1',
        'versionCode': 182,
        'abis': ['armeabi-v7a'],
        'directory': 'unused',
      },
      lookup: () async => null,
    );
    addTearDown(service.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: service,
        child: MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(body: UpdatesPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l = AppLocalizations.of(tester.element(find.byType(UpdatesPage)))!;
    final messages = {
      'invalid_package': l.updateWrongPackage,
      'invalid_version': l.updateNotNewer,
      'invalid_signers': l.updateSignersUnavailable,
      'invalid_signature': l.updateSignatureMismatch,
      'invalid_file': l.updateInvalidFile,
      'invalid_verification': l.updateVerificationFailed,
      'invalid': l.updateIncompatible,
    };
    for (final entry in messages.entries) {
      service.installStatus = entry.key;
      service.failed = true;
      service.notifyListeners();
      await tester.pumpAndSettle();
      expect(updateFailureMessage(l, service), entry.value);
      expect(find.text(entry.value), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Russian update page works with remote at narrow panel width',
      (tester) async {
    tester.view.physicalSize = const Size(350, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    var requests = 0, installs = 0;
    final service = UpdateService(preferences,
        environment: () async => {
              'play': false,
              'version': '1.0.0',
              'versionCode': 2,
              'abis': ['armeabi-v7a'],
              'directory': 'unused'
            },
        lookup: () async {
          requests++;
          return {
            'tag_name': 'v1.1.0+3',
            'assets': [
              {
                'name': 'CuteLauncher-universal-release.apk',
                'size': 3,
                'browser_download_url':
                    'https://github.com/$updateRepository/releases/download/v1.1.0/app.apk'
              }
            ]
          };
        },
        download: (_, _, progress) async {
          progress(1);
          return File('unused');
        },
        installer: () async {
          installs++;
          return 'permission';
        });
    addTearDown(service.dispose);
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: service,
        child: MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate
          ],
          theme: ThemeData.dark(),
          home: const Scaffold(body: UpdatesPage()),
        )));
    await tester.pumpAndSettle();
    expect(find.text('Новый совместимый релиз не найден.'), findsNothing);
    expect(Focus.of(tester.element(find.text('Обновлять на пререлизы'))).hasFocus, isTrue);
    Focus.of(tester.element(find.text('Проверить сейчас'))).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(requests, 1);
    expect(find.textContaining('v1.1.0'), findsWidgets);
    expect(find.textContaining('v1.1.0+3'), findsNothing);
    await tester.ensureVisible(find.text('Показывать уведомления об обновлении'));
    await tester.tap(find.text('Показывать уведомления об обновлении'));
    await tester.pumpAndSettle();
    expect(service.notificationsEnabled, isFalse);
    expect(preferences.getBool(updateNotificationsKey), isFalse);
    expect(service.release, isNotNull);
    await tester.ensureVisible(find.text('Скачать и установить'));
    await tester.tap(find.text('Скачать и установить'));
    await tester.pumpAndSettle();
    expect(installs, 1);
    expect(find.text('Установить загруженное обновление'), findsOneWidget);
    final l = AppLocalizations.of(tester.element(find.byType(UpdatesPage)))!;
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(find.text(l.updatePermission), findsOneWidget);
    await tester.ensureVisible(find.text(l.updateInstall));
    await tester.tap(find.text(l.updateInstall));
    await tester.pumpAndSettle();
    expect(installs, 2);
    expect(tester.takeException(), isNull);
  });
}
