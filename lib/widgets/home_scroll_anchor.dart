import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

/// Corrects structural changes above the selected section during layout, before
/// painting. Unlike a post-frame jump this never presents the displaced frame.
class HomeScrollController extends ScrollController {
  RenderBox? _anchor;
  double? _contentTop;
  bool Function()? canPreserve;

  double? _top(ScrollPosition position) {
    final box = _anchor;
    if (box == null || !box.attached || !box.hasSize) return null;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return null;
    return box.localToGlobal(Offset.zero, ancestor: viewport).dy + position.pixels;
  }

  void anchorTo(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    _anchor = box is RenderBox ? box : null;
    _contentTop = hasClients ? _top(position) : null;
  }

  double correction(ScrollPosition position, double min, double max) {
    final top = _top(position);
    final previous = _contentTop;
    _contentTop = top;
    if (top == null || previous == null || canPreserve?.call() == false ||
        position.isScrollingNotifier.value) {
      return 0;
    }
    return (position.pixels + top - previous).clamp(min, max) - position.pixels;
  }

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics,
      ScrollContext context, ScrollPosition? oldPosition) => _HomeScrollPosition(
        owner: this, physics: physics, context: context, oldPosition: oldPosition);
}

class _HomeScrollPosition extends ScrollPositionWithSingleContext {
  _HomeScrollPosition({required this.owner, required super.physics,
    required super.context, super.oldPosition});
  final HomeScrollController owner;

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    final delta = owner.correction(this, minScrollExtent, maxScrollExtent);
    if (delta.abs() > .5) {
      correctPixels(pixels + delta);
      // The viewport lays out again with the corrected offset in the same frame.
      return false;
    }
    return super.applyContentDimensions(minScrollExtent, maxScrollExtent);
  }
}
