import 'package:flutter/material.dart';

import '../section_icons.dart';

/// Decorative 24-unit line glyphs that follow the surrounding icon theme.
class SectionHeadingIcon extends StatelessWidget {
  const SectionHeadingIcon(this.icon, {super.key});

  final SectionIcon icon;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final color =
        theme.color ??
        DefaultTextStyle.of(context).style.color ??
        Theme.of(context).colorScheme.onSurface;
    return CustomPaint(
      size: Size.square(theme.size ?? 24),
      painter: _SectionIconPainter(
        icon,
        color.withValues(alpha: color.a * (theme.opacity ?? 1)),
      ),
    );
  }
}

class _SectionIconPainter extends CustomPainter {
  const _SectionIconPainter(this.icon, this.color);

  final SectionIcon icon;
  final Color color;
  static final _paths = {
    for (final icon in SectionIcon.values) icon: _drawIcon(icon),
  };

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    canvas.drawPath(
      _paths[icon]!,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SectionIconPainter oldDelegate) =>
      oldDelegate.icon != icon || oldDelegate.color != color;
}

Path _drawIcon(SectionIcon icon) {
  final path = Path();

  void box(
    double left,
    double top,
    double right,
    double bottom, [
    double r = 2,
  ]) {
    path.addRRect(
      RRect.fromLTRBR(left, top, right, bottom, Radius.circular(r)),
    );
  }

  void oval(double x, double y, double rx, double ry) {
    path.addOval(
      Rect.fromCenter(center: Offset(x, y), width: 2 * rx, height: 2 * ry),
    );
  }

  void line(List<(double, double)> points, {bool close = false}) {
    final (x, y) = points.first;
    path.moveTo(x, y);
    for (final (x, y) in points.skip(1)) {
      path.lineTo(x, y);
    }
    if (close) path.close();
  }

  switch (icon) {
    case SectionIcon.allApps:
      box(3, 3, 10, 10, 1.5);
      box(14, 3, 21, 10, 1.5);
      box(3, 14, 10, 21, 1.5);
      box(14, 14, 21, 21, 1.5);
    case SectionIcon.tvApps:
      box(2.5, 4, 21.5, 17, 2.5);
      line([(8, 21), (16, 21)]);
      line([(12, 17), (12, 21)]);
      line([(10.5, 8), (15, 10.5), (10.5, 13)], close: true);
    case SectionIcon.otherApps:
      box(3, 3, 15, 21, 2.5);
      line([(7, 17.5), (11, 17.5)]);
      path
        ..moveTo(18.5, 8)
        ..lineTo(19.5, 8)
        ..quadraticBezierTo(21, 8, 21, 9.5)
        ..lineTo(21, 15.5)
        ..quadraticBezierTo(21, 17, 19.5, 17)
        ..lineTo(18.5, 17);
    case SectionIcon.favorites:
      path
        ..moveTo(12, 20)
        ..cubicTo(9, 17.5, 3, 13.8, 3, 8.9)
        ..cubicTo(3, 4, 9, 2.8, 12, 7)
        ..cubicTo(15, 2.8, 21, 4, 21, 8.9)
        ..cubicTo(21, 13.8, 15, 17.5, 12, 20)
        ..close();
    case SectionIcon.appFeeds:
      box(3, 4, 14, 20, 2);
      line([(7.5, 9.5), (11, 12), (7.5, 14.5)], close: true);
      line([(17.5, 5.5), (21, 5.5)]);
      line([(17.5, 12), (21, 12)]);
      line([(17.5, 18.5), (21, 18.5)]);
    case SectionIcon.continueWatching:
      path
        ..moveTo(6, 6)
        ..cubicTo(11, 1, 21, 3, 21, 12)
        ..cubicTo(21, 20.5, 10.5, 24, 5, 17);
      line([(3, 4), (3, 9), (8, 9)]);
      line([(11, 8.5), (16, 12), (11, 15.5)], close: true);
    case SectionIcon.movies:
      box(3, 10, 21, 20.5);
      line([(3.5, 9.5), (2.5, 6), (19.8, 2.5), (20.7, 6.5), (3.5, 9.5)]);
      line([(8.2, 5), (10.2, 8)]);
      line([(14.2, 3.7), (16.2, 7)]);
      line([(7, 15.3), (17, 15.3)]);
    case SectionIcon.music:
      line([(9, 16.7), (9, 6), (20, 3.5), (20, 14)]);
      line([(9, 9.7), (20, 7.2)]);
      oval(6, 17.5, 3, 2.5);
      oval(17, 15, 3, 2.5);
    case SectionIcon.games:
      path
        ..moveTo(8, 6.5)
        ..lineTo(16, 6.5)
        ..cubicTo(20, 6.5, 21, 10, 22, 15)
        ..cubicTo(22.7, 19.5, 19, 19.5, 16, 15.5)
        ..lineTo(8, 15.5)
        ..cubicTo(5, 19.5, 1.3, 19.5, 2, 15)
        ..cubicTo(3, 10, 4, 6.5, 8, 6.5)
        ..close();
      line([(5.5, 11.3), (10.5, 11.3)]);
      line([(8, 8.8), (8, 13.8)]);
      line([(15, 12.8), (15.15, 12.8)]);
      line([(17.8, 10.2), (17.95, 10.2)]);
    case SectionIcon.entertainment:
      path
        ..moveTo(10, 3)
        ..quadraticBezierTo(10.8, 9.2, 17, 10)
        ..quadraticBezierTo(10.8, 10.8, 10, 17)
        ..quadraticBezierTo(9.2, 10.8, 3, 10)
        ..quadraticBezierTo(9.2, 9.2, 10, 3)
        ..close();
      line([(17, 18), (22, 18)]);
      line([(19.5, 15.5), (19.5, 20.5)]);
    case SectionIcon.liveTv:
      box(3, 8, 21, 20, 2.5);
      line([(7, 3.5), (12, 8), (17, 3.5)]);
      path
        ..moveTo(6.5, 14)
        ..lineTo(9.5, 14)
        ..lineTo(11.5, 11.5)
        ..lineTo(14, 16)
        ..lineTo(16, 14)
        ..lineTo(17.5, 14);
    case SectionIcon.sports:
      path
        ..moveTo(7, 4)
        ..lineTo(17, 4)
        ..lineTo(17, 9)
        ..cubicTo(17, 15.5, 7, 15.5, 7, 9)
        ..close()
        ..moveTo(7, 6)
        ..lineTo(3, 6)
        ..quadraticBezierTo(3, 12, 8, 12)
        ..moveTo(17, 6)
        ..lineTo(21, 6)
        ..quadraticBezierTo(21, 12, 16, 12);
      line([(12, 14), (12, 20)]);
      line([(8, 20), (16, 20)]);
    case SectionIcon.news:
      box(3, 4, 21, 20);
      box(6.5, 8, 11, 12, .6);
      line([(14, 8), (17.5, 8)]);
      line([(14, 12), (17.5, 12)]);
      line([(6.5, 16), (17.5, 16)]);
    case SectionIcon.tools:
      path
        ..moveTo(13, 5)
        ..quadraticBezierTo(16, 2, 20, 4)
        ..lineTo(16.5, 7.5)
        ..lineTo(18.5, 9.5)
        ..lineTo(22, 6)
        ..quadraticBezierTo(23, 13, 16, 13)
        ..lineTo(8.5, 20.5)
        ..quadraticBezierTo(6.5, 22.5, 4.5, 20.5)
        ..quadraticBezierTo(2.5, 18.5, 4.5, 16.5)
        ..lineTo(12, 9)
        ..quadraticBezierTo(11, 6.5, 13, 5)
        ..close();
    case SectionIcon.photos:
      box(3, 4, 21, 20);
      oval(8.5, 9, 1.4, 1.4);
      line([(3.5, 17.5), (8.5, 13), (12, 16), (16.5, 11), (21, 15)]);
    case SectionIcon.folder:
      path
        ..moveTo(3, 7)
        ..quadraticBezierTo(3, 5, 5, 5)
        ..lineTo(9, 5)
        ..lineTo(12, 8)
        ..lineTo(19, 8)
        ..quadraticBezierTo(21, 8, 21, 10)
        ..lineTo(21, 17)
        ..quadraticBezierTo(21, 19, 19, 19)
        ..lineTo(5, 19)
        ..quadraticBezierTo(3, 19, 3, 17)
        ..close();
    case SectionIcon.weather:
      path
        ..moveTo(6.5, 20)
        ..cubicTo(1.4, 20, 1.4, 12.5, 6.7, 12.7)
        ..cubicTo(8.1, 7.5, 15.1, 7.9, 16.1, 13.2)
        ..cubicTo(21.3, 11.8, 22.4, 20, 17.2, 20)
        ..close()
        ..moveTo(12.8, 6.6)
        ..cubicTo(15.2, 2.7, 21.2, 5.6, 18.6, 10);
      line([(15.5, 2), (15.7, 2.6)]);
      line([(20.3, 3.7), (21.1, 2.9)]);
      line([(21.3, 8.1), (22, 8.2)]);
    case SectionIcon.reading:
      path
        ..moveTo(12, 6.5)
        ..quadraticBezierTo(8.5, 3.8, 3, 4.5)
        ..lineTo(3, 18.5)
        ..quadraticBezierTo(8.5, 17.8, 12, 20.5)
        ..quadraticBezierTo(15.5, 17.8, 21, 18.5)
        ..lineTo(21, 4.5)
        ..quadraticBezierTo(15.5, 3.8, 12, 6.5)
        ..close();
      line([(12, 6.5), (12, 20.5)]);
    case SectionIcon.kids:
      oval(12, 12, 9, 9);
      line([(8.2, 10), (8.4, 10)]);
      line([(15.6, 10), (15.8, 10)]);
      path
        ..moveTo(8, 14)
        ..quadraticBezierTo(12, 19, 16, 14);
    case SectionIcon.smartHome:
      line([(3, 10.5), (12, 3), (21, 10.5)]);
      line([(5, 9), (5, 21), (19, 21), (19, 9)]);
      path
        ..moveTo(8.5, 12.8)
        ..quadraticBezierTo(12, 9.8, 15.5, 12.8)
        ..moveTo(10.2, 15.3)
        ..quadraticBezierTo(12, 13.8, 13.8, 15.3);
      line([(11.9, 18), (12.1, 18)]);
    case SectionIcon.travel:
      box(3, 7, 21, 20, 2.5);
      path
        ..moveTo(8.5, 7)
        ..lineTo(8.5, 5)
        ..quadraticBezierTo(8.5, 3.5, 10, 3.5)
        ..lineTo(14, 3.5)
        ..quadraticBezierTo(15.5, 3.5, 15.5, 5)
        ..lineTo(15.5, 7);
      line([(7.5, 11), (7.5, 16)]);
      line([(16.5, 11), (16.5, 16)]);
    case SectionIcon.podcasts:
      box(9, 3, 15, 14, 3);
      path
        ..moveTo(5.5, 11)
        ..cubicTo(5.5, 20, 18.5, 20, 18.5, 11);
      line([(12, 17.75), (12, 21)]);
      line([(8.5, 21), (15.5, 21)]);
  }
  return path;
}
