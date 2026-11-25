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
    bool loop = true,
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
                  loop: loop,
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

  Duration scrollTime(double distance) =>
      Duration(microseconds: (distance * 1000000 / 36).round());

  for (final direction in TextDirection.values) {
    testWidgets(
      'two overflowing labels start together and loop at their own widths ($direction)',
      (tester) async {
        const subtitle = 'Shorter label';
        final titleFinder = find.text(longLabel).first;
        final subtitleFinder = find.text(subtitle).first;
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

        final afterSubtitleWrap = tester.getSize(subtitleFinder).width + 24 + 9;
        await tester.pump(scrollTime(afterSubtitleWrap - 18));
        expect(
          x(titleFinder) - titleStart,
          closeTo(sign * afterSubtitleWrap, .1),
        );
        expect(x(subtitleFinder) - subtitleStart, closeTo(sign * 9, .1));
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'the beginning enters before the end leaves and scrolling loops ($direction)',
      (tester) async {
        final text = find.text(longLabel);
        final sign = direction == TextDirection.ltr ? -1 : 1;
        await showLabel(tester, direction: direction);
        final originalSize = tester.getSize(label);
        await tester.pump(const Duration(milliseconds: 700));
        expect(clip, findsNothing);
        expect(tester.binding.hasScheduledFrame, isFalse);
        await tester.pump(const Duration(milliseconds: 100));
        expect(clip, findsOneWidget);
        final first = text.first;
        final start = tester.getTopLeft(first).dx;
        final textWidth = tester.getSize(first).width;
        const gap = 24.0;
        final seam = textWidth - (tester.getSize(clip).width - gap) / 2;
        await tester.pump(scrollTime(seam));
        expect(tester.getTopLeft(first).dx - start, closeTo(sign * seam, .1));
        expect(
          tester.getTopLeft(text.last).dx - tester.getTopLeft(first).dx,
          closeTo(-sign * (textWidth + gap), .1),
        );
        expect(find.bySemanticsLabel(longLabel), findsOneWidget);
        expect(tester.getSize(label), originalSize);
        await tester.pump(scrollTime(textWidth + gap - seam + 9));
        expect(tester.getTopLeft(first).dx, closeTo(start + sign * 9, .1));

        await showLabel(tester, scroll: false, direction: direction);
        await tester.pump(const Duration(seconds: 3));
        expect(clip, findsNothing);
        expect(tester.widget<Text>(text).overflow, TextOverflow.ellipsis);
        expect(tester.getSize(label), originalSize);
      },
    );
  }

  testWidgets(
    'restart mode pauses then shows a single line from the beginning',
    (tester) async {
      final text = find.text(longLabel);
      await showLabel(tester, loop: false);
      await tester.pump(const Duration(milliseconds: 800));
      final start = tester.getTopLeft(text).dx;
      await tester.pump(const Duration(seconds: 30));
      final end = tester.getTopLeft(text).dx;
      expect(end, lessThan(start));
      await tester.pump(const Duration(milliseconds: 1999));
      expect(tester.getTopLeft(text).dx, end);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pump(const Duration(milliseconds: 1));
      expect(tester.getTopLeft(text).dx, start);

      await showLabel(tester);
      expect(clip, findsNothing);
      await tester.pump(const Duration(milliseconds: 800));
      expect(clip, findsOneWidget);
      expect(text, findsNWidgets(2));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'restart mode waits and rewinds both overflowing lines together',
    (tester) async {
      const subtitle = 'Shorter label';
      final title = find.text(longLabel);
      final second = find.text(subtitle);
      double x(Finder finder) => tester.getTopLeft(finder).dx;
      await showLabel(tester, loop: false, subtitle: subtitle);
      await tester.pump(const Duration(milliseconds: 800));
      final titleStart = x(title);
      final subtitleStart = x(second);
      await tester.pump(const Duration(seconds: 5));
      final subtitleEnd = x(second);
      final titleStillMoving = x(title);
      await tester.pump(const Duration(seconds: 1));
      expect(x(second), subtitleEnd);
      expect(x(title), lessThan(titleStillMoving));
      await tester.pump(const Duration(seconds: 30));
      final titleEnd = x(title);
      await tester.pump(const Duration(milliseconds: 1999));
      expect(x(title), titleEnd);
      expect(x(second), subtitleEnd);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 150));
      expect(x(title), closeTo((titleStart + titleEnd) / 2, .1));
      expect(x(second), closeTo((subtitleStart + subtitleEnd) / 2, .1));
      await tester.pump(const Duration(milliseconds: 150));
      expect(x(title), closeTo(titleStart, .1));
      expect(x(second), closeTo(subtitleStart, .1));
      await tester.pumpWidget(const SizedBox());
    },
  );

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
