import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/home_layout.dart';
import 'package:flauncher/tile_appearance.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/category_appearance.dart';
import 'package:flauncher/settings_import.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('focus movement preserves section geometry at every setting', () {
    for (final mode in ['row', 'rows', 'grid']) {
      for (final columns in [0, 1, 4, 12]) {
        HomeLayout layout(TileAppearance style) => HomeLayout(
          mode: mode, count: 30, availableWidth: 900,
          requestedColumns: columns, requestedRows: 2, style: style,
        );
        final before = layout(const TileAppearance({'focusEffect': 'border'}));
        for (final effect in ['scale', 'lift']) {
          for (var step = 0; step <= 10; step++) {
            final after = layout(TileAppearance({
              'focusEffect': effect, 'focusScale': step * .05,
              'focusLift': step * 5,
            }));
            expect(after.inset, before.inset);
            expect(after.width, before.width);
            expect(after.height, before.height);
            expect(after.columns, before.columns);
            expect(after.lengths, before.lengths);
            expect(after.contentHeight, before.contentHeight);
            expect(after.contentWidth, before.contentWidth);
          }
        }
      }
    }
  });
  test('shadow toggle preserves layout for every effect and layout mode', () {
    for (final mode in ['row', 'rows', 'grid']) {
      for (final effect in ['scale', 'border', 'lift']) {
        for (final columns in [0, 4]) {
          HomeLayout layout(bool shadow) => HomeLayout(
            mode: mode, count: 12, availableWidth: 900,
            requestedColumns: columns, requestedRows: 2,
            style: TileAppearance({'focusEffect': effect, 'focusShadow': shadow}),
          );
          final before = layout(false), after = layout(true);
          expect(after.inset, before.inset);
          expect(after.width, before.width);
          expect(after.height, before.height);
          expect(after.columns, before.columns);
          expect(after.lengths, before.lengths);
          expect(after.contentHeight, before.contentHeight);
        }
      }
    }
  });
  test('rows consume the ordered list once and move without wrapping', () {
    for (var count = 0; count < 70; count++) {
      for (var rows = 1; rows <= 6; rows++) {
        final l = HomeLayout(
          mode: 'rows',
          count: count,
          availableWidth: 900,
          style: const TileAppearance(),
          requestedRows: rows,
        );
        expect(l.lengths.fold(0, (a, b) => a + b), count);
        for (var i = 0; i < count; i++) {
          final (r, c) = l.cell(i);
          expect(l.start(r) + c, i);
          if (c == 0) expect(l.neighbor(i, AxisDirection.left), isNull);
          if (c == l.lengths[r] - 1) {
            expect(l.neighbor(i, AxisDirection.right), isNull);
          }
          for (final d in AxisDirection.values) {
            final next = l.neighbor(i, d);
            if (next != null) expect(next, inInclusiveRange(0, count - 1));
          }
        }
      }
    }
  });
  test('fixed visible count determines size; Auto uses independent size', () {
    HomeLayout layout(int count, int size) => HomeLayout(
      mode: 'rows',
      count: 30,
      availableWidth: 900,
      style: TileAppearance({'size': size}),
      requestedColumns: count,
    );
    expect(layout(5, 64).width, layout(5, 256).width);
    expect(layout(0, 64).width, lessThan(layout(0, 128).width));
    expect(layout(6, 128).width, lessThan(layout(4, 128).width));
    expect(layout(4, 128).contentWidth, greaterThan(900));
  });
  test('fixed count and effects fit the viewport even with maximum gaps', () {
    for (final width in [480.0, 640.0, 960.0, 1920.0]) {
      for (var columns = 1; columns <= 12; columns++) {
        for (final effect in ['scale', 'lift']) {
          final l = HomeLayout(
            mode: 'grid',
            count: columns * 2,
            availableWidth: width,
            requestedColumns: columns,
            style: TileAppearance({
              'horizontalGap': 48,
              'focusScale': .5,
              'focusEffect': effect,
              'focusLift': 50,
            }),
          );
          expect(l.columns, columns);
          expect(l.width, greaterThan(0));
          expect(
            l.columns * l.width + (l.columns - 1) * l.gapX + 2 * l.inset,
            closeTo(width, .001),
          );
          expect(l.height, l.width / (16 / 9));
        }
      }
    }
  });
  test(
    'layout reset also restores common appearance and leaves navigation intact',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = AppearanceService(prefs);
      addTearDown(service.dispose);
      await service.set('sectionScroll', 'free');
      await service.setCategory(1, 'padding', 16);
      expect(service.tilesFor(1).number('sectionPadding'), 16);
      await service.inheritField(1, 'sectionPadding');
      expect(service.tilesFor(1).number('sectionPadding'), isNull);
      await service.setCategoryTile(1, 'sectionBackground', 0);
      expect(service.tilesFor(1).homeFieldValue('sectionBackground'), 0);
      await service.setCategory(1, 'layout', 'rows');
      await service.setCategory(1, 'columns', 4);
      await service.reset();
      expect(service.appearance.anchored, isFalse);
      expect(service.category(1).layout, 'rows');
      expect(service.category(1).columns, 4);
      await service.setCategoryTile(1, 'radius', 32);
      await service.resetCategoryLayout(1, grid: true);
      expect(service.category(1).layout, 'grid');
      expect(service.category(1).columns, 6);
      expect(service.tilesFor(1).number('radius'), isNull);
    },
  );
  test('global style reset supersedes explicit legacy labels and titles', () async {
    SharedPreferences.setMockInitialValues({'show_app_names_below_icons': true, 'show_category_titles': false});
    final prefs = await SharedPreferences.getInstance();
    final service = AppearanceService(prefs);
    addTearDown(service.dispose);
    expect(service.appearance.labels, 'all');
    expect(service.appearance.sectionTitles, isFalse);
    await service.resetFields(['labels', 'sectionTitles']);
    expect(service.appearance.labels, 'none');
    expect(service.appearance.sectionTitles, isTrue);
    expect(TileAppearance.decode(prefs.getString(tileAppearanceKey)).sectionTitles, isTrue);
  });
  test('one local field does not snapshot neighboring global fields; import preserves inheritance', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = AppearanceService(prefs);
    addTearDown(service.dispose);
    await service.setCategoryTile(1, 'radius', 32);
    await service.set('size', 160);
    await service.set('focusScale', .2);
    expect(service.tilesFor(1).tileSize, 160);
    expect(service.tilesFor(1).focusScale, .2);
    expect(service.category(1).tiles.keys, ['radius']);
    final imported = compatibleSettings({
      categoryAppearanceKey: prefs.getString(categoryAppearanceKey),
    }, {});
    expect(
      CategoryAppearance.decode(imported[categoryAppearanceKey])['1']['tiles'],
      {'radius': 32},
    );
    await service.setCategory(1, 'layout', 'rows');
    await service.resetFields(['size']);
    expect(service.tilesFor(1).number('radius'), 32);
    await service.inheritField(1, 'radius');
    await service.set('radius', 8);
    expect(service.tilesFor(1).number('radius'), 8);
    await service.setCategoryTile(1, 'labels', 'selected');
    await service.resetCategoryStyle(1);
    expect(service.category(1).layout, 'rows');
    expect(service.tilesFor(1).labels, 'none');
  });
}
