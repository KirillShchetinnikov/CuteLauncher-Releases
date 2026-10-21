import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/screensaver_clock_style_page.dart';
import 'package:flauncher/widgets/settings/settings_help.dart';
import 'package:flauncher/widgets/settings/settings_page_layout.dart';
import 'package:flauncher/widgets/settings/settings_panel_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/settings_help.dart';

Widget app(Widget page) => MaterialApp(
  locale: const Locale('ru'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: page),
);

void main() {
  testWidgets('root settings omit the explanation and its More information button', (
    tester,
  ) async {
    await tester.pumpWidget(app(const SettingsPanelPage()));
    await tester.pumpAndSettle();
    const hint = 'Открыть системное меню телевизора';
    expect(find.text(hint), findsNothing);
    expect(find.byType(SettingsHelp), findsNothing);
    expect(find.text('Подробнее'), findsNothing);
    expect(find.text('Настройки Android TV'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'clock descriptions share one panel and do not change the selection',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService(await SharedPreferences.getInstance());
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: settings,
          child: app(const ScreensaverClockStylePage()),
        ),
      );
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(
        tester.element(find.byType(ScreensaverClockStylePage)),
      )!;
      final previous = settings.screensaverClockStyle;
      expect(find.byType(SettingsHelp), findsOneWidget);
      expect(find.textContaining(l.clockMinimalDescription), findsNothing);
      expect(find.text(l.clockMinimal), findsOneWidget);
      expect(find.text(l.clockDigital), findsOneWidget);
      await toggleSettingsHelp(tester, l.clockMinimalDescription);
      expect(find.textContaining(l.clockMinimalDescription), findsOneWidget);
      expect(find.textContaining(l.clockDigitalDescription), findsOneWidget);
      expect(settings.screensaverClockStyle, previous);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('introductory help is reachable without stealing entry focus', (
    tester,
  ) async {
    final setting = FocusNode();
    addTearDown(setting.dispose);
    await tester.pumpWidget(
      app(
        SettingsPageLayout(
          title: const Text('Настройки'),
          child: ListView(
            children: [
              const SettingsHelp(text: 'Короткое пояснение'),
              FocusableSettingsTile(
                focusNode: setting,
                title: const Text('Параметр'),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(setting.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('Подробнее'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(setting.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });
}
