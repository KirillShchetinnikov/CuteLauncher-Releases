import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../information_placement.dart';
import '../background_information_geometry.dart';
import '../l10n/app_localizations.dart';
import '../models/weather_data.dart';
import '../providers/appearance_service.dart';
import '../providers/settings_service.dart';
import '../providers/weather_service.dart';
import '../tile_appearance.dart';
import '../weather_warning_text.dart';
import '../weather_text_format.dart';
import 'date_time_widget.dart';
import 'landscape_clock_clip.dart';
import 'weather_display_text.dart';
import 'weather_glyph.dart';
import 'information_bounds.dart';
import 'background_information_scale.dart';

/// Decorative wallpaper layer: never consumes input or space in the app viewport.
class BackgroundInformation extends StatelessWidget {
  const BackgroundInformation({super.key});

  @override
  Widget build(BuildContext context) {
    final appearance =
        context.watch<AppearanceService?>()?.appearance.forInformation(background: true) ??
        const TileAppearance();
    final placements = context.select<SettingsService, Map<String, String>>(
      (settings) => InformationPlacement(appearance, settings).values,
    );
    final timeVisible = placements['time'] == 'background';
    final dateVisible = placements['date'] == 'background';
    final weatherVisible = placements['weather'] == 'background';
    if (!timeVisible && !dateVisible && !weatherVisible) {
      return const SizedBox.shrink();
    }
    final formats = context.select<SettingsService, (String, String)>(
      (s) => (s.timeFormat, s.dateFormat),
    );
    final style = appearance.renderedInformationStyle(background: true);
    final fixedTime = context.select<SettingsService, DateTime?>(
      (s) => s.screenshotScene?.now,
    );
    final text = style
        .textStyle(
          appearance.panelTextStyleFor(Localizations.localeOf(context)),
          locale: Localizations.localeOf(context),
        )
        .copyWith(decoration: TextDecoration.none);
    final clock = text.copyWith(
      fontSize: BackgroundInformationGeometry.referenceSize,
      height: 1.1,
    );
    final detail = text.copyWith(
      fontSize: BackgroundInformationGeometry.referenceSize * .27,
      height: 1.3,
    );
    final anchor = switch (appearance.backgroundInformationPosition) {
      'left' => -1.0,
      'right' => 1.0,
      _ => 0.0,
    };
    final offset = appearance.backgroundInformationOffset / 100;
    final towardEdge = offset * anchor > 0;
    const defaultInset = 24.0;
    const edgeInset = 12.0;
    final inset = towardEdge
        ? defaultInset - (defaultInset - edgeInset) * offset.abs()
        : defaultInset;
    // Alignment interpolates over the space left after laying out the block.
    final alignment = Alignment(
      anchor + (towardEdge ? 0 : offset * (anchor == 0 ? 1 / 3 : .5)),
      0,
    );
    final columnAlignment = switch (appearance.backgroundInformationAlignment) {
      'left' => CrossAxisAlignment.start,
      'right' => CrossAxisAlignment.end,
      _ => CrossAxisAlignment.center,
    };
    final landscape = context.select<SettingsService, bool>(
      (s) => s.backgroundSource == 'landscape',
    );
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final screen = constraints.biggest;
        final geometry = BackgroundInformationGeometry(
          screen, appearance.backgroundInformationVerticalOffset,
        );
        final time = RepaintBoundary(
          child: DateTimeWidget(
            formats.$1,
            key: const Key('background_clock'),
            textStyle: clock,
            animate: style.animate,
            clockStyle: style,
            fixedTime: fixedTime,
          ),
        );
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(inset, geometry.top, inset, 0),
            child: Align(
              alignment: alignment,
              heightFactor: 1,
              child: SizedBox(
                height: geometry.availableHeight,
                child: Align(
                  alignment: Alignment.topCenter,
                  widthFactor: 1,
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: math.max(0.0, screen.width - 2 * defaultInset),
                      maxHeight: geometry.availableHeight,
                    ),
                    child: InformationBounds(
                      onBounds: context.read<AppearanceService?>()?.reportInformationBounds ?? (_) {},
                      child: BackgroundInformationScale(
                      key: const Key('background_information_block'),
                      value: appearance.backgroundInformationSize,
                      geometry: geometry,
                      onMetrics: context.read<AppearanceService?>()?.reportBackgroundInformationMetrics ?? (_, _) {},
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: columnAlignment,
                          textDirection: TextDirection.ltr,
                          children: [
                            for (final id
                                in appearance.backgroundInformationOrder)
                              if (id == 'date' && dateVisible)
                                RepaintBoundary(
                                  child: DateTimeWidget(
                                    formats.$2,
                                    key: const Key('background_date'),
                                    textStyle: appearance.dateTextStyle(detail),
                                    animate: false,
                                    fixedTime: fixedTime,
                                  ),
                                )
                              else if (id == 'weather' && weatherVisible)
                                _BackgroundWeather(style: detail, appearance: appearance)
                              else if (id == 'time' && timeVisible)
                                time,
                          ],
                        ),
                      ),
                    ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    return IgnorePointer(
      child: ExcludeFocus(
        child: ExcludeSemantics(
          child: RepaintBoundary(
            child: landscape && !appearance.backgroundInformationAboveLandscape
                ? LandscapeInformationGeometry(
                    builder: (_, horizon) => LandscapeSkyClip(horizon: horizon, child: content),
                  )
                : content,
          ),
        ),
      ),
    );
  }
}

class _BackgroundWeather extends StatelessWidget {
  final TextStyle style;
  final TileAppearance appearance;
  const _BackgroundWeather({required this.style, required this.appearance});
  @override
  Widget build(BuildContext context) {
    final (weather, stale) = context
        .select<WeatherService, (WeatherData?, bool)>(
          (s) => (s.weatherData, s.stale),
        );
    final fahrenheit = context.select<SettingsService, bool>(
      (s) => s.useFahrenheit,
    );
    final format = context.select<SettingsService, WeatherTextFormat>(
      (s) => s.weatherTextFormat,
    );
    final showWarnings = context.select<SettingsService, bool>(
      (s) => s.showWeatherWarnings,
    );
    final l = AppLocalizations.of(context)!;
    final textStyle = appearance.weatherTextStyle(style);
    final warning =
        !format.explicitLayout && showWarnings && !stale && weather != null && weather.hasWarning
        ? localizedWeatherWarning(weather, l, DateTime.now())
        : null;
    final icon = WeatherGlyph(
      condition: weather?.getCondition() ?? WeatherCondition.unknown,
      pack: appearance.weatherIconPack,
      size: style.fontSize,
      color: appearance.weatherIconColor ?? textStyle.color,
      shadows: style.shadows,
    );
    return Semantics(
      label: AppLocalizations.of(context)!.weather,
      child: Row(
        key: const Key('background_weather'),
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: [
          if (!format.explicitLayout) ...[icon, const SizedBox(width: 8)],
          WeatherDisplayText(
            [
              format.format(weather, l, fahrenheit: fahrenheit, warningsAvailable: !stale),
              ?warning,
            ].join(' • '),
            style: textStyle,
            inlineIcon: icon,
            maxWidth: weatherTextMaxWidth(format,
              backgroundScreenWidth: MediaQuery.sizeOf(context).width),
          ),
        ],
      ),
    );
  }
}
