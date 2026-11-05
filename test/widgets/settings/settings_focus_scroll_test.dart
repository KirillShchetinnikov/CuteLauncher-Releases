import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/settings_page_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final disableAnimations in [false, true]) {
    testWidgets(
      'held Down follows focus with large text; reduced motion=$disableAnimations',
      (tester) async {
        final nodes = List.generate(18, (_) => FocusNode());
        addTearDown(() {
          for (final node in nodes) {
            node.dispose();
          }
        });
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(
                  disableAnimations: disableAnimations,
                  textScaler: const TextScaler.linear(1.5),
                ),
                child: Center(
                  child: SizedBox(
                    width: 360,
                    height: 500,
                    child: SettingsPageLayout(
                      title: const Text('Настройки'),
                      child: ListView(
                        children: [
                          for (var i = 0; i < nodes.length; i++)
                            FocusableSettingsTile(
                              focusNode: nodes[i],
                              title: Text('Длинное название настройки $i'),
                              onPressed: () {},
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump(const Duration(milliseconds: 16));
        var previous = nodes.indexWhere((node) => node.hasPrimaryFocus);
        for (var i = 0; i < 9; i++) {
          await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowDown);
          await tester.pump(const Duration(milliseconds: 30));
          final current = nodes.indexWhere((node) => node.hasPrimaryFocus);
          expect(current, inInclusiveRange(previous, previous + 1));
          previous = current;
        }
        await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        final focused = nodes.indexWhere((node) => node.hasPrimaryFocus);
        // A repeat may scroll a text gap before the next control is visible.
        expect(focused, greaterThanOrEqualTo(6));
        final viewport = tester.getRect(find.byType(ListView));
        expect(nodes[focused].rect.top, greaterThanOrEqualTo(viewport.top));
        expect(nodes[focused].rect.bottom, lessThanOrEqualTo(viewport.bottom));
        final position = tester
            .state<ScrollableState>(find.byType(Scrollable))
            .position;
        final settled = position.pixels;
        await tester.pump(const Duration(seconds: 1));
        expect(position.pixels, settled);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final rtl in [false, true]) {
    for (final switches in [false, true]) {
      testWidgets(
        'settings scroll near the middle; RTL=$rtl switches=$switches',
        (tester) async {
          final nodes = List.generate(20, (_) => FocusNode());
          final rebuild = ValueNotifier(0);
          addTearDown(() {
            for (final node in nodes) {
              node.dispose();
            }
            rebuild.dispose();
          });
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 360,
                    height: 500,
                    child: Directionality(
                      textDirection: rtl
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      child: ValueListenableBuilder<int>(
                        valueListenable: rebuild,
                        builder: (_, value, _) => SettingsPageLayout(
                          title: Text('Settings $value'),
                          child: ListView(
                            children: [
                              for (var i = 0; i < nodes.length; i++)
                                SizedBox(
                                  height: 64,
                                  child: switches
                                      ? RoundedSwitchListTile(
                                          focusNode: nodes[i],
                                          title: Text('Row $i'),
                                          value: false,
                                          onChanged: (_) {},
                                        )
                                      : FocusableSettingsTile(
                                          focusNode: nodes[i],
                                          title: Text('Row $i'),
                                          onPressed: () {},
                                        ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final position = tester
              .state<ScrollableState>(find.byType(Scrollable))
              .position;
          final viewport = tester.getRect(find.byType(ListView));
          expect(nodes.first.hasPrimaryFocus, isTrue);
          expect(position.pixels, 0);
          // First rows stay still, then the list follows before reaching its edge.
          for (var i = 1; i <= 2; i++) {
            await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
            await tester.pumpAndSettle();
            expect(nodes[i].hasPrimaryFocus, isTrue);
            expect(position.pixels, 0);
          }
          for (var i = 3; i <= 6; i++) {
            await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
            await tester.pumpAndSettle();
            expect(nodes[i].hasPrimaryFocus, isTrue);
            expect(
              nodes[i].rect.center.dy,
              lessThanOrEqualTo(viewport.top + viewport.height * .6),
            );
          }
          expect(position.pixels, greaterThan(0));
          final beforeReverse = position.pixels;
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
          await tester.pumpAndSettle();
          expect(nodes[5].hasPrimaryFocus, isTrue);
          expect(position.pixels, beforeReverse);
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
          await tester.pumpAndSettle();
          expect(nodes[4].hasPrimaryFocus, isTrue);
          expect(position.pixels, lessThan(beforeReverse));
          expect(
            nodes[4].rect.center.dy,
            greaterThanOrEqualTo(viewport.top + viewport.height * .4),
          );
          final beforeRebuild = position.pixels;
          rebuild.value++;
          await tester.pumpAndSettle();
          expect(nodes[4].hasPrimaryFocus, isTrue);
          expect(position.pixels, beforeRebuild);
          for (var i = 5; i < nodes.length; i++) {
            await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
            await tester.pumpAndSettle();
          }
          expect(nodes.last.hasPrimaryFocus, isTrue);
          expect(position.pixels, position.maxScrollExtent);
          for (var i = 18; i >= 0; i--) {
            await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
            await tester.pumpAndSettle();
          }
          expect(nodes.first.hasPrimaryFocus, isTrue);
          expect(position.pixels, position.minScrollExtent);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
