import 'package:flauncher/theme/launcher_style.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/flauncher_channel.dart';

import 'settings_value_text.dart';
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
  final VoidCallback? onLongPress;
  final bool selected;
  final bool enabled;
  final IconData valueIcon;
  final bool alignValueToEnd;
  final bool scrollOnFocus;

  const FocusableSettingsTile({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.onPressed,
    this.autofocus = false,
    this.focusNode,
    this.onKeyEvent,
    this.onLongPress,
    this.selected = false,
    this.enabled = true,
    this.valueIcon = Icons.chevron_right_rounded,
    this.alignValueToEnd = true,
    this.scrollOnFocus = true,
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
    if (context.read<SettingsService?>()?.appKeyClickEnabled == true) {
      FLauncherChannel().playClickSound();
    }
    widget.onPressed!();
  }

  @override
  bool get wantKeepAlive => _focused;

  Widget _fullTextMetrics(Widget child) {
    if (DefaultTextStyle.of(context).style.fontFamily != 'Manrope') {
      return child;
    }
    // Keep native metrics on every wrapped line, not just its outer edges.
    return DefaultTextStyle.merge(
      style: const TextStyle(height: kTextHeightNone),
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
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
            updateKeepAlive();
            if (hasFocus && widget.scrollOnFocus) {
              Scrollable.ensureVisible(
                context,
                alignment: 0.5,
                duration: style.scrollDuration,
              );
            }
          },
          child: GestureDetector(
            onTap: !widget.enabled || widget.onPressed == null
                ? null
                : _activate,
            onLongPress: widget.enabled ? widget.onLongPress : null,
            behavior: HitTestBehavior.opaque,
            child: Container(
              constraints: BoxConstraints(minHeight: style.rowMinHeight),
              padding: style.rowPadding,
              decoration: skin.standard
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
                          widget.onPressed != null) ...[
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
                                if (widget.onPressed != null) ...[
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
