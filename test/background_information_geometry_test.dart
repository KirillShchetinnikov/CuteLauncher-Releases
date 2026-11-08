import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/background_information_geometry.dart';

void main() {
  test('zero starts immediately below the toolbar', () {
    const screen = Size(960, 540);
    const geometry = BackgroundInformationGeometry(screen, 0);
    expect(geometry.top, kToolbarHeight + 8);
    expect(geometry.availableHeight, screen.height / 2 - geometry.top);
    expect(const BackgroundInformationGeometry(screen, -25).top, geometry.top);
  });
  test(
    'all offsets remain between toolbar and screen middle at every resolution',
    () {
      for (final screen in [
        const Size(960, 540),
        const Size(640, 360),
        const Size(340, 220),
        const Size(1920, 1080),
      ]) {
        double previous = 0;
        for (var offset = 0; offset <= 100; offset += 5) {
          final geometry = BackgroundInformationGeometry(
            screen,
            offset.toDouble(),
          );
          expect(geometry.top, greaterThanOrEqualTo(kToolbarHeight + 8));
          expect(
            geometry.top + geometry.availableHeight,
            closeTo(screen.height / 2, .0001),
          );
          expect(geometry.availableHeight, greaterThanOrEqualTo(8));
          expect(geometry.top, greaterThanOrEqualTo(previous));
          previous = geometry.top;
        }
      }
    },
  );
  test(
    'maximum vertical offset leaves room for the complete visible block',
    () {
      const zero = BackgroundInformationGeometry(Size(960, 540), 0);
      for (final height in [40.0, 80.0, 120.0, 200.0]) {
        final offset = zero.maximumOffsetForHeight(height);
        final moved = BackgroundInformationGeometry(
          zero.screen,
          offset.toDouble(),
        );
        expect(moved.availableHeight, greaterThanOrEqualTo(height - .0001));
        if (offset < 100) {
          expect(
            BackgroundInformationGeometry(
              zero.screen,
              offset + 1.0,
            ).availableHeight,
            lessThan(height),
          );
        }
      }
    },
  );
}
