import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../information_formats.dart';
import '../../information_placement.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/appearance_service.dart';
import '../../providers/settings_service.dart';
import '../../providers/weather_service.dart';
import '../action_notice.dart';
import '../launcher_dialog.dart';
import 'focusable_settings_tile.dart';
import 'information_preview.dart';
import 'settings_panel_presentation.dart';
import 'weather_text_format_dialog.dart';

class InformationWeatherFormatTile extends StatelessWidget {
  const InformationWeatherFormatTile({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    final options = settings.informationWeather();
    final appearance = context.watch<AppearanceService>().appearance;
    final background = InformationPlacement(
      appearance,
      settings,
    ).onBackground('weather');
    final composition = InformationPanelComposition(appearance, settings);
    return FocusableSettingsTile(
      title: Text(l.weatherTextFormat),
      valueIcon: Icons.edit_outlined,
      onPressed: () async {
        final result = await SettingsPanelPresentation.runHidden(
          context,
          () => showLauncherDialog<WeatherDisplayOptions>(
            context: context,
            parentPanelHidden: true,
            parentPanelWidth: 0,
            builder: (_) => WeatherTextFormatDialog(
              background: background,
              format: options.format,
              fahrenheit: options.fahrenheit,
              warnings: options.warnings,
              weather: context.read<WeatherService?>()?.weatherData,
              singleLine:
                  !background &&
                  composition.combined &&
                  composition.members.contains('date'),
              previewBuilder: (options, compact) => InformationPreview(
                background: background,
                dense: true,
                compact: compact,
                weatherOptions: options,
              ),
            ),
          ),
        );
        if (result == null || !context.mounted) return;
        try {
          await settings.setInformationWeather(result);
        } catch (_) {
          if (context.mounted) {
            showActionNotice(context, l.weatherTextSaveError, error: true);
          }
        }
      },
    );
  }
}
