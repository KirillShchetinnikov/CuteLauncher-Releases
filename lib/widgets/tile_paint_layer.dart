import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Paints highlighted tiles after all sections without moving their layout,
/// focus nodes, or state into an overlay.
class TilePaintLayer extends SingleChildRenderObjectWidget {
  const TilePaintLayer({super.key, required super.child});
  @override
  RenderObject createRenderObject(BuildContext context) => _TilePaintLayer();
}

class RaisedTile extends SingleChildRenderObjectWidget {
  final bool raised;
  const RaisedTile({super.key, required this.raised, required super.child});
  @override
  RenderObject createRenderObject(BuildContext context) => _RaisedTile(raised);
  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) {
    (renderObject as _RaisedTile).raised = raised;
  }
}

class _TilePaintLayer extends RenderProxyBox {
  final Set<_RaisedTile> tiles = {};
  @override
  bool get alwaysNeedsCompositing => true;
  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    for (final tile in tiles) {
      if (tile.raised && tile.canPaintRaised) {
        context.pushTransform(
          true,
          offset,
          tile.getTransformTo(this),
          tile.paintRaised,
        );
      }
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final tile in tiles.toList().reversed) {
      if (tile.raised &&
          tile.canPaintRaised &&
          result.addWithPaintTransform(
            transform: tile.getTransformTo(this),
            position: position,
            hitTest: (result, position) =>
                tile.hitTest(result, position: position),
          )) {
        return true;
      }
    }
    return super.hitTestChildren(result, position: position);
  }
}

class _RaisedTile extends RenderProxyBox {
  _RaisedTile(this._raised);
  _TilePaintLayer? paintLayer;
  bool _raised;
  bool get raised => _raised;
  bool get canPaintRaised {
    if (!attached || !hasSize) return false;
    RenderObject? ancestor = this;
    while (ancestor != null && ancestor != paintLayer) {
      if (ancestor is RenderOffstage && ancestor.offstage) return false;
      final data = ancestor.parentData;
      if (data is SliverMultiBoxAdaptorParentData && data.keptAlive) return false;
      ancestor = ancestor.parent;
    }
    return ancestor == paintLayer;
  }
  @override
  void markNeedsPaint() {
    super.markNeedsPaint();
    // Slivers cache each cell separately. Repaint the shared top layer too
    // when an animation above an inner repaint boundary changes the cell.
    paintLayer?.markNeedsPaint();
  }

  set raised(bool value) {
    if (_raised == value) return;
    _raised = value;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _connect();
  }

  @override
  void performLayout() {
    super.performLayout();
    _connect();
  }

  void _connect() {
    RenderObject? ancestor = parent;
    while (ancestor != null && ancestor is! _TilePaintLayer) {
      ancestor = ancestor.parent;
    }
    final next = ancestor as _TilePaintLayer?;
    if (next != paintLayer) {
      paintLayer?.tiles.remove(this);
      paintLayer = next;
      paintLayer?.tiles.add(this);
    }
  }

  @override
  void detach() {
    paintLayer?.tiles.remove(this);
    paintLayer?.markNeedsPaint();
    paintLayer = null;
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!raised || paintLayer == null) super.paint(context, offset);
  }

  void paintRaised(PaintingContext context, Offset offset) =>
      super.paint(context, offset);
}

/// Traversal uses the cell's layout bounds, independently of scale/lift.
class TileFocusNode extends FocusNode {
  final BuildContext Function() layoutContext;
  TileFocusNode(this.layoutContext);
  @override
  Rect get rect {
    final box = layoutContext().findRenderObject();
    if (box is RenderBox && box.attached && box.hasSize) {
      return box.localToGlobal(Offset.zero) & box.size;
    }
    return super.rect;
  }
}
