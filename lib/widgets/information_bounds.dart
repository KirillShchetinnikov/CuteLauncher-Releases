import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Reports the rendered, scaled bounds after layout, never during build.
class InformationBounds extends SingleChildRenderObjectWidget {
  final ValueChanged<Rect?> onBounds;
  const InformationBounds({
    super.key,
    required this.onBounds,
    required super.child,
  });
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _InformationBounds(onBounds);
  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderProxyBox renderObject,
  ) {
    (renderObject as _InformationBounds).onBounds = onBounds;
  }
}

class _InformationBounds extends RenderProxyBox {
  ValueChanged<Rect?> onBounds;
  Rect? _last;
  bool _scheduled = false;
  _InformationBounds(this.onBounds);
  @override
  void performLayout() {
    super.performLayout();
    _reportAfterFrame();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    // Alignment may move us without laying out this child again.
    _reportAfterFrame();
  }

  void _reportAfterFrame() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!attached || !hasSize) return;
      final bounds = MatrixUtils.transformRect(
        getTransformTo(null),
        Offset.zero & size,
      );
      if (_last == bounds) return;
      _last = bounds;
      onBounds(bounds);
    });
  }

  @override
  void detach() {
    final callback = onBounds;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!attached) callback(null);
    });
    super.detach();
  }
}
