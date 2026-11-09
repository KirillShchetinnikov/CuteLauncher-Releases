import 'package:flutter/material.dart';

/// Static placeholders: no ticker, image decode, blur or offscreen work.
class HomeSkeletonBlock extends StatelessWidget {
  const HomeSkeletonBlock({super.key, this.radius, this.focused = false});
  final BorderRadius? radius;
  final bool focused;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: radius ?? BorderRadius.circular(4),
        border: focused
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
      ),
    ),
  );
}

class HomeSkeletonRow extends StatelessWidget {
  const HomeSkeletonRow({super.key, required this.width, required this.height,
    required this.gap, required this.labelHeight, required this.card, this.radius});
  final double width, height, gap, labelHeight;
  final Widget Function(bool first) card;
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, constraints) {
    final count = ((constraints.maxWidth + gap) / (width + gap)).floor().clamp(1, 24);
    return ClipRect(child: CustomPaint(
      painter: _SkeletonRowPainter(width: width, height: height, gap: gap,
        labelHeight: labelHeight, count: count,
        radius: radius ?? BorderRadius.circular(4),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        direction: Directionality.of(context)),
      child: Stack(children: [
        // Only the first card participates in focus. The remaining static
        // shapes need no elements or individual layout passes.
        PositionedDirectional(start: 0, top: 0, width: width, height: height,
          child: card(true)),
      ]),
    ));
  });
}

class _SkeletonRowPainter extends CustomPainter {
  const _SkeletonRowPainter({required this.width, required this.height,
    required this.gap, required this.labelHeight, required this.count,
    required this.radius, required this.color, required this.direction});
  final double width, height, gap, labelHeight;
  final int count;
  final BorderRadius radius;
  final Color color;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final rtl = direction == TextDirection.rtl;
    for (var i = 0; i < count; i++) {
      final start = i * (width + gap);
      final left = rtl ? size.width - start - width : start;
      if (i > 0) {
        canvas.drawRRect(radius.toRRect(Rect.fromLTWH(left, 0, width, height)), paint);
      }
      if (labelHeight > 8) {
        final labelWidth = width * .65;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(
          rtl ? left + width - labelWidth : left, height + 8,
          labelWidth, (labelHeight - 8) * .28), const Radius.circular(4)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SkeletonRowPainter old) => width != old.width ||
      height != old.height || gap != old.gap || labelHeight != old.labelHeight ||
      count != old.count || radius != old.radius || color != old.color ||
      direction != old.direction;
}

/// Reserves a known numeric field using the actual font and text scale.
class HomeSkeletonValue extends StatelessWidget {
  const HomeSkeletonValue({super.key, required this.sample,
    required this.child, this.loading = false, this.style});
  final String sample;
  final Widget child;
  final bool loading;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final textStyle = DefaultTextStyle.of(context).style.merge(style);
    final painter = TextPainter(text: TextSpan(text: sample, style: textStyle),
      textDirection: Directionality.of(context), textScaler: MediaQuery.textScalerOf(context))..layout();
    final size = painter.size;
    painter.dispose();
    return ConstrainedBox(constraints: BoxConstraints(minWidth: size.width),
      child: loading ? SizedBox(width: size.width, height: size.height,
        child: Align(alignment: AlignmentDirectional.centerStart,
          child: SizedBox(width: size.width, height: size.height * .55,
            child: const HomeSkeletonBlock()))) : child);
  }
}
