import 'package:flutter/material.dart';

import '../launcher_dialog.dart';
import 'settings_option_tile.dart';

/// One scroll owner, a reserved scrollbar gutter and a visible initial choice.
class SettingsChoiceDialog<T> extends StatefulWidget {
  final Widget title;
  final T value;
  final Widget Function(T option, Widget row)? decorateOption;
  final List<T> options;
  final Widget Function(T) optionBuilder;
  final Widget Function(T)? leadingBuilder;
  final ValueChanged<T> onSelected;
  final double width;
  final List<Widget>? actions;
  const SettingsChoiceDialog({
    super.key,
    required this.title,
    required this.value,
    this.decorateOption,
    required this.options,
    required this.optionBuilder,
    required this.onSelected,
    this.leadingBuilder,
    this.width = 400,
    this.actions,
  });

  @override
  State<SettingsChoiceDialog<T>> createState() =>
      _SettingsChoiceDialogState<T>();
}

class _SettingsChoiceDialogState<T> extends State<SettingsChoiceDialog<T>> {
  final _initialRow = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final row = _initialRow.currentContext;
      if (row != null) Scrollable.ensureVisible(row, alignment: .5);
    });
  }

  Widget _option(T option, bool initial) {
    final row = SettingsOptionTile(
      key: initial ? _initialRow : null,
      selected: option == widget.value,
      autofocus: initial,
      title: widget.optionBuilder(option),
      leading: widget.leadingBuilder?.call(option),
      onPressed: () => widget.onSelected(option),
    );
    return widget.decorateOption?.call(option, row) ?? row;
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.options.contains(widget.value)
        ? widget.options.indexOf(widget.value)
        : 0;
    return LauncherAlertDialog(
      title: widget.title,
      content: SizedBox(
        width: widget.width,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(end: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < widget.options.length; index++)
                _option(widget.options[index], index == initial),
            ],
          ),
        ),
      ),
      actions: widget.actions,
    );
  }
}
