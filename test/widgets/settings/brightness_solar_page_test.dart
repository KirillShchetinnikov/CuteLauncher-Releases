import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/brightness_service.dart';
import 'package:flauncher/providers/night_mode_service.dart';
import 'package:flauncher/widgets/settings/brightness_page.dart';
import 'package:flauncher/widgets/settings/settings_slider_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'adb_test_compatibility.dart';

void main() {
  for (final language in ['ru', 'en']) {
    testWidgets('solar brightness presets and transition range ($language)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({nightModeKey: '{"enabled":false,"scheduled":false,"solar":true}'});
      const native = MethodChannel('me.efesser.flauncher/method');
      const nightChannel = MethodChannel('cutelauncher/night');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        native,
        (call) async => call.method == 'getAdbCompatibility'
            ? supportedAdbCompatibility
            : true,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        nightChannel,
        (_) async => {'permission': false},
      );
      final prefs = await SharedPreferences.getInstance();
      final night = NightModeService(prefs);
      final service = BrightnessService(prefs, nightMode: night);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: service),
            ChangeNotifierProvider.value(value: night),
          ],
          child: MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: BrightnessPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(
        tester.element(find.byType(BrightnessPage)),
      )!;
      expect(find.text('06:00–09:00'), findsOneWidget);
      await tester.tap(find.text(l.brightnessSolar));
      await tester.pumpAndSettle();
      expect(find.text(l.brightnessAfterNightEnd), findsOneWidget);
      expect(find.text(l.brightnessAfterNightStart), findsOneWidget);
      expect(find.text('06:00–09:00'), findsNothing);
      expect(find.text(l.brightnessSolarUnavailable), findsOneWidget);
      final slider = tester.widget<SettingsSliderTile>(
        find.byWidgetPredicate(
          (widget) =>
              widget is SettingsSliderTile &&
              widget.title == l.brightnessTransitionTime,
        ),
      );
      expect(slider.options.first, 1);
      expect(slider.options.last, 60);
      expect(slider.options.length, 60);
      Focus.of(tester.element(find.text(l.brightnessTransitionTime)))
          .requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(service.transitionMinutes, 2);
      expect(service.isEnabled, isFalse);
      await tester.tap(find.text(l.brightnessSolar));
      await tester.pumpAndSettle();
      expect(find.text('06:00–09:00'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      service.dispose();
      night.dispose();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        native,
        null,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        nightChannel,
        null,
      );
    });
  }
}
