import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/category_appearance.dart';
import 'package:flauncher/home_style_availability.dart';
import 'package:flauncher/tile_appearance.dart';

void main() {
  test('fixed counts own size in every layout, including legacy grids', () {
    for (final mode in ['row', 'rows', 'grid']) {
      expect(
        homeStyleBlock(
          'size',
          const TileAppearance(),
          CategoryAppearance({'layout': mode, 'columns': 4}),
        ),
        HomeStyleBlock.columns,
      );
      expect(
        homeStyleBlock(
          'size',
          const TileAppearance(),
          CategoryAppearance({'layout': mode, 'columns': 0}),
        ),
        isNull,
      );
    }
    expect(
      homeStyleBlock(
        'size',
        const TileAppearance(),
        const CategoryAppearance(),
        legacyRow: false,
      ),
      HomeStyleBlock.columns,
    );
  });
  test('label dependencies distinguish selected captions and all labels', () {
    for (final mode in ['none', 'selected', 'all']) {
      final tiles = TileAppearance({'labels': mode});
      for (final field in ['labelSize', 'labelColor']) {
        expect(
          homeStyleBlock(field, tiles, const CategoryAppearance()),
          mode == 'none' ? HomeStyleBlock.labels : null,
        );
      }
      expect(
        homeStyleBlock('labelPosition', tiles, const CategoryAppearance()),
        mode == 'all' ? null : HomeStyleBlock.allLabels,
      );
    }
  });
  test('effect, border, title, opacity and memory dependencies', () {
    const layout = CategoryAppearance();
    expect(
      homeStyleBlock('focusLift', const TileAppearance(), layout),
      HomeStyleBlock.lift,
    );
    expect(
      homeStyleBlock(
        'focusScale',
        const TileAppearance({'focusEffect': 'lift'}),
        layout,
      ),
      HomeStyleBlock.scale,
    );
    for (final key in ['focusBorderColor', 'focusPulse']) {
      expect(
        homeStyleBlock(
          key,
          const TileAppearance({'focusBorderStyle': 'none'}),
          layout,
        ),
        HomeStyleBlock.border,
      );
    }
    expect(
      homeStyleBlock(
        'sectionIcons',
        const TileAppearance({'sectionTitles': false}),
        layout,
      ),
      HomeStyleBlock.title,
    );
    expect(
      homeStyleBlock('blurTiles', const TileAppearance(), layout),
      HomeStyleBlock.opaque,
    );
    expect(
      homeStyleBlock(
        'blurTiles',
        const TileAppearance({'opacity': .5}),
        layout,
      ),
      isNull,
    );
    expect(
      homeStyleBlock(
        'blurTiles',
        const TileAppearance({'opacity': .5}),
        layout,
        economy: true,
      ),
      HomeStyleBlock.economy,
    );
    expect(
      homeStyleBlock(
        'focusPulse',
        const TileAppearance(),
        layout,
        economy: true,
      ),
      HomeStyleBlock.economy,
    );
    // Shadow is limited, not suppressed, by memory saving.
    expect(
      homeStyleBlock('shadow', const TileAppearance(), layout, economy: true),
      isNull,
    );
  });
  test('vertical gap is meaningful only for multirow layouts', () {
    for (final mode in ['row', 'rows', 'grid']) {
      expect(
        homeStyleBlock(
          'verticalGap',
          const TileAppearance(),
          CategoryAppearance({'layout': mode, 'rows': 2}),
        ),
        mode == 'row' ? HomeStyleBlock.rows : null,
      );
    }
    expect(
      homeStyleBlock(
        'verticalGap',
        const TileAppearance(),
        const CategoryAppearance({'layout': 'rows', 'rows': 1}),
      ),
      HomeStyleBlock.rows,
    );
  });
  test(
    'single-column grid and transparent background have no inactive controls',
    () {
      expect(
        homeStyleBlock(
          'horizontalGap',
          const TileAppearance(),
          const CategoryAppearance({'layout': 'grid', 'columns': 1}),
        ),
        HomeStyleBlock.singleColumn,
      );
      // A horizontal row still has off-screen neighbours when one card fits.
      expect(
        homeStyleBlock(
          'horizontalGap',
          const TileAppearance(),
          const CategoryAppearance({'layout': 'row', 'columns': 1}),
        ),
        isNull,
      );
      expect(
        homeStyleBlock(
          'backgroundColor',
          const TileAppearance({'opacity': 0}),
          const CategoryAppearance(),
        ),
        HomeStyleBlock.transparent,
      );
      expect(
        homeStyleBlock(
          'backgroundColor',
          const TileAppearance({'opacity': .5}),
          const CategoryAppearance(),
        ),
        isNull,
      );
    },
  );
  test('inheritance recognizes per-field and legacy overrides', () {
    const own = CategoryAppearance({
      'useGlobalTiles': false,
      'tiles': {'size': 160},
      'padding': 12,
    });
    expect(ownsHomeStyleField(own, 'size'), isTrue);
    expect(ownsHomeStyleField(own, 'radius'), isFalse);
    expect(ownsHomeStyleField(own, 'sectionPadding'), isTrue);
    expect(
      ownsHomeStyleField(
        const CategoryAppearance({
          'tiles': {'size': 160},
        }),
        'size',
      ),
      isFalse,
    );
  });
}
