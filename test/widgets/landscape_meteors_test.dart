import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/adaptive_landscape.dart';
import 'package:flauncher/landscape_meteors.dart';
import 'package:flauncher/widgets/adaptive_landscape_background.dart';

void main() {
  test('rare meteor flights move, fade, disappear and use different paths next time', () {
    expect(LandscapeMeteors.at(0), isEmpty);
    expect(LandscapeMeteors.untilBoundary(0), 2);
    final early = LandscapeMeteors.at(2.2).single;
    final later = LandscapeMeteors.at(2.8).single;
    expect(later.x, greaterThan(early.x));
    expect(later.y, greaterThan(early.y));
    expect(later.tailX, greaterThan(0));
    expect(later.tailY, greaterThan(0));
    expect(LandscapeMeteors.at(2.625).single.opacity, closeTo(1, .00001));
    expect(LandscapeMeteors.at(3.24).single.opacity, lessThan(.03));
    expect(LandscapeMeteors.at(3.25), isEmpty);
    expect(LandscapeMeteors.untilBoundary(3.25), 14.75);
    expect(LandscapeMeteors.at(17), isEmpty);
    expect(LandscapeMeteors.at(32.2).single.x, isNot(closeTo(early.x, .001)));
    expect(LandscapeMeteors.at(1, demo: true), isNotEmpty);
  });

  testWidgets(
    'meteor images move then clear, and daytime/reduced motion stay empty',
    (tester) async {
      final frame = ValueNotifier<double>(2.2);
      addTearDown(frame.dispose);
      await tester.runAsync(() async {
        Future<List<int>> render(
          double time, {
          double night = 1,
          bool enabled = true,
        }) async {
          frame.value = time;
          final recorder = ui.PictureRecorder();
          LandscapeMeteorsPainter(
            frame,
            nightOpacity: night,
            season: LandscapeSeason.summer,
            enabled: enabled,
            photographic: true,
          ).paint(Canvas(recorder), const Size(320, 180));
          final picture = recorder.endRecording();
          final image = await picture.toImage(320, 180);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!.buffer.asUint8List().toList();
          image.dispose();
          picture.dispose();
          return bytes;
        }

        final first = await render(2.2), later = await render(2.8);
        expect(first.any((v) => v > 0), true);
        expect(first, isNot(orderedEquals(later)));
        for (final image in [
          await render(3.3),
          await render(2.2, night: 0),
          await render(2.2, enabled: false),
        ]) {
          expect(image.every((v) => v == 0), true);
        }
        if (Platform.environment['LANDSCAPE_METEOR_CAPTURE'] == '1') {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          final times = [2.2, 2.8, 3.3, 18.6];
          for (var i = 0; i < times.length; i++) {
            canvas.save();
            canvas.translate((i % 2) * 320.0, (i ~/ 2) * 180.0);
            LandscapePainter(
              LandscapeSeason.summer,
              LandscapePhase.night,
              bodies: const LandscapeCelestialState(2, .5),
            ).paint(canvas, const Size(320, 180));
            frame.value = times[i];
            LandscapeMeteorsPainter(
              frame,
              nightOpacity: 1,
              season: LandscapeSeason.summer,
            ).paint(canvas, const Size(320, 180));
            canvas.restore();
          }
          final picture = recorder.endRecording();
          final image = await picture.toImage(640, 360);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('.local/landscape-meteors-review.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
          picture.dispose();
        }
      });
    },
  );
}
