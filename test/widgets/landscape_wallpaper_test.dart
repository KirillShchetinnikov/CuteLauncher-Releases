import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/adaptive_landscape.dart';
import 'package:flauncher/widgets/adaptive_landscape_background.dart';
import 'package:flauncher/widgets/landscape_wallpaper.dart';
import 'package:flauncher/widgets/wallpaper_background.dart';
import 'package:flauncher/widgets/background_raster_cache.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:flauncher/models/weather_data.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/weather_sources.dart';

import '../mocks.mocks.dart';

void main() {

  testWidgets('information stays unfiltered between terrain and a single effects layer in every path', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService(await SharedPreferences.getInstance());
    addTearDown(settings.dispose);
    await settings.setLandscape(const LandscapeConfiguration(timeOfDay: false, motion: false));
    final weather = MockWeatherService();
    when(weather.configuration).thenReturn(const WeatherConfiguration());
    when(weather.stale).thenReturn(false);
    final appearance = AppearanceService(await SharedPreferences.getInstance());
    addTearDown(appearance.dispose);
    for (final above in [false, true]) {
      await appearance.set('panelBackgroundInformationAboveWeather', above);
      const info = ValueKey('decorative-information');
      const captureKey = ValueKey('weather-over-information');
      for (final condition in [803, 500, 600, 741]) {
        when(weather.weatherData).thenReturn(WeatherData(currentConditionCode: condition));
        for (final mode in ['normal', 'memory', 'bright', 'demo']) {
          settings.landscapeDemo.value = mode == 'demo'
              ? LandscapeDemoFrame(LandscapeDemoTimeline(DateTime(2026, 11, 1, 12)).dayDuration + Duration(seconds: 2 + [803, 500, 600, 741].indexOf(condition) * 5), DateTime(2026, 11, 1, 12))
              : null;
          await tester.pumpWidget(MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: appearance),
              ChangeNotifierProvider.value(value: settings),
              ChangeNotifierProvider<WeatherService>.value(value: weather),
            ],
            child: MaterialApp(home: RepaintBoundary(key: captureKey,
              child: LandscapeWallpaper(
                gradient: const LinearGradient(colors: [Colors.black, Colors.black]),
                brightness: mode == 'bright' ? 1.4 : 1,
                memorySaver: mode == 'memory',
                informationLayer: const ColoredBox(key: info, color: Colors.white),
              ),
            )),
          ));
          await tester.pump();
          final scene = tester.widget<AdaptiveLandscapeBackground>(find.byType(AdaptiveLandscapeBackground));
          expect(scene.informationLayer, isNotNull);
          expect(scene.informationAboveWeather, above);
          expect(find.ancestor(of: find.byKey(info), matching: find.byType(ColorFiltered)), findsNothing);
          expect(find.ancestor(of: find.byKey(info), matching: find.byType(BackgroundRasterCache)), findsNothing);
          final effects = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LandscapeEffectsPainter);
          expect(effects, findsOneWidget);
          final parent = tester.widget<Stack>(find.ancestor(of: find.byKey(info), matching: find.byType(Stack)).first);
          expect(parent.children.indexWhere((w) => w.key == info), above ? 2 : 1);
          expect(parent.children.length, 3);
          final bytes = (await tester.runAsync(() async {
            final image = await tester.renderObject<RenderRepaintBoundary>(find.byKey(captureKey)).toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
            image.dispose();
            return data!.buffer.asUint8List();
          }))!;
          // Terrain is fully covered by the white surrogate. Only weather can
          // change these pixels when effects paint above the content. When the
          // entire block is above effects, every pixel must stay white.
          var changed = 0;
          for (var i = 0; i < bytes.length; i += 4) {
            if (bytes[i] < 250 || bytes[i + 1] < 250 || bytes[i + 2] < 250) changed++;
          }
          expect(changed, above ? 0 : greaterThan(100), reason: '$condition / $mode / above=$above');
        }
      }
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'static fog uses the combined cache; stale fog and rain separate',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService(await SharedPreferences.getInstance());
      await settings.setLandscape(const LandscapeConfiguration(fog: true));
      final weather = MockWeatherService();
      when(weather.configuration).thenReturn(const WeatherConfiguration());
      for (final sample in [
        (741, false, false),
        (741, true, true),
        (500, false, true),
      ]) {
        when(weather.stale).thenReturn(sample.$2);
        when(weather.weatherData)
            .thenReturn(WeatherData(currentConditionCode: sample.$1));
        await tester.pumpWidget(
          MultiProvider(
            key: ValueKey(sample),
            providers: [
              ChangeNotifierProvider.value(value: settings),
              ChangeNotifierProvider<WeatherService>.value(value: weather),
            ],
            child: const MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(size: Size(800, 600), devicePixelRatio: 1),
                child: LandscapeWallpaper(
                  gradient: LinearGradient(
                    colors: [Colors.black, Colors.white],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(BackgroundRasterCache), findsOneWidget);
        expect(
          tester
                  .widget<AdaptiveLandscapeBackground>(
                    find.byType(AdaptiveLandscapeBackground),
                  )
                  .effectsColors !=
              null,
          sample.$3,
        );
      }
      await tester.pumpWidget(const SizedBox());
      settings.dispose();
    },
  );
  testWidgets(
    'weather uses 30 Hz on the optimized path, 10 Hz on fallback, and pauses in background',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService(await SharedPreferences.getInstance());
      await settings.setLandscape(
        const LandscapeConfiguration(motion: true, timeOfDay: false),
      );
      final weather = MockWeatherService();
      when(weather.configuration).thenReturn(const WeatherConfiguration());
      when(weather.stale).thenReturn(false);
      when(weather.weatherData)
          .thenReturn(const WeatherData(currentConditionCode: 500));
      for (final brightness in [.8, 1.2]) {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: settings),
              ChangeNotifierProvider<WeatherService>.value(value: weather),
            ],
            child: MaterialApp(
              home: MediaQuery(
                data: const MediaQueryData(
                  size: Size(800, 600),
                  devicePixelRatio: 1,
                ),
                child: LandscapeWallpaper(
                  brightness: brightness,
                  gradient: const LinearGradient(
                    colors: [Colors.black, Colors.white],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        final painter =
            tester
                    .widget<CustomPaint>(
                      find.byWidgetPredicate(
                        (w) =>
                            w is CustomPaint &&
                            w.painter is LandscapeEffectsPainter,
                      ),
                    )
                    .painter
                as LandscapeEffectsPainter;
        expect(painter.weather, LandscapeWeather.rain);
        final cloudDirection = painter.cloudsMoveLeft;
        var ticks = 0;
        void count() => ticks++;
        painter.frame.addListener(count);
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(
          ticks,
          brightness < 1 ? inInclusiveRange(9, 10) : inInclusiveRange(3, 4),
        );
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        expect(painter.cloudCache?.bytes, 0);
        final before = ticks;
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(ticks, before);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(ticks, greaterThan(before));
        final resumedPainter = tester.widget<CustomPaint>(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is LandscapeEffectsPainter,
          ),
        ).painter as LandscapeEffectsPainter;
        expect(resumedPainter.cloudsMoveLeft, cloudDirection);
        expect(resumedPainter.cloudCache?.bytes, greaterThan(0));
        tester.binding.handleMemoryPressure();
        await tester.pump();
        expect(resumedPainter.cloudCache?.bytes, 0);
        final pressurePainter = tester.widget<CustomPaint>(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is LandscapeEffectsPainter,
          ),
        ).painter as LandscapeEffectsPainter;
        expect(pressurePainter.cloudCache, isNull);
        painter.frame.removeListener(count);
      }
      await tester.pumpWidget(const SizedBox());
      settings.dispose();
    },
  );
  testWidgets(
    'demo preserves its original composition then restores independent weather',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService(await SharedPreferences.getInstance());
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: settings,
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: Size(800, 600), devicePixelRatio: 1),
              child: LandscapeWallpaper(
                gradient: LinearGradient(colors: [Colors.black, Colors.white]),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(BackgroundRasterCache), findsOneWidget);
      expect(
        tester
            .widget<AdaptiveLandscapeBackground>(
              find.byType(AdaptiveLandscapeBackground),
            )
            .effectsColors,
        isNotNull,
      );
      settings.landscapeDemo.value = LandscapeDemoFrame(
        Duration.zero,
        DateTime(2026, 10, 31, 12),
      );
      await tester.pump();
      expect(find.byType(BackgroundRasterCache), findsOneWidget);
      expect(
        tester
            .widget<AdaptiveLandscapeBackground>(
              find.byType(AdaptiveLandscapeBackground),
            )
            .effectsColors,
        isNull,
      );
      settings.landscapeDemo.value = null;
      await tester.pump();
      expect(find.byType(BackgroundRasterCache), findsOneWidget);
      expect(
        tester
            .widget<AdaptiveLandscapeBackground>(
              find.byType(AdaptiveLandscapeBackground),
            )
            .effectsColors,
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox());
      settings.dispose();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('separate weather filtering preserves composited pixels', (
    tester,
  ) async {
    const key = ValueKey('pixels');
    const gradient = LinearGradient(
      colors: [Color(0xff327166), Color(0xff302351)],
    );
    final frame = ValueNotifier(2.6);
    const terrain = DecoratedBox(decoration: BoxDecoration(gradient: gradient));
    Future<Uint8List> capture(Widget child) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: RepaintBoundary(
              key: key,
              child: MediaQuery(
                data: const MediaQueryData(devicePixelRatio: 2),
                child: SizedBox(width: 160, height: 90, child: child),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return (await tester.runAsync(() async {
        final image = await tester
            .renderObject<RenderRepaintBoundary>(find.byKey(key))
            .toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final bytes = Uint8List.fromList(data!.buffer.asUint8List());
        image.dispose();
        return bytes;
      }))!;
    }

    for (final weather in LandscapeWeather.values) {
      for (final values in [
        (1.0, 1.0, 0.0),
        (1.0, 1.0, 1.0),
        (.6, .4, 2.0),
        (0.0, 0.0, 2.0),
        (1.0, 0.0, 1.0),
        (.2, 1.0, 2.0),
      ]) {
        final (brightness, saturation, dimming) = values;
        final treatment = LandscapeEffectsColors(
          brightness: brightness,
          saturation: saturation,
          dimming: dimming,
        );
        Widget effects({bool baked = false}) => Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: LandscapeMeteorsPainter(
                frame,
                nightOpacity: .8,
                season: LandscapeSeason.autumn,
                colors: baked ? treatment : null,
              ),
            ),
            CustomPaint(
              painter: LandscapeEffectsPainter(
                const LandscapeConfiguration(motion: true),
                weather,
                LandscapePhase.day,
                frame,
                colors: baked ? treatment : null,
              ),
            ),
          ],
        );
        Widget background(Widget artwork) => WallpaperBackground(
          image: null,
          gradient: gradient,
          brightness: brightness,
          saturation: saturation,
          dimming: dimming,
          artwork: artwork,
        );
        final original = await capture(
          background(
            Stack(fit: StackFit.expand, children: [terrain, effects()]),
          ),
        );
        final split = await capture(
          Stack(
            fit: StackFit.expand,
            children: [
              BackgroundRasterCache(child: background(terrain)),
              effects(baked: true),
            ],
          ),
        );
        var maxDifference = 0;
        for (var i = 0; i < original.length; i++) {
          final difference = (original[i] - split[i]).abs();
          if (difference > maxDifference) maxDifference = difference;
        }
        expect(maxDifference, lessThanOrEqualTo(3), reason: '$weather $values');
      }
    }
    await tester.pumpWidget(const SizedBox());
    frame.dispose();
  });
  test(
    'clamping colour adjustments and economy retain the original composition',
    () {
      const gradient = LinearGradient(colors: [Colors.black, Colors.white]);
      expect(const LandscapeWallpaper(gradient: gradient).canSeparate, isTrue);
      expect(
        const LandscapeWallpaper(
          gradient: gradient,
          brightness: 1.1,
        ).canSeparate,
        isFalse,
      );
      expect(
        const LandscapeWallpaper(
          gradient: gradient,
          saturation: 1.1,
        ).canSeparate,
        isFalse,
      );
      expect(
        const LandscapeWallpaper(
          gradient: gradient,
          memorySaver: true,
        ).canSeparate,
        isFalse,
      );
      expect(
        const LandscapeWallpaper(gradient: gradient)
            .canSeparateAt(const Size(960, 540), 2),
        isTrue,
      );
      expect(
        const LandscapeWallpaper(gradient: gradient)
            .canSeparateAt(const Size(1920, 1080), 2),
        isFalse,
      );
    },
  );
}
