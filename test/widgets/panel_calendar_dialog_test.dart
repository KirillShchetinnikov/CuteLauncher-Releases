import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/panel_calendar_dialog.dart';

void main() {
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
