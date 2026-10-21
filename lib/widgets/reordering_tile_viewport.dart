import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../home_layout.dart';

/// Keeps each mounted card keyed by package while its layout position changes.
/// Only cards near the viewport (and the selected card) are materialized.
class ReorderingTileViewport extends StatefulWidget {
  final HomeLayout layout;
  final List<String> packages;
  final ScrollController controller;
  final IndexedWidgetBuilder itemBuilder;
  final String? selected;
  final bool animate;
  final ScrollPhysics? physics;

  const ReorderingTileViewport({
    super.key,
    required this.layout,
    required this.packages,
    required this.controller,
    required this.itemBuilder,
    this.selected,
    this.animate = true,
    this.physics,
  });

  @override
  State<ReorderingTileViewport> createState() => _ReorderingTileViewportState();
}

class _ReorderingTileViewportState extends State<ReorderingTileViewport>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: 1,
  );
  Map<String, Offset> _origins = {};
  late Map<String, Offset> _targets;
  double get _progress => Curves.easeInOutCubic.transform(_motion.value);

  Map<String, Offset> _positions() => {
    for (var i = 0; i < widget.packages.length; i++)
      widget.packages[i]: Offset(
        widget.layout.cell(i).$2 * widget.layout.stepX,
        widget.layout.cell(i).$1 * widget.layout.stepY,
      ),
  };

  Offset _position(String package) => Offset.lerp(
    _origins[package] ?? _targets[package],
    _targets[package],
    _progress,
  )!;

  @override
  void initState() {
    super.initState();
    _targets = _positions();
  }

  @override
  void didUpdateWidget(ReorderingTileViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _positions();
    final sameGeometry =
        widget.layout.mode == oldWidget.layout.mode &&
        widget.layout.stepX == oldWidget.layout.stepX &&
        widget.layout.stepY == oldWidget.layout.stepY;
    if (widget.animate &&
        sameGeometry &&
        !listEquals(widget.packages, oldWidget.packages) &&
        setEquals(next.keys.toSet(), _targets.keys.toSet())) {
      // Restart from the currently painted positions if another launch arrives.
      _origins = {for (final package in next.keys) package: _position(package)};
      _targets = next;
      _motion.forward(from: 0);
    } else if (!widget.animate || !sameGeometry || !mapEquals(next, _targets)) {
      _origins = {};
      _targets = next;
      _motion.value = 1;
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final l = widget.layout;
      final vertical = l.mode == 'grid';
      return AnimatedBuilder(
        animation: Listenable.merge([_motion, widget.controller]),
        builder: (context, _) {
          final scroll = widget.controller.hasClients
              ? widget.controller.offset
              : 0.0;
          final viewport = Rect.fromLTWH(
            vertical ? 0 : scroll,
            vertical ? scroll : 0,
            bounds.maxWidth,
            bounds.maxHeight,
          ).inflate(math.max(l.stepX, l.stepY));
          final size = Size(l.width, l.height + l.labelHeight);
          return SingleChildScrollView(
            controller: widget.controller,
            primary: false,
            scrollDirection: vertical ? Axis.vertical : Axis.horizontal,
            physics: widget.physics,
            child: SizedBox(
              width: vertical
                  ? bounds.maxWidth
                  : math.max(bounds.maxWidth, l.contentWidth - l.inset * 2),
              height: vertical
                  ? math.max(bounds.maxHeight, l.contentHeight - l.inset * 2)
                  : bounds.maxHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < widget.packages.length; i++)
                    if (widget.packages[i] == widget.selected ||
                        viewport.overlaps(_position(widget.packages[i]) & size))
                      PositionedDirectional(
                        key: ValueKey(('tile-position', widget.packages[i])),
                        start: _position(widget.packages[i]).dx,
                        top: _position(widget.packages[i]).dy,
                        width: size.width,
                        height: size.height,
                        child: widget.itemBuilder(context, i),
                      ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
