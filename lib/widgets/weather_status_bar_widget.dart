import 'top_panel_item.dart';
import 'weather_display_text.dart';
import 'weather_glyph.dart';
import 'home_skeleton.dart';

import 'package:flauncher/weather_text_format.dart';
import 'package:flauncher/weather_warning_text.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/models/weather_data.dart';
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
    return Selector<SettingsService, (bool, bool, bool, WeatherTextFormat, bool, String)>(
      selector: (_, settings) => (
        settings.showWeatherInStatusBar,
        settings.showWeatherWarnings,
        settings.useFahrenheit,
        settings.weatherTextFormat,
        settings.informationWeather().missingAsDash,
        settings.informationWeather().panelAlignment,
      ),
      builder: (context, settingsTuple, _) {
        final (showWeather, showWarnings, useFahrenheit, format, missingAsDash, alignment) = settingsTuple;
        if (!(widget.showWeather ?? showWeather)) return const SizedBox.shrink();

        return Consumer<WeatherService>(
          builder: (context, weatherService, _) {
            final weather = weatherService.weatherData;
            final appearance = topPanelAppearance(context);
            final base = widget.textStyle ?? appearance.panelTextStyleFor(Localizations.localeOf(context));
            final textStyle = appearance.weatherTextStyle(base);
            final icon = WeatherGlyph(
              condition: weather?.getCondition() ?? WeatherCondition.unknown,
              pack: appearance.weatherIconPack,
              size: base.fontSize,
              color: appearance.weatherIconColor ?? textStyle.color,
              shadows: base.shadows,
            );
            if (weather == null && format.isStandard) {
              return TopPanelItem(textStyle: widget.textStyle, focusNode: widget.focusNode, selected: widget.selected,
                onPressed: widget.onPressed, child: Row(mainAxisSize: MainAxisSize.min,
                  children: [icon, const SizedBox(width: 8),
                    HomeSkeletonValue(sample: '−99°', style: textStyle,
                      loading: !weatherService.initialized || weatherService.loading,
                      child: Text('—', style: textStyle))]));
            }

            final bool isWarning =
                !format.explicitLayout && showWarnings && weather?.hasWarning == true && !weatherService.stale;

            final l10n = AppLocalizations.of(context);
            final warning = isWarning && weather != null
                ? (l10n == null ? weather.warningText : localizedWeatherWarning(weather, l10n, DateTime.now()))
                : null;
            final displayText = [
              format.format(weather, l10n, fahrenheit: useFahrenheit, missingAsDash: missingAsDash, warningsAvailable: !weatherService.stale),
              ?warning,
            ].join(' • ');

            return TopPanelItem(
              textStyle: format.isStandard ? widget.textStyle : base,
              focusNode: widget.focusNode,
              selected: widget.selected,
              onPressed: widget.onPressed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                textDirection: TextDirection.ltr,
                children: [
                  if (!format.explicitLayout) ...[icon, const SizedBox(width: 8)],
                  if (format.isStandard)
                    HomeSkeletonValue(sample: '−99°', style: textStyle,
                      child: WeatherDisplayText(displayText, alignment: alignment, style: textStyle, inlineIcon: icon, maxWidth: weatherTextMaxWidth(format)))
                  else
                    WeatherDisplayText(displayText, alignment: alignment, style: textStyle, inlineIcon: icon, maxWidth: weatherTextMaxWidth(format)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
