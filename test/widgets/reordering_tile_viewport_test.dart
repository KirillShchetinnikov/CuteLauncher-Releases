import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/home_layout.dart';
import 'package:flauncher/tile_appearance.dart';
import 'package:flauncher/widgets/reordering_tile_viewport.dart';
import 'package:flauncher/widgets/tile_paint_layer.dart';

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('wheel advances tape and hands off at its end: $direction', (
      tester,
    ) async {
      final inner = ScrollController();
      final outer = ScrollController();
      final layout = HomeLayout(
        mode: 'row',
        count: 20,
        availableWidth: 400,
        style: const TileAppearance({'size': 70}),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: Center(
              child: SizedBox(
                width: 400,
                height: 300,
                child: SingleChildScrollView(
                  controller: outer,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 160,
                        child: TilePaintLayer(
                          child: ReorderingTileViewport(
                            layout: layout,
                            packages: List.generate(20, (i) => '$i'),
                            controller: inner,
                            selected: '0',
                            itemBuilder: (_, i) => RaisedTile(
                              raised: i == 0,
                              child: ColoredBox(
                                key: ValueKey('wheel-$i'),
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 800),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: tester.getCenter(find.byKey(const ValueKey('wheel-0'))),
          scrollDelta: const Offset(0, 80),
        ),
      );
      await tester.pumpAndSettle();
      expect(inner.offset, 80);
      expect(outer.offset, 0);
      inner.jumpTo(inner.position.maxScrollExtent);
      await tester.pumpAndSettle();
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: tester.getCenter(find.byType(ReorderingTileViewport)),
          scrollDelta: const Offset(0, 80),
        ),
      );
      await tester.pumpAndSettle();
      expect(outer.offset, 80);
      await tester.pumpWidget(const SizedBox());
      inner.dispose();
      outer.dispose();
    });
  }
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
