import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/settings_style_page.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flauncher/widgets/side_panel_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('menu side persists, validates imports and round-trips in backup', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);
    expect(settings.settingsMenuOnRight, isFalse);
    await settings.setSettingsMenuOnRight(true);
    final restored = SettingsService(prefs);
    expect(restored.settingsMenuOnRight, isTrue);
    final backup = settings.exportSettingsMap();
    await settings.setSettingsMenuOnRight(false);
    await settings.importSettingsMap(backup);
    expect(settings.settingsMenuOnRight, isTrue);
    await settings.importSettingsMap({'settings_menu_on_right': 'invalid'});
    expect(settings.settingsMenuOnRight, isTrue);
    await settings.importSettingsMap({'settings_menu_on_right': false});
    expect(settings.settingsMenuOnRight, isFalse);
    settings.dispose();
    restored.dispose();
  });

  for (final language in ['ru', 'en']) {
    testWidgets('remote moves menu and scrollbar while keeping content order in $language', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      final appearance = AppearanceService(prefs);
      addTearDown(appearance.dispose);
      await tester.pumpWidget(MultiProvider(
        providers: [ChangeNotifierProvider.value(value: settings), ChangeNotifierProvider.value(value: appearance)],
        child: MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPanel(initialRoute: SettingsStylePage.routeName),
        ),
      ));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(SettingsStylePage)))!;
      final focus = FocusManager.instance.primaryFocus;
      final page = tester.state(find.byType(Scrollable).first);
      expect(tester.widget<SidePanelDialog>(find.byType(SidePanelDialog)).isRightSide, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.settingsMenuRight).last);
      await tester.pumpAndSettle();
      expect(settings.settingsMenuOnRight, isTrue);
      expect(tester.widget<SidePanelDialog>(find.byType(SidePanelDialog)).isRightSide, isTrue);
      expect(FocusManager.instance.primaryFocus, same(focus));
      expect(tester.state(find.byType(Scrollable).first), same(page));
      expect(tester.widget<Scrollbar>(find.byType(Scrollbar)).scrollbarOrientation, ScrollbarOrientation.right);
      expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);
      expect(find.byIcon(Icons.chevron_right_rounded), findsWidgets);
      expect(tester.getCenter(find.text(l.settingsMenuPosition)).dy,
          lessThan(tester.getCenter(find.text(l.settingsMenuRight)).dy));
      expect(Directionality.of(tester.element(find.text(l.settingsMenuPosition))), TextDirection.ltr);
      focus?.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.settingsMenuLeft).last);
      await tester.pumpAndSettle();
      expect(settings.settingsMenuOnRight, isFalse);
      expect(tester.widget<Scrollbar>(find.byType(Scrollbar)).scrollbarOrientation, ScrollbarOrientation.left);
      expect(FocusManager.instance.primaryFocus, same(focus));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      settings.dispose();
    });
  }
}
