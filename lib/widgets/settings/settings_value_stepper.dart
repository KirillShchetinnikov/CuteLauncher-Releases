import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'focusable_settings_tile.dart';
import 'settings_choice_tile.dart';
import 'settings_slider_tile.dart';
import 'settings_value_text.dart';

/// One remote focus target; horizontal keys change the value in place.
class SettingsValueStepper extends StatelessWidget {
  final String title;
  final Widget? leading;
  final List<dynamic> options;
  final dynamic value;
  final String Function(dynamic) label;
  final ValueChanged<dynamic> onChanged;
  final bool autofocus;
  final bool valueBelow;
  final bool enabled;
  final bool useSlider;
  const SettingsValueStepper({
    super.key,
    required this.title,
    this.leading,
    required this.options,
    required this.value,
    required this.label,
    required this.onChanged,
    this.autofocus = false,
    this.valueBelow = false,
    this.enabled = true,
    this.useSlider = true,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    if (!options.every((option) => option == null || option is num)) {
      return SettingsChoiceTile<dynamic>(
        leading: leading,
        title: title,
        value: value,
        options: options,
        label: label,
        onChanged: onChanged,
        enabled: enabled,
        autofocus: autofocus,
      );
    }
    if (useSlider && options.length > 10 && options.every((option) => option is num)) {
      return SettingsSliderTile(
        title: title,
        value: value as num,
        options: options.cast<num>(),
        label: label,
        onChanged: onChanged,
        enabled: enabled,
        autofocus: autofocus,
      );
    }
    var index = options.indexOf(value);
    if (index < 0 && value is num) {
      index = options.indexWhere((option) => option is num);
      for (var i = 1; i < options.length; i++) {
        if (options[i] is! num) continue;
        if (((options[i] as num) - (value as num)).abs() <
            ((options[index] as num) - (value as num)).abs()) {
          index = i;
        }
      }
    }
    index = index.clamp(0, options.length - 1);
    final canDecrease = enabled && index > 0;
    final canIncrease = enabled && index < options.length - 1;
    void change(int direction) {
      if (!enabled) return;
      final next = index + direction;
      if (next >= 0 && next < options.length) onChanged(options[next]);
    }

    Widget arrow(bool enabled, IconData icon, int direction) => GestureDetector(
      onTap: enabled ? () => change(direction) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Icon(
          icon,
          size: 20,
          color: enabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).disabledColor,
        ),
      ),
    );
    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, event) {
        if (enabled && (event is KeyDownEvent || event is KeyRepeatEvent)) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            change(-1);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            change(1);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Semantics(
        label: title,
        value: label(value),
        increasedValue: canIncrease ? label(options[index + 1]) : null,
        decreasedValue: canDecrease ? label(options[index - 1]) : null,
        onDecrease: canDecrease ? () => change(-1) : null,
        onIncrease: canIncrease ? () => change(1) : null,
        child: FocusableSettingsTile(
          leading: leading,
          autofocus: autofocus,
          enabled: enabled,
          title: valueBelow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title),
                    Row(
                      children: [
                        arrow(canDecrease, Icons.chevron_left, -1),
                        Expanded(child: SettingsValueText(
                          text: Text(label(value)), alignment: TextAlign.start)),
                        arrow(canIncrease, Icons.chevron_right, 1),
                      ],
                    ),
                  ],
                )
              : Text(title),
          trailing: valueBelow
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    arrow(canDecrease, Icons.chevron_left, -1),
                    Flexible(child: SettingsValueText(
                      text: Text(label(value)), alignment: TextAlign.end)),
                    arrow(canIncrease, Icons.chevron_right, 1),
                  ],
                ),
        ),
      ),
    );
  }
}
