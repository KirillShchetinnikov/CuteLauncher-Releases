import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/appearance_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/settings_value_stepper.dart';
import 'package:flauncher/widgets/settings/wallpaper_display_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('disabled controls reject pointer and remote and are skipped', (
    tester,
  ) async {
    var changes = 0;
    var activated = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              FocusableSettingsTile(
                autofocus: true,
                title: const Text('First'),
                onPressed: () {},
              ),
              RoundedSwitchListTile(
                enabled: false,
                value: true,
                onChanged: (_) => changes++,
                title: const Text('Disabled switch'),
                secondary: const Icon(Icons.memory),
              ),
              SettingsValueStepper(
                enabled: false,
                title: 'Disabled stepper',
                options: const [0, 1, 2],
                value: 1,
                label: (v) => '$v',
                onChanged: (_) => changes++,
              ),
              FocusableSettingsTile(
                title: const Text('Last'),
                onPressed: () => activated = true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Disabled switch'));
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(changes, 0);
    expect(activated, isTrue);
  });

  for (final section in ['tiles', 'focus', 'panel', 'wallpaper']) {
    testWidgets('economy locks $section effects and preserves saved values', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 5000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      final appearance = AppearanceService(prefs);
      await appearance.set('blurTiles', true);
      await appearance.set('opacity', .5);
      await appearance.set('blurPanel', true);
      await appearance.set('shadow', 16);
      await settings.setAppHighlightAnimationEnabled(true);
      await settings.setWallpaperFit('blurred');
      await settings.setMemorySaverEnabled(true);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider.value(value: appearance),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: section == 'wallpaper'
                  ? const WallpaperDisplayPage()
                  : AppearancePage(section: section),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (section == 'wallpaper') {
        final placement = tester.widget<SettingsValueStepper>(
          find.byType(SettingsValueStepper).first,
        );
        expect(placement.options, ['cover', 'contain']);
        expect(placement.value, 'contain');
      } else {
        final switches = tester.widgetList<RoundedSwitchListTile>(
          find.byType(RoundedSwitchListTile),
        );
        expect(switches.where((s) => !s.enabled), isNotEmpty);
        if (section == 'tiles') {
          final shadow = tester.widget<SettingsValueStepper>(find.byWidgetPredicate(
              (w) => w is SettingsValueStepper && w.title == 'Shadow'));
          expect(shadow.enabled, isTrue); // Economy clamps shadows, not disables them.
        }
      }
      await settings.setMemorySaverEnabled(false);
      await tester.pumpAndSettle();
      if (section == 'wallpaper') {
        final placement = tester.widget<SettingsValueStepper>(
          find.byType(SettingsValueStepper).first,
        );
        expect(placement.options, contains('blurred'));
        expect(placement.value, 'blurred');
      } else {
        expect(
          tester
              .widgetList<RoundedSwitchListTile>(
                find.byType(RoundedSwitchListTile),
              )
              .every((s) => s.enabled),
          isTrue,
        );
      }
      expect(appearance.appearance.blurTiles, isTrue);
      expect(appearance.appearance.blurPanel, isTrue);
      expect(appearance.appearance.number('shadow'), 16);
      expect(settings.appHighlightAnimationEnabled, isTrue);
      expect(settings.wallpaperFit, 'blurred');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      settings.dispose();
      appearance.dispose();
    });
  }
}
