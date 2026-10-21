import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/home_layout.dart';
import 'package:flauncher/tile_appearance.dart';
import 'package:flauncher/widgets/reordering_tile_viewport.dart';

void main() {
  test('motion preference does not change legacy card decoration', () {
    expect(const TileAppearance({'animateReordering': false}).active,
        const TileAppearance().active);
  });
  for (final mode in ['row', 'rows', 'grid']) {
    testWidgets(
      '$mode moves tiles together and can interrupt or disable motion',
      (tester) async {
        final scroll = ScrollController();
        final layout = HomeLayout(
          mode: mode,
          count: 4,
          availableWidth: 600,
          requestedRows: 2,
          requestedColumns: 2,
          style: const TileAppearance({'size': 70}),
        );
        final focus = FocusNode();
        Future<void> show(List<String> order, {bool animate = true}) =>
            tester.pumpWidget(
              MaterialApp(
                home: Center(
                  child: SizedBox(
                    width: 600,
                    height: 350,
                    child: ReorderingTileViewport(
                      layout: layout,
                      packages: order,
                      controller: scroll,
                      animate: animate,
                      selected: 'b',
                      itemBuilder: (_, index) => Focus(
                        focusNode: order[index] == 'b' ? focus : null,
                        child: ColoredBox(
                          key: ValueKey('card:${order[index]}'),
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
        Offset position(String id) =>
            tester.getTopLeft(find.byKey(ValueKey('card:$id')));
        await show(['a', 'b', 'c', 'd']);
        focus.requestFocus();
        await tester.pumpAndSettle();
        final before = {
          for (final id in ['a', 'b', 'c', 'd']) id: position(id),
        };
        await show(['d', 'c', 'b', 'a']);
        for (final id in before.keys) {
          expect(position(id), before[id]);
        }
        await tester.pump(const Duration(milliseconds: 140));
        for (final id in before.keys) {
          expect(position(id), isNot(before[id]));
        }
        expect(focus.hasFocus, isTrue);
        final halfway = position('b');
        await show(['b', 'a', 'd', 'c']);
        expect(position('b'), halfway);
        await tester.pumpAndSettle();
        expect(focus.hasFocus, isTrue);
        await show(['a', 'b', 'c', 'd'], animate: false);
        for (final id in before.keys) {
          expect(position(id), before[id]);
        }
        expect(tester.binding.hasScheduledFrame, isFalse);
        await tester.pumpWidget(const SizedBox());
        focus.dispose();
        scroll.dispose();
      },
    );
  }

  testWidgets('large lists only materialize nearby cards', (tester) async {
    final scroll = ScrollController();
    final layout = HomeLayout(
      mode: 'row',
      count: 1000,
      availableWidth: 600,
      style: const TileAppearance(),
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 600,
            height: 200,
            child: ReorderingTileViewport(
              layout: layout,
              packages: List.generate(1000, (i) => '$i'),
              controller: scroll,
              itemBuilder: (_, i) => Text('tile $i'),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(Text).evaluate().length, lessThan(15));
    scroll.jumpTo(20000);
    await tester.pumpAndSettle();
    expect(find.byType(Text).evaluate().length, lessThan(15));
    await tester.pumpWidget(const SizedBox());
    scroll.dispose();
  });
}
