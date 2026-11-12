import 'package:flauncher/widgets/content_card_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const longLabel = 'A very long title that is too wide even on two lines';
  const labelKey = ValueKey('content-label');
  final label = find.byKey(labelKey);
  final clip = find.descendant(of: label, matching: find.byType(Flow));

  Future<void> showLabel(
    WidgetTester tester, {
    bool scroll = true,
    bool disableAnimations = false,
    bool tickerEnabled = true,
    TextDirection direction = TextDirection.ltr,
    String text = longLabel,
    String? subtitle,
  }) => tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Directionality(
        textDirection: direction,
        child: DefaultTextStyle(
          style: const TextStyle(fontSize: 14),
          child: TickerMode(
            enabled: tickerEnabled,
            child: Center(
              child: SizedBox(
                width: 112,
                child: ContentCardLabel(
                  text,
                  key: labelKey,
                  maxLines: subtitle == null ? 2 : 1,
                  scroll: scroll,
                  subtitle: subtitle,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('disabled, hidden and fully visible labels stay static', (
    tester,
  ) async {
    await showLabel(tester, scroll: false);
    await tester.pump(const Duration(seconds: 1));
    expect(clip, findsNothing);
    await showLabel(tester, disableAnimations: true);
    await tester.pump(const Duration(seconds: 1));
    expect(clip, findsNothing);
    await showLabel(tester, tickerEnabled: false);
    await tester.pump(const Duration(seconds: 1));
    expect(clip, findsNothing);
    await showLabel(tester, text: 'Fits');
    await tester.pump(const Duration(seconds: 1));
    expect(clip, findsNothing);
    await showLabel(tester, text: 'word word');
    await tester.pump(const Duration(seconds: 1));
    expect(clip, findsNothing);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('a subtitle that fits stays still beside a scrolling title', (
    tester,
  ) async {
    const subtitle = 'Fits';
    final subtitleFinder = find.text(subtitle);
    await showLabel(tester, subtitle: subtitle);
    final position = tester.getTopLeft(subtitleFinder);
    await tester.pump(const Duration(milliseconds: 800));
    expect(clip, findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.getTopLeft(subtitleFinder), position);
    await tester.pumpWidget(const SizedBox());
  });

  for (final direction in TextDirection.values) {
    testWidgets('two labels wait and rewind together ($direction)', (
      tester,
    ) async {
      const subtitle = 'Shorter label';
      final titleFinder = find.text(longLabel);
      final subtitleFinder = find.text(subtitle);
      double x(Finder finder) => tester.getTopLeft(finder).dx;

      await showLabel(tester, direction: direction, subtitle: subtitle);
      final originalSize = tester.getSize(label);
      await tester.pump(const Duration(milliseconds: 800));
      expect(clip, findsNWidgets(2));
      final titleStart = x(titleFinder);
      final subtitleStart = x(subtitleFinder);
      final sign = direction == TextDirection.ltr ? -1 : 1;
      await tester.pump(const Duration(milliseconds: 500));
      expect(x(titleFinder) - titleStart, closeTo(sign * 18, .1));
      expect(x(subtitleFinder) - subtitleStart, closeTo(sign * 18, .1));
      expect(tester.getSize(label), originalSize);

      final subtitleDistance = tester.getSize(subtitleFinder).width - 112;
      final subtitleEnd = subtitleStart + sign * subtitleDistance;
      await tester.pump(
        Duration(milliseconds: (subtitleDistance * 1000 / 36).ceil()),
      );
      expect(x(subtitleFinder), closeTo(subtitleEnd, .1));
      final titleStillMoving = x(titleFinder);
      await tester.pump(const Duration(seconds: 3));
      expect(x(subtitleFinder), closeTo(subtitleEnd, .1));
      expect(x(titleFinder), isNot(titleStillMoving));

      await tester.pump(const Duration(seconds: 30));
      final titleEnd = x(titleFinder);
      await tester.pump(const Duration(milliseconds: 1999));
      expect(x(titleFinder), titleEnd);
      expect(x(subtitleFinder), closeTo(subtitleEnd, .1));
      expect(tester.binding.hasScheduledFrame, isFalse);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 150));
      expect(x(titleFinder), closeTo((titleStart + titleEnd) / 2, .1));
      expect(x(subtitleFinder), closeTo((subtitleStart + subtitleEnd) / 2, .1));
      await tester.pump(const Duration(milliseconds: 151));
      expect(x(titleFinder), closeTo(titleStart, .1));
      expect(x(subtitleFinder), closeTo(subtitleStart, .1));
      await tester.pump(const Duration(milliseconds: 500));
      expect(x(titleFinder) - titleStart, closeTo(sign * 18, .1));
      expect(x(subtitleFinder) - subtitleStart, closeTo(sign * 18, .1));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('pauses at the end for two seconds and loops ($direction)', (
      tester,
    ) async {
      final text = find.text(longLabel);
      await showLabel(tester, direction: direction);
      final originalSize = tester.getSize(label);
      await tester.pump(const Duration(milliseconds: 700));
      expect(clip, findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pump(const Duration(milliseconds: 100));
      expect(clip, findsOneWidget);
      final start = tester.getTopLeft(text).dx;
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        tester.getTopLeft(text).dx - start,
        closeTo(direction == TextDirection.ltr ? -18 : 18, .1),
      );
      expect(tester.getSize(label), originalSize);
      await tester.pump(const Duration(seconds: 30));
      final end = tester.getTopLeft(text);
      await tester.pump(const Duration(milliseconds: 1999));
      expect(tester.getTopLeft(text), end);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pump(const Duration(milliseconds: 1));
      expect(tester.getTopLeft(text).dx, start);
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.getTopLeft(text).dx, isNot(start));
      await tester.pump(const Duration(seconds: 30));

      await showLabel(tester, scroll: false, direction: direction);
      await tester.pump(const Duration(seconds: 3));
      expect(clip, findsNothing);
      expect(tester.widget<Text>(text).overflow, TextOverflow.ellipsis);
      expect(tester.getSize(label), originalSize);
    });
  }

  testWidgets('background cancels motion and resume starts with a pause', (
    tester,
  ) async {
    await showLabel(tester);
    await tester.pump(const Duration(milliseconds: 900));
    expect(clip, findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(clip, findsNothing);
    await tester.pump(const Duration(seconds: 2));
    expect(clip, findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(clip, findsNothing);
    await tester.pump(const Duration(milliseconds: 900));
    expect(clip, findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
