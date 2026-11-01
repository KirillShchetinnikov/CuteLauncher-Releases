import 'top_panel_item.dart';

import 'package:flauncher/weather_warning_text.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WeatherStatusBarWidget extends StatefulWidget {
  final bool? showWeather;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final bool selected;
  final TextStyle? textStyle;
  const WeatherStatusBarWidget({super.key, this.showWeather, this.onPressed,
    this.focusNode, this.selected = false, this.textStyle});

  @override
  State<WeatherStatusBarWidget> createState() => _WeatherStatusBarWidgetState();
}

class _WeatherStatusBarWidgetState extends State<WeatherStatusBarWidget> {
  @override
  Widget build(BuildContext context) {
    return Selector<SettingsService, (bool, bool, bool)>(
      selector: (_, settings) => (
        settings.showWeatherInStatusBar,
        settings.showWeatherWarnings,
        settings.useFahrenheit,
      ),
      builder: (context, settingsTuple, _) {
        final (showWeather, showWarnings, useFahrenheit) = settingsTuple;
        if (!(widget.showWeather ?? showWeather)) return const SizedBox.shrink();

        return Consumer<WeatherService>(
          builder: (context, weatherService, _) {
            final weather = weatherService.weatherData;
            if (weather == null) {
              return TopPanelItem(textStyle: widget.textStyle, focusNode: widget.focusNode, selected: widget.selected,
                onPressed: widget.onPressed, child: const Icon(Icons.cloud_outlined));
            }

            final bool isWarning =
                showWarnings && weather.hasWarning && !weatherService.stale;
            final icon = weather.getConditionIcon();
            final tempText = weather.formatTemperature(
              useFahrenheit: useFahrenheit,
            );

            final l10n = AppLocalizations.of(context);
            final warning = l10n == null
                ? weather.warningText
                : localizedWeatherWarning(weather, l10n, DateTime.now());
            String displayText;
            if (isWarning && warning != null) {
              displayText = "$tempText • $warning";
            } else {
              displayText = tempText;
            }

            final appearance = topPanelAppearance(context);
            return TopPanelItem(
              textStyle: widget.textStyle,
              focusNode: widget.focusNode,
              selected: widget.selected,
              onPressed: widget.onPressed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                textDirection: TextDirection.ltr,
                children: [
                  Icon(
                    icon,
                    size: widget.textStyle?.fontSize ?? appearance.panelTextSize,
                    color: widget.textStyle?.color ?? appearance.panelTextColor,
                    shadows: widget.textStyle?.shadows,
                  ),
                  const SizedBox(width: 8),
                  Text(displayText, style: widget.textStyle ?? appearance.panelTextStyleFor(Localizations.localeOf(context))),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
