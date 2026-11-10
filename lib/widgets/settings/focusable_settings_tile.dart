import 'package:flauncher/theme/launcher_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'dart:async';
import 'dart:math' as math;

import '../../key_sounds.dart';

import 'settings_value_text.dart';
import 'settings_panel_style.dart';
import 'inherited_setting.dart';
import '../../theme/interface_style.dart';
import '../panel_tooltip.dart';
import '../app_card_keys.dart';

class FocusableSettingsTile extends StatefulWidget {
  final Widget title;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onPressed;
  final bool autofocus;
  final FocusNode? focusNode;
  final FocusOnKeyEventCallback? onKeyEvent;
  final ValueChanged<bool>? onFocusChange;
  final VoidCallback? onLongPress;
  final bool? selected;
  final bool? toggled;
  final bool? checked;
  final bool enabled;

  /// Blocks activation temporarily while preserving focus and traversal.
  final bool busy;
  final IconData valueIcon;
  final bool alignValueToEnd;
  final bool scrollOnFocus;
  final bool subtle;
  final bool showActionChevron;
  final bool dense;

  /// Give a long choice more room when the setting title is short.
  /// Both columns still wrap when text is enlarged.
  final bool wideValue;

  /// Sliders merge this row's focus into their adjustable semantics node.
  final bool semanticContainer;

  const FocusableSettingsTile({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.onPressed,
    this.autofocus = false,
    this.focusNode,
    this.onKeyEvent,
    this.onFocusChange,
    this.onLongPress,
    this.selected,
    this.toggled,
    this.checked,
    this.enabled = true,
    this.busy = false,
    this.valueIcon = Icons.chevron_right_rounded,
    this.alignValueToEnd = true,
    this.scrollOnFocus = true,
    this.subtle = false,
    this.showActionChevron = true,
    this.dense = false,
    this.wideValue = false,
    this.semanticContainer = true,
  });

  @override
  State<FocusableSettingsTile> createState() => _FocusableSettingsTileState();
}

class _FocusableSettingsTileState extends State<FocusableSettingsTile>
    with AutomaticKeepAliveClientMixin {
  bool _focused = false;
  bool _pressed = false;
  Timer? _pressTimer;
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _pressTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _activate() {
    if (!widget.enabled || widget.busy || widget.onPressed == null) return;
    // Pointer activation must remember the same opener as remote activation.
    (widget.focusNode ?? _focusNode).requestFocus();
    _pressTimer?.cancel();
    setState(() => _pressed = true);
    _pressTimer = Timer(LauncherStyle.of(context).pressDuration, () {
      if (mounted) setState(() => _pressed = false);
    });
    playKeySound(context);
    widget.onPressed!();
  }

  @override
  bool get wantKeepAlive => _focused;

  void _revealIfNeeded(Duration duration) {
    final scrollable = Scrollable.maybeOf(context);
    final target = context.findRenderObject();
    if (scrollable == null || target == null || !target.attached) return;
    final viewport = RenderAbstractViewport.maybeOf(target);
    if (viewport == null) return;
    final start = viewport.getOffsetToReveal(target, 0).offset;
    final end = viewport.getOffsetToReveal(target, 1).offset;
    final offset = scrollable.position.pixels;
    final vertical =
        axisDirectionToAxis(scrollable.axisDirection) == Axis.vertical;
    // Keep ordinary rows in a central band. Crossing it starts scrolling while
    // the next controls are still visible; reversing within it stays still.
    // Oversized rows and horizontal menus retain the visibility-only behavior.
    final band = vertical && start >= end;
    final lower = band ? start + (end - start) * 0.6 : end;
    final upper = band ? start + (end - start) * 0.4 : start;
    final position = scrollable.position;
    final destination = (offset < lower ? lower : upper).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((offset >= lower - 0.5 && offset <= upper + 0.5) ||
        (destination - offset).abs() <= 0.5) {
      return;
    }
    Scrollable.ensureVisible(
      context,
      alignment: band ? (offset < lower ? 0.6 : 0.4) : 0.5,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : duration,
    );
  }

  Widget _fullTextMetrics(Widget child) {
    if (DefaultTextStyle.of(context).style.fontFamily != 'Manrope') {
      return child;
    }
    // Titles need the same paragraph headroom as values, also after refocusing.
    return DefaultTextStyle.merge(
      style: SettingsPanelStyle.fullTextMetrics(
        DefaultTextStyle.of(context).style,
      ),
      textHeightBehavior: const TextHeightBehavior(),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final style = LauncherStyle.of(context);
    final skin = InterfaceSkin.of(context);
    final colors = Theme.of(context).colorScheme;
    final selected = widget.selected == true;
    final active = widget.enabled && !widget.busy && widget.onPressed != null;
    final borderWidth = skin.calm
        ? style.rowFocusWidth
        : style.rowAccentFocusWidth;
    // Materials can paint different outlines without moving text or scroll offsets.
    final borderPadding = EdgeInsets.all(
      math.max(style.rowFocusWidth, style.rowAccentFocusWidth) - borderWidth,
    );
    final fill = Color.alphaBlend(
      colors.primary.withValues(
        alpha: _pressed
            ? style.rowPressedTint
            : _focused
            ? style.rowFocusTint
            : selected
            ? style.rowSelectedTint
            : 0,
      ),
      _focused || selected || _pressed
          ? colors.surface
          : colors.onSurface.withValues(
              alpha: widget.subtle ? 0 : style.rowIdleOpacity,
            ),
    );
    final calmDecoration = skin
        .surface(
          fill,
          colors.onSurface,
          quiet: true,
          cornerRadius: style.rowRadius,
          borderWidth: style.rowFocusWidth,
        )
        .copyWith(
          border: Border.all(
            color: _focused ? colors.primary : Colors.transparent,
            width: style.rowFocusWidth,
          ),
        );
    final accentBase = Color.alphaBlend(
      (_pressed ? colors.onSurface : colors.primary).withValues(
        alpha: _pressed
            ? style.rowPressedTint
            : selected
            ? style.rowSelectedTint
            : 0,
      ),
      colors.surface,
    );
    final accentDecoration = skin.standard
        ? BoxDecoration(
            color: _focused
                ? Color.alphaBlend(
                    colors.primary.withValues(alpha: style.rowFocusTint),
                    accentBase,
                  )
                : selected || _pressed
                ? accentBase
                : colors.onSurface.withValues(alpha: .025),
            borderRadius: BorderRadius.circular(style.rowRadius),
            border: Border.all(
              color: _focused ? colors.primary : Colors.transparent,
              width: style.rowAccentFocusWidth,
            ),
          )
        : skin.surface(
            accentBase,
            colors.onSurface,
            focused: _focused,
            accent: colors.primary,
            cornerRadius: style.rowRadius,
            borderWidth: style.rowAccentFocusWidth,
          );
    final decoration = widget.subtle && !_focused && !selected && !_pressed
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(style.rowRadius),
            border: Border.all(
              color: Colors.transparent,
              width: skin.calm
                  ? style.rowFocusWidth
                  : style.rowAccentFocusWidth,
            ),
          )
        : skin.calm
        ? calmDecoration
        : accentDecoration;
    final inheritedLabel = InheritedSettingSource.labelOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
      child: Semantics(
        container: widget.semanticContainer,
        button:
            widget.toggled == null &&
            widget.checked == null &&
            widget.onPressed != null,
        selected: widget.selected,
        toggled: widget.toggled,
        checked: widget.checked,
        enabled: widget.enabled && !widget.busy,
        focusable: widget.enabled,
        focused: _focused,
        onTap: active ? _activate : null,
        onLongPress: widget.enabled && !widget.busy ? widget.onLongPress : null,
        child: Actions(
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) => _activate(),
            ),
            ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
              onInvoke: (_) => _activate(),
            ),
          },
          child: Focus(
            includeSemantics: false,
            canRequestFocus: widget.enabled,
            descendantsAreFocusable: widget.enabled,
            onKeyEvent: widget.enabled && !widget.busy
                ? (node, event) {
                    if (active &&
                        AppCardKeys.validationKeys.contains(event.logicalKey)) {
                      setState(() => _pressed = event is! KeyUpEvent);
                    }
                    return widget.onKeyEvent?.call(node, event) ??
                        KeyEventResult.ignored;
                  }
                : null,
            autofocus: widget.autofocus,
            focusNode: widget.focusNode ?? _focusNode,
            onFocusChange: (hasFocus) {
              setState(() {
                _focused = hasFocus;
                if (!hasFocus) _pressed = false;
              });
              widget.onFocusChange?.call(hasFocus);
              updateKeepAlive();
              if (hasFocus && widget.scrollOnFocus) {
                _revealIfNeeded(style.scrollDuration);
              }
            },
            child: GestureDetector(
              excludeFromSemantics: true,
              onTapDown: active ? (_) => setState(() => _pressed = true) : null,
              onTapUp: active ? (_) => setState(() => _pressed = false) : null,
              onTapCancel: active
                  ? () => setState(() => _pressed = false)
                  : null,
              onTap: !widget.enabled || widget.busy || widget.onPressed == null
                  ? null
                  : _activate,
              onLongPress: widget.enabled && !widget.busy
                  ? widget.onLongPress
                  : null,
              behavior: HitTestBehavior.opaque,
              child: Container(
                constraints: BoxConstraints(
                  minHeight: widget.dense ? 36 : style.rowMinHeight,
                ),
                padding:
                    (widget.dense
                        ? const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          )
                        : style.rowPadding) +
                    borderPadding,
                decoration: decoration,
                child: _fullTextMetrics(
                  LayoutBuilder(
                    builder: (context, constraints) => Row(
                      children: [
                        if (widget.leading != null) ...[
                          Container(
                            width: style.iconExtent,
                            height: style.iconExtent,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary
                                  .withValues(alpha: _focused ? 0.22 : 0.12),
                              borderRadius: BorderRadius.circular(
                                style.iconRadius,
                              ),
                            ),
                            child: IconTheme(
                              data: IconThemeData(
                                size: 22,
                                color: (_focused || selected)
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                              ),
                              child: Center(child: widget.leading!),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          flex: widget.wideValue ? 2 : 1,
                          child: Opacity(
                            opacity: widget.enabled ? 1 : 0.45,
                            child: inheritedLabel == null
                                ? widget.title
                                : Row(
                                    children: [
                                      Expanded(child: widget.title),
                                      const SizedBox(width: 6),
                                      PanelTooltip(
                                        message: inheritedLabel,
                                        excludeFromSemantics: true,
                                        child: Icon(
                                          Icons.link,
                                          size: 16,
                                          semanticLabel: inheritedLabel,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        if (widget.trailing != null ||
                            widget.onPressed != null &&
                                widget.showActionChevron) ...[
                          const SizedBox(width: 8),
                          if (widget.trailing is Text)
                            Flexible(
                              flex: widget.wideValue ? 3 : 1,
                              fit: widget.alignValueToEnd
                                  ? FlexFit.tight
                                  : FlexFit.loose,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: widget.alignValueToEnd
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  Flexible(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            constraints.maxWidth *
                                            (widget.wideValue ? 0.6 : 0.4),
                                      ),
                                      child: SettingsValueText(
                                        alignment: widget.alignValueToEnd
                                            ? TextAlign.end
                                            : TextAlign.start,
                                        text: widget.trailing! as Text,
                                      ),
                                    ),
                                  ),
                                  if (widget.onPressed != null &&
                                      widget.showActionChevron) ...[
                                    const SizedBox(width: 4),
                                    Icon(widget.valueIcon, size: 20),
                                  ],
                                ],
                              ),
                            )
                          else if (widget.trailing != null)
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: constraints.maxWidth * 0.5,
                              ),
                              child: widget.trailing!,
                            )
                          else
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
