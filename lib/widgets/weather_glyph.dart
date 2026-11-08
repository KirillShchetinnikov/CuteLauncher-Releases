import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'dart:math' as math;

import '../models/weather_data.dart';
import '../tile_appearance.dart';

/// A monochrome condition glyph. The caller supplies the resolved weather tint.
class WeatherGlyph extends StatelessWidget {
  const WeatherGlyph({
    super.key,
    required this.condition,
    required this.pack,
    this.size,
    this.color,
    this.shadows,
  });

  final WeatherCondition condition;
  final WeatherIconPack pack;
  final double? size;
  final Color? color;
  final List<Shadow>? shadows;

  @override
  Widget build(BuildContext context) {
    if (pack == WeatherIconPack.standard) {
      return Icon(
        condition.standardIcon,
        size: size,
        color: color,
        shadows: shadows,
      );
    }
    final theme = IconTheme.of(context);
    final nominalSize = size ?? theme.size ?? 24;
    final extent = theme.applyTextScaling == true
        ? MediaQuery.textScalerOf(context).scale(nominalSize)
        : nominalSize;
    final baseColor =
        color ??
        theme.color ??
        DefaultTextStyle.of(context).style.color ??
        Colors.white;
    final tint = baseColor.withValues(
      alpha: baseColor.a * (theme.opacity ?? 1),
    );
    return CustomPaint(
      size: Size.square(extent),
      painter: _WeatherGlyphPainter(
        condition,
        pack,
        tint,
        shadows ?? theme.shadows,
      ),
    );
  }
}

class _WeatherGlyphPainter extends CustomPainter {
  const _WeatherGlyphPainter(
    this.condition,
    this.pack,
    this.color,
    this.shadows,
  );

  final WeatherCondition condition;
  final WeatherIconPack pack;
  final Color color;
  final List<Shadow>? shadows;

  @override
  void paint(Canvas canvas, Size size) {
    void draw(Color tint, {Shadow? shadow}) {
      canvas.save();
      if (shadow != null) canvas.translate(shadow.offset.dx, shadow.offset.dy);
      canvas.scale(size.width / 24, size.height / 24);
      final ink = Paint()
        ..color = tint
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      if (shadow != null && shadow.blurRadius > 0) {
        ink.maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurSigma);
      }
      switch (pack) {
        case WeatherIconPack.standard:
          break; // Rendered by Icon.
        case WeatherIconPack.outline:
          ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.65;
          final (body, detail) = _outlinePaths[condition]!;
          canvas.drawPath(body, ink);
          canvas.drawPath(detail, ink);
        case WeatherIconPack.solid:
          canvas.drawPath(_solidPaths[condition]!, ink);
        case WeatherIconPack.duotone:
          final (secondary, primary) = _duotonePaths[condition]!;
          ink.color = tint.withValues(alpha: tint.a * .48);
          canvas.drawPath(secondary, ink);
          ink.color = tint;
          canvas.drawPath(primary, ink);
        case WeatherIconPack.pixel:
          canvas.drawPath(_pixelPaths[condition]!, ink);
        case WeatherIconPack.geometric:
          canvas.drawPath(_geometricPaths[condition]!, ink);
        case WeatherIconPack.circled:
          ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4;
          canvas.drawCircle(const Offset(12, 12), 10.7, ink);
          ink.style = PaintingStyle.fill;
          canvas.translate(12, 12);
          canvas.scale(.66);
          canvas.translate(-12, -12);
          canvas.drawPath(_solidPaths[condition]!, ink);
      }
      canvas.restore();
    }

    for (final shadow in shadows ?? const <Shadow>[]) {
      draw(shadow.color, shadow: shadow);
    }
    draw(color);
  }

  @override
  bool shouldRepaint(_WeatherGlyphPainter oldDelegate) =>
      condition != oldDelegate.condition ||
      pack != oldDelegate.pack ||
      color != oldDelegate.color ||
      !listEquals(shadows, oldDelegate.shadows);
}

// Paths share a 24 × 24 box. The outline set uses thin, rounded strokes.
final _outlinePaths = {
  for (final condition in WeatherCondition.values)
    condition: _drawOutline(condition),
};

(Path, Path) _drawOutline(WeatherCondition condition) {
  final body = Path();
  final detail = Path();
  void line(double x1, double y1, double x2, double y2) {
    detail
      ..moveTo(x1, y1)
      ..lineTo(x2, y2);
  }

  void cloud({Offset offset = Offset.zero}) {
    final silhouette = Path()
      ..moveTo(6, 17)
      ..cubicTo(1.6, 17, 1.6, 10.6, 6.2, 10.2)
      ..cubicTo(7, 5.1, 14.5, 4.2, 16.9, 10)
      ..cubicTo(22.8, 9, 23, 17, 18.1, 17)
      ..close();
    body.addPath(silhouette, offset);
  }

  switch (condition) {
    case WeatherCondition.sun:
      body.addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 4.1));
      line(12, 2, 12, 4.5);
      line(12, 19.5, 12, 22);
      line(2, 12, 4.5, 12);
      line(19.5, 12, 22, 12);
      line(5, 5, 6.8, 6.8);
      line(17.2, 17.2, 19, 19);
      line(19, 5, 17.2, 6.8);
      line(6.8, 17.2, 5, 19);
    case WeatherCondition.moon:
      body
        ..moveTo(13.7, 3.3)
        ..cubicTo(8.9, 9.4, 12.3, 16, 20.4, 14.5)
        ..cubicTo(18.6, 21.8, 9.5, 23, 5.1, 17.5)
        ..cubicTo(0.5, 11.8, 5.3, 3.2, 13.7, 3.3)
        ..close();
      line(18, 3.5, 18, 7.5);
      line(16, 5.5, 20, 5.5);
    case WeatherCondition.partlyCloudy:
      cloud(offset: const Offset(0, 3));
      detail
        ..moveTo(5.1, 11.2)
        ..cubicTo(3, 6.4, 9.7, 3.3, 12.3, 7.1);
      line(7.4, 2.2, 7.9, 3.6);
      line(2.3, 5.2, 3.5, 6.3);
      line(13, 3.2, 12.4, 4.3);
    case WeatherCondition.cloudy:
      cloud();
    case WeatherCondition.unknown:
      cloud(offset: const Offset(0, -1));
      line(9, 20, 15, 20);
    case WeatherCondition.rain:
      cloud(offset: const Offset(0, -2.5));
      line(8, 17.8, 6.6, 21);
      line(13, 17.8, 11.6, 21);
      line(18, 17.8, 16.6, 21);
    case WeatherCondition.snow:
      cloud(offset: const Offset(0, -3));
      line(12, 16.5, 12, 22.5);
      line(9.4, 18, 14.6, 21);
      line(9.4, 21, 14.6, 18);
    case WeatherCondition.storm:
      cloud(offset: const Offset(0, -4));
      body
        ..moveTo(12, 14.8)
        ..lineTo(15, 14.8)
        ..lineTo(12.6, 17.8)
        ..lineTo(15, 17.8)
        ..lineTo(10.4, 22.6)
        ..lineTo(11.2, 19.3)
        ..lineTo(9.1, 19.3)
        ..close();
    case WeatherCondition.fog:
      cloud(offset: const Offset(0, -4));
      line(3, 16.5, 20, 16.5);
      line(6, 20.5, 17, 20.5);
    case WeatherCondition.wind:
      detail
        ..moveTo(2.8, 8)
        ..lineTo(13, 8)
        ..cubicTo(17.3, 8, 16.9, 2, 13.3, 3.5)
        ..moveTo(2.8, 12.5)
        ..lineTo(18.2, 12.5)
        ..cubicTo(22.7, 12.5, 22.5, 6.3, 18.6, 7.4)
        ..moveTo(4.3, 17)
        ..lineTo(13.6, 17)
        ..cubicTo(17.6, 17, 17, 22.8, 13.3, 21.2);
  }
  return (body, detail);
}

// Filled silhouettes use a wide cloud, a sunburst and rounded rain drops.
final _solidPaths = {
  for (final condition in WeatherCondition.values)
    condition: _drawSolid(condition),
};

Path _drawSolid(WeatherCondition condition) {
  final path = Path();
  switch (condition) {
    case WeatherCondition.sun:
      _burst(path, const Offset(12, 12), 11, 7, 8);
      _disc(path, 12, 12, 3.4);
      path.fillType = PathFillType.evenOdd;
    case WeatherCondition.moon:
      path
        ..moveTo(7.2, 3.7)
        ..cubicTo(5.8, 13.4, 12.2, 19.2, 21.6, 16)
        ..cubicTo(17.4, 24.5, 6.6, 24, 3, 16.7)
        ..cubicTo(.7, 12, 2.5, 6.8, 7.2, 3.7)
        ..close();
      _burst(path, const Offset(16.7, 8), 4, 1.5, 4);
    case WeatherCondition.partlyCloudy:
      _burst(path, const Offset(6.8, 6.5), 5.5, 3.5, 8);
      _cloud(path, 4.2, 10, 17.8, 10.5);
    case WeatherCondition.cloudy:
      _cloud(path, 1.3, 5, 21.4, 14);
    case WeatherCondition.unknown:
      _cloud(path, 2, 4, 20, 12);
      for (final x in [8.0, 12.0, 16.0]) {
        _disc(path, x, 20, 1.2);
      }
    case WeatherCondition.rain:
      _cloud(path, 1.8, 3, 20.4, 10);
      _drop(path, 8, 15.5, 2.15);
      _drop(path, 15, 14.5, 3.05);
    case WeatherCondition.snow:
      _burst(path, const Offset(12, 12), 10.4, 4.0, 6);
      for (final point in const [
        Offset(4, 4),
        Offset(20, 4),
        Offset(4, 20),
        Offset(20, 20),
      ]) {
        _disc(path, point.dx, point.dy, 1.25);
      }
    case WeatherCondition.storm:
      _cloud(path, 1.8, 2.3, 20.4, 10.2);
      _bolt(path, 8.2, 13.5);
    case WeatherCondition.fog:
      _pill(path, 3.2, 4.5, 14, 3.2);
      _pill(path, 1.5, 10.5, 20, 3.2);
      _pill(path, 6.5, 16.5, 15.5, 3.2);
    case WeatherCondition.wind:
      path
        ..moveTo(2, 8)
        ..cubicTo(10, 11, 11, 1, 20, 4.2)
        ..cubicTo(15, 5, 13, 13.5, 2, 11.2)
        ..close()
        ..moveTo(2.8, 16.2)
        ..cubicTo(11, 17, 13.5, 8.4, 22, 12)
        ..cubicTo(16, 12.2, 13, 21, 2.8, 19.5)
        ..close();
  }
  return path;
}

// The two-tone set layers soft halos and clouds with a full-opacity foreground.
final _duotonePaths = {
  for (final condition in WeatherCondition.values)
    condition: _drawDuotone(condition),
};

(Path, Path) _drawDuotone(WeatherCondition condition) {
  final soft = Path();
  final ink = Path();
  switch (condition) {
    case WeatherCondition.sun:
      _disc(soft, 12, 12, 8.5);
      _disc(ink, 12, 12, 4.4);
      for (var i = 0; i < 8; i++) {
        final angle = i * math.pi / 4;
        _disc(
          ink,
          12 + 10.2 * math.cos(angle),
          12 + 10.2 * math.sin(angle),
          .9,
        );
      }
    case WeatherCondition.moon:
      _disc(soft, 10.9, 12.1, 8.4);
      ink
        ..moveTo(9.3, 4.1)
        ..cubicTo(4.1, 12.7, 11.7, 20.5, 19, 15.3)
        ..cubicTo(15.3, 23.6, 3.4, 20, 3.5, 12.6)
        ..cubicTo(3.5, 8.7, 5.8, 5.3, 9.3, 4.1)
        ..close();
      _disc(ink, 18, 5.3, 1.4);
      _disc(soft, 21.2, 8.7, 1.1);
    case WeatherCondition.partlyCloudy:
      _disc(soft, 15.5, 7.8, 6);
      _disc(ink, 15.5, 7.8, 2.8);
      _cloud(ink, 2, 10.1, 18, 10.4);
    case WeatherCondition.cloudy:
      _cloud(soft, 8, 3, 14.3, 10.3);
      _cloud(ink, 1.5, 9.4, 19, 11.4);
    case WeatherCondition.unknown:
      _cloud(soft, 2.1, 4, 19.8, 14);
      _pill(ink, 8.5, 11, 7, 2.4);
    case WeatherCondition.rain:
      _cloud(soft, 2.1, 2.5, 19.8, 11.8);
      _drop(ink, 6.3, 13.4, 2.0);
      _drop(ink, 12.1, 15.2, 2.8);
      _drop(ink, 18, 13.4, 2.0);
    case WeatherCondition.snow:
      _cloud(soft, 2.1, 2.5, 19.8, 12);
      _burst(ink, const Offset(12, 17.7), 5.2, 1.9, 6);
      _disc(ink, 5.6, 16.9, 1.2);
      _disc(ink, 18.4, 16.9, 1.2);
    case WeatherCondition.storm:
      _cloud(soft, 1.7, 2.7, 20.6, 13);
      _bolt(ink, 8.2, 12);
    case WeatherCondition.fog:
      _cloud(soft, 4, 3.1, 15.8, 12.3);
      _pill(ink, 1.8, 12, 20.4, 1.9);
      _pill(ink, 3.9, 16, 16.2, 1.9);
      _pill(soft, 6.1, 20, 11.8, 1.9);
    case WeatherCondition.wind:
      _pill(soft, 4, 5.5, 13.4, 3);
      _disc(soft, 19.6, 7, 1.5);
      _pill(ink, 1.6, 10.5, 20.4, 3);
      _disc(soft, 3.5, 17, 1.5);
      _pill(soft, 6.5, 15.5, 12.2, 3);
  }
  return (soft, ink);
}

void _disc(Path path, double x, double y, double radius) =>
    path.addOval(Rect.fromCircle(center: Offset(x, y), radius: radius));

void _pill(Path path, double x, double y, double width, double height) =>
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, width, height),
        Radius.circular(height / 2),
      ),
    );

void _cloud(Path path, double x, double y, double width, double height) {
  _pill(path, x, y + height * .43, width, height * .57);
  _disc(path, x + width * .44, y + height * .42, height * .42);
  _disc(path, x + width * .70, y + height * .51, height * .32);
}

void _burst(Path path, Offset center, double outer, double inner, int rays) {
  path.addPolygon([
    for (var i = 0; i < rays * 2; i++)
      center +
          Offset.fromDirection(
            i * math.pi / rays - math.pi / 2,
            i.isEven ? outer : inner,
          ),
  ], true);
}

void _drop(Path path, double x, double y, double radius) => path
  ..moveTo(x, y)
  ..cubicTo(
    x + radius * 2,
    y + radius * 2,
    x + radius,
    y + radius * 2.8,
    x,
    y + radius * 2.8,
  )
  ..cubicTo(x - radius, y + radius * 2.8, x - radius * 2, y + radius * 2, x, y)
  ..close();

void _bolt(Path path, double x, double y) => path.addPolygon([
  Offset(x + 3, y),
  Offset(x + 8, y),
  Offset(x + 5.2, y + 3.2),
  Offset(x + 8, y + 3.2),
  Offset(x, y + 9.5),
  Offset(x + 2.2, y + 5.2),
  Offset(x, y + 5.2),
], true);

// Angular silhouettes use straight edges, lozenges and faceted clouds.
final _geometricPaths = {
  for (final condition in WeatherCondition.values)
    condition: _drawGeometric(condition),
};

Path _drawGeometric(WeatherCondition condition) {
  final path = Path();
  void diamond(double x, double y, double radius) => path.addPolygon([
    Offset(x, y - radius), Offset(x + radius, y),
    Offset(x, y + radius), Offset(x - radius, y),
  ], true);
  void cloud(double bottom) => path.addPolygon([
    Offset(2, bottom - 2), Offset(2, bottom - 6),
    Offset(6, bottom - 8), Offset(8, bottom - 11),
    Offset(13, bottom - 11), Offset(17, bottom - 7),
    Offset(20, bottom - 7), Offset(23, bottom - 3),
    Offset(20, bottom), Offset(5, bottom),
  ], true);
  switch (condition) {
    case WeatherCondition.sun:
      path.addPolygon([
        for (var i = 0; i < 8; i++)
          const Offset(12, 12) + Offset.fromDirection(i * math.pi / 4, 5),
      ], true);
      for (var i = 0; i < 8; i++) {
        final direction = i * math.pi / 4;
        final center = const Offset(12, 12) + Offset.fromDirection(direction, 9.1);
        final radial = Offset.fromDirection(direction, 1.8);
        final cross = Offset.fromDirection(direction + math.pi / 2, .8);
        path.addPolygon([center - radial, center + cross, center + radial, center - cross], true);
      }
    case WeatherCondition.moon:
      path.addPolygon(const [
        Offset(13, 2), Offset(8, 7), Offset(8, 12), Offset(12, 16),
        Offset(17, 17), Offset(22, 14), Offset(19, 21), Offset(12, 23),
        Offset(5, 20), Offset(2, 13), Offset(5, 6),
      ], true);
      diamond(18, 6, 2.3);
    case WeatherCondition.partlyCloudy:
      diamond(6, 6, 4.5);
      cloud(21);
    case WeatherCondition.cloudy:
      cloud(19);
    case WeatherCondition.unknown:
      cloud(15);
      for (final x in [7.0, 11.0, 15.0]) {
        path.addRect(Rect.fromLTWH(x, 19, 2, 2));
      }
    case WeatherCondition.rain:
      cloud(13);
      for (final x in [7.0, 13.0, 19.0]) {
        path.addPolygon([
          Offset(x, 16), Offset(x + 1.6, 17),
          Offset(x - .8, 22), Offset(x - 2.4, 21),
        ], true);
      }
    case WeatherCondition.snow:
      cloud(13);
      diamond(7, 19, 2.4);
      diamond(12, 17.5, 1.6);
      diamond(17, 20, 2.4);
    case WeatherCondition.storm:
      cloud(13);
      _bolt(path, 8.2, 13.5);
    case WeatherCondition.fog:
      for (var i = 0; i < 3; i++) {
        final y = 5.0 + i * 6;
        final x = i == 1 ? 2.0 : 5.0;
        path.addPolygon([
          Offset(x + 2, y), Offset(22 - x, y),
          Offset(20 - x, y + 2.5), Offset(x, y + 2.5),
        ], true);
      }
    case WeatherCondition.wind:
      for (final y in [5.0, 14.0]) {
        path.addPolygon([
          Offset(2, y + 2), Offset(16, y + 2), Offset(16, y),
          Offset(22, y + 3.5), Offset(16, y + 7), Offset(16, y + 5),
          Offset(2, y + 5),
        ], true);
      }
  }
  return path;
}

// Each mark represents one square on a 12 × 12 grid. Paths are built once.
final _pixelPaths = _pixelArt.map((condition, art) {
  final path = Path();
  final rows = art.trim().split('\n');
  for (var y = 0; y < rows.length; y++) {
    final row = rows[y];
    var x = 0;
    while (x < row.length) {
      if (row[x] != '#') {
        x++;
        continue;
      }
      final start = x;
      do {
        x++;
      } while (x < row.length && row[x] == '#');
      path.addRect(Rect.fromLTWH(start * 2.0, y * 2.0, (x - start) * 2.0, 2));
    }
  }
  return MapEntry(condition, path);
});

const _pixelArt = {
  WeatherCondition.sun: '''............
.....##.....
..#..##..#..
...#....#...
....####....
.##.####.##.
.##.####.##.
....####....
...#....#...
..#..##..#..
.....##.....
............''',
  WeatherCondition.moon: '''............
........#...
....###.#...
...###.###..
..###...#...
..###.......
..####......
..#####..#..
...#######..
....#####...
............
............''',
  WeatherCondition.partlyCloudy: '''............
...#........
.#...#......
..###.......
.####.###...
..##.#####..
....#######.
...########.
...########.
....######..
............
............''',
  WeatherCondition.cloudy: '''............
............
.....###....
....#####...
...#######..
..#########.
.##########.
.##########.
..########..
............
............
............''',
  WeatherCondition.unknown: '''............
............
.....###....
....#...#...
...#.....#..
..#.......#.
.##.......#.
..########..
............
....####....
............
............''',
  WeatherCondition.rain: '''............
.....###....
....#####...
...#######..
..#########.
.##########.
..########..
............
....#..#..#.
...#..#..#..
..#..#..#...
............''',
  WeatherCondition.snow: '''............
.....###....
....#####...
...#######..
..#########.
..########..
............
...#..#..#..
....#####...
...#######..
....#####...
...#..#..#..''',
  WeatherCondition.storm: '''............
.....###....
....#####...
...#######..
..#########.
..########..
.....##.....
....##......
....####....
......#.....
.....#......
....#.......''',
  WeatherCondition.fog: '''............
.....###....
....#####...
...#######..
..#########.
..########..
............
.##########.
............
...######...
............
............''',
  WeatherCondition.wind: '''............
.......##...
.........#..
..#######...
............
.........##.
.#########..
............
...######...
.........#..
.......##...
............''',
};
