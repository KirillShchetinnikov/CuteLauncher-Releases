import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/settings/accent_color_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'open settings apply accent immediately without another style edit',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final settings = SettingsService(preferences);
      final appearance = AppearanceService(preferences);
      addTearDown(settings.dispose);
      addTearDown(appearance.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider.value(value: appearance),
          ],
          child: Consumer<SettingsService>(
            builder: (_, settings, child) => MaterialApp(
              theme: ThemeData.dark().copyWith(
                colorScheme: ColorScheme.dark(primary: settings.accentColor),
              ),
              locale: const Locale('ru'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: child,
            ),
            child: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showLauncherDialog<void>(
                    context: context,
                    styleDialog: false,
                    builder: (_) => const SettingsPanel(
                      initialRoute: AccentColorPage.routeName,
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      Color panelAccent() =>
          Theme.of(tester.element(find.byType(AccentColorPage)))
              .colorScheme
              .primary;
      expect(panelAccent(), settings.accentColor);
      final l = AppLocalizations.of(
        tester.element(find.byType(AccentColorPage)),
      )!;
      final colorName = AccentColorPage.colorPresets(l)
          .firstWhere((p) => p.$1 != settings.accentColorHex)
          .$2;
      final scroll = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text(colorName),
        -100,
        scrollable: scroll,
      );
      await tester.tap(find.text(colorName));
      await tester.pumpAndSettle();
      expect(panelAccent(), settings.accentColor);
      expect(find.byType(SettingsPanel), findsOneWidget);
      final focus = FocusManager.instance.primaryFocus;
      final position = tester.state<ScrollableState>(scroll).position;
      final offset = position.pixels;
      await settings.setAccentColor(ACCENT_COLOR_ICE_BLUE);
      await tester.pumpAndSettle();
      expect(panelAccent(), settings.accentColor);
      expect(FocusManager.instance.primaryFocus, same(focus));
      expect(position.pixels, closeTo(offset, .01));
      await settings.resetAppearanceSection('accent');
      await tester.pumpAndSettle();
      expect(panelAccent(), settings.accentColor);
      expect(FocusManager.instance.primaryFocus, same(focus));
      expect(position.pixels, closeTo(offset, .01));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Long Russian color names fit and remote reaches the last row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(350, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final settings = SettingsService(preferences);
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData.dark(),
          home: const Scaffold(body: AccentColorPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final lastName = AppLocalizations.of(
      tester.element(find.byType(AccentColorPage)),
    )!.colorIceBlue;
    bool lastHasFocus() =>
        find.text(lastName).evaluate().isNotEmpty &&
        Focus.of(tester.element(find.text(lastName))).hasFocus;
    for (var index = 0; index < 60 && !lastHasFocus(); index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    expect(lastHasFocus(), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(settings.accentColorHex, ACCENT_COLOR_ICE_BLUE);
    expect(tester.takeException(), isNull);
  });
}
