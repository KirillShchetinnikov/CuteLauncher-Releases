import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/adaptive_landscape.dart';
import 'package:flauncher/diagnostics/screenshot_scene.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/animated_character.dart';
import 'package:flauncher/widgets/date_time_widget.dart';
import 'package:flauncher/widgets/settings/screenshot_scene_controls.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'scene changes preserve the date and do not touch preferences',
    () async {
      SharedPreferences.setMockInitialValues({'existing': 'preserved'});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      addTearDown(settings.dispose);
      final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      final scene = ScreenshotScene(
        now: DateTime(2026, 11, 1, 16, 15),
        weather: LandscapeWeather.cloudy,
      ).withTime(hour: 17, minute: 3).withWeather(LandscapeWeather.snow);
      settings.setScreenshotScene(scene);
      expect(settings.screenshotScene, screenshotBuild ? same(scene) : isNull);
      expect(scene.now, DateTime(2026, 11, 1, 17, 3));
      expect(scene.weather, LandscapeWeather.snow);
      expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
      settings.setScreenshotScene(null);
      expect(settings.screenshotScene, isNull);
    },
  );

  testWidgets(
    'manual controls stay active after leaving the page and can be disabled',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService(await SharedPreferences.getInstance());
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: settings,
          child: const MaterialApp(
            locale: Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(child: ScreenshotSceneControls()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Режим съёмки'),
        screenshotBuild ? findsOneWidget : findsNothing,
      );
      if (screenshotBuild) {
        expect(find.text('Часы'), findsOneWidget);
        expect(find.text('Минуты'), findsOneWidget);
        expect(find.text('Облачно'), findsOneWidget);
        final original = settings.screenshotScene;
        await tester.pumpWidget(const SizedBox());
        expect(settings.screenshotScene, same(original));
        settings.setScreenshotScene(null);
        expect(settings.screenshotScene, isNull);
      }
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'fixed clock survives ticks, resume and changes back to live time',
    (tester) async {
      Future<void> show(DateTime? fixed) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DateTimeWidget('HH:mm', fixedTime: fixed, animate: false),
            ),
          ),
        );
        await tester.pump();
      }

      String display() => tester
          .widget<AnimatedTimeDisplay>(find.byType(AnimatedTimeDisplay))
          .displayText;
      await show(DateTime(2026, 11, 1, 16, 15));
      expect(display(), '16:15');
      await tester.pump(const Duration(minutes: 2));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(display(), '16:15');
      await show(DateTime(2026, 11, 1, 18, 5));
      expect(display(), '18:05');
      await show(null);
      final now = DateTime.now();
      expect(
        display(),
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
}
