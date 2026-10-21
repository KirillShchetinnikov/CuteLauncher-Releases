import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'tile_appearance.dart';

/// One geometry shared by rendering, remote navigation and materialization.
class HomeLayout {
  final String mode;
  final int count, columns, rows;
  final double width, height, gapX, gapY, inset, labelHeight;
  final List<int> lengths;
  HomeLayout._(
    this.mode,
    this.count,
    this.columns,
    this.rows,
    this.width,
    this.height,
    this.gapX,
    this.gapY,
    this.inset,
    this.labelHeight,
    this.lengths,
  );

  factory HomeLayout({
    required String mode,
    required int count,
    required double availableWidth,
    required TileAppearance style,
    int requestedRows = 1,
    int requestedColumns = 0,
    double labelHeight = 0,
  }) {
    final safeWidth = math.max(48.0, availableWidth);
    // Focus effects paint above sections through TilePaintLayer. Keep their
    // geometry out of layout so changing focus cannot move or resize all cells.
    final inset = math.min(safeWidth / 4, 32.0);
    final inner = math.max(1.0, safeWidth - 2 * inset);
    final columns = requestedColumns > 0
        ? requestedColumns.clamp(1, 12)
        : ((inner + style.horizontalGap) /
                  (style.tileSize * style.aspectRatio + style.horizontalGap))
              .floor()
              .clamp(1, 12);
    final gapX = requestedColumns > 0 && columns > 1
        ? math.min(
            style.horizontalGap,
            math.max(0.0, (inner - columns * 48) / (columns - 1)),
          )
        : style.horizontalGap;
    final width = requestedColumns > 0
        ? (inner - (columns - 1) * gapX) / columns
        : math.min(inner, style.tileSize * style.aspectRatio);
    final rows = mode == 'grid'
        ? (count / columns).ceil()
        : math.min(count, mode == 'row' ? 1 : requestedRows.clamp(1, 6));
    final lengths = <int>[
      for (var r = 0; r < rows; r++)
        mode == 'grid'
            ? math.min(columns, count - r * columns)
            : count ~/ rows + (r < count % rows ? 1 : 0),
    ];
    return HomeLayout._(
      mode,
      count,
      columns,
      rows,
      width,
      width / style.aspectRatio,
      gapX,
      style.verticalGap,
      inset,
      labelHeight,
      lengths,
    );
  }
  double get stepX => width + gapX;
  double get stepY => height + labelHeight + gapY;
  double get contentHeight => rows == 0 ? 0 : rows * stepY - gapY + inset * 2;
  double get contentWidth =>
      lengths.isEmpty ? 0 : lengths.reduce(math.max) * stepX - gapX + inset * 2;
  double windowHeight(int maxRows, double availableHeight) =>
      mode == 'grid' && maxRows > 0
      ? math.min(
          contentHeight,
          math.min(
            math.max(height + labelHeight + inset * 2, availableHeight),
            maxRows * stepY - gapY + inset * 2,
          ),
        )
      : contentHeight;
  int visibleRows(int maxRows, double availableHeight) => math.min(
    rows,
    math.max(
      1,
      ((windowHeight(maxRows, availableHeight) - inset * 2 + gapY) / stepY)
          .floor(),
    ),
  );
  int start(int row) => lengths.take(row).fold(0, (a, b) => a + b);
  (int, int) cell(int index) {
    var rest = index;
    for (var r = 0; r < rows; r++) {
      if (rest < lengths[r]) return (r, rest);
      rest -= lengths[r];
    }
    return (0, 0);
  }

  int? neighbor(int index, AxisDirection direction) {
    final (r, c) = cell(index);
    return switch (direction) {
      AxisDirection.left => c > 0 ? index - 1 : null,
      AxisDirection.right => c + 1 < lengths[r] ? index + 1 : null,
      AxisDirection.up =>
        r > 0 ? start(r - 1) + math.min(c, lengths[r - 1] - 1) : null,
      AxisDirection.down =>
        r + 1 < rows ? start(r + 1) + math.min(c, lengths[r + 1] - 1) : null,
    };
  }
}
