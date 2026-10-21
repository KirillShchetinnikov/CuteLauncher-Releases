import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'focusable_settings_tile.dart';

/// Optional help, with a separate D-pad reading stop and bounded text viewport.
class SettingsHelp extends StatefulWidget {
  final String text;

  const SettingsHelp({super.key, required this.text});

  @override
  State<SettingsHelp> createState() => _SettingsHelpState();
}

class _SettingsHelpState extends State<SettingsHelp>
    with AutomaticKeepAliveClientMixin {
  final _headerFocus = FocusNode();
  final _textFocus = FocusNode();
  final _scroll = ScrollController();
  bool _expanded = false;
  bool _reading = false;

  @override
  bool get wantKeepAlive => _expanded;

  void _toggle() {
    if (_expanded) _headerFocus.requestFocus();
    setState(() => _expanded = !_expanded);
    updateKeepAlive();
  }

  KeyEventResult _readText(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final down = event.logicalKey == LogicalKeyboardKey.arrowDown;
    final up = event.logicalKey == LogicalKeyboardKey.arrowUp;
    if (!down && !up) return KeyEventResult.ignored;
    if (!_scroll.hasClients) return KeyEventResult.handled;
    final position = _scroll.position;
    final target =
        (position.pixels + (down ? 1 : -1) * position.viewportDimension * 0.35)
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble();
    if (target != position.pixels) {
      _scroll.jumpTo(target);
    } else if (up) {
      _headerFocus.requestFocus();
    } else {
      _textFocus.focusInDirection(TraversalDirection.down);
    }
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _headerFocus.dispose();
    _textFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          expanded: _expanded,
          child: FocusableSettingsTile(
            focusNode: _headerFocus,
            leading: const Icon(Icons.info_outline_rounded),
            title: Text(l.settingsHelp),
            trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            onPressed: _toggle,
            onKeyEvent: (_, event) {
              if (_expanded &&
                  (event is KeyDownEvent || event is KeyRepeatEvent) &&
                  event.logicalKey == LogicalKeyboardKey.arrowDown) {
                _textFocus.requestFocus();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
          ),
        ),
        if (_expanded)
          Focus(
            focusNode: _textFocus,
            onKeyEvent: _readText,
            onFocusChange: (focused) {
              setState(() => _reading = focused);
              if (focused && _textFocus.context != null) {
                Scrollable.ensureVisible(_textFocus.context!, alignment: 0.5);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _reading
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: (MediaQuery.sizeOf(context).height * 0.45)
                            .clamp(96.0, 320.0),
                      ),
                      child: Scrollbar(
                        controller: _scroll,
                        thumbVisibility: true,
                        interactive: false,
                        child: RepaintBoundary(
                          child: SingleChildScrollView(
                            controller: _scroll,
                            primary: false,
                            padding: const EdgeInsetsDirectional.only(end: 12),
                            child: Text(widget.text),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l.settingsHelpScroll,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
