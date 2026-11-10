import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../information_formats.dart';
import '../../background_information_geometry.dart';
import '../../information_placement.dart';
import '../../l10n/app_localizations.dart';
import '../../models/weather_data.dart';
import '../../providers/appearance_service.dart';
import '../../providers/settings_service.dart';
import '../../providers/weather_service.dart';
import '../../weather_warning_text.dart';
import '../combined_information.dart';
import '../date_time_widget.dart';
import '../weather_display_text.dart';
import '../weather_glyph.dart';

/// A fixed snapshot using the same formatters and glyphs as the home widgets.
class InformationPreview extends StatelessWidget {
  final bool background;
  final bool dense;
  final bool compact;
  final WeatherDisplayOptions? weatherOptions;
  const InformationPreview({
    super.key,
    this.background = false,
    this.dense = false,
    this.compact = false,
    this.weatherOptions,
  });
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final appearance = context
        .watch<AppearanceService>()
        .appearance
        .forInformation(background: background);
    final weatherService = context.watch<WeatherService?>();
    final l = AppLocalizations.of(context)!;
    final weather =
        weatherService?.weatherData ??
        WeatherData(
          currentTemp: 6,
          feelsLikeTemp: 2,
          currentConditionCode: 803,
          windSpeed: 4,
          currentHumidity: 82,
          location: l.weatherTextSampleCity,
          todayMinTemp: 3,
          todayMaxTemp: 8,
        );
    final options = weatherOptions ?? settings.informationWeather();
    final formats = settings.informationDateTime();
    final placement = InformationPlacement(appearance, settings);
    final members = InformationPlacement.ids
        .where(background ? placement.onBackground : placement.onPanel)
        .toSet();
    if (members.isEmpty) members.addAll(InformationPlacement.ids);
    if (weatherOptions != null) members.add('weather');
    final now = DateTime.now();
    final compact = this.compact || MediaQuery.viewInsetsOf(context).bottom > 0;
    final style = appearance.renderedInformationStyle(background: background);
    final baseText = style.textStyle(
      appearance.panelTextStyleFor(Localizations.localeOf(context)),
      locale: Localizations.localeOf(context),
    );
    final text = background
        ? baseText.copyWith(
            fontSize: BackgroundInformationGeometry.referenceSize * .27,
            height: 1.3,
            decoration: TextDecoration.none,
          )
        : appearance.panelTextStyleFor(Localizations.localeOf(context));
    final warning =
        !options.format.explicitLayout && options.warnings && weatherService?.stale != true && weather.hasWarning
        ? localizedWeatherWarning(weather, l, now)
        : null;
    final icon = WeatherGlyph(
      condition: weather.getCondition(),
      pack: appearance.weatherIconPack,
      size: text.fontSize,
      color: appearance.weatherIconColor ?? appearance.weatherTextStyle(text).color,
    );
    Widget weatherText() => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!options.format.explicitLayout) ...[icon, const SizedBox(width: 4)],
        WeatherDisplayText(
          [
            options.format.format(weather, l, fahrenheit: options.fahrenheit, warningsAvailable: weatherService?.stale != true, now: now),
            ?warning,
          ].join(' · '),
          style: appearance.weatherTextStyle(text),
          inlineIcon: icon,
          maxWidth: weatherTextMaxWidth(options.format,
            backgroundScreenWidth: background ? MediaQuery.sizeOf(context).width : null),
        ),
      ],
    );
    final children = <String, Widget>{
      'time': DateTimeWidget(
        formats.time,
        textStyle: background
            ? baseText.copyWith(
                fontSize: BackgroundInformationGeometry.referenceSize,
                height: 1.1,
              )
            : baseText,
        clockStyle: style,
        animate: false,
        fixedTime: now,
      ),
      'date': DateTimeWidget(
        formats.date,
        textStyle: appearance.dateTextStyle(text),
        animate: false,
        fixedTime: now,
      ),
      'weather': weatherText(),
    };
    final content = background
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                switch (appearance.backgroundInformationAlignment) {
                  'left' => CrossAxisAlignment.start,
                  'right' => CrossAxisAlignment.end,
                  _ => CrossAxisAlignment.center,
                },
            children: [
              for (final id in appearance.backgroundInformationOrder)
                if (members.contains(id)) children[id]!,
            ],
          )
        : appearance.combinedInformation && members.length > 1
        ? CombinedInformation(
            appearance: appearance,
            showTime: members.contains('time'),
            showDate: members.contains('date'),
            showWeather: members.contains('weather'),
            timeFormat: formats.time,
            dateFormat: formats.date,
            weather: weather,
            weatherTextFormat: options.format,
            useFahrenheit: options.fahrenheit,
            showWarnings: options.warnings && weatherService?.stale != true,
            weatherStale: weatherService?.stale == true,
            fixedTime: now,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [for (final id in members) children[id]!],
          );
    return ExcludeFocus(
      child: Container(
        margin: EdgeInsets.fromLTRB(2, 0, 2, dense ? 2 : 12),
        padding: dense
            ? EdgeInsets.symmetric(horizontal: 8, vertical: compact ? 0 : 2)
            : EdgeInsets.all(compact ? 0 : 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface
              .withValues(alpha: .035),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: .08),
          ),
        ),
        child: dense
            ? SizedBox(
                height: compact ? 32 : 56,
                child: FittedBox(fit: BoxFit.contain, child: content),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!compact)
                    Text(
                      background ? l.informationOnBackground : l.topPanel,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(letterSpacing: 0),
                    ),
                  SizedBox(
                    height: compact
                        ? 36
                        : background
                        ? 96
                        : 56,
                    child: Center(
                      child: FittedBox(fit: BoxFit.scaleDown, child: content),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
