import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/adaptive_landscape.dart';
import 'package:flauncher/widgets/adaptive_landscape_background.dart';

Future<ui.Image> render(CustomPainter painter, {Color? background}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  if (background != null) canvas.drawColor(background, BlendMode.src);
  painter.paint(canvas, const Size(320, 180));
  final picture = recorder.endRecording();
  final image = await picture.toImage(320, 180);
  picture.dispose();
  return image;
}

Future<Uint8List> pixels(ui.Image image) async =>
    (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer
        .asUint8List();

void main() {
  testWidgets(
    'glow spreads from sunrise/sunset across sky with weaker terrain and smooth fading',
    (tester) async {
      await tester.runAsync(() async {
        for (final sunrise in [true, false]) {
          final glow = LandscapeGlow(1, sunrise: sunrise);
          final image = await render(
            LandscapeSkyGlowPainter(glow, photographic: true),
          );
          final data = await pixels(image);
          final x = (320 * (sunrise ? .18 : .82)).round();
          int alpha(int y) => data[(y * 320 + x) * 4 + 3];
          expect(alpha(38), greaterThan(90));
          for (var y = 55; y < 95; y++) {
            expect(
              (alpha(y + 1) - alpha(y)).abs(),
              lessThan(20),
              reason:
                  'horizon edge must fade rather than show the ridge polygon',
            );
          }
          expect(
            alpha(38),
            greaterThan(alpha(100) * 5),
            reason: 'sky glow dominates forest/ground',
          );
          expect(
            data[(38 * 320 + x) * 4],
            greaterThan(data[(38 * 320 + x) * 4 + 1]),
          );
          final opposite = (38 * 320 + (320 - x)) * 4 + 3;
          expect(
            alpha(38),
            greaterThan(data[opposite]),
            reason: 'sun horizon point is brightest',
          );
          final half = await render(
            LandscapeSkyGlowPainter(
              LandscapeGlow(.5, sunrise: sunrise),
              photographic: true,
            ),
          );
          final b = await pixels(half);
          expect(b[(38 * 320 + x) * 4 + 3], closeTo(alpha(38) / 2, 4));
          image.dispose();
          half.dispose();
        }
        final off = await render(
          const LandscapeSkyGlowPainter(LandscapeGlow.none),
        );
        expect((await pixels(off)).every((v) => v == 0), true);
        off.dispose();
      });
    },
  );

  testWidgets(
    'sun sets completely behind terrain, moon rises separately, both can be absent',
    (tester) async {
      await tester.runAsync(() async {
        const config = LandscapeConfiguration();
        for (final hour in [12, 18, 20, 0]) {
          final now = DateTime(2026, 10, 24, hour);
          final phase = landscapePhase(now, config);
          final light = landscapeLight(now, config);
          final state = LandscapeCelestialState.at(now, config);
          final baseline = await render(
            LandscapePainter(LandscapeSeason.summer, phase, lighting: light),
          );
          final scene = await render(
            LandscapePainter(
              LandscapeSeason.summer,
              phase,
              lighting: light,
              bodies: state,
            ),
          );
          final a = await pixels(baseline), b = await pixels(scene);
          var changed = 0;
          for (var i = 0; i < a.length; i += 4) {
            if (a[i] != b[i] || a[i + 1] != b[i + 1] || a[i + 2] != b[i + 2]) {
              changed++;
            }
            if (i ~/ 4 ~/ 320 > 100) {
              expect(a.sublist(i, i + 4), b.sublist(i, i + 4));
            }
          }
          if (hour == 18) {
            expect(
              changed,
              0,
              reason: 'last sun pixel has disappeared at the local sunset',
            );
          } else {
            expect(
              changed,
              greaterThan(40),
              reason: hour == 12 ? 'visible sun' : 'visible moon',
            );
          }
          baseline.dispose();
          scene.dispose();
        }
        for (final progress in [.5, 1.12]) {
          final photo = await render(
            LandscapeCelestialPainter(
              LandscapeCelestialState(progress, 2),
              photoHorizon: true,
            ),
          );
          final data = await pixels(photo);
          var visible = 0;
          for (var y = 0; y < 180; y++) {
            for (var x = 0; x < 320; x++) {
              final alpha = data[(y * 320 + x) * 4 + 3];
              if (alpha > 0) visible++;
              if (y >= 80) {
                expect(alpha, 0, reason: 'photo foreground must stay clear');
              }
            }
          }
          expect(visible, progress == .5 ? greaterThan(40) : 0);
          photo.dispose();
        }
      });
    },
  );

  testWidgets(
    'random stars are stable, rotate visibly and leave the ground clear',
    (tester) async {
      await tester.runAsync(() async {
        final initial = await render(const LandscapeStarsPainter());
        final repeat = await render(const LandscapeStarsPainter());
        final rotated = await render(
          const LandscapeStarsPainter(angle: 1.04719755),
        );
        final a = await pixels(initial),
            b = await pixels(repeat),
            c = await pixels(rotated);
        expect(a, orderedEquals(b));
        var changed = 0;
        final occupied = <int>{};
        for (var y = 0; y < 180; y++) {
          for (var x = 0; x < 320; x++) {
            final i = (y * 320 + x) * 4;
            if (a[i + 3] != c[i + 3]) changed++;
            if (y >= 54) expect(a[i + 3], 0);
            if (a[i + 3] > 60) occupied.add((x ~/ 32) + (y ~/ 18) * 10);
          }
        }
        expect(changed, greaterThan(150));
        expect(
          occupied.length,
          greaterThan(18),
          reason: 'stars fill the sky rather than a few bands',
        );
        initial.dispose();
        repeat.dispose();
        rotated.dispose();
      });
    },
  );

  testWidgets(
    'spring and summer have clearly different terrain and seasonal details',
    (tester) async {
      await tester.runAsync(() async {
        final spring = await render(
          LandscapePainter(LandscapeSeason.spring, LandscapePhase.day),
        );
        final summer = await render(
          LandscapePainter(LandscapeSeason.summer, LandscapePhase.day),
        );
        final a = await pixels(spring), b = await pixels(summer);
        var different = 0;
        for (var i = 0; i < a.length; i += 4) {
          if ((a[i] - b[i]).abs() > 15 ||
              (a[i + 1] - b[i + 1]).abs() > 15 ||
              (a[i + 2] - b[i + 2]).abs() > 15) {
            different++;
          }
        }
        expect(different, greaterThan(320 * 180 * .4));
        for (final season in [LandscapeSeason.spring, LandscapeSeason.summer]) {
          final photo = await render(
            LandscapeSeasonAccentsPainter(season, photographic: true),
          );
          final data = await pixels(photo);
          var visible = 0;
          for (var y = 0; y < 180; y++) {
            for (var x = 0; x < 320; x++) {
              final alpha = data[(y * 320 + x) * 4 + 3];
              if (alpha > 0) visible++;
              if (y < 140) {
                expect(
                  alpha,
                  0,
                  reason: 'season accents stay in the foreground',
                );
              }
            }
          }
          expect(visible, greaterThan(80));
          photo.dispose();
        }
        spring.dispose();
        summer.dispose();
      });
    },
  );

  testWidgets(
    'normal rain has visible light streaks and dark edges, and obeys the precipitation switch',
    (tester) async {
      final frame = ValueNotifier<double>(0);
      addTearDown(frame.dispose);
      await tester.runAsync(() async {
        for (final background in [
          const Color(0xffeeeeee),
          const Color(0xff102030),
        ]) {
          final painter = LandscapeEffectsPainter(
            const LandscapeConfiguration(clouds: false),
            LandscapeWeather.rain,
            LandscapePhase.day,
            frame,
          );
          final image = await render(painter, background: background);
          final data = await pixels(image);
          var changed = 0, light = 0, dark = 0;
          final base = (background.r * 255).round();
          for (var i = 0; i < data.length; i += 4) {
            if ((data[i] - base).abs() > 10) changed++;
            if (data[i] - base > 20) light++;
            if (base - data[i] > 20) dark++;
          }
          expect(changed, inExclusiveRange(1000, 2500));
          if (base > 200) {
            expect(dark, greaterThan(150));
          } else {
            expect(light, greaterThan(600));
          }
          image.dispose();
        }
        final disabled = await render(
          LandscapeEffectsPainter(
            const LandscapeConfiguration(clouds: false, precipitation: false),
            LandscapeWeather.rain,
            LandscapePhase.day,
            frame,
          ),
        );
        expect((await pixels(disabled)).every((value) => value == 0), true);
        disabled.dispose();
        if (Platform.environment['LANDSCAPE_PREVIEW_CAPTURE'] == '1') {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          final scenes = <CustomPainter>[
            LandscapePainter(LandscapeSeason.summer, LandscapePhase.day),
            LandscapePainter(LandscapeSeason.summer, LandscapePhase.dawn),
            LandscapePainter(LandscapeSeason.summer, LandscapePhase.dusk),
            LandscapeEffectsPainter(
              const LandscapeConfiguration(clouds: false),
              LandscapeWeather.rain,
              LandscapePhase.day,
              frame,
            ),
          ];
          for (var i = 0; i < scenes.length; i++) {
            final image = await render(
              scenes[i],
              background: i == 3 ? const Color(0xffeeeeee) : null,
            );
            canvas.drawImage(
              image,
              Offset((i % 2) * 320.0, (i ~/ 2) * 180.0),
              Paint(),
            );
            image.dispose();
          }
          final picture = recorder.endRecording();
          final image = await picture.toImage(640, 360);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('.local/landscape-sky-rain-review.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
          picture.dispose();
        }
      });
    },
  );
}
