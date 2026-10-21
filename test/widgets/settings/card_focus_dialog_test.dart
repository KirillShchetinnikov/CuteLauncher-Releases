import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/interface_settings_page.dart';

void main() {
  for (final language in ['ru', 'en']) {
    testWidgets(
      'Home focus offers three modes accessible by remote in $language',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final settings = SettingsService(await SharedPreferences.getInstance());
        await settings.setCardFocusMode(CardFocusMode.remember);
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: settings,
            child: MaterialApp(
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(
                body: SizedBox(width: 380, child: HomeParametersPage()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(HomeParametersPage));
        final l = AppLocalizations.of(context)!;
        await tester.ensureVisible(find.text(l.cardFocusMode));
        expect(tester.widget<Text>(find.text(l.cardFocusRemember)).textAlign,
            TextAlign.end);
        await tester.tap(find.text(l.cardFocusMode));
        await tester.pumpAndSettle();
        expect(find.text(l.cardFocusRemember), findsWidgets);
        expect(find.text(l.cardFocusFirst), findsOneWidget);
        expect(find.text(l.cardFocusSettings), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(settings.cardFocusMode, CardFocusMode.first);
        expect(find.byType(AlertDialog), findsNothing);
        await tester.tap(find.text(l.cardFocusMode));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(settings.cardFocusMode, CardFocusMode.settings);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        settings.dispose();
      },
    );
  }
}
