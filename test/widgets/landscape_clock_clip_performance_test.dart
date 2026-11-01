import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/adaptive_landscape.dart';
import 'package:flauncher/widgets/landscape_clock_clip.dart';
import 'package:flauncher/widgets/landscape_horizon.dart';

class _RepaintDriver extends CustomPainter {
  _RepaintDriver(Listenable repaint) : super(repaint: repaint);
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  bool shouldRepaint(_RepaintDriver oldDelegate) => false;
}

void main() {
  testWidgets('unrelated parent paints retain the clock clip layer', (
    tester,
  ) async {
    final ticks = ValueNotifier(0);
    final capture = GlobalKey();
    final horizon = LandscapeHorizon(
      const Size(400, 300),
      LandscapeSeason.summer,
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: capture,
          child: CustomPaint(
            foregroundPainter: _RepaintDriver(ticks),
            child: LandscapeSkyClip(
              horizon: horizon,
              child: const RepaintBoundary(
                child: SizedBox(
                  width: 400,
                  height: 300,
                  child: ColoredBox(color: Colors.red),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    ClipPathLayer clockClip() {
      final found = <ClipPathLayer>[];
      void walk(Layer layer) {
        if (layer is ClipPathLayer) found.add(layer);
        if (layer is ContainerLayer) {
          for (
            Layer? child = layer.firstChild;
            child != null;
            child = child.nextSibling
          ) {
            walk(child);
          }
        }
      }

      walk(
        (capture.currentContext!.findRenderObject()! as RenderRepaintBoundary)
            .debugLayer!,
      );
      return found.single;
    }

    final original = clockClip();
    for (var i = 1; i <= 20; i++) {
      ticks.value = i;
      await tester.pump();
      expect(
        identical(clockClip(), original),
        isTrue,
        reason: 'Scrolling elsewhere must not allocate a new clock mask layer',
      );
    }
    final oldBounds = clockClip().clipPath!.getBounds();
    tester
        .renderObject<RenderLandscapeSkyClip>(find.byType(LandscapeSkyClip))
        .horizon = LandscapeHorizon(
      const Size(300, 220),
      LandscapeSeason.winter,
      photographic: true,
    );
    await tester.pump();
    expect(identical(clockClip(), original), isTrue);
    expect(
      clockClip().clipPath!.getBounds(),
      isNot(oldBounds),
      reason: 'Retaining a layer must still update changed horizon geometry',
    );
    await tester.pumpWidget(const SizedBox());
    ticks.dispose();
    expect(tester.takeException(), isNull);
  });
}
