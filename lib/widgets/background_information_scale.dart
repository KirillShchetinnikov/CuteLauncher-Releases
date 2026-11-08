import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../background_information_geometry.dart';

/// Reuses the fitted-box transform and reports size limits after real layout.
class BackgroundInformationScale extends SingleChildRenderObjectWidget {
  final double value;
  final BackgroundInformationGeometry geometry;
  final void Function(Object, BackgroundInformationMetrics?) onMetrics;
  const BackgroundInformationScale({
    super.key,
    required this.value,
    required this.geometry,
    required this.onMetrics,
    required super.child,
  });
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _BackgroundInformationScale(value, geometry, onMetrics);
  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) {
    final box = renderObject as _BackgroundInformationScale;
    if (box.onMetrics != onMetrics) {
      box.onMetrics = onMetrics;
      box._last = null;
      box.markNeedsLayout();
    }
    if (box.value != value ||
        box.geometry.screen != geometry.screen ||
        box.geometry.verticalOffset != geometry.verticalOffset) {
      box.value = value;
      box.geometry = geometry;
      box.markNeedsLayout();
    }
  }
}

class _BackgroundInformationScale extends RenderFittedBox {
  double value;
  BackgroundInformationGeometry geometry;
  void Function(Object, BackgroundInformationMetrics?) onMetrics;
  BackgroundInformationMetrics? _pending, _last;
  bool _scheduled = false;
  _BackgroundInformationScale(this.value, this.geometry, this.onMetrics)
    : super(fit: BoxFit.contain, alignment: Alignment.topCenter);
  double _maximumScale(Size natural, BoxConstraints bounds) => natural.isEmpty
      ? 0
      : math.max(
          0,
          math.min(
            BackgroundInformationGeometry.maximumStoredSize /
                BackgroundInformationGeometry.referenceSize,
            math.min(
              bounds.maxWidth / natural.width,
              bounds.maxHeight / natural.height,
            ),
          ),
        );
  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final natural = child?.getDryLayout(const BoxConstraints()) ?? Size.zero;
    final scale = math.min(
      value / BackgroundInformationGeometry.referenceSize,
      _maximumScale(natural, constraints),
    );
    return constraints.constrain(natural * scale);
  }

  @override
  void performLayout() {
    super.performLayout(); // Also clears the cached paint transform.
    final natural = child?.size ?? Size.zero;
    final maximum = _maximumScale(natural, constraints);
    final scale = math.min(
      value / BackgroundInformationGeometry.referenceSize,
      maximum,
    );
    size = constraints.constrain(natural * scale);
    _pending = (
      screen: geometry.screen,
      natural: natural,
      requestedSize: value,
      effectiveSize: scale * BackgroundInformationGeometry.referenceSize,
      maximumSize:
          (maximum * BackgroundInformationGeometry.referenceSize + .000001)
              .floor(),
      maximumVerticalOffset: geometry.maximumOffsetForHeight(size.height),
      verticalOffset: geometry.verticalOffset,
    );
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!attached || _pending == _last) return;
      _last = _pending;
      onMetrics(this, _pending);
    });
  }

  @override
  void detach() {
    final report = onMetrics;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!attached) report(this, null);
    });
    super.detach();
  }
}
