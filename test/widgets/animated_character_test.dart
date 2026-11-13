import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/widgets/animated_character.dart';

class _ObservedAnimation extends Animation<double> {
  final statusListeners = <AnimationStatusListener>{};
  @override
  double value = .5;
  @override
  AnimationStatus status = AnimationStatus.forward;
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
  @override
  void addStatusListener(AnimationStatusListener listener) => statusListeners.add(listener);
  @override
  void removeStatusListener(AnimationStatusListener listener) => statusListeners.remove(listener);
}

void main() {
  testWidgets('rebuilding character transitions does not retain status listeners', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AnimatedCharacter(character: '7')));
    final builder = tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).transitionBuilder;
    final animation = _ObservedAnimation();
    for (var rebuild = 0; rebuild < 100; rebuild++) {
      builder(const Text('7', key: ValueKey('7')), animation);
    }
    expect(animation.statusListeners, isEmpty);
  });

  testWidgets('incoming and outgoing motion keeps the same curve and opacity', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AnimatedCharacter(character: '7')));
    final builder = tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).transitionBuilder;
    final animation = _ObservedAnimation();
    for (final status in [AnimationStatus.forward, AnimationStatus.reverse]) {
      animation.status = status;
      for (final value in [0.0, .25, .5, .75, 1.0]) {
        animation.value = value;
        for (final incoming in [true, false]) {
          final transition = builder(Text(incoming ? '7' : '6', key: ValueKey(incoming ? '7' : '6')), animation) as SlideTransition;
          final curve = Curves.easeOutCubic.transform(value);
          expect(transition.position.value, Offset.lerp(
            incoming ? const Offset(0, .5) : Offset.zero,
            incoming ? Offset.zero : const Offset(0, -.5), curve));
          expect((transition.child as FadeTransition).opacity.value, value);
        }
      }
    }
  });

  group('AnimatedCharacter', () {
    Widget buildTestWidget(String character, {TextStyle? textStyle, Duration duration = const Duration(milliseconds: 300)}) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: AnimatedCharacter(
              character: character,
              textStyle: textStyle,
              duration: duration,
            ),
          ),
        ),
      );
    }

    testWidgets('renders initial character correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget('A'));

      expect(find.text('A'), findsOneWidget);
      expect(find.byType(AnimatedCharacter), findsOneWidget);
    });

    testWidgets('animates to new character', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget('A'));
      expect(find.text('A'), findsOneWidget);

      await tester.pumpWidget(buildTestWidget('B'));

      // Halfway through animation (default 300ms, pump 150ms)
      await tester.pump(const Duration(milliseconds: 150));

      // Both characters should be visible during transition
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);

      // Finish animation
      await tester.pumpAndSettle();

      // Only new character should be visible
      expect(find.text('A'), findsNothing);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('applies custom textStyle', (WidgetTester tester) async {
      const customStyle = TextStyle(color: Colors.red, fontSize: 24);
      await tester.pumpWidget(buildTestWidget('C', textStyle: customStyle));

      final Text textWidget = tester.widget(find.text('C'));
      expect(textWidget.style?.color, Colors.red);
      expect(textWidget.style?.fontSize, 24);
    });

    testWidgets('respects custom duration', (WidgetTester tester) async {
      const customDuration = Duration(milliseconds: 500);
      await tester.pumpWidget(buildTestWidget('A', duration: customDuration));

      await tester.pumpWidget(buildTestWidget('B', duration: customDuration));

      // Advance by 400ms (not yet finished with 500ms duration)
      await tester.pump(const Duration(milliseconds: 400));

      // Both still visible
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);

      // Advance by 200ms to finish it
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('A'), findsNothing);
      expect(find.text('B'), findsOneWidget);
    });
  });

  group('AnimatedTimeDisplay', () {
    Widget buildTestWidget(String displayText, {TextStyle? textStyle}) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: AnimatedTimeDisplay(
              displayText: displayText,
              textStyle: textStyle,
            ),
          ),
        ),
      );
    }

    testWidgets('renders string correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget('ABC'));

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.byType(AnimatedCharacter), findsNWidgets(3));
    });

    testWidgets('animates only changed characters', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget('ABC'));
      expect(find.text('C'), findsOneWidget);
      expect(find.text('D'), findsNothing);

      await tester.pumpWidget(buildTestWidget('ABD'));

      // Advance partially to see both C (old) and D (new)
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('A'), findsOneWidget); // unchanged
      expect(find.text('B'), findsOneWidget); // unchanged
      expect(find.text('C'), findsOneWidget); // animating out
      expect(find.text('D'), findsOneWidget); // animating in

      await tester.pumpAndSettle();

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsNothing);
      expect(find.text('D'), findsOneWidget);
    });

    testWidgets('applies custom textStyle', (WidgetTester tester) async {
      const customStyle = TextStyle(color: Colors.blue, fontSize: 32);
      await tester.pumpWidget(buildTestWidget('12:00', textStyle: customStyle));

      final Text textWidget = tester.widget(find.text('1'));
      expect(textWidget.style?.color, Colors.blue);
      expect(textWidget.style?.fontSize, 32);
    });
  });
}
