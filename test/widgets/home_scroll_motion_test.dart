import 'package:flauncher/widgets/home_scroll_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final disabled in [false, true]) {
    testWidgets('home reveal respects reduced motion: $disabled', (
      tester,
    ) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: disabled),
            child: Builder(
              builder: (value) {
                context = value;
                return SingleChildScrollView(
                  controller: scroll,
                  child: const SizedBox(height: 3000),
                );
              },
            ),
          ),
        ),
      );
      revealHomeOffset(context, scroll.position, 400);
      if (disabled) {
        expect(scroll.offset, 400);
        expect(scroll.position.isScrollingNotifier.value, isFalse);
        return;
      }
      await tester.pump();
      final samples = <double>[scroll.offset];
      for (var i = 0; i < 13; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        samples.add(scroll.offset);
        // Focus and materialization may request the same target every frame.
        revealHomeOffset(context, scroll.position, 400);
      }
      expect(samples[1], inExclusiveRange(0, 40));
      expect(samples.last, closeTo(400, .01));
      for (var i = 1; i < samples.length; i++) {
        expect(samples[i], greaterThanOrEqualTo(samples[i - 1]));
      }
      expect(scroll.position.isScrollingNotifier.value, isFalse);

      revealHomeOffset(context, scroll.position, 800);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 48));
      final turn = scroll.offset;
      revealHomeOffset(context, scroll.position, 100);
      expect(scroll.offset, turn, reason: 'Retargeting must not jump');
      await tester.pump();
      await tester.pumpAndSettle();
      expect(scroll.offset, closeTo(100, .01));

      revealHomeOffset(context, scroll.position, 800);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 48));
      final stop = scroll.offset;
      revealHomeOffset(context, scroll.position, stop);
      await tester.pumpAndSettle();
      expect(scroll.offset, stop, reason: 'An obsolete reveal must stop');
    });
  }
}
