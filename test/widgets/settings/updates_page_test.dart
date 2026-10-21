import 'dart:io';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/update_service.dart';
import 'package:flauncher/widgets/settings/updates_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
            'tag_name': 'v1.1.0',
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
    expect(tester.takeException(), isNull);
  });
}
