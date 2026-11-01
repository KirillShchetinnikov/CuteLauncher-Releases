import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'focusable_settings_tile.dart';

/// A labelled value, not help: only truncated values add a focus/expand action.
class SettingsReadOnlyValue extends StatefulWidget {
  final String label;
  final String value;
  final FocusNode? focusNode;
  final double readingHeight;
  final TextDirection? textDirection;
  final bool compact;

  const SettingsReadOnlyValue({
    super.key,
    required this.label,
    required this.value,
    this.focusNode,
    this.readingHeight = 80,
    this.textDirection,
    this.compact = false,
  });

  @override
  State<SettingsReadOnlyValue> createState() => _SettingsReadOnlyValueState();
}

class _SettingsReadOnlyValueState extends State<SettingsReadOnlyValue> {
  final _scroll = ScrollController();
  bool _expanded = false;

  @override
  void didUpdateWidget(SettingsReadOnlyValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _expanded = false;
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  KeyEventResult _read(FocusNode node, KeyEvent event) {
    if (!_expanded ||
        !_scroll.hasClients ||
        (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    final down = event.logicalKey == LogicalKeyboardKey.arrowDown;
    if (!down && event.logicalKey != LogicalKeyboardKey.arrowUp) {
      return KeyEventResult.ignored;
    }
    final position = _scroll.position;
    final next =
        (position.pixels + (down ? 1 : -1) * position.viewportDimension * .65)
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble();
    if (next == position.pixels) return KeyEventResult.ignored;
    _scroll.jumpTo(next);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final style = DefaultTextStyle.of(context).style;
      final labelPainter = TextPainter(
        text: TextSpan(
          text: '${widget.label}:',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout(maxWidth: box.maxWidth * .34);
      final labelWidth = labelPainter.width;
      final labelOverflow = labelPainter.didExceedMaxLines;
      labelPainter.dispose();
      final painter =
          TextPainter(
            text: TextSpan(text: widget.value, style: style),
            textDirection: widget.textDirection ?? Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1,
          )..layout(
            maxWidth: (box.maxWidth - (widget.compact ? 36 + labelWidth : 64))
                .clamp(1, double.infinity),
          );
      final overflow =
          painter.didExceedMaxLines || widget.compact && labelOverflow;
      painter.dispose();
      Widget content() => widget.compact && !_expanded
          ? Row(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: box.maxWidth * .34),
                  child: Text(
                    '${widget.label}:',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: widget.textDirection,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_expanded && overflow)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: widget.readingHeight,
                    ),
                    child: Scrollbar(
                      controller: _scroll,
                      thumbVisibility: true,
                      interactive: false,
                      child: SingleChildScrollView(
                        controller: _scroll,
                        primary: false,
                        padding: const EdgeInsetsDirectional.only(end: 10),
                        child: Text(
                          widget.value,
                          textDirection: widget.textDirection,
                        ),
                      ),
                    ),
                  )
                else
                  Text(
                    widget.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: widget.textDirection,
                  ),
              ],
            );
      if (!overflow) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: content(),
        );
      }
      return Semantics(
        expanded: _expanded,
        child: FocusableSettingsTile(
          dense: widget.compact,
          focusNode: widget.focusNode,
          subtle: true,
          scrollOnFocus: false,
          onFocusChange: (focused) {
            if (!focused && _expanded && mounted) {
              setState(() => _expanded = false);
            }
          },
          title: content(),
          trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          onKeyEvent: _read,
          onPressed: () => setState(() => _expanded = !_expanded),
        ),
      );
    },
  );
}
