import '../providers/appearance_service.dart';
import '../tile_appearance.dart';

import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import '../panel_clock_style.dart';
import '../theme/launcher_style.dart';
import 'date_time_widget.dart';
import 'top_panel_item.dart';

class PanelClock extends StatelessWidget {
  final PanelClockStyle style;
  final String format;
  const PanelClock({super.key, required this.style, required this.format});
  @override
  Widget build(BuildContext context) {
    final appearance =
        context.watch<AppearanceService?>()?.appearance ??
        const TileAppearance();
    final custom = style.values.isNotEmpty;
    final textStyle = style.textStyle(
      appearance.panelTextStyleFor(Localizations.localeOf(context)),
      locale: Localizations.localeOf(context),
    );
    return TopPanelItem(
      appearance: appearance,
      textStyle: custom ? textStyle : null,
      backgroundColor: custom
          ? style.background(appearance.panelItemBackground)
          : null,
      borderRadius: custom
          ? style.radius(LauncherStyle.of(context).topButtonRadius)
          : null,
      child: DateTimeWidget(
        format,
        key: const Key('statusbar_clock'),
        textStyle: textStyle,
        animate: style.animate,
      ),
    );
  }
}
