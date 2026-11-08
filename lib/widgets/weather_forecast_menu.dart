import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/weather_data.dart';
import '../providers/appearance_service.dart';
import '../providers/settings_service.dart';
import '../providers/weather_service.dart';
import '../theme/interface_style.dart';
import '../tile_appearance.dart';
import '../weather_sources.dart';
import '../weather_warning_text.dart';
import 'launcher_dialog.dart';
import 'menu_header.dart';
import 'menu_header_action.dart';
import 'panel_calendar_dialog.dart';
import 'settings/information_settings_page.dart';
import 'settings/settings_panel.dart';
import 'settings/settings_panel_style.dart';
import 'settings/weather_page.dart';
import 'side_panel_dialog.dart';
import 'weather_glyph.dart';

/// Reads the shared service's snapshot; opening a menu never starts another poll.
class WeatherForecastMenu extends StatefulWidget {
  final Rect anchor;
  final bool showCalendar;
  final DateTime? now;
  final bool? autofocusSettings;
  final VoidCallback? onSettingsClosed;
  const WeatherForecastMenu({
    super.key,
    required this.anchor,
    this.showCalendar = false,
    this.now,
    this.autofocusSettings,
    this.onSettingsClosed,
  });

  @override
  State<WeatherForecastMenu> createState() => _WeatherForecastMenuState();
}

class _WeatherForecastMenuState extends State<WeatherForecastMenu> {
  final _settingsNode = FocusNode();
  bool _settingsOpen = false;

  @override
  void dispose() {
    _settingsNode.dispose();
    super.dispose();
  }

  Future<void> _openSettings() async {
    setState(() => _settingsOpen = true);
    await showLauncherDialog<void>(
      context: context,
      parentPanelHidden: true,
      styleDialog: false,
      barrierColor: Colors.transparent,
      builder: (_) =>
          const SettingsPanel(initialRoute: InformationSettingsPage.routeName),
    );
    if (!mounted) return;
    setState(() => _settingsOpen = false);
    widget.onSettingsClosed?.call();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _settingsNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) => SettingsPanelStyle(
    builder: (context) {
      final l = AppLocalizations.of(context)!;
      return ExcludeFocus(
        excluding: _settingsOpen,
        child: Offstage(
          offstage: _settingsOpen,
          child: Stack(
            children: [
              const Positioned.fill(child: LauncherPanelBackdrop()),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              SidePanelDialog(
                anchor: widget.anchor,
                topInset: kToolbarHeight,
                width: widget.showCalendar ? 920 : 680,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MenuHeader(
                      title: Text(
                        widget.showCalendar
                            ? l.informationGroup
                            : l.weatherForecastTitle,
                      ),
                      actions: [
                        MenuHeaderAction(
                          focusNode: _settingsNode,
                          autofocus:
                              widget.autofocusSettings ?? !widget.showCalendar,
                          tooltip: l.settings,
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: _openSettings,
                        ),
                      ],
                    ),
                    const Divider(),
                    Flexible(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Reflow first; fit the complete body only when the
                          // viewport/text size still exceeds one screen. The
                          // shared header and gear keep their normal size.
                          return FittedBox(
                            key: const Key('weather_screen_fit'),
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.topCenter,
                            child: SizedBox(
                              width: constraints.maxWidth,
                              child: _content(constraints.maxWidth),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _content(double width) {
    final weather = WeatherForecastContent(
      now: widget.now,
      showTitle: widget.showCalendar,
    );
    if (!widget.showCalendar) return weather;
    final calendar = PanelCalendarDialog(embedded: true, today: widget.now);
    if (width >= 700) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: calendar),
          const SizedBox(width: 12),
          Expanded(flex: 5, child: weather),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [calendar, const SizedBox(height: 12), weather],
    );
  }
}

class WeatherForecastContent extends StatelessWidget {
  final DateTime? now;
  final bool showTitle;
  const WeatherForecastContent({super.key, this.now, this.showTitle = true});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<WeatherService>();
    final appearance =
        context.watch<AppearanceService?>()?.appearance ??
        const TileAppearance();
    final fahrenheit = context.watch<SettingsService>().useFahrenheit;
    final weather = service.weatherData;
    final feelsLike = weather?.feelsLikeTemp;
    final count = appearance.forecastDays;
    final days =
        weather
            ?.forecastDays(now ?? DateTime.now(), count)
            .where(
              (day) =>
                  day.minTemp != null ||
                  day.maxTemp != null ||
                  day.conditionCode != null ||
                  day.precipProbability != null,
            )
            .toList() ??
        [];
    final source = switch (service.configuration.source) {
      WeatherSource.breezy => 'Breezy Weather',
      WeatherSource.openMeteo => 'Open-Meteo',
      WeatherSource.customOpenMeteo => weather?.source ?? l.weatherCustomServer,
      WeatherSource.metNorway => 'MET Norway',
      WeatherSource.openWeather => 'OpenWeather',
      WeatherSource.gismeteo => 'Gismeteo',
      WeatherSource.yandex => l.yandexWeather,
    };
    final updated = service.updatedAt;
    final theme = Theme.of(context);
    final content = Column(
      key: const Key('weather_forecast_content'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.place_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                weather?.location?.isNotEmpty == true
                    ? weather!.location!
                    : service.configuration.source == WeatherSource.customOpenMeteo &&
                        weather?.latitude != null && weather?.longitude != null
                    ? '${weather!.latitude!.toStringAsFixed(3)}, ${weather.longitude!.toStringAsFixed(3)}'
                    : l.weatherForecastTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (service.configuration.source == WeatherSource.customOpenMeteo &&
            weather?.timezone != null)
          Text(weather!.timezone!, style: theme.textTheme.bodySmall),
        DefaultTextStyle.merge(
          style: theme.textTheme.bodySmall,
          child: Wrap(
            spacing: 12,
            runSpacing: 2,
            children: [
              if (feelsLike != null)
                Text(
                  l.weatherFeelsLike(
                    WeatherData.formatDegrees(
                      feelsLike,
                      useFahrenheit: fahrenheit,
                    ),
                  ),
                  style: appearance.weatherTextColor == null
                      ? null : TextStyle(color: appearance.weatherTextColor),
                ),
              Text('${l.weatherSource}: $source'),
              Text(
                weather?.utcOffsetSeconds == null
                    ? l.weatherForecastTvTime
                    : _offsetLabel(weather!.utcOffsetSeconds!),
              ),
              if (updated != null)
                Text(
                  '${service.stale ? l.weatherStale : l.weatherUpdated}: '
                  '${DateFormat.yMd(l.localeName).add_jm().format(updated.toLocal())}',
                ),
            ],
          ),
        ),
        if (service.loading) const LinearProgressIndicator(),
        if (service.failure != null)
          Text(
            weatherFailureMessage(
              l,
              service.failure!,
              service.configuration.source,
            ),
          ),
        const SizedBox(height: 8),
        if (days.isEmpty && !service.loading)
          Text(l.weatherUnavailable)
        else if (days.isNotEmpty) ...[
          if (days.length < count)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(l.weatherForecastAvailable(days.length, count)),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final detailed = appearance.detailedForecast;
              final minimum = detailed ? 240.0 : 150.0;
              final columns = (constraints.maxWidth / minimum).floor().clamp(
                1,
                detailed ? 2 : days.length.clamp(1, 4),
              );
              final width =
                  (constraints.maxWidth - (columns - 1) * 8) / columns;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final day in days)
                    SizedBox(
                      width: width,
                      child: _day(context, day, fahrenheit, appearance, detailed: detailed),
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );
    if (!showTitle) return content;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: InterfaceSkin.of(context).surface(
        theme.colorScheme.onSurface.withValues(alpha: .035),
        theme.colorScheme.onSurface,
        borderWidth: 1,
      ),
      child: content,
    );
  }

  String _offsetLabel(int seconds) {
    final minutes = seconds.abs() ~/ 60;
    return 'UTC${seconds < 0 ? '−' : '+'}${(minutes ~/ 60).toString().padLeft(2, '0')}:'
        '${(minutes % 60).toString().padLeft(2, '0')}';
  }

  Widget _day(
    BuildContext context,
    WeatherForecastItem day,
    bool fahrenheit,
    TileAppearance appearance, {
    bool detailed = false,
  }) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final code = day.conditionCode;
    final inherited = DefaultTextStyle.of(context).style;
    final small = appearance.weatherTextStyle(theme.textTheme.bodySmall ?? inherited);
    final temperatureStyle = appearance.weatherTextStyle(theme.textTheme.titleSmall ?? inherited);
    final dataStyle = detailed ? small : temperatureStyle;
    final today = DateUtils.isSameDay(
      day.date,
      weatherCalendarDay(
        now ?? DateTime.now(),
        context.read<WeatherService>().weatherData?.utcOffsetSeconds,
      ),
    );
    String temperature(int? value) => value == null
        ? '—'
        : WeatherData.formatDegrees(value, useFahrenheit: fahrenheit);
    final condition = localizedWeatherCondition(code, l) ?? '—';
    return Container(
      key: ValueKey('forecast_${weatherDateString(day.date!)}'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: InterfaceSkin.of(context).surface(
        theme.colorScheme.onSurface.withValues(alpha: today ? .12 : .05),
        theme.colorScheme.onSurface,
        borderWidth: 1,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                DateFormat.MMMEd(l.localeName).format(day.date!),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: today ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              if (detailed) ...[
                Text(
                  '${temperature(day.minTemp)} / ${temperature(day.maxTemp)}',
                  style: temperatureStyle,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              WeatherGlyph(
                condition: WeatherData(currentConditionCode: code).getCondition(),
                pack: appearance.weatherIconPack,
                size: detailed ? 18 : 24,
                color: appearance.weatherIconColor ?? dataStyle.color ?? inherited.color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  detailed
                      ? condition
                      : '${temperature(day.minTemp)} / ${temperature(day.maxTemp)}',
                  style: dataStyle,
                ),
              ),
              if (detailed) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${l.weatherPrecipitation}: ${day.precipProbability == null ? '—' : '${day.precipProbability}%'}',
                    style: small,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
