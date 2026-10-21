import 'package:flutter/material.dart';
import 'settings_menu_layout.dart';
import 'settings_help.dart';
import 'package:flutter/services.dart';

/// Shared header and scroll indicator. The page owns its content and scrolling.
/// The inherited controller survives rebuilds and is disposed with the route.
class SettingsPageLayout extends StatefulWidget {
  final Widget title;
  final Widget child;
  final Widget? header;
  final Widget? subtitle;
  final Widget? footer;
  final EdgeInsetsGeometry footerPadding;
  final bool showDivider;

  const SettingsPageLayout({
    super.key,
    required this.title,
    required this.child,
    this.header,
    this.subtitle,
    this.footer,
    this.footerPadding = const EdgeInsets.only(left: 14),
    this.showDivider = true,
  });

  @override
  State<SettingsPageLayout> createState() => _SettingsPageLayoutState();
}

class _SettingsPageLayoutState extends State<SettingsPageLayout> {
  final _controller = ScrollController();
  final _viewportKey = GlobalKey();
  final _pageFocus = FocusScopeNode(skipTraversal: true);
  bool _entryFocused = false;
  FocusNode? _lastFocus;
  double? _focusContentY;

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
    for (final candidate in page.traversalDescendants) {
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
    if (target == position.pixels) return KeyEventResult.handled;
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
    final contentPadding = mirrored ? const EdgeInsets.only(right: 14) : const EdgeInsets.only(left: 14);
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
        // Help stays reachable with D-pad, but entry targets an actual setting.
        for (final node in _pageFocus.traversalDescendants) {
          if (node.context?.findAncestorWidgetOfExactType<SettingsHelp>() == null) {
            first = node;
            break;
          }
        }
        if (first == null) return;
        _entryFocused = true;
        first.requestFocus();
      });
    }
    return FocusScope(
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
          if (widget.header != null)
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: widget.header!,
            ),
          Expanded(
            child: PrimaryScrollController(
              controller: _controller,
              automaticallyInheritForPlatforms: TargetPlatform.values.toSet(),
              child: Focus(
                skipTraversal: true,
                onKeyEvent: _scrollText,
                child: Scrollbar(
                  // No extra focus stops or pointer actions for the TV remote.
                  interactive: false,
                  scrollbarOrientation: mirrored ? ScrollbarOrientation.right : ScrollbarOrientation.left,
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
              padding: widget.footerPadding,
              child: widget.footer!,
            ),
        ],
      ),
    );
  }
}
