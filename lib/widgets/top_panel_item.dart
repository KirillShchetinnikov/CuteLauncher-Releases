import 'package:flutter/foundation.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/appearance_service.dart';
import '../tile_appearance.dart';
import '../theme/launcher_style.dart';

TileAppearance topPanelAppearance(BuildContext context) =>
    PanelAppearanceScope.maybeOf(context) ??
    context.watch<AppearanceService?>()?.appearance ??
    const TileAppearance();

/// Limits a panel's own style to its objects, without changing settings or clocks.
class PanelAppearanceScope extends InheritedWidget {
  final TileAppearance appearance;
  const PanelAppearanceScope({
    super.key,
    required this.appearance,
    required super.child,
  });
  static TileAppearance? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<PanelAppearanceScope>()
      ?.appearance;
  @override
  bool updateShouldNotify(PanelAppearanceScope oldWidget) =>
      !mapEquals(appearance.values, oldWidget.appearance.values);
}

/// A single surface, focus/hover treatment and typography for all panel objects.
class TopPanelItem extends StatefulWidget {
  final Widget child;
  final TileAppearance? appearance;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final double? borderRadius;
  final bool selected;
  const TopPanelItem({
    super.key,
    required this.child,
    this.appearance,
    this.onPressed,
    this.focusNode,
    this.textStyle,
    this.backgroundColor,
    this.borderRadius,
    this.selected = false,
  });

  @override
  State<TopPanelItem> createState() => _TopPanelItemState();
}

class _TopPanelItemState extends State<TopPanelItem> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final appearance = widget.appearance ?? topPanelAppearance(context);
    final style = LauncherStyle.of(context);
    final highlighted = widget.selected || _focused || _hovered;
    final textStyle = widget.textStyle ?? appearance.panelTextStyle;
    final background = widget.backgroundColor ?? appearance.panelItemBackground;
    final radius = widget.borderRadius ?? style.topButtonRadius;
    final foreground = textStyle.color;
    final height =
        MediaQuery.textScalerOf(context).scale(textStyle.fontSize ?? 18) * 1.5 +
        8 +
        style.topButtonFocusWidth * 2;
    final outline = Theme.of(context).colorScheme.primary;
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: widget.textStyle == null
          ? height
          : math.min(kToolbarHeight - 4, height),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted
            ? Color.alphaBlend(outline.withValues(alpha: .18), background)
            : background,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: highlighted ? outline : Colors.transparent,
          width: style.topButtonFocusWidth,
        ),
        boxShadow: highlighted
            ? const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: DefaultTextStyle(
        style: textStyle,
        child: IconTheme(
          data: IconThemeData(color: foreground, size: textStyle.fontSize),
          child: Center(
            widthFactor: 1,
            child: widget.textStyle == null
                ? widget.child
                : FittedBox(fit: BoxFit.scaleDown, child: widget.child),
          ),
        ),
      ),
    );
    if (widget.onPressed == null) return content;
    return Actions(
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => widget.onPressed!(),
        ),
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
          onInvoke: (_) => widget.onPressed!(),
        ),
      },
      child: Focus(
        focusNode: widget.focusNode,
        onFocusChange: (value) => setState(() => _focused = value),
        child: InkWell(
          onTap: widget.onPressed,
          canRequestFocus: false,
          onHover: (value) => setState(() => _hovered = value),
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
          child: content,
        ),
      ),
    );
  }
}
