import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/widgets/date_time_widget.dart';
import 'package:flauncher/panel_clock_style.dart';
import 'package:flauncher/widgets/animated_character.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flauncher/l10n/app_localizations.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en_US');
  });

  group('DateTimeWidget Tests', () {
    testWidgets(
      'clock colors, glow and colon update without changing geometry',
      (tester) async {
        for (final format in ['H:mm', 'HH:mm', 'hh:mm', 'h:mm a', 'hh:mm a']) {
          for (final locale in ['en', 'ru', 'ar']) {
            Future<void> pump(bool showColon) => tester.pumpWidget(
              MaterialApp(
                locale: Locale(locale),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Center(
                  child: DateTimeWidget(
                    format,
                    fixedTime: DateTime(2026, 11, 4, 3, 45),
                    animate: false,
                    textStyle: const TextStyle(
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 8)],
                    ),
                    clockStyle: PanelClockStyle({
                      'hoursColor': Colors.red.toARGB32(),
                      'minutesColor': Colors.blue.toARGB32(),
                      'showColon': showColon,
                    }),
                  ),
                ),
              ),
            );
            await pump(true);
            final size = tester.getSize(find.byType(Row));
            final chars = tester
                .widgetList<AnimatedCharacter>(find.byType(AnimatedCharacter))
                .toList();
            final colon = chars.indexWhere((c) => c.character == ':');
            expect(
              chars.map((c) => c.character).join(),
              DateFormat(format, locale).format(DateTime(2026, 11, 4, 3, 45)),
            );
            for (var i = 0; i < chars.length; i++) {
              final color = i < colon
                  ? Colors.red
                  : i > colon && i <= colon + 2
                  ? Colors.blue
                  : Colors.white;
              expect(chars[i].textStyle!.color!.toARGB32(), color.toARGB32());
              if (color != Colors.white) {
                expect(
                  chars[i].textStyle!.shadows!.single.color.toARGB32(),
                  color.toARGB32(),
                );
              }
            }
            await pump(false);
            expect(tester.getSize(find.byType(Row)), size);
            final hidden = tester.widget<Opacity>(
              find
                  .ancestor(of: find.text(':'), matching: find.byType(Opacity))
                  .first,
            );
            expect(hidden.opacity, 0);
            expect(tester.takeException(), isNull);
          }
        }
      },
    );
    testWidgets('date follows app locale and updates when language changes', (
      tester,
    ) async {
      for (final locale in ['en', 'ru', 'en']) {
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: DateTimeWidget('MMMM', animate: false)),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<AnimatedTimeDisplay>(find.byType(AnimatedTimeDisplay))
              .displayText,
          DateFormat('MMMM', locale).format(DateTime.now()),
        );
      }
    });

    testWidgets('Renders static text when animate is false', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DateTimeWidget('HH:mm:ss', animate: false)),
        ),
      );

      final display = tester.widget<AnimatedTimeDisplay>(
        find.byType(AnimatedTimeDisplay),
      );
      expect(display.animate, isFalse);
      expect(display.displayText, matches(RegExp(r'^\d{2}:\d{2}:\d{2}$')));
      expect(
        tester
            .widgetList<AnimatedCharacter>(find.byType(AnimatedCharacter))
            .every((character) => !character.animate),
        isTrue,
      );
    });

    testWidgets('Renders AnimatedTimeDisplay when animate is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DateTimeWidget('HH:mm:ss', animate: true)),
        ),
      );

      expect(find.byType(AnimatedTimeDisplay), findsOneWidget);
    });

    testWidgets('Updates format when widget is updated', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DateTimeWidget('HH:mm', animate: false)),
        ),
      );

      final initialText = tester
          .widget<AnimatedTimeDisplay>(find.byType(AnimatedTimeDisplay))
          .displayText;

      // Update the widget with a new format string
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DateTimeWidget('HH:mm:ss', animate: false)),
        ),
      );

      final newText = tester
          .widget<AnimatedTimeDisplay>(find.byType(AnimatedTimeDisplay))
          .displayText;

      expect(newText, isNot(equals(initialText)));
      expect(
        newText.contains(':'),
        isTrue,
      ); // Ensures standard time formatting is active
    });

    testWidgets('Timer correctly ticks and is disposed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            // Use 's' so interval is 1 second, but we pass custom interval to speed it up
            body: DateTimeWidget(
              'ss',
              animate: false,
              updateInterval: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      // Verify widget builds without crashing
      expect(find.byType(AnimatedTimeDisplay), findsOneWidget);

      // Advance time to allow the Timer to fire at least once
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // Unmount the widget to trigger dispose and cancel the Timer
      await tester.pumpWidget(Container());

      // If the timer was not canceled properly, pumpWidget would fail or tests would hang.
      expect(find.byType(DateTimeWidget), findsNothing);
    });

    testWidgets('Refreshes time when app lifecycle state changes to resumed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DateTimeWidget('HH:mm:ss', animate: false)),
        ),
      );

      expect(find.byType(AnimatedTimeDisplay), findsOneWidget);

      // Simulate app lifecycle state transition to paused and back to resumed
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(find.byType(AnimatedTimeDisplay), findsOneWidget);
    });
  });
}
