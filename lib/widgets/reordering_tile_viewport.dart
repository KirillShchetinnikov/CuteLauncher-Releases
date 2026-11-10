import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
  final ValueListenable<String?>? selection;
  final String? requested;
  final bool animate;
  final ScrollPhysics? physics;
  // Diagnostic A/B switch: materialize the entire configured Home, including
  // off-screen rows and horizontal cards. Ordinary builds keep the lazy policy.
  final bool materializeAll;

  const ReorderingTileViewport({
    super.key,
    required this.layout,
    required this.packages,
    required this.controller,
    required this.itemBuilder,
    this.selected,
    this.selection,
    this.requested,
    this.animate = true,
    this.physics,
    this.materializeAll = const bool.fromEnvironment('CUTE_HOME_MATERIALIZE_ALL'),
  });

  @override
  State<ReorderingTileViewport> createState() => _ReorderingTileViewportState();
}

class _ReorderingTileViewportState extends State<ReorderingTileViewport>
    with SingleTickerProviderStateMixin {
  ScrollPosition? _outer;
  bool _nearScreen = false, _visibilityScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (_outer != position) {
      _outer?.removeListener(_scheduleVisibility);
      _outer = position;
      _outer?.addListener(_scheduleVisibility);
    }
    _scheduleVisibility();
  }

  void _scheduleVisibility() {
    if (_visibilityScheduled) return;
    _visibilityScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityScheduled = false;
      if (!mounted) return;
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.hasSize || !box.attached) return;
      final screen = Offset.zero & MediaQuery.sizeOf(context);
      // Prepare neighboring rows before a fast D-pad descent reaches them.
      // A 120 dp entry margin created whole feeds during the transition frame.
      // Keep one more screen of visited rows to avoid churn on a short reversal;
      // distant rows and horizontal cards still remain lazily materialized.
      final margin = math.max(120.0, screen.height * (_nearScreen ? 2 : 1));
      final visible = (box.localToGlobal(Offset.zero) & box.size)
          .overlaps(screen.inflate(margin));
      if (visible != _nearScreen) setState(() => _nearScreen = visible);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }
  void _onPointerSignal(PointerSignalEvent event) {
    if (widget.layout.mode == 'grid' ||
        event is! PointerScrollEvent ||
        event.scrollDelta.dx != 0 ||
        event.scrollDelta.dy == 0 ||
        !widget.controller.hasClients) {
      return;
    }
    final position = widget.controller.position;
    if (!position.physics.shouldAcceptUserOffset(position)) return;
    final delta = event.scrollDelta.dy;
    final target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    // Leave the wheel to the outer page at either end of a tape.
    if (target == position.pixels) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      if (mounted && widget.controller.hasClients) {
        widget.controller.position.pointerScroll(delta);
      }
    });
  }

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
    _scheduleVisibility();
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
    _outer?.removeListener(_scheduleVisibility);
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final l = widget.layout;
      final vertical = l.mode == 'grid';
      // Reuse mounted card widgets while only scroll/selection/positions change.
      // A new layout or parent configuration rebuilds this bounded cache.
      var cards = <String, Widget>{};
      return AnimatedBuilder(
        animation: Listenable.merge([_motion, widget.controller, widget.selection]),
        builder: (context, _) {
          final selected = widget.selection?.value ?? widget.selected;
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
          final visible = <int>[
            for (var i = 0; i < widget.packages.length; i++)
              if (widget.materializeAll || widget.packages[i] == selected ||
                  widget.packages[i] == widget.requested ||
                  _nearScreen && viewport.overlaps(_position(widget.packages[i]) & size)) i,
          ];
          cards = {
            for (final i in visible)
              widget.packages[i]: cards[widget.packages[i]] ?? widget.itemBuilder(context, i),
          };
          return Listener(
            onPointerSignal: _onPointerSignal,
            child: SingleChildScrollView(
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
                    for (final i in visible)
                        PositionedDirectional(
                          key: ValueKey(('tile-position', widget.packages[i])),
                          start: _position(widget.packages[i]).dx,
                          top: _position(widget.packages[i]).dy,
                          width: size.width,
                          height: size.height,
                          child: cards[widget.packages[i]]!,
                        ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
