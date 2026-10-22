import '../app_fonts.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/weather_data.dart';
import '../tile_appearance.dart';
import '../weather_warning_text.dart';
import 'date_time_widget.dart';
import 'top_panel_item.dart';

/// One panel surface; existing visibility, formats and calendar action survive.
class CombinedInformation extends StatelessWidget {
  final TileAppearance appearance;
  final bool showTime, showDate, showWeather, useFahrenheit, showWarnings;
  final String timeFormat, dateFormat;
  final WeatherData? weather;
  final VoidCallback? onCalendar;
  final FocusNode? focusNode;
  final bool selected;
  const CombinedInformation({
    super.key,
    required this.appearance,
    required this.showTime,
    required this.showDate,
    required this.showWeather,
    required this.timeFormat,
    required this.dateFormat,
    this.weather,
    this.useFahrenheit = false,
    this.showWarnings = false,
    this.onCalendar,
    this.focusNode,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final base = appearance.panelTextStyleFor(Localizations.localeOf(context));
    final size = base.fontSize ?? 18;
    final clock = appearance.clockStyle.textStyle(base);
    final current = weather;
    final l = AppLocalizations.of(context)!;
    final warning = current != null && showWarnings && current.hasWarning
        ? localizedWeatherWarning(current, l, DateTime.now())
        : null;
    final detail = base.copyWith(fontSize: size * .65, height: 1.25);
    return TopPanelItem(
      key: const ValueKey('combined_information'),
      appearance: appearance,
      focusNode: focusNode,
      onPressed: showDate ? onCalendar : null,
      selected: selected,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showTime)
              DateTimeWidget(
                timeFormat,
                key: const Key('statusbar_clock'),
                textStyle: clock.copyWith(
                  fontSize: size * 1.55,
                  height: 1,
                  fontFamily:
                      appearance.clockStyle.values['font'] == null &&
                          !appearance.values.containsKey('panelFont')
                      ? AppFonts.family('outfit', Localizations.localeOf(context))
                      : clock.fontFamily,
                ),
                animate: appearance.clockStyle.animate,
              ),
            if (showTime && (showDate || showWeather && current != null))
              const SizedBox(width: 12),
            if (showDate || showWeather && current != null)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showDate)
                    DateTimeWidget(
                      dateFormat,
                      key: const Key('statusbar_date'),
                      textStyle: detail,
                    ),
                  if (showWeather && current != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(current.getConditionIcon(), size: size * .75),
                        const SizedBox(width: 4),
                        Text(
                          '${current.formatTemperature(useFahrenheit: useFahrenheit)}${warning == null ? '' : ' · $warning'}',
                          style: detail,
                        ),
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
