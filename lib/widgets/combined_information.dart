import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/weather_data.dart';
import '../tile_appearance.dart';
import '../weather_warning_text.dart';
import '../weather_text_format.dart';
import 'date_time_widget.dart';
import 'top_panel_item.dart';
import 'weather_display_text.dart';
import 'weather_glyph.dart';

/// One panel surface with a shared action independent of its visible parts.
class CombinedInformation extends StatelessWidget {
  final TileAppearance appearance;
  final bool showTime, showDate, showWeather, useFahrenheit, showWarnings;
  final String timeFormat, dateFormat;
  final WeatherData? weather;
  final WeatherTextFormat weatherTextFormat;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final bool selected;
  final DateTime? fixedTime;
  final bool weatherStale;
  const CombinedInformation({
    super.key,
    required this.appearance,
    required this.showTime,
    required this.showDate,
    required this.showWeather,
    required this.timeFormat,
    required this.dateFormat,
    this.weather,
    this.weatherTextFormat = WeatherTextFormat.standard,
    this.useFahrenheit = false,
    this.showWarnings = false,
    this.onPressed,
    this.focusNode,
    this.selected = false,
    this.fixedTime,
    this.weatherStale = false,
  });

  @override
  Widget build(BuildContext context) {
    final base = appearance.panelTextStyleFor(Localizations.localeOf(context));
    final style = appearance.renderedInformationStyle();
    final clock = style.textStyle(
      base,
      locale: Localizations.localeOf(context),
    );
    final size = clock.fontSize ?? 18;
    final current = weather;
    final l = AppLocalizations.of(context)!;
    final warning = !weatherTextFormat.explicitLayout && current != null && showWarnings && !weatherStale && current.hasWarning
        ? localizedWeatherWarning(current, l, DateTime.now())
        : null;
    final detail = clock.copyWith(fontSize: size * .65, height: 1.25);
    final weatherStyle = appearance.weatherTextStyle(detail);
    final icon = WeatherGlyph(
      condition: current?.getCondition() ?? WeatherCondition.unknown,
      pack: appearance.weatherIconPack,
      size: size * .75,
      color: appearance.weatherIconColor ?? weatherStyle.color,
      shadows: clock.shadows,
    );
    return TopPanelItem(
      key: const ValueKey('combined_information'),
      appearance: appearance,
      textStyle: clock,
      focusNode: focusNode,
      onPressed: onPressed,
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
                fixedTime: fixedTime,
                key: const Key('statusbar_clock'),
                textStyle: clock.copyWith(fontSize: size * 1.55, height: 1),
                animate: style.animate,
                clockStyle: style,
              ),
            if (showTime && (showDate || showWeather))
              SizedBox(width: style.spacing),
            if (showDate || showWeather)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: style.clockOnRight
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (showDate)
                    DateTimeWidget(
                      dateFormat,
                      fixedTime: fixedTime,
                      key: const Key('statusbar_date'),
                      textStyle: appearance.dateTextStyle(detail),
                    ),
                  if (showWeather)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      textDirection: TextDirection.ltr,
                      children: [
                        if (!weatherTextFormat.explicitLayout) ...[icon, const SizedBox(width: 4)],
                        WeatherDisplayText(
                          [
                            weatherTextFormat.format(current, l, fahrenheit: useFahrenheit, warningsAvailable: !weatherStale, now: fixedTime),
                            ?warning,
                          ].join(' · '),
                          style: weatherStyle,
                          inlineIcon: icon,
                          singleLine: showDate,
                          maxWidth: weatherTextMaxWidth(weatherTextFormat),
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
