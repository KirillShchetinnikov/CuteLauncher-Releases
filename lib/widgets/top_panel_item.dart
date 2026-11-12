import 'package:flutter/foundation.dart';

import '../key_sounds.dart';

import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/appearance_service.dart';
import '../tile_appearance.dart';
import '../theme/launcher_style.dart';
import '../theme/interface_style.dart';

TileAppearance topPanelAppearance(BuildContext context) =>
    PanelAppearanceScope.maybeOf(context) ??
    context.watch<AppearanceService?>()?.appearance ??
    const TileAppearance();

const topPanelItemPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 4);

double topPanelItemHeight(double textSize, double borderWidth) =>
    textSize * 1.5 + topPanelItemPadding.vertical + borderWidth * 2;

BoxDecoration topPanelItemDecoration(
  BuildContext context, {
  required Color background,
  required Color? foreground,
  required double radius,
  bool highlighted = false,
}) {
  final skin = InterfaceSkin.of(context);
  final borderWidth = LauncherStyle.of(context).topButtonFocusWidth;
  final outline = Theme.of(context).colorScheme.primary;
  return skin.standard
      ? BoxDecoration(
          color: highlighted
              ? Color.alphaBlend(outline.withValues(alpha: .18), background)
              : background,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: highlighted ? outline : Colors.transparent,
            width: borderWidth,
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
        )
      : skin.surface(
          background,
          foreground ?? Colors.white,
          focused: highlighted,
          accent: outline,
          cornerRadius: radius,
          borderWidth: borderWidth,
        );
}

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
  bool _pressed = false;
  Timer? _pressTimer;

  void _activate() {
    if (widget.onPressed == null) return;
    _pressTimer?.cancel();
    setState(() => _pressed = true);
    _pressTimer = Timer(LauncherStyle.of(context).pressDuration, () {
      if (mounted) setState(() => _pressed = false);
    });
    playKeySound(context);
    widget.onPressed!();
  }

  @override
  void dispose() {
    _pressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appearance = widget.appearance ?? topPanelAppearance(context);
    final style = LauncherStyle.of(context);
    final highlighted = _focused || _hovered;
    final textStyle =
        widget.textStyle ??
        appearance.panelTextStyleFor(Localizations.localeOf(context));
    final base = widget.backgroundColor ?? appearance.panelItemBackground;
    final colors = Theme.of(context).colorScheme;
    final background = Color.alphaBlend(
      (_pressed ? colors.onSurface : colors.primary).withValues(
        alpha: _pressed
            ? style.rowPressedTint
            : widget.selected
            ? style.rowSelectedTint
            : 0,
      ),
      base,
    );
    final radius = widget.borderRadius ?? style.topButtonRadius;
    final foreground = textStyle.color;
    final height = topPanelItemHeight(
      MediaQuery.textScalerOf(context).scale(textStyle.fontSize ?? 18),
      style.topButtonFocusWidth,
    );
    final glyphs = widget.textStyle == null
        ? widget.child
        : FittedBox(fit: BoxFit.scaleDown, child: widget.child);
    final content = AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : style.pressDuration,
      height: widget.textStyle == null
          ? height
          : math.min(kToolbarHeight - 4, height),
      padding: topPanelItemPadding,
      decoration: topPanelItemDecoration(
        context,
        background: background,
        foreground: foreground,
        radius: radius,
        highlighted: highlighted,
      ),
      child: DefaultTextStyle(
        style: textStyle,
        child: IconTheme(
          data: IconThemeData(color: foreground, size: textStyle.fontSize),
          child: Center(widthFactor: 1, child: glyphs),
        ),
      ),
    );
    if (widget.onPressed == null) return content;
    return Semantics(
      button: true,
      selected: widget.selected ? true : null,
      focusable: true,
      focused: _focused,
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => _activate(),
          ),
          ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
            onInvoke: (_) => _activate(),
          ),
        },
        child: Focus(
          includeSemantics: false,
          focusNode: widget.focusNode,
          onFocusChange: (value) => setState(() => _focused = value),
          child: InkWell(
            enableFeedback: false,
            onTap: _activate,
            onHighlightChanged: (value) => setState(() => _pressed = value),
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
      ),
    );
  }
}
