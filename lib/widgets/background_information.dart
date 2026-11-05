import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../information_placement.dart';
import '../l10n/app_localizations.dart';
import '../models/weather_data.dart';
import '../providers/appearance_service.dart';
import '../providers/settings_service.dart';
import '../providers/weather_service.dart';
import '../tile_appearance.dart';
import '../weather_warning_text.dart';
import 'date_time_widget.dart';
import 'landscape_clock_clip.dart';
import 'landscape_horizon.dart';

/// Decorative wallpaper layer: never consumes input or space in the app viewport.
class BackgroundInformation extends StatelessWidget {
  const BackgroundInformation({super.key});

  @override
  Widget build(BuildContext context) {
    final appearance =
        context.watch<AppearanceService?>()?.appearance ??
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
    final style = appearance.backgroundInformationStyle;
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
      fontSize: appearance.backgroundInformationSize,
      height: 1.1,
    );
    final detail = text.copyWith(
      fontSize: appearance.backgroundInformationSize * .27,
      height: 1.3,
    );
    final alignment = switch (appearance.backgroundInformationAlignment) {
      'left' => Alignment.centerLeft,
      'right' => Alignment.centerRight,
      _ => Alignment.center,
    };
    final columnAlignment = switch (appearance.backgroundInformationAlignment) {
      'left' => CrossAxisAlignment.start,
      'right' => CrossAxisAlignment.end,
      _ => CrossAxisAlignment.center,
    };
    final landscape = context.select<SettingsService, bool>(
      (s) => s.backgroundSource == 'landscape',
    );
    Widget content(LandscapeHorizon? horizon) => LayoutBuilder(
      builder: (context, constraints) {
        final screen = constraints.biggest;
        final maxHeight = (screen.height - kToolbarHeight - 16).clamp(
          0.0,
          screen.height * .5,
        );
        final x = switch (appearance.backgroundInformationAlignment) {
          'left' => screen.width * .2,
          'right' => screen.width * .8,
          _ => screen.width * .5,
        };
        final headerHeight = horizon == null
            ? null
            : (horizon.heightAt(x) - kToolbarHeight + clock.fontSize! * .12 + 8)
                  .clamp(0.0, maxHeight);
        Widget time = RepaintBoundary(
          child: DateTimeWidget(
            formats.$1,
            key: const Key('background_clock'),
            textStyle: clock,
            animate: style.animate,
            clockStyle: style,
            fixedTime: fixedTime,
          ),
        );
        if (horizon != null && !appearance.backgroundInformationAboveLandscape) {
          time = LandscapeSkyClip(horizon: horizon, child: time);
        }
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, kToolbarHeight + 8, 24, 8),
            child: Align(
              alignment: alignment,
              heightFactor: 1,
              child: SizedBox(
                height: headerHeight,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  widthFactor: 1,
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxHeight),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: columnAlignment,
                          children: [
                            for (final id
                                in appearance.backgroundInformationOrder)
                              if (id == 'date' && dateVisible)
                                RepaintBoundary(
                                  child: DateTimeWidget(
                                    formats.$2,
                                    key: const Key('background_date'),
                                    textStyle: detail,
                                    animate: false,
                                    fixedTime: fixedTime,
                                  ),
                                )
                              else if (id == 'weather' && weatherVisible)
                                _BackgroundWeather(style: detail)
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
        );
      },
    );
    return IgnorePointer(
      child: ExcludeFocus(
        child: ExcludeSemantics(
          child: RepaintBoundary(
            child: landscape && timeVisible
                ? LandscapeInformationGeometry(
                    builder: (_, horizon) => content(horizon),
                  )
                : content(null),
          ),
        ),
      ),
    );
  }
}

class _BackgroundWeather extends StatelessWidget {
  final TextStyle style;
  const _BackgroundWeather({required this.style});
  @override
  Widget build(BuildContext context) {
    final (weather, stale) = context
        .select<WeatherService, (WeatherData?, bool)>(
          (s) => (s.weatherData, s.stale),
        );
    final fahrenheit = context.select<SettingsService, bool>(
      (s) => s.useFahrenheit,
    );
    final showWarnings = context.select<SettingsService, bool>(
      (s) => s.showWeatherWarnings,
    );
    final l = AppLocalizations.of(context)!;
    final warning =
        showWarnings && !stale && weather != null && weather.hasWarning
        ? localizedWeatherWarning(weather, l, DateTime.now())
        : null;
    return Semantics(
      label: AppLocalizations.of(context)!.weather,
      child: Row(
        key: const Key('background_weather'),
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: [
          Icon(
            weather?.getConditionIcon() ?? Icons.cloud_outlined,
            size: style.fontSize,
            color: style.color,
            shadows: style.shadows,
          ),
          const SizedBox(width: 8),
          Text(
            [
              weather?.formatTemperature(useFahrenheit: fahrenheit) ?? '—',
              ?warning,
            ].join(' • '),
            style: style,
          ),
        ],
      ),
    );
  }
}
