import 'dart:async';
import 'dart:io';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/action_notice.dart';
import 'package:flauncher/providers/update_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/update_notification.dart';
import 'package:flauncher/widgets/settings/updates_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'panel_backdrop_assertions.dart';

import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';

void main() {
  for (final state in [AppLifecycleState.paused, AppLifecycleState.inactive]) {
    testWidgets('Late update waits for resume from $state and expires', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        automaticUpdatesKey: true,
        updateCheckTimeKey: DateTime.now().millisecondsSinceEpoch,
      });
      final response = Completer<Map<String, dynamic>?>();
      final service = UpdateService(
        await SharedPreferences.getInstance(),
        environment: () async => {
          'play': false,
          'version': '1.0.0',
          'versionCode': 2,
          'abis': ['armeabi-v7a'],
        },
        lookup: () => response.future,
      );
      final focus = FocusNode();
      addTearDown(focus.dispose);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: service,
          child: MaterialApp(
            builder: (_, child) =>
                ActionNoticeHost(child: UpdateNotification(child: child!)),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TextButton(
                autofocus: true,
                focusNode: focus,
                onPressed: () {},
                child: const Text('Home'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final check = service.check(force: true);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(state);
      response.complete({
        'tag_name': 'v1.0.0+3',
        'assets': [
          {
            'name': 'app-release.apk',
            'size': 3,
            'browser_download_url':
                'https://github.com/$updateRepository/releases/download/v1.0.0+3/app.apk',
          },
        ],
      });
      await check;
      await tester.pump(const Duration(seconds: 10));
      expect(find.textContaining('v1.0.0'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('v1.0.0'), findsOneWidget);
      expect(find.textContaining('v1.0.0+3'), findsNothing);
      expect(focus.hasFocus, isTrue);
      await tester.pump(const Duration(seconds: 5));
      expect(find.textContaining('v1.0.0'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(state);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.textContaining('v1.0.0'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      service.dispose();
    });
  }
  testWidgets(
    'Transient notice preserves focus; update settings retain download progress',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        automaticUpdatesKey: true,
        updateCheckTimeKey: DateTime.now().millisecondsSinceEpoch,
      });
      final downloaded = Completer<File>();
      final installed = Completer<String?>();
      late void Function(double) reportProgress;
      final service = UpdateService(
        await SharedPreferences.getInstance(),
        environment: () async => {
          'play': false,
          'version': '1.0.0',
          'versionCode': 2,
          'abis': ['armeabi-v7a'],
          'directory': '.',
        },
        download: (_, _, progress) {
          reportProgress = progress;
          return downloaded.future;
        },
        installer: () => installed.future,
        lookup: () async => {
          'tag_name': 'v1.0.0+3',
          'assets': [
            {
              'name': 'app-release.apk',
              'size': 3,
              'browser_download_url':
                  'https://github.com/$updateRepository/releases/download/v1.0.0+3/app.apk',
            },
          ],
        },
      );
      final focus = FocusNode();
      final settings = SettingsService(await SharedPreferences.getInstance());
      addTearDown(settings.dispose);
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: service),
            ChangeNotifierProvider.value(value: settings),
          ],
          child: MaterialApp(
            builder: (_, child) =>
                ActionNoticeHost(child: UpdateNotification(child: child!)),
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Column(
                children: [
                  Builder(
                    builder: (context) => TextButton(
                      autofocus: true,
                      focusNode: focus,
                      onPressed: () => showLauncherDialog<void>(
                        context: context,
                        barrierColor: Colors.transparent,
                        builder: (_) => const SettingsPanel(
                          initialRoute: UpdatesPage.routeName,
                        ),
                      ),
                      child: const Text('Home'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('v1.0.0'), findsNothing);
      await service.check(force: true);
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isTrue);
      expect(find.textContaining('v1.0.0'), findsOneWidget);
      expect(find.textContaining('v1.0.0+3'), findsNothing);
      await tester.pump(const Duration(seconds: 5));
      expect(find.textContaining('v1.0.0'), findsNothing);
      await service.check(force: true);
      await tester.pumpAndSettle();
      expect(find.textContaining('v1.0.0'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expectSinglePanelBackdrop(tester);
      await tester.pumpAndSettle();
      expect(find.byType(UpdatesPage), findsOneWidget);
      expect(find.text('Обновлять на пререлизы'), findsOneWidget);
      await tester.ensureVisible(
        find.text(
          AppLocalizations.of(tester.element(find.byType(UpdatesPage)))!
              .updateDownloadInstall,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(
          AppLocalizations.of(tester.element(find.byType(UpdatesPage)))!
              .updateDownloadInstall,
        ),
      );
      await tester.pump();
      reportProgress(.5);
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Обновление приложения: 50%'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.text('Обновление приложения: 50%'), findsOneWidget);
      downloaded.complete(File('update.apk'));
      await tester.pump();
      expect(find.text('Обновление приложения: 50%'), findsNothing);
      installed.complete('permission');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      service.dispose();
    },
  );
}
