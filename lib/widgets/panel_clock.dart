import 'package:flutter/material.dart';

import '../panel_clock_style.dart';

import 'date_time_widget.dart';
import 'top_panel_item.dart';

class PanelClock extends StatelessWidget {
  final PanelClockStyle style;
  final String format;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final bool selected;
  const PanelClock({
    super.key,
    required this.style,
    required this.format,
    this.onPressed,
    this.focusNode,
    this.selected = false,
  });
  @override
  Widget build(BuildContext context) {
    final appearance = topPanelAppearance(context);
    final custom = style.values.isNotEmpty;
    final textStyle = style.textStyle(
      appearance.panelTextStyleFor(Localizations.localeOf(context)),
      locale: Localizations.localeOf(context),
    );
    return TopPanelItem(
      appearance: appearance,
      textStyle: custom ? textStyle : null,
      onPressed: onPressed,
      focusNode: focusNode,
      selected: selected,
      child: DateTimeWidget(
        format,
        key: const Key('statusbar_clock'),
        textStyle: textStyle,
        animate: style.animate,
      ),
    );
  }
}
