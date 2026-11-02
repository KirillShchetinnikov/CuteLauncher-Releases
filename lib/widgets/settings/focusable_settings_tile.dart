import 'package:flauncher/theme/launcher_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../key_sounds.dart';

import 'settings_value_text.dart';
import 'settings_panel_style.dart';
import 'inherited_setting.dart';
import '../../theme/interface_style.dart';

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
  final bool selected;
  final bool enabled;
  final IconData valueIcon;
  final bool alignValueToEnd;
  final bool scrollOnFocus;
  final bool subtle;
  final bool showActionChevron;
  final bool dense;

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
    this.selected = false,
    this.enabled = true,
    this.valueIcon = Icons.chevron_right_rounded,
    this.alignValueToEnd = true,
    this.scrollOnFocus = true,
    this.subtle = false,
    this.showActionChevron = true,
    this.dense = false,
  });

  @override
  State<FocusableSettingsTile> createState() => _FocusableSettingsTileState();
}

class _FocusableSettingsTileState extends State<FocusableSettingsTile>
    with AutomaticKeepAliveClientMixin {
  bool _focused = false;
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _activate() {
    if (!widget.enabled || widget.onPressed == null) return;
    // Pointer activation must remember the same opener as remote activation.
    (widget.focusNode ?? _focusNode).requestFocus();
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
    // A visible row needs only its focus highlight. Recentring it on every
    // D-pad step starts needless animations and interrupts an ongoing scroll.
    if (offset >= end - 0.5 && offset <= start + 0.5) return;
    Scrollable.ensureVisible(context, alignment: 0.5, duration: duration);
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
    final inheritedLabel = InheritedSettingSource.labelOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
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
          canRequestFocus: widget.enabled,
          descendantsAreFocusable: widget.enabled,
          onKeyEvent: widget.enabled ? widget.onKeyEvent : null,
          autofocus: widget.autofocus,
          focusNode: widget.focusNode ?? _focusNode,
          onFocusChange: (hasFocus) {
            setState(() => _focused = hasFocus);
            widget.onFocusChange?.call(hasFocus);
            updateKeepAlive();
            if (hasFocus && widget.scrollOnFocus) {
              _revealIfNeeded(style.scrollDuration);
            }
          },
          child: GestureDetector(
            onTap: !widget.enabled || widget.onPressed == null
                ? null
                : _activate,
            onLongPress: widget.enabled ? widget.onLongPress : null,
            behavior: HitTestBehavior.opaque,
            child: Container(
              constraints: BoxConstraints(
                minHeight: widget.dense ? 36 : style.rowMinHeight,
              ),
              padding: widget.dense
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 4)
                  : style.rowPadding,
              decoration: widget.subtle && !_focused && !widget.selected
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(style.rowRadius),
                      border: Border.all(
                        color: Colors.transparent,
                        width: style.rowFocusWidth,
                      ),
                    )
                  : skin.standard
                  ? BoxDecoration(
                      color: (_focused || widget.selected)
                          ? Color.alphaBlend(
                              Theme.of(context).colorScheme.primary
                                  .withValues(alpha: style.rowFocusTint),
                              Theme.of(context).colorScheme.surface,
                            )
                          : Theme.of(context).colorScheme.onSurface
                                .withValues(alpha: style.rowIdleOpacity),
                      borderRadius: BorderRadius.circular(style.rowRadius),
                      border: (_focused || widget.selected)
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: style.rowFocusWidth,
                            )
                          : Border.all(
                              color: Colors.transparent,
                              width: style.rowFocusWidth,
                            ),
                    )
                  : skin.surface(
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.onSurface,
                      focused: _focused || widget.selected,
                      accent: Theme.of(context).colorScheme.primary,
                      cornerRadius: style.rowRadius,
                      borderWidth: style.rowFocusWidth,
                    ),
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
                              color: (_focused || widget.selected)
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
                        child: Opacity(
                          opacity: widget.enabled ? 1 : 0.45,
                          child: inheritedLabel == null
                              ? widget.title
                              : Row(
                                  children: [
                                    Expanded(child: widget.title),
                                    const SizedBox(width: 6),
                                    Tooltip(
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
                                      maxWidth: constraints.maxWidth * 0.4,
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
    );
  }
}
