import 'package:flutter/material.dart';
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
}
