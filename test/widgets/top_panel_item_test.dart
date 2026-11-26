import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/widgets/top_panel_item.dart';

void main() {
  late AppearanceService appearance;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    appearance = AppearanceService(await SharedPreferences.getInstance());
  });
  tearDown(() => appearance.dispose());
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appearance,
        child: MaterialApp(home: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('panel surfaces have equal height for icons and scaled text', (
    tester,
  ) async {
    for (final font in [
      'sans-serif',
      'serif',
      'monospace',
      'sans-serif-condensed',
    ]) {
      await appearance.set('panelFont', font);
      await appearance.set('panelTextSize', 24);
      await pump(
        tester,
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: Scaffold(
            body: Row(
              children: [
                const TopPanelItem(child: Icon(Icons.settings_outlined)),
                const TopPanelItem(child: Icon(Icons.tv_outlined)),
                const TopPanelItem(child: Text('23:59')),
                TopPanelItem(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [Icon(Icons.cloud_outlined), Text('−25°')],
                  ),
                ),
                TopPanelItem(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.notifications_outlined),
                      Text('12'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      final items = find.byType(TopPanelItem);
      final height = tester.getSize(items.first).height;
      for (var i = 0; i < items.evaluate().length; i++) {
        expect(tester.getSize(items.at(i)).height, height, reason: font);
        final content = find.byWidget(
          tester.widget<TopPanelItem>(items.at(i)).child,
        );
        expect(tester.getCenter(content).dy, tester.getCenter(items.at(i)).dy);
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'panel text keeps its vertical position at different line heights',
    (tester) async {
      const details = ValueKey('details');
      const font = TextStyle(fontFamily: 'Ahem', fontSize: 24);
      Widget label(String name, {double? height}) => Text(
        '12:34',
        key: ValueKey(name),
        style: font.copyWith(height: height),
      );
      await pump(
        tester,
        Scaffold(
          body: Row(
            children: [
              TopPanelItem(child: label('natural')),
              TopPanelItem(child: label('compact', height: .85)),
              TopPanelItem(
                textStyle: font,
                child: Column(
                  key: details,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    label('loose', height: 1.5),
                    const Text('Weather', style: TextStyle(fontSize: 8)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      (double, double) measure(String name) {
        final text = tester.renderObject<RenderParagraph>(
          find.byKey(ValueKey(name)),
        );
        final painter = TextPainter(
          text: text.text,
          textDirection: text.textDirection,
          textHeightBehavior: text.textHeightBehavior,
        )..layout();
        final baseline = painter.computeDistanceToActualBaseline(
          TextBaseline.alphabetic,
        );
        final offset = baseline - painter.height / 2;
        painter.dispose();
        return (text.size.height, offset);
      }

      final (naturalHeight, naturalOffset) = measure('natural');
      final (compactHeight, compactOffset) = measure('compact');
      final (looseHeight, looseOffset) = measure('loose');
      expect(compactHeight, lessThan(naturalHeight));
      expect(looseHeight, greaterThan(naturalHeight));
      expect(compactOffset, closeTo(naturalOffset, .5));
      expect(looseOffset, closeTo(naturalOffset, .5));
      expect(
        tester.getCenter(find.byKey(details)).dy,
        tester.getCenter(find.byType(TopPanelItem).last).dy,
      );
    },
  );
}
