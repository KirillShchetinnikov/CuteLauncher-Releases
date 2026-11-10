import 'settings_adjustment_semantics.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'focusable_settings_tile.dart';

/// A single focus target. The thumb never enters the remote traversal order.
class SettingsSliderTile extends StatefulWidget {
  final String title;
  final List<num> options;
  final num value;
  final String Function(num) label;
  final ValueChanged<num> onChanged;
  final bool enabled, autofocus;
  final TextDirection? sliderTextDirection;
  final bool busy;
  const SettingsSliderTile({
    super.key,
    required this.title,
    required this.options,
    required this.value,
    required this.label,
    required this.onChanged,
    this.enabled = true,
    this.busy = false,
    this.autofocus = false,
    this.sliderTextDirection,
  });

  @override
  State<SettingsSliderTile> createState() => _SettingsSliderTileState();
}

class _SettingsSliderTileState extends State<SettingsSliderTile> {
  double? _draft;
  int get _index {
    var nearest = 0;
    for (var i = 1; i < widget.options.length; i++) {
      if ((widget.options[i] - widget.value).abs() <
          (widget.options[nearest] - widget.value).abs()) {
        nearest = i;
      }
    }
    return nearest;
  }

  @override
  void didUpdateWidget(SettingsSliderTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        oldWidget.enabled != widget.enabled) {
      _draft = null;
    }
  }

  void _change(int direction) {
    if (!widget.enabled || widget.busy) return;
    final next = (_index + direction).clamp(0, widget.options.length - 1);
    if (next != _index) widget.onChanged(widget.options[next]);
  }

  @override
  Widget build(BuildContext context) {
    final index = _draft?.round() ?? _index;
    final displayed = _draft == null ? widget.value : widget.options[index];
    return SettingsAdjustmentSemantics(
      enabled: widget.enabled && !widget.busy,
      label: widget.title,
      value: widget.label(displayed),
      increasedValue:
          widget.enabled && !widget.busy && _index < widget.options.length - 1
          ? widget.label(widget.options[_index + 1])
          : null,
      decreasedValue: widget.enabled && !widget.busy && _index > 0
          ? widget.label(widget.options[_index - 1])
          : null,
      onIncrease:
          widget.enabled && !widget.busy && _index < widget.options.length - 1
          ? () => _change(1)
          : null,
      onDecrease: widget.enabled && !widget.busy && _index > 0
          ? () => _change(-1)
          : null,
      child: FocusableSettingsTile(
        semanticContainer: false,
        autofocus: widget.autofocus,
        enabled: widget.enabled,
        busy: widget.busy,
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent || event is KeyRepeatEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _change(
                event.logicalKey == LogicalKeyboardKey.arrowRight ? 1 : -1,
              );
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        title: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) => Row(
                  children: [
                    Expanded(child: Text(widget.title)),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * 0.4,
                      ),
                      child: Text(
                        widget.label(displayed),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
              ExcludeFocus(
                child: ExcludeSemantics(
                  child: Directionality(
                    textDirection:
                        widget.sliderTextDirection ??
                        Directionality.of(context),
                    child: Slider(
                      value: (_draft ?? _index.toDouble())
                          .clamp(0, widget.options.length - 1)
                          .toDouble(),
                      max: (widget.options.length - 1).toDouble(),
                      divisions: widget.options.length > 1
                          ? widget.options.length - 1
                          : null,
                      label: widget.label(displayed),
                      onChanged: widget.enabled && !widget.busy
                          ? (value) => setState(() => _draft = value)
                          : null,
                      onChangeEnd: widget.enabled && !widget.busy
                          ? (value) {
                              widget.onChanged(widget.options[value.round()]);
                              setState(() => _draft = null);
                            }
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
