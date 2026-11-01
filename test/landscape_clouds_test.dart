import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/landscape_clouds.dart';

void main() {
  const size = Size(1920, 1080);
  test(
    'all clouds share direction and drift slowly without vertical motion',
    () {
      for (final left in [false, true]) {
        for (final cloud in LandscapeCloud.all) {
          final start = cloud.position(0, size, left: left);
          final end = cloud.position(10, size, left: left);
          expect(end.dy, start.dy);
          expect((end.dx - start.dx).sign, left ? -1 : 1);
          expect((end.dx - start.dx).abs(), inInclusiveRange(10, 26));
        }
      }
    },
  );
  test('clouds have distinct proportions and contours', () {
    expect(LandscapeCloud.all.map((c) => c.width / c.height).toSet().length, 7);
    expect(LandscapeCloud.all.map((c) => c.crest).toSet().length, 7);
    for (final cloud in LandscapeCloud.all) {
      final bounds = cloud.silhouette(size).getBounds();
      expect(bounds.width, greaterThan(0));
      expect(
        bounds.left,
        greaterThanOrEqualTo(-cloud.width * size.width / 2 - .001),
      );
      expect(
        bounds.right,
        lessThanOrEqualTo(cloud.width * size.width / 2 + .001),
      );
      expect(cloud.silhouette(size).computeMetrics().single.isClosed, true);
    }
  });
  test(
    'wrapping in either direction happens completely outside the screen',
    () {
      for (final left in [false, true]) {
        for (final cloud in LandscapeCloud.all) {
          final distance = left
              ? cloud.start + cloud.width / 2
              : 1 + cloud.width / 2 - cloud.start;
          final crossing = distance / cloud.speed;
          final pathBounds = cloud.silhouette(size).getBounds();
          final before = pathBounds.shift(
            cloud.position(crossing - .001, size, left: left),
          );
          final after = pathBounds.shift(
            cloud.position(crossing + .001, size, left: left),
          );
          expect(left ? before.right : after.right, lessThan(.01));
          expect(
            left ? after.left : before.left,
            greaterThan(size.width - .01),
          );
        }
      }
    },
  );
}
