import 'package:flauncher/theme/interface_style.dart';
import 'package:flauncher/tile_appearance.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/appearance_page.dart';
import 'package:flauncher/widgets/settings/settings_section.dart';
import 'package:flauncher/widgets/settings/settings_style_page.dart';
import 'package:flauncher/widgets/settings/settings_option_tile.dart';
import 'package:flauncher/widgets/settings/reset_style_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final skin in InterfaceStyle.values) {
    for (final locale in ['ru', 'ar']) {
      testWidgets('sections preserve focus and geometry: $skin $locale 150%', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final appearance = AppearanceService(prefs);
        final settings = SettingsService(prefs);
        addTearDown(appearance.dispose);
        addTearDown(settings.dispose);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: appearance),
              ChangeNotifierProvider.value(value: settings),
            ],
            child: MaterialApp(
              theme: InterfaceSkin(skin).apply(
                ThemeData(
                  colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
                  extensions: [InterfaceSkin(skin)],
                ),
              ),
              locale: Locale(locale),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(1.5)),
                child: child!,
              ),
              home: const Scaffold(
                body: SizedBox(
                  width: 350,
                  child: AppearancePage(section: 'panel'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l = AppLocalizations.of(
          tester.element(find.byType(AppearancePage)),
        )!;
        final initialFocus = FocusManager.instance.primaryFocus;
        expect(
          Focus.of(tester.element(find.text(l.panelBackground).last)).hasFocus,
          isTrue,
        );
        final initialPosition = tester.getTopLeft(
          find.text(l.panelBackground).last,
        );
        for (final style in SettingsSectionStyle.values) {
          await appearance.set('settingsSectionStyle', style.name);
          await tester.pumpAndSettle();
          expect(FocusManager.instance.primaryFocus, initialFocus);
          expect(
            tester.getTopLeft(find.text(l.panelBackground).last),
            initialPosition,
          );
          expect(appearance.appearance.values, {
            'settingsSectionStyle': style.name,
          });
          final header = find.descendant(
            of: find.byType(SettingsSection).first,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics && widget.properties.header == true,
            ),
          );
          expect(header, findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        // Header is not a remote stop: Down goes straight to the next control.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(
          Focus.of(tester.element(find.text(l.panelTransparency))).hasFocus,
          isTrue,
        );
        // All later groups remain reachable through the one page scroll view.
        final wrapSwitch = find.byWidgetPredicate(
          (widget) =>
              widget is RoundedSwitchListTile &&
              widget.title is Text &&
              (widget.title as Text).data == l.panelWrapNavigation,
        );
        await tester.scrollUntilVisible(wrapSwitch, 250);
        await tester.pumpAndSettle();
        expect(wrapSwitch.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      });
    }
  }

  testWidgets(
    'settings group choice has two values, persists and resets to surface',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final appearance = AppearanceService(prefs);
      final settings = SettingsService(prefs);
      addTearDown(appearance.dispose);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: appearance),
            ChangeNotifierProvider.value(value: settings),
          ],
          child: const MaterialApp(
            locale: Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox(width: 380, child: SettingsStylePage()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Оформление групп'), 200);
      await tester.pumpAndSettle();
      expect(find.text('Общая поверхность'), findsOneWidget);
      await tester.tap(find.text('Оформление групп'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsOptionTile), findsNWidgets(2));
      await tester.tap(find.text('Акцентная полоса'));
      await tester.pumpAndSettle();
      final reloaded = AppearanceService(prefs);
      addTearDown(reloaded.dispose);
      expect(
        reloaded.appearance.settingsSectionStyle,
        SettingsSectionStyle.accentBand,
      );
      await tester.scrollUntilVisible(find.byType(ResetStyleTile), 200);
      await tester
          .widget<ResetStyleTile>(find.byType(ResetStyleTile))
          .onReset();
      await tester.pumpAndSettle();
      expect(
        appearance.appearance.settingsSectionStyle,
        SettingsSectionStyle.surface,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
}
