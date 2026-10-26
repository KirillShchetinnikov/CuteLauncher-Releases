import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Physical screen corners; independent of text direction.
enum NoticeCorner {
  bottomRight,
  bottomLeft,
  topRight,
  topLeft;

  bool get left => this == bottomLeft || this == topLeft;
  bool get top => this == topLeft || this == topRight;
  NoticeCorner get oppositeSide => switch (this) {
    bottomRight => bottomLeft,
    bottomLeft => bottomRight,
    topRight => topLeft,
    topLeft => topRight,
  };
  Alignment get alignment => Alignment(left ? -1 : 1, top ? -1 : 1);
  static NoticeCorner parse(Object? value) => values.firstWhere(
    (corner) => corner.name == value,
    orElse: () => bottomRight,
  );
}

/// Tracks actual visible panels, including Offstage menus retained by routes.
/// Observes rendered frames without requesting continuous frames while idle.
class NoticePanels extends ChangeNotifier {
  static final instance = NoticePanels();
  final _panels = <Object, BuildContext>{};
  List<bool> _sides = const [];
  bool _scheduled = false;

  void register(Object owner, BuildContext context) {
    _panels[owner] = context;
    _observeFrame();
  }

  void unregister(Object owner) {
    _panels.remove(owner);
    _observeFrame();
  }

  /// The panel belonging to the route opening a nested dialog.
  Rect? boundsForRoute(BuildContext source) {
    if (_panels.isEmpty) return null;
    final route = ModalRoute.of(source);
    for (final context in _panels.values.toList().reversed) {
      if (!context.mounted || ModalRoute.of(context) != route) continue;
      final render = context.findRenderObject();
      if (render is! RenderBox || !render.attached || !render.hasSize) continue;
      RenderObject? ancestor = render;
      var visible = true;
      while (ancestor != null) {
        if (ancestor is RenderOffstage && ancestor.offstage) visible = false;
        ancestor = ancestor.parent;
      }
      if (visible) return render.localToGlobal(Offset.zero) & render.size;
    }
    return null;
  }

  NoticeCorner resolve(NoticeCorner preferred) {
    if (!_sides.contains(!preferred.left)) return preferred;
    // When both sides have panels, avoid the most recently opened visible one.
    if (_sides.contains(preferred.left) && _sides.last == preferred.left) {
      return preferred;
    }
    return preferred.oppositeSide;
  }

  void _observeFrame() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      final sides = <bool>[];
      for (final context in _panels.values) {
        if (!context.mounted) continue;
        final render = context.findRenderObject();
        if (render is! RenderBox || !render.attached || !render.hasSize) {
          continue;
        }
        var visible = true;
        RenderObject? ancestor = render;
        while (ancestor != null) {
          if (ancestor is RenderOffstage && ancestor.offstage) {
            visible = false;
            break;
          }
          ancestor = ancestor.parent;
        }
        if (!visible) continue;
        final size = MediaQuery.sizeOf(context);
        sides.add(
          render.localToGlobal(render.size.center(Offset.zero)).dx >
              size.width / 2,
        );
      }
      if (!_equal(sides, _sides)) {
        _sides = sides;
        notifyListeners();
        WidgetsBinding.instance.ensureVisualUpdate();
      }
      if (_panels.isNotEmpty) _observeFrame();
    });
  }

  static bool _equal(List<bool> a, List<bool> b) =>
      a.length == b.length &&
      Iterable<int>.generate(a.length).every((i) => a[i] == b[i]);
}

class NoticePanelRegion extends StatefulWidget {
  final Widget child;
  const NoticePanelRegion({super.key, required this.child});
  @override
  State<NoticePanelRegion> createState() => _NoticePanelRegionState();
}

class _NoticePanelRegionState extends State<NoticePanelRegion> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    NoticePanels.instance.register(this, context);
  }

  @override
  void dispose() {
    NoticePanels.instance.unregister(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
