import '../theme/launcher_style.dart';

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
    final style = appearance.informationStyle;
    final clock = style.textStyle(
      base,
      locale: Localizations.localeOf(context),
    );
    final size = clock.fontSize ?? 18;
    final current = weather;
    final l = AppLocalizations.of(context)!;
    final warning = current != null && showWarnings && current.hasWarning
        ? localizedWeatherWarning(current, l, DateTime.now())
        : null;
    final detail = clock.copyWith(fontSize: size * .65, height: 1.25);
    return TopPanelItem(
      key: const ValueKey('combined_information'),
      appearance: appearance,
      textStyle: clock,
      backgroundColor: style.background(appearance.panelItemBackground),
      borderRadius: style.radius(LauncherStyle.of(context).topButtonRadius),
      focusNode: focusNode,
      onPressed: showDate ? onCalendar : null,
      selected: selected,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: style.clockOnRight
              ? TextDirection.rtl
              : TextDirection.ltr,
          children: [
            if (showTime)
              DateTimeWidget(
                timeFormat,
                key: const Key('statusbar_clock'),
                textStyle: clock.copyWith(fontSize: size * 1.55, height: 1),
                animate: style.animate,
              ),
            if (showTime && (showDate || showWeather && current != null))
              SizedBox(width: style.spacing),
            if (showDate || showWeather && current != null)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: style.clockOnRight
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
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
                      textDirection: TextDirection.ltr,
                      children: [
                        Icon(
                          current.getConditionIcon(),
                          size: size * .75,
                          color: clock.color,
                          shadows: clock.shadows,
                        ),
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
