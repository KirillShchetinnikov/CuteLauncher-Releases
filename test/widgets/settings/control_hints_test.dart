import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/remote_panel_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/background_information_order_page.dart';
import 'package:flauncher/widgets/settings/panel_order_page.dart';
import 'package:flauncher/widgets/settings/settings_help.dart';
import 'package:flauncher/widgets/settings/sleep_timer_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final language in ['ru', 'en']) {
    for (final (name, page, hintText)
        in <(String, Widget, String Function(AppLocalizations))>[
          ('top panel', const PanelOrderPage(), (l) => l.panelOrderHint),
          (
            'quick settings panel',
            const PanelOrderPage(remotePanel: true),
            (l) => l.panelOrderHint,
          ),
          (
            'wallpaper information',
            const BackgroundInformationOrderPage(),
            (l) => l.backgroundInformationOrderHint,
          ),
          (
            'timer presets',
            const SleepTimerPresetsPage(),
            (l) => l.sleepTimerReorderHint,
          ),
        ]) {
      testWidgets('$name controls need no help expansion: $language', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(960, 540);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final appearance = AppearanceService(prefs);
        final settings = SettingsService(prefs);
        final remote = RemotePanelService(prefs);
        addTearDown(appearance.dispose);
        addTearDown(settings.dispose);
        addTearDown(remote.dispose);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: appearance),
              ChangeNotifierProvider.value(value: settings),
              ChangeNotifierProvider.value(value: remote),
            ],
            child: MaterialApp(
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: page),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l = AppLocalizations.of(tester.element(find.byWidget(page)))!;
        final hint = find.text(hintText(l));
        // Lazy lists may need scrolling, but never an extra action to reveal help.
        await tester.scrollUntilVisible(hint, 300);
        await tester.pumpAndSettle();
        expect(hint.hitTestable(), findsOneWidget);
        expect(
          find.ancestor(of: hint, matching: find.byType(SettingsHelp)),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
