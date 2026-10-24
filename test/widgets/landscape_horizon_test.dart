import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/adaptive_landscape.dart';
import 'package:flauncher/widgets/adaptive_landscape_background.dart';
import 'package:flauncher/widgets/landscape_horizon.dart';

void main() {
  test('solar contact uses the actual ridge including the circle radius and cover crop', () {
    for (final size in [
      const Size(960, 540),
      const Size(800, 600),
      const Size(1260, 540),
    ]) {
      for (final season in LandscapeSeason.values) {
        for (final photo in [false, true]) {
          final horizon = LandscapeHorizon(size, season, photographic: photo);
          for (final progress in [0.0, 1.0]) {
            final circle = horizon.sunDisc(progress);
            final contact = horizon.contact(circle.centre.dx, circle.radius);
            expect(circle.centre.dy, closeTo(contact.centreY, .000001));
            expect(
              (circle.centre - contact.edge).distance,
              closeTo(circle.radius, .000001),
            );
            for (var sample = 0; sample <= 100; sample++) {
              final dx = circle.radius * (sample / 50 - 1);
              final top =
                  circle.centre.dy -
                  math.sqrt(
                    math.max(0, circle.radius * circle.radius - dx * dx),
                  );
              expect(
                top - horizon.heightAt(circle.centre.dx + dx),
                greaterThanOrEqualTo(-.000001),
                reason: 'no disc pixel can lie above the skyline at the invisible tangent',
              );
            }
          }
          expect(
            horizon.sunDisc(.5).centre.dy,
            lessThan(horizon.heightAt(size.width * .5)),
          );
        }
      }
    }
  });

  testWidgets(
    'the first and last solar pixels follow the same sunrise/sunset across every season',
    (tester) async {
      await tester.runAsync(() async {
        const size = Size(960, 540);
        for (final season in LandscapeSeason.values) {
          for (final photo in [false, true]) {
            for (final progress in [
              -.001,
              0.0,
              1 / 720,
              1 - 1 / 720,
              1.0,
              1.001,
            ]) {
              final recorder = ui.PictureRecorder();
              final canvas = Canvas(recorder);
              LandscapeCelestialPainter(
                LandscapeCelestialState(progress, 2, sunWarmth: 1),
                season: season,
                photoHorizon: photo,
              ).paint(canvas, size);
              final picture = recorder.endRecording();
              final image = await picture.toImage(
                size.width.toInt(),
                size.height.toInt(),
              );
              final rgba = (await image.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              ))!.buffer.asUint8List();
              var visible = 0;
              for (var i = 3; i < rgba.length; i += 4) {
                if (rgba[i] > 0) visible++;
              }
              expect(
                visible,
                progress > 0 && progress < 1 ? greaterThan(0) : 0,
              );
              image.dispose();
              picture.dispose();
            }
          }
        }
      });
    },
  );

  test('rain falls down and slightly left, parallel to its visible slash', () {
    const size = Size(1920, 1080);
    final initial = landscapeRainPosition(1, 0, size);
    final next = landscapeRainPosition(1, .1, size);
    final motion = next - initial, streak = landscapeRainStreak(size);
    expect(motion.dx, lessThan(0));
    expect(motion.dy, greaterThan(0));
    expect(motion.dx.abs() / motion.dy, closeTo(.12, .00001));
    expect(streak.dx, lessThan(0));
    expect(streak.dy, greaterThan(0));
    expect(motion.dx * streak.dy - motion.dy * streak.dx, closeTo(0, .00001));
  });
}
