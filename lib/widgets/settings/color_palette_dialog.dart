import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Ten grayscale shades, then nine hues with ten lightness levels each.
final appearancePalette = List<int>.unmodifiable([
  for (var column = 0; column < 10; column++)
    Color.fromARGB(
      255,
      (column * 255 / 9).round(),
      (column * 255 / 9).round(),
      (column * 255 / 9).round(),
    ).toARGB32(),
  for (var row = 0; row < 9; row++)
    for (var column = 0; column < 10; column++)
      HSLColor.fromAHSL(
        1,
        row * 40,
        .75,
        .12 + column * .08,
      ).toColor().toARGB32(),
]);

class ColorPaletteDialog extends StatelessWidget {
  final String title;
  final int? current;
  final bool allowDefault;
  final bool forPanel;
  final String? defaultLabel;
  const ColorPaletteDialog({
    super.key,
    required this.title,
    this.current,
    this.allowDefault = false,
    this.forPanel = false,
    this.defaultLabel,
  });
  @override
  Widget build(BuildContext context) => LauncherAlertDialog(
    title: Text(title),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (allowDefault)
              LauncherDialogButton(
                onPressed: () => Navigator.pop(context, (null,)),
                child: Text(defaultLabel ?? AppLocalizations.of(context)!.defaultOption),
              ),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 10,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: [
                for (final value in appearancePalette)
                  _ColorCell(
                    value: value,
                    onPressed: () => Navigator.pop(context, (value,)),
                    selected: current == value,
                    autofocus:
                        current == value ||
                        (value == appearancePalette.first &&
                            !appearancePalette.contains(current)),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _ColorCell extends StatefulWidget {
  final int value;
  final VoidCallback onPressed;
  final bool selected, autofocus;
  const _ColorCell({
    required this.value,
    required this.onPressed,
    required this.selected,
    required this.autofocus,
  });
  @override
  State<_ColorCell> createState() => _ColorCellState();
}

class _ColorCellState extends State<_ColorCell> {
  bool focused = false;
  @override
  Widget build(BuildContext context) {
    final color = Color(widget.value);
    final contrast = color.computeLuminance() > .5
        ? Colors.black
        : Colors.white;
    return Semantics(
      label: '#${widget.value.toRadixString(16).substring(2).toUpperCase()}',
      selected: widget.selected,
      child: InkWell(
        autofocus: widget.autofocus,
        onFocusChange: (value) {
          setState(() => focused = value);
          if (value) Scrollable.ensureVisible(context, alignment: .5);
        },
        onTap: widget.onPressed,
        child: Container(
          key: ValueKey('palette-${widget.value}'),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: focused
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
              width: focused ? 4 : 1,
            ),
          ),
          child: widget.selected || focused
              ? Icon(
                  widget.selected ? Icons.check : Icons.circle_outlined,
                  color: contrast,
                  size: 18,
                )
              : null,
        ),
      ),
    );
  }
}
