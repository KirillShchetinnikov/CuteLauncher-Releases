import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/night_mode_service.dart';
import 'package:flauncher/widgets/night_mode_menu.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';

void main() {
  for (final locale in ['ru', 'en']) {
    for (final (scheduled, solar) in [
      (false, false),
      (true, false),
      (true, true),
    ]) {
      testWidgets(
        'master switch preserves schedule and focus: $locale $scheduled $solar',
        (tester) async {
          SharedPreferences.setMockInitialValues({});
          Completer<void>? pending;
          const channel = MethodChannel('cutelauncher/night');
          const tcl = MethodChannel('cutelauncher/tcl_blue_light');
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            (_) async {
              await pending?.future;
              return {'permission': false};
            },
          );
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            tcl,
            (_) async => {'status': 'unsupported'},
          );
          addTearDown(() {
            tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
              channel,
              null,
            );
            tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
              tcl,
              null,
            );
          });
          final prefs = await SharedPreferences.getInstance();
          final service = NightModeService(prefs);
          final now = DateTime.now();
          final initial = NightModeConfiguration(
            enabled: true,
            scheduled: scheduled,
            solar: solar,
            startHour: (now.hour + 22) % 24,
            endHour: (now.hour + 6) % 24,
            dim: 70,
            warmth: 30,
            overrideMode: scheduled && !solar ? 'off' : 'none',
            overrideUntil: scheduled && !solar
                ? now.add(const Duration(hours: 2)).millisecondsSinceEpoch
                : 0,
          );
          await service.configure(initial);
          await tester.pumpWidget(
            ChangeNotifierProvider.value(
              value: service,
              child: MaterialApp(
                locale: Locale(locale),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const Scaffold(
                  body: NightModeMenu(anchor: Rect.fromLTWH(20, 20, 40, 40)),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final master = find.byKey(const ValueKey('night_mode_enabled'));
          final node = tester.widget<RoundedSwitchListTile>(master).focusNode!;
          final temporary = find.byKey(const ValueKey('night_mode_temporary'));
          if (scheduled) {
            expect(
              tester.getTopLeft(master).dy,
              greaterThan(tester.getTopLeft(temporary).dy),
            );
            expect(
              tester.widget<FocusableSettingsTile>(temporary).enabled,
              !solar,
            );
          } else {
            expect(temporary, findsNothing);
          }
          if (scheduled && !solar) {
            final actionNode = tester
                .widget<FocusableSettingsTile>(temporary)
                .focusNode!;
            expect(actionNode.hasFocus, isTrue);
            await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
            await tester.pumpAndSettle();
            expect(node.hasFocus, isTrue);
            await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
            await tester.pumpAndSettle();
            expect(actionNode.hasFocus, isTrue);
          } else {
            expect(node.hasFocus, isTrue);
          }
          node.requestFocus();
          await tester.pump();
          pending = Completer<void>();
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));
          expect(tester.widget<RoundedSwitchListTile>(master).enabled, isFalse);
          pending.complete();
          pending = null;
          await tester.pumpAndSettle();
          expect(service.configuration.enabled, isFalse);
          expect(service.intensity, 0);
          expect(service.configuration.overrideMode, 'none');
          expect(service.configuration.overrideUntil, 0);
          expect(node.hasFocus, isTrue);
          expect(find.byType(NightModeMenu), findsOneWidget);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          expect(
            service.configuration.toJson(),
            initial.copyWith(clearOverrides: true).toJson(),
          );
          expect(service.intensity, solar ? 0 : 1);
          expect(node.hasFocus, isTrue);
          expect(
            NightModeConfiguration.decode(prefs.getString(nightModeKey))
                .enabled,
            isTrue,
          );
          await tester.pumpWidget(const SizedBox());
          service.dispose();
        },
      );
    }
  }
  for (final active in [true, false]) {
    testWidgets('scheduled mode $active toggles, then returns to schedule', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      Completer<void>? pendingChange;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('cutelauncher/night'),
        (_) async {
          await pendingChange?.future;
          return {'permission': false};
        },
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('cutelauncher/tcl_blue_light'),
        (_) async => {'status': 'unsupported'},
      );
      final service = NightModeService(await SharedPreferences.getInstance());
      final now = DateTime.now();
      await service.configure(
        NightModeConfiguration(
          enabled: true,
          scheduled: true,
          startHour: (now.hour + (active ? -2 : 6)) % 24,
          endHour: (now.hour + (active ? 6 : 10)) % 24,
        ),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: service,
          child: MaterialApp(
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: NightModeMenu(anchor: Rect.fromLTWH(20, 20, 40, 40)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final action = find.byKey(const ValueKey('night_mode_temporary'));
      final l = AppLocalizations.of(tester.element(action))!;
      final initialLabel = active
          ? l.nightSkipUntilNext
          : l.nightEnableUntilMorning;
      expect(service.intensity > 0, active);
      expect(find.text(initialLabel), findsOneWidget);
      expect(find.text(l.nightResumeSchedule), findsNothing);

      final node = tester.widget<FocusableSettingsTile>(action).focusNode!;
      node.requestFocus();
      await tester.pump();
      pendingChange = Completer<void>();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.widget<FocusableSettingsTile>(action).enabled, isFalse);
      pendingChange.complete();
      pendingChange = null;
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue);
      expect(service.configuration.overrideMode, active ? 'off' : 'on');
      expect(service.intensity > 0, !active);
      expect(find.byType(NightModeMenu), findsOneWidget);
      expect(find.text(initialLabel), findsNothing);
      expect(find.text(l.nightResumeSchedule), findsOneWidget);

      // Returning to schedule must remain possible without solar data.
      await service.configure(service.configuration.copyWith(solar: true));
      await tester.pumpAndSettle();
      expect(tester.widget<FocusableSettingsTile>(action).enabled, isTrue);
      expect(find.text(l.nightSolarUnavailable), findsNothing);
      await service.configure(service.configuration.copyWith(solar: false));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue);
      expect(service.configuration.overrideMode, 'none');
      expect(service.configuration.overrideUntil, 0);
      expect(service.intensity > 0, active);
      expect(find.text(l.nightResumeSchedule), findsNothing);
      expect(find.text(initialLabel), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      service.dispose();
    });
  }
}
