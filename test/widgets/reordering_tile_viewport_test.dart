import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/home_layout.dart';
import 'package:flauncher/tile_appearance.dart';
import 'package:flauncher/widgets/reordering_tile_viewport.dart';
import 'package:flauncher/widgets/tile_paint_layer.dart';

void main() {
  testWidgets('neighboring feeds are mounted before fast downward navigation', (tester) async {
    final outer = ScrollController();
    final rows = List.generate(12, (_) => ScrollController());
    final builds = <int, int>{};
    final layout = HomeLayout(mode: 'row', count: 20, availableWidth: 400,
        style: const TileAppearance({'size': 70}));
    await tester.pumpWidget(MaterialApp(home: SingleChildScrollView(
      controller: outer,
      child: Column(children: [
        for (var row = 0; row < rows.length; row++)
          SizedBox(height: 200, child: ReorderingTileViewport(
            layout: layout, packages: List.generate(20, (i) => '$i'),
            controller: rows[row], itemBuilder: (_, i) {
              builds.update(row, (n) => n + 1, ifAbsent: () => 1);
              return ColoredBox(key: ValueKey('prepared-$row-$i'), color: Colors.blue);
            },
          )),
      ]),
    )));
    await tester.pumpAndSettle();
    // The 600 px screen ends before this row at y=800. A 120 px
    // entry margin would leave its cards unmounted until the descent.
    final prepared = tester.element(find.byKey(const ValueKey('prepared-4-0')));
    final before = builds[4];
    expect(find.byKey(const ValueKey('prepared-10-0')), findsNothing);
    outer.jumpTo(400);
    await tester.pumpAndSettle();
    expect(tester.element(find.byKey(const ValueKey('prepared-4-0'))), same(prepared));
    expect(builds[4], before, reason: 'Entering a prepared feed must reuse its cards');
    outer.jumpTo(1800);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('prepared-0-0')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    outer.dispose();
    for (final row in rows) { row.dispose(); }
  });
  testWidgets('full materialization keeps all rows and horizontal cards mounted', (tester) async {
    final outer = ScrollController();
    final rows = List.generate(8, (_) => ScrollController());
    final layout = HomeLayout(mode: 'row', count: 20, availableWidth: 400,
        style: const TileAppearance({'size': 70}));
    await tester.pumpWidget(MaterialApp(home: SizedBox(width: 400, height: 300,
      child: SingleChildScrollView(controller: outer, child: Column(children: [
        for (var row = 0; row < rows.length; row++)
          SizedBox(height: 200, child: ReorderingTileViewport(
            materializeAll: true, layout: layout,
            packages: List.generate(20, (i) => '$i'), controller: rows[row],
            itemBuilder: (_, i) => ColoredBox(key: ValueKey('full-$row-$i'), color: Colors.blue),
          )),
      ])),
    )));
    await tester.pumpAndSettle();
    final first = tester.element(find.byKey(const ValueKey('full-0-0')));
    final last = tester.element(find.byKey(const ValueKey('full-7-19')));
    outer.jumpTo(outer.position.maxScrollExtent);
    rows.last.jumpTo(rows.last.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(tester.element(find.byKey(const ValueKey('full-0-0'))), same(first));
    expect(tester.element(find.byKey(const ValueKey('full-7-19'))), same(last));
    await tester.pumpWidget(const SizedBox());
    outer.dispose();
    for (final row in rows) { row.dispose(); }
  });
  testWidgets('visited rows survive a nearby reversal but distant rows are released', (tester) async {
    final outer = ScrollController();
    final rows = List.generate(12, (_) => ScrollController());
    final layout = HomeLayout(mode: 'row', count: 20, availableWidth: 400,
        style: const TileAppearance({'size': 70}));
    await tester.pumpWidget(MaterialApp(home: Align(alignment: Alignment.topLeft,
      child: SizedBox(width: 400, height: 300,
        child: SingleChildScrollView(controller: outer,
          child: Column(children: [for (var row = 0; row < rows.length; row++)
            SizedBox(height: 200, child: ReorderingTileViewport(layout: layout,
              packages: List.generate(20, (i) => '$i'), controller: rows[row],
              itemBuilder: (_, i) => ColoredBox(key: ValueKey('retained-$row-$i'), color: Colors.blue),
            )),
          ]),
        ),
      ),
    )));
    await tester.pumpAndSettle();
    final original = tester.element(find.byKey(const ValueKey('retained-0-0')));
    expect(find.byKey(const ValueKey('retained-10-0')), findsNothing);
    outer.jumpTo(450);
    await tester.pumpAndSettle();
    expect(tester.element(find.byKey(const ValueKey('retained-0-0'))), same(original));
    outer.jumpTo(1800);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('retained-0-0')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    outer.dispose();
    for (final row in rows) { row.dispose(); }
  });
  testWidgets('selection and scrolling reuse mounted cards without retaining old cells', (tester) async {
    final scroll = ScrollController();
    final selection = ValueNotifier<String?>('0');
    final builds = <int, int>{};
    final layout = HomeLayout(mode: 'row', count: 30, availableWidth: 400,
        style: const TileAppearance({'size': 70}));
    await tester.pumpWidget(MaterialApp(home: Center(child: SizedBox(
      width: 400, height: 160,
      child: ReorderingTileViewport(layout: layout,
        packages: List.generate(30, (i) => '$i'), controller: scroll,
        selection: selection,
        itemBuilder: (_, i) {
          builds.update(i, (n) => n + 1, ifAbsent: () => 1);
          return ColoredBox(key: ValueKey('cached-$i'), color: Colors.blue);
        },
      ),
    ))));
    await tester.pumpAndSettle();
    final before = Map<int, int>.of(builds);
    selection.value = '1';
    await tester.pump();
    expect(builds, before, reason: 'Selection must not rebuild unchanged cards');
    scroll.jumpTo(100);
    await tester.pumpAndSettle();
    for (final entry in before.entries) {
      expect(builds[entry.key], entry.value);
    }
    selection.value = '29';
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cached-29')), findsOneWidget);
    expect(find.byKey(const ValueKey('cached-0')), findsNothing);
    expect(find.byType(ColoredBox).evaluate().length, lessThan(15));
    await tester.pumpWidget(const SizedBox());
    scroll.dispose();
    selection.dispose();
  });
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
