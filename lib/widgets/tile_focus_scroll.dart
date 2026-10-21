import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Align vertically; horizontally move only enough to reveal the whole tile.
Future<void> revealFocusedTile(
  BuildContext context, {
  double alignment = 0.5,
  bool keepTop = false,
  bool horizontalStart = false,
}) async {
  final target = context.findRenderObject();
  if (target == null || !target.attached) return;
  final animations = <Future<void>>[];
  var ancestor = context;
  ScrollableState? scrollable;
  while ((scrollable = Scrollable.maybeOf(ancestor)) != null) {
    final state = scrollable!;
    final position = state.position;
    final viewport = RenderAbstractViewport.of(target);
    final horizontal =
        axisDirectionToAxis(position.axisDirection) == Axis.horizontal;
    double offset;
    if (horizontal) {
      final leading = viewport.getOffsetToReveal(target, 0).offset;
      final trailing = viewport.getOffsetToReveal(target, 1).offset;
      offset = horizontalStart
          ? 0
          : trailing > leading
          ? leading
          : position.pixels.clamp(trailing, leading);
    } else {
      // Use the viewport belonging to this ancestor, including nested grids.
      RenderObject? render = target;
      RenderAbstractViewport? outer;
      while (render != null) {
        if (render is RenderAbstractViewport) outer = render;
        if (render == state.context.findRenderObject()) break;
        render = render.parent;
      }
      offset = keepTop
          ? 0
          : (outer ?? viewport).getOffsetToReveal(target, alignment).offset;
    }
    offset = offset.clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((offset - position.pixels).abs() > 0.5) {
      animations.add(
        position.animateTo(
          offset,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
        ),
      );
    }
    ancestor = state.context;
  }
  await Future.wait(animations);
}
