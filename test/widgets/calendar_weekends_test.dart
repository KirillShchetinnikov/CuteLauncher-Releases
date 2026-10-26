import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/panel_calendar_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final locale in ['ru', 'en', 'ar']) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'weekend dates stay red including today: $locale $brightness',
        (tester) async {
          final scheme = ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: brightness,
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(colorScheme: scheme),
              locale: Locale(locale),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(
                body: PanelCalendarDialog(today: DateTime(2026, 10, 4)),
              ),
            ),
          );
          await tester.pumpAndSettle();

          Text dayText(int day) => tester.widget<Text>(
            find.descendant(
              of: find.byKey(ValueKey('calendar_day_$day')),
              matching: find.byType(Text),
            ),
          );
          // October 2 is Friday, 3 is Saturday, 4 is Sunday (today), 5 is Monday.
          expect(dayText(2).style?.color, isNull);
          expect(dayText(3).style?.color, scheme.error);
          expect(dayText(4).style?.color, scheme.error);
          expect(dayText(5).style?.color, isNull);
          final today = tester.widget<Container>(
            find.byKey(const ValueKey('calendar_day_4')),
          );
          expect(
            (today.decoration as BoxDecoration).color,
            scheme.errorContainer,
          );

          // Changing the month must follow dates, not fixed column positions.
          await tester.tap(find.byIcon(Icons.chevron_right));
          await tester.pumpAndSettle();
          expect(dayText(1).style?.color, scheme.error); // Sunday in November.
          expect(dayText(2).style?.color, isNull); // Monday.
          expect(dayText(7).style?.color, scheme.error); // Saturday.
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
