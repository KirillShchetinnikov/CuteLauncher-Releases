import 'category_appearance.dart';
import 'tile_appearance.dart';

enum HomeStyleBlock {
  columns,
  rows,
  labels,
  allLabels,
  scale,
  lift,
  border,
  title,
  economy,
  opaque,
  transparent,
  singleColumn,
  inherited,
}

/// Dependencies use the resolved style, not just the value in the open menu.
HomeStyleBlock? homeStyleBlock(
  String field,
  TileAppearance tiles,
  CategoryAppearance layout, {
  bool legacyRow = true,
  int legacyColumns = 6,
  bool economy = false,
  bool legacyHiddenBorder = false,
}) {
  if (economy && {'blurTiles', 'focusPulse'}.contains(field)) {
    return HomeStyleBlock.economy;
  }
  switch (field) {
    case 'size':
      if (layout.resolvedColumns(
            legacyRow: legacyRow,
            legacyColumns: legacyColumns,
          ) >
          0) {
        return HomeStyleBlock.columns;
      }
    case 'verticalGap':
      final mode = layout.resolvedLayout(legacyRow);
      if (mode == 'row' || mode == 'rows' && layout.rows == 1) {
        return HomeStyleBlock.rows;
      }
    case 'horizontalGap':
      if (layout.resolvedLayout(legacyRow) == 'grid' &&
          layout.resolvedColumns(
                legacyRow: legacyRow,
                legacyColumns: legacyColumns,
              ) ==
              1) {
        return HomeStyleBlock.singleColumn;
      }
    case 'labelPosition':
      if (tiles.labels != 'all') return HomeStyleBlock.allLabels;
    case 'labelSize':
    case 'labelColor':
      if (tiles.labels == 'none') return HomeStyleBlock.labels;
    case 'focusScale':
      if (tiles.focusEffect != 'scale') return HomeStyleBlock.scale;
    case 'focusLift':
      if (tiles.focusEffect != 'lift') return HomeStyleBlock.lift;
    case 'focusBorderColor':
    case 'focusPulse':
      if (tiles.focusBorderStyle(legacyHidden: legacyHiddenBorder) == 'none') {
        return HomeStyleBlock.border;
      }
    case 'sectionIcons':
      if (!tiles.sectionTitles) return HomeStyleBlock.title;
    case 'blurTiles':
      if (tiles.opacity == 1) return HomeStyleBlock.opaque;
    case 'backgroundColor':
      if (tiles.opacity == 0) return HomeStyleBlock.transparent;
  }
  return null;
}

bool ownsHomeStyleField(CategoryAppearance style, String field) =>
    !style.useGlobalTiles && style.tiles.containsKey(field) ||
    field == 'sectionPadding' && style.values.containsKey('padding') ||
    field == 'sectionBackground' && style.values.containsKey('background');
