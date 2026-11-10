import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'settings_scroll_behavior.dart';

import 'settings_menu_layout.dart';
import 'settings_help.dart';
import 'information_preview.dart';

import 'package:flutter/services.dart';

/// Shared header and scroll indicator. The page owns its content and scrolling.
/// The inherited controller survives rebuilds and is disposed with the route.
class SettingsPageLayout extends StatefulWidget {
  final Widget title;
  final Widget child;
  final Widget? header;
  final Widget? subtitle;
  final Widget? footer;
  final EdgeInsetsGeometry? footerPadding;
  final bool showDivider;
  final bool showObscuredInformationPreview;

  const SettingsPageLayout({
    super.key,
    required this.title,
    required this.child,
    this.header,
    this.subtitle,
    this.footer,
    this.footerPadding,
    this.showDivider = true,
    this.showObscuredInformationPreview = true,
  });

  @override
  State<SettingsPageLayout> createState() => _SettingsPageLayoutState();
}

class _SettingsPageLayoutState extends State<SettingsPageLayout> {
  late final _controller = ScrollController(
    onAttach: (_) => _updateScrollbar(),
    onDetach: (_) => _updateScrollbar(),
  );
  bool _scrollbarUpdatePending = false, _hasScrollPosition = false;
  final _viewportKey = GlobalKey();
  final _pageFocus = FocusScopeNode(skipTraversal: true);
  final _traversal = _SettingsTraversalPolicy();
  bool _entryFocused = false;
  FocusNode? _lastFocus;
  double? _focusContentY;

  void _updateScrollbar() {
    if (_scrollbarUpdatePending) return;
    _scrollbarUpdatePending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollbarUpdatePending = false;
      if (!mounted) return;
      final attached = _controller.positions.length == 1;
      if (_hasScrollPosition != attached) {
        setState(() => _hasScrollPosition = attached);
      }
    });
  }

  KeyEventResult _scrollText(FocusNode page, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final down = event.logicalKey == LogicalKeyboardKey.arrowDown;
    if (!down && event.logicalKey != LogicalKeyboardKey.arrowUp) {
      return KeyEventResult.ignored;
    }
    if (!_controller.hasClients || _controller.positions.length != 1) {
      return KeyEventResult.ignored;
    }
    final current = FocusManager.instance.primaryFocus;
    final box = _viewportKey.currentContext?.findRenderObject();
    if (current == null || box is! RenderBox || !box.hasSize) {
      return KeyEventResult.ignored;
    }
    final viewport = box.localToGlobal(Offset.zero) & box.size;
    final position = _controller.position;
    if (current.rect.center.dy.isFinite) {
      _lastFocus = current;
      _focusContentY = current.rect.center.dy + position.pixels;
    }
    final focusY = current == _lastFocus && _focusContentY != null
        ? _focusContentY! - position.pixels
        : viewport.center.dy;
    // Let normal traversal reach visible controls. Across a text-only gap,
    // move the viewport first so long explanations can be read in steps.
    final candidates = page.traversalDescendants.toList()
      ..sort((a, b) => down
          ? a.rect.center.dy.compareTo(b.rect.center.dy)
          : b.rect.center.dy.compareTo(a.rect.center.dy));
    for (final candidate in candidates) {
      if (candidate == current) continue;
      final rect = candidate.rect;
      if (!rect.center.dy.isFinite) continue;
      final ahead = down
          ? rect.center.dy > focusY + 1
          : rect.center.dy < focusY - 1;
      if (ahead && rect.overlaps(viewport)) {
        if (!current.rect.center.dy.isFinite ||
            !current.rect.overlaps(viewport)) {
          candidate.requestFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      }
    }
    final target = (position.pixels + (down ? 1 : -1) * viewport.height * 0.35)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    // At either edge let traversal leave the scrolling body for the fixed
    // header/footer. Consuming the key here traps remote focus in the list.
    if (target == position.pixels) return KeyEventResult.ignored;
    _controller.jumpTo(target);
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _pageFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mirrored = SettingsMenuLayout.isOnRight(context);
    final contentPadding = mirrored
        ? const EdgeInsets.only(right: 14)
        : const EdgeInsets.only(left: 14);
    if (!_entryFocused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            _entryFocused ||
            ModalRoute.of(context)?.isCurrent == false) {
          return;
        }
        if (_pageFocus.traversalDescendants.isEmpty) return;
        var first = WidgetOrderTraversalPolicy().findFirstFocus(
          _pageFocus,
          ignoreCurrentFocus: true,
        );
        // Lazy slivers can register a footer before the earlier list/grid items.
        // Entry follows visual reading order, not focus-node attachment order.
        final controls = _pageFocus.traversalDescendants
            .where(
              (node) =>
                  node.context?.findAncestorWidgetOfExactType<SettingsHelp>() ==
                      null &&
                  node.rect.isFinite &&
                  !node.rect.isEmpty,
            )
            .toList();
        if (controls.isNotEmpty) {
          first = ReadingOrderTraversalPolicy()
              .sortDescendants(controls, _pageFocus)
              .first;
        }
        if (first == null) return;
        _entryFocused = true;
        first.requestFocus();
      });
    }
    final page = FocusScope(
      node: _pageFocus,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: DefaultTextStyle.merge(
              style: Theme.of(context).textTheme.titleLarge,
              child: widget.title,
            ),
          ),
          if (widget.subtitle != null) widget.subtitle!,
          if (widget.showDivider) const Divider(),
          if (widget.header != null || widget.showObscuredInformationPreview &&
              SettingsMenuLayout.maybeOf(context)?.informationObscured == true)
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: widget.header ?? const InformationPreview(background: true),
            ),
          Expanded(
            child: PrimaryScrollController(
              controller: _controller,
              automaticallyInheritForPlatforms: TargetPlatform.values.toSet(),
              child: Focus(
                skipTraversal: true,
                onKeyEvent: _scrollText,
                child: SettingsScrollbar(
                  controller: _controller,
                  hasScrollPosition: _hasScrollPosition,
                  // No extra focus stops or pointer actions for the TV remote.
                  scrollbarOrientation: mirrored
                      ? ScrollbarOrientation.right
                      : ScrollbarOrientation.left,
                  thickness: 4,
                  child: Padding(
                    key: _viewportKey,
                    // Keep the indicator and its gap outside every page's content.
                    padding: contentPadding,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
          if (widget.footer != null)
            Padding(
              padding: widget.footerPadding ?? contentPadding,
              child: widget.footer!,
            ),
        ],
      ),
    );
    return FocusTraversalGroup(policy: _traversal, child: page);
  }
}

class _SettingsTraversalPolicy extends ReadingOrderTraversalPolicy {
  final _layouts = Expando<Map<FocusNode, Rect>>();

  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    final scope = currentNode.nearestScope!;
    final layout = {
      for (final node in scope.traversalDescendants) node: _contentRect(node),
    };
    // Flutter can reuse the previous focus path when reversing direction.
    // Keep it only while the available controls still occupy the same places.
    if (!mapEquals(_layouts[scope], layout)) invalidateScopeData(scope);
    _layouts[scope] = layout;
    return super.inDirection(currentNode, direction);
  }

  Rect _contentRect(FocusNode node) {
    final rect = node.rect;
    final context = node.context;
    final scrollable = context == null ? null : Scrollable.maybeOf(context);
    if (scrollable == null) return rect;
    // Scrolling moves the viewport over the same rows without reordering them.
    final pixels = scrollable.position.pixels;
    final offset = switch (scrollable.axisDirection) {
      AxisDirection.down => Offset(0, pixels),
      AxisDirection.up => Offset(0, -pixels),
      AxisDirection.right => Offset(pixels, 0),
      AxisDirection.left => Offset(-pixels, 0),
    };
    return rect.shift(offset);
  }
}
