import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../launcher_dialog.dart';
import 'focusable_settings_tile.dart';
import 'settings_scroll_behavior.dart';
import 'settings_value_text.dart';

typedef RemoteActionChoice = ({
  String action,
  String target,
  String label,
  String? detail,
  bool enabled,
});
typedef RemoteActionGroup = ({String label, List<RemoteActionChoice> choices});

class RemoteActionPicker extends StatefulWidget {
  const RemoteActionPicker({
    super.key,
    required this.groups,
    required this.ignore,
    required this.action,
    required this.target,
  });

  final List<RemoteActionGroup> groups;
  final RemoteActionChoice ignore;
  final String action, target;

  @override
  State<RemoteActionPicker> createState() => _RemoteActionPickerState();
}

class _RemoteActionPickerState extends State<RemoteActionPicker> {
  late final _sections = List.generate(
    widget.groups.length + 1,
    (_) => FocusNode(),
  );
  late final _options = [
    for (final group in widget.groups)
      [
        for (final choice in group.choices)
          if (choice.enabled) FocusNode(),
      ],
  ];
  final _cancel = FocusNode();
  final _sectionScroll = ScrollController();
  final _actionScroll = ScrollController();
  late final int _initialSection = widget.groups.indexWhere(
    (group) => group.choices.any(_selected),
  );
  late int _section = _initialSection < 0 ? 0 : _initialSection;

  bool _selected(RemoteActionChoice choice) =>
      choice.action == widget.action && choice.target == widget.target;

  @override
  void dispose() {
    _sectionScroll.dispose();
    _actionScroll.dispose();
    for (final node in [
      ..._sections,
      ..._options.expand((nodes) => nodes),
      _cancel,
    ]) {
      node.dispose();
    }
    super.dispose();
  }

  Widget _scrollColumn({
    required Key key,
    required ScrollController controller,
    required Widget child,
  }) => SettingsScrollbar(
    controller: controller,
    scrollbarOrientation: ScrollbarOrientation.left,
    thickness: 4,
    child: Padding(
      padding: const EdgeInsets.only(left: 14),
      child: SingleChildScrollView(
        key: key,
        controller: controller,
        primary: false,
        child: child,
      ),
    ),
  );

  void _showSection(int section) {
    if (section != _section) setState(() => _section = section);
  }

  KeyEventResult _navigate(KeyEvent event, List<FocusNode> column, int index) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final forward = rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final backward = rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown) {
      final next = index + (key == LogicalKeyboardKey.arrowUp ? -1 : 1);
      if (next >= 0 && next < column.length) column[next].requestFocus();
      if (next == column.length) _cancel.requestFocus();
    } else if (key == forward && identical(column, _sections)) {
      _options[_section].firstOrNull?.requestFocus();
    } else if (key == backward && !identical(column, _sections)) {
      _sections[_section].requestFocus();
    } else if (key != forward && key != backward) {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Widget _choice(
    RemoteActionChoice choice,
    FocusNode? node, {
    required bool autofocus,
    required List<FocusNode> column,
  }) {
    final selected = _selected(choice);
    return FocusableSettingsTile(
      title: SettingsValueText(
        text: Text(choice.label),
        alignment: TextAlign.start,
      ),
      trailing: selected || choice.detail != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (choice.detail case final detail?)
                  SettingsValueText(
                    text: Text(detail),
                    alignment: TextAlign.end,
                  ),
                if (selected) const ExcludeSemantics(child: Icon(Icons.check)),
              ],
            )
          : null,
      enabled: choice.enabled,
      selected: selected,
      focusNode: node,
      autofocus: autofocus,
      showActionChevron: false,
      onKeyEvent: node == null
          ? null
          : (_, event) => _navigate(event, column, column.indexOf(node)),
      onPressed: () => Navigator.pop(context, choice),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final group = widget.groups[_section];
    final nodes = _options[_section];
    final selected = group.choices.any(
      (choice) => choice.enabled && _selected(choice),
    );
    var optionIndex = 0;
    final sections = _scrollColumn(
      key: const PageStorageKey('remote-action-sections'),
      controller: _sectionScroll,
      child: Column(
        children: [
          for (final (index, group) in widget.groups.indexed)
            FocusableSettingsTile(
              title: SettingsValueText(
                text: Text(group.label),
                alignment: TextAlign.start,
              ),
              selected: _section == index,
              focusNode: _sections[index],
              autofocus:
                  !selected && index == _section && widget.action != 'ignore',
              onFocusChange: (focused) {
                if (focused) _showSection(index);
              },
              onKeyEvent: (_, event) => _navigate(event, _sections, index),
              onPressed: () {
                _showSection(index);
                _options[index].firstOrNull?.requestFocus();
              },
            ),
          const Divider(),
          _choice(
            widget.ignore,
            _sections.last,
            autofocus: widget.action == 'ignore',
            column: _sections,
          ),
        ],
      ),
    );
    final actions = _scrollColumn(
      key: ValueKey(_section),
      controller: _actionScroll,
      child: Column(
        children: [
          for (final choice in group.choices)
            _choice(
              choice,
              choice.enabled ? nodes[optionIndex++] : null,
              autofocus: choice.enabled && _selected(choice),
              column: nodes,
            ),
        ],
      ),
    );
    return LauncherAlertDialog(
      title: Text(l.remoteMappingChooseAction),
      scrollContent: false,
      contentPadding: EdgeInsets.fromLTRB(
        24,
        Theme.of(context).useMaterial3 ? 16 : 20,
        24,
        4,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 2, 24, 6),
      content: SizedBox(
        width: 700,
        height: 420,
        child: LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth < 380
              ? Column(
                  children: [
                    Expanded(child: sections),
                    const Divider(),
                    Expanded(child: actions),
                  ],
                )
              : Row(
                  children: [
                    Expanded(flex: 5, child: sections),
                    const VerticalDivider(width: 20),
                    Expanded(flex: 6, child: actions),
                  ],
                ),
        ),
      ),
      actions: [
        Focus(
          canRequestFocus: false,
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.arrowUp) {
              (_options[_section].lastOrNull ?? _sections[_section])
                  .requestFocus();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: LauncherDialogButton(
            focusNode: _cancel,
            isCancel: true,
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancel),
          ),
        ),
      ],
    );
  }
}
