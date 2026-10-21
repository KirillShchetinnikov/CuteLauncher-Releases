import 'dart:ui' as ui;
import 'package:flauncher/theme/launcher_style.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/memory_resources.dart';

/// The base tile theme's outline, shared with the live settings preview.
/// Explicit appearance settings use AppearanceSurface's outline instead.
class TileThemeOutline extends StatefulWidget {
  final String theme;
  final Color accent;
  final double opacity;
  final bool pulse;
  final double? radius;
  final String borderStyle;

  const TileThemeOutline({
    super.key,
    required this.theme,
    required this.accent,
    this.opacity = 1,
    this.pulse = false,
    this.radius,
    this.borderStyle = 'outline',
  });

  @override
  State<TileThemeOutline> createState() => _TileThemeOutlineState();
}

class _TileThemeOutlineState extends State<TileThemeOutline>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(vsync: this);
  bool _effectsAllowed = true;

  bool get _pulsing =>
      _effectsAllowed && widget.pulse && widget.borderStyle != 'none' &&
      widget.theme != 'classic' && widget.theme != 'premium';

  void _syncAnimation() {
    if (_pulsing) {
      if (!_animation.isAnimating) _animation.repeat(reverse: true);
    } else {
      _animation.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animation.duration = LauncherStyle.of(context).pulseDuration;
    final resources = context.watch<MemoryResources?>();
    _effectsAllowed = TickerMode.valuesOf(context).enabled &&
        !(resources?.economyEnabled ?? false) && (resources?.isForeground ?? true);
    _syncAnimation();
  }

  @override
  void didUpdateWidget(TileThemeOutline oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.theme == 'premium' || widget.borderStyle == 'none') return const SizedBox.shrink();
    final style = LauncherStyle.of(context);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final opacity = _pulsing ? .7 + _animation.value * .3 : widget.opacity;
        final color = brighterTileFocusColor(widget.accent).withValues(alpha: opacity);
        if (widget.borderStyle == 'glow') {
          return IgnorePointer(child: CustomPaint(
            painter: TileGlowPainter(
              color: color,
              radius: style.tileCorners(widget.theme, radius: widget.radius).topLeft.x,
            ),
            child: const SizedBox.expand(),
          ));
        }
        return IgnorePointer(child: CustomPaint(
          painter: TileOutlinePainter(
            color: color,
            radius: style.tileCorners(widget.theme, radius: widget.radius).topLeft.x,
            width: widget.theme == 'classic' ? 4 : 2,
            separator: widget.theme == 'classic' ? 0 : 2,
          ),
          child: const SizedBox.expand(),
        ));
      },
    );
  }
}

/// Both the colored line and its separator are outside the image rectangle.
class TileOutlinePainter extends CustomPainter {
  final Color color;
  final double radius, width, separator;
  const TileOutlinePainter({required this.color, required this.radius,
    required this.width, required this.separator});
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final outer = separator + width / 2;
    canvas.drawRRect(RRect.fromRectAndRadius(bounds.inflate(outer), Radius.circular(radius + outer)),
      Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = width);
    if (separator > 0) {
      canvas.drawRRect(RRect.fromRectAndRadius(bounds.inflate(separator / 2), Radius.circular(radius + separator / 2)),
        Paint()..color = Colors.black.withValues(alpha: color.a)
          ..style = PaintingStyle.stroke..strokeWidth = separator);
    }
  }
  @override
  bool shouldRepaint(TileOutlinePainter old) => color != old.color || radius != old.radius ||
    width != old.width || separator != old.separator;
}

class TileGlowPainter extends CustomPainter {
  final Color color;
  final double radius;
  const TileGlowPainter({required this.color, required this.radius});
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    const extent = 16.0;
    final r = radius.clamp(0.0, size.shortestSide / 2);
    final colors = [color, color.withValues(alpha: color.a * .5625),
      color.withValues(alpha: color.a * .25), color.withValues(alpha: color.a * .0625),
      color.withValues(alpha: 0)];
    const stops = [0.0, .25, .5, .75, 1.0];
    final outside = Path()..fillType = PathFillType.evenOdd
      ..addRect(bounds.inflate(extent))
      ..addRRect(RRect.fromRectAndRadius(bounds, Radius.circular(r)));
    canvas.save();
    canvas.clipPath(outside);
    final paint = Paint();
    void edge(Rect area, Offset from, Offset to) {
      paint.shader = ui.Gradient.linear(from, to, colors, stops);
      canvas.drawRect(area, paint);
    }
    edge(Rect.fromLTRB(r, -extent, size.width-r, 0), Offset.zero, const Offset(0, -extent));
    edge(Rect.fromLTRB(r, size.height, size.width-r, size.height+extent),
      Offset(0, size.height), Offset(0, size.height+extent));
    edge(Rect.fromLTRB(-extent, r, 0, size.height-r), Offset.zero, const Offset(-extent, 0));
    edge(Rect.fromLTRB(size.width, r, size.width+extent, size.height-r),
      Offset(size.width, 0), Offset(size.width+extent, 0));
    final radialStops = [0.0, for (final stop in stops) (r+extent*stop)/(r+extent)];
    for (final corner in [
      (Offset(r, r), Rect.fromLTRB(-extent, -extent, r, r)),
      (Offset(size.width-r, r), Rect.fromLTRB(size.width-r, -extent, size.width+extent, r)),
      (Offset(r, size.height-r), Rect.fromLTRB(-extent, size.height-r, r, size.height+extent)),
      (Offset(size.width-r, size.height-r), Rect.fromLTRB(size.width-r, size.height-r, size.width+extent, size.height+extent)),
    ]) {
      paint.shader = ui.Gradient.radial(corner.$1, r+extent, [color, ...colors], radialStops);
      canvas.drawRect(corner.$2, paint);
    }
    canvas.restore();
  }
  @override
  bool shouldRepaint(TileGlowPainter oldDelegate) => color != oldDelegate.color || radius != oldDelegate.radius;
}

/// A modest lightness boost keeps the selected accent hue for both effects.
Color brighterTileFocusColor(Color color) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness + .08).clamp(0.0, 1.0)).toColor();
}
