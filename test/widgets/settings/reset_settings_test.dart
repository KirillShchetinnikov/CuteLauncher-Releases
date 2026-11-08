import 'dart:async';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/settings/general_settings_page.dart';
import 'package:flauncher/widgets/settings/reset_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final outcome in ['accepted', 'denied', 'failure', 'closed page']) {
    testWidgets('reset confirmation, guard and $outcome', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService(await SharedPreferences.getInstance());
      addTearDown(settings.dispose);
      final pending = Completer<bool>();
      var calls = 0;
      const channel = MethodChannel('me.efesser.flauncher/method');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) {
        expect(call.method, 'resetApplicationData');
        expect(call.arguments, isNull);
        calls++;
        return pending.future;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider.value(value: settings)],
          child: MaterialApp(
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: GeneralSettingsPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(
        tester.element(find.byType(ResetSettingsTile)),
      )!;
      await tester.scrollUntilVisible(find.text(l.aboutFlauncher), 120);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text(l.resetLauncherSettings)).dy,
        lessThan(tester.getTopLeft(find.text(l.aboutFlauncher)).dy),
      );
      await tester.tap(find.text(l.resetLauncherSettings));
      await tester.pumpAndSettle();
      final dialog = find.byType(LauncherAlertDialog);
      final cancel = find.descendant(of: dialog, matching: find.text('Отмена'));
      expect(Focus.of(tester.element(cancel)).hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(dialog, findsNothing);
      await tester.tap(find.text(l.resetLauncherSettings));
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .descendant(
              of: dialog,
              matching: find.text(l.resetLauncherSettings),
            )
            .last,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(calls, 1);
      await tester.tap(find.text(l.resetLauncherSettings));
      await tester.pump();
      expect(calls, 1);
      expect(dialog, findsNothing);
      if (outcome == 'closed page') await tester.pumpWidget(const SizedBox());
      if (outcome == 'failure') {
        pending.completeError(PlatformException(code: 'reset_unavailable'));
      } else {
        pending.complete(outcome != 'denied');
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      if (outcome == 'failure' || outcome == 'denied') {
        expect(find.text(l.resetLauncherSettingsError), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        // A refused request can be retried and must open confirmation again.
        await tester.tap(find.text(l.resetLauncherSettings));
        await tester.pumpAndSettle();
        expect(dialog, findsOneWidget);
      }
      if (outcome == 'accepted') {
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text(l.resetLauncherSettingsError), findsNothing);
        await tester.tap(find.text(l.resetLauncherSettings));
        await tester.pump();
        expect(calls, 1);
        expect(dialog, findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
