import 'package:flauncher/adaptive_landscape.dart';
import 'package:flauncher/diagnostics/landscape_capture_main.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'capture starts at noon in summer without changing season demo stages',
    () {
      final now = DateTime(2026, 10, 24, 23, 45);
      final start = captureStart(now);
      expect(start, DateTime(2026, 10, 24, 12));
      final first = CaptureDemoFrame(Duration.zero, start);
      expect(first.now.hour, 12);
      expect(first.now.minute, 0);
      expect(first.season, LandscapeSeason.summer);
      expect(
        CaptureDemoFrame(const Duration(seconds: 5), start).season,
        LandscapeSeason.summer,
      );
      final winter = CaptureDemoFrame(
        first.timeline.dayDuration + const Duration(seconds: 10),
        start,
      );
      expect(winter.season, LandscapeSeason.winter);
    },
  );
  test('capture uses only the local sun cache for the current date', () async {
    const channel = MethodChannel('cutelauncher/night');
    final start = DateTime(2026, 10, 24, 14);
    final rise = DateTime(2026, 10, 24, 7, 23).millisecondsSinceEpoch;
    final sunset = DateTime(2026, 10, 24, 17, 49).millisecondsSinceEpoch;
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return [
            {'sunrise': rise, 'sunset': sunset},
          ];
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final timeline = await captureTimeline(start);
    expect(timeline.start, start);
    expect(timeline.solarDays.first['sunrise'], rise);
    expect(timeline.solarDays.first['sunset'], sunset);
    expect(calls, ['solarCache']);
  });

  testWidgets('capture caption supports English and starts at noon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CaptureCaption(
            demo: CaptureDemoFrame(
              Duration.zero,
              captureStart(DateTime(2026, 10, 24)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Time of day · 12:00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'capture caption shows localized effect and time without controls',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final start = DateTime(2026, 6, 21);
      final cases = [
        (Duration.zero, 'Время суток · 00:00'),
        (
          LandscapeDemoFrame.dayDuration + const Duration(seconds: 1),
          'Времена года · Лето · 12:00',
        ),
        (
          LandscapeDemoFrame.weatherStart + const Duration(seconds: 6),
          'Погода · Дождь · 12:00',
        ),
      ];
      for (final (elapsed, label) in cases) {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Scaffold(
                body: Align(
                  alignment: Alignment.topLeft,
                  child: CaptureCaption(
                    demo: LandscapeDemoFrame(elapsed, start),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(label), findsOneWidget);
        expect(find.byType(Text), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(find.byType(FilledButton), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );

  test(
    'capture variants and effects leave all launcher preferences intact',
    () async {
      final saved = const LandscapeConfiguration(
        variant: 'realistic',
        motion: false,
        celestialBodies: false,
      ).encode();
      SharedPreferences.setMockInitialValues({
        landscapeSettingsKey: saved,
        'memory_saver_enabled': true,
        'background_source': 'slideshow',
      });
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      final capture = CaptureSettings(prefs);
      addTearDown(capture.dispose);
      expect(capture.memorySaverEnabled, false);
      expect(capture.landscape.motion, true);
      expect(capture.landscape.starRotation, true);
      expect(capture.landscape.celestialBodies, true);
      for (final variant in ['realistic', 'illustrated']) {
        capture.select(variant);
        expect(capture.landscape.variant, variant);
      }
      for (final code in ['en', 'ru']) {
        capture.selectLanguage(code);
        expect(capture.captureLocale, Locale(code));
      }
      await prefs.reload();
      expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
      final normal = SettingsService(prefs);
      addTearDown(normal.dispose);
      expect(normal.landscape.encode(), saved);
      expect(normal.memorySaverEnabled, true);
      expect(normal.backgroundSource, 'slideshow');
    },
  );
}
