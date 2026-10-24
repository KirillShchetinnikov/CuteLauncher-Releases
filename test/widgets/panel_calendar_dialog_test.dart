import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/information_settings_page.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/menu_header_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/panel_calendar_dialog.dart';

void main() {
  testWidgets('calendar gear opens the whole information block and restores focus', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final appearance = AppearanceService(prefs);
    final settings = SettingsService(prefs);
    addTearDown(appearance.dispose);
    addTearDown(settings.dispose);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appearance),
        ChangeNotifierProvider.value(value: settings),
      ],
      child: MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: Builder(builder: (context) => TextButton(
          onPressed: () => showLauncherDialog<void>(context: context, styleDialog: false,
            builder: (_) => const PanelCalendarDialog(anchor: Rect.fromLTWH(20, 0, 100, 56))),
          child: const Text('open'),
        ))),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MenuHeaderAction));
    await tester.pumpAndSettle();
    expect(find.byType(InformationSettingsPage), findsOneWidget);
    expect(find.text('Часы, дата и погода'), findsOneWidget);
    expect(find.text('Настройки погоды'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(InformationSettingsPage), findsNothing);
    final action = tester.widget<MenuHeaderAction>(find.byType(MenuHeaderAction));
    expect(action.focusNode!.hasFocus, true);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final locale in ['ru', 'en', 'ar']) {
    testWidgets(
      'calendar localizes weeks, leap month and month navigation: $locale',
      (tester) async {
        tester.view.physicalSize = const Size(960, 540);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) =>
                        PanelCalendarDialog(today: DateTime(2024, 2, 29)),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(PanelCalendarDialog));
        final material = MaterialLocalizations.of(context);
        expect(find.byKey(const ValueKey('calendar_day_29')), findsOneWidget);
        expect(find.byKey(const ValueKey('calendar_day_30')), findsNothing);
        // February 1st 2024 is Thursday: localized column differs by first weekday.
        final expectedColumn = switch (locale) {
          'ru' => 3,
          'ar' => 5,
          _ => 4,
        };
        final bounds = tester.getRect(find.byType(Table));
        final column = locale == 'ar' ? 6 - expectedColumn : expectedColumn;
        expect(
          tester.getCenter(find.byKey(const ValueKey('calendar_day_1'))).dx,
          closeTo(bounds.left + bounds.width / 7 * (column + .5), 1),
        );
        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pumpAndSettle();
        expect(
          find.textContaining(material.formatMonthYear(DateTime(2024, 3))),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('calendar_day_31')), findsOneWidget);
        await tester.tap(find.text(material.currentDateLabel));
        await tester.pumpAndSettle();
        expect(
          find.textContaining(material.formatMonthYear(DateTime(2024, 2))),
          findsOneWidget,
        );
        await tester.tap(find.byIcon(Icons.chevron_left));
        await tester.pumpAndSettle();
        expect(
          find.textContaining(material.formatMonthYear(DateTime(2024, 1))),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
