import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/settings/background_startup_page.dart';
import 'package:flauncher/widgets/settings/auto_launch_page.dart';
import 'package:flauncher/widgets/settings/settings_help.dart';

void main() {
  const channel = MethodChannel('cutelauncher/auto_launch');
  testWidgets('slow catalog receives initial row focus and saves keep it', (
    tester,
  ) async {
    final loaded = Completer<Map<String, dynamic>>();
    final saving = Completer<Map<String, dynamic>>();
    var saves = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) {
      if (call.method == 'backgroundSetApp') {
        saves++;
        return saving.future;
      }
      return loaded.future;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: BackgroundStartupPage()),
      ),
    );
    await tester.pump();
    loaded.complete({
      'apps': [
        {
          'packageName': 'org.example.a',
          'name': 'Example',
          'available': true,
          'selected': false,
        },
      ],
    });
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('Example'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(Focus.of(tester.element(find.text('Example'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(saves, 1);
    saving.complete({
      'status': 'success',
      'selected': ['org.example.a'],
    });
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_box), findsOneWidget);
    expect(Focus.of(tester.element(find.text('Example'))).hasFocus, isTrue);
  });
  for (final language in ['ru', 'en']) {
    testWidgets('subsection navigation, help and long names at 130%: $language', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(440, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const name =
          'Приложение с очень длинным названием для проверки переноса текста в узкой панели';
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'info') return {'mode': 'off'};
        return {
          'apps': [
            {
              'packageName': 'org.example.a',
              'name': name,
              'available': true,
              'selected': true,
            },
          ],
        };
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.3)),
            child: child ?? const SizedBox.shrink(),
          ),
          routes: {
            BackgroundStartupPage.routeName: (_) =>
                const Scaffold(body: BackgroundStartupPage()),
          },
          home: const Scaffold(body: AutoLaunchPage()),
        ),
      );
      await tester.pumpAndSettle();
      final title = language == 'ru' ? 'Приложения в фоне' : 'Background apps';
      await tester.ensureVisible(find.text(title));
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      expect(find.text(name), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byType(SettingsHelp).last);
      await tester.tap(
        find.descendant(of: find.byType(SettingsHelp).last, matching: find.byType(FocusableSettingsTile)).first,
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          language == 'ru' ? 'Отметьте приложения' : 'Select apps',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      Navigator.of(tester.element(find.byType(BackgroundStartupPage))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(BackgroundStartupPage), findsNothing);
      expect(find.text(title), findsOneWidget);
    });
  }
  for (final success in [true, false]) {
    testWidgets('remote selection persists only on successful save: $success', (
      tester,
    ) async {
      final saved = <List<dynamic>>[];
      final selected = <String>{'org.example.missing'};
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'backgroundSetApp') {
          final args = call.arguments as Map;
          final next = {...selected};
          if (args['enabled'] == true) {
            next.add(args['app'] as String);
          } else {
            next.remove(args['app']);
          }
          saved.add(next.toList());
          if (success) {
            selected.clear();
            selected.addAll(next);
          }
          return {
            'status': success ? 'success' : 'unavailable',
            'selected': selected.toList(),
          };
        }
        return {
          'apps': [
            {
              'packageName': 'org.example.a',
              'name': 'Example',
              'available': true,
              'selected': false,
            },
            {
              'packageName': 'org.example.missing',
              'name': 'Missing',
              'available': false,
              'selected': true,
            },
            {
              'packageName': 'org.example.unsupported',
              'name': 'Unsupported',
              'available': false,
              'selected': false,
            },
          ],
        };
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: BackgroundStartupPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SettingsHelp), findsOneWidget);
      expect(find.textContaining('Отметьте приложения'), findsNothing);
      await tester.tap(find.text('Example'));
      await tester.pumpAndSettle();
      expect(saved.single, contains('org.example.a'));
      expect(find.byIcon(Icons.check_box), findsNWidgets(success ? 2 : 1));
      if (!success) {
        expect(
          find.text('Не удалось загрузить или сохранить настройки'),
          findsOneWidget,
        );
      }
      // Pointer activation remembers the same row, so OK toggles it back.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        saved.last,
        success ? isNot(contains('org.example.a')) : contains('org.example.a'),
      );
      await tester.tap(find.text('Missing'));
      await tester.pumpAndSettle();
      expect(saved.last, isNot(contains('org.example.missing')));
      final count = saved.length;
      await tester.tap(find.text('Unsupported'));
      await tester.pumpAndSettle();
      expect(saved.length, count);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'load failure offers retry and recovers without clearing selection',
    (tester) async {
      var calls = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        _,
      ) async {
        if (++calls == 1) throw PlatformException(code: 'unavailable');
        return {
          'apps': [
            {
              'packageName': 'org.example.a',
              'name': 'Example',
              'available': true,
              'selected': true,
            },
          ],
        };
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: BackgroundStartupPage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();
      expect(find.text('Example'), findsOneWidget);
      expect(find.byIcon(Icons.check_box), findsOneWidget);
    },
  );
}
