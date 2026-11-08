import 'settings_choice_dialog.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/weather_data.dart';
import '../../providers/appearance_service.dart';
import '../../tile_appearance.dart';
import '../launcher_dialog.dart';
import '../weather_glyph.dart';
import 'color_palette_dialog.dart';
import 'focusable_settings_tile.dart';
import 'settings_color_swatch.dart';

class WeatherAppearanceOptions extends StatelessWidget {
  const WeatherAppearanceOptions({
    super.key,
    required this.service,
    required this.appearance,
    this.background = false,
  });

  final AppearanceService service;
  final TileAppearance appearance;
  final bool background;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final base = (background ? appearance.backgroundInformationStyle : appearance.informationStyle).textStyle(
      appearance.panelTextStyleFor(locale),
      locale: locale,
    );
    final weatherText =
        appearance.weatherTextStyle(base).color ?? appearance.panelTextColor;
    final glyphColor = appearance.weatherIconColor ?? weatherText;

    String label(WeatherIconPack pack) => switch (pack) {
      WeatherIconPack.standard => l.weatherIconsStandard,
      WeatherIconPack.outline => l.weatherIconsOutline,
      WeatherIconPack.solid => l.weatherIconsSolid,
      WeatherIconPack.duotone => l.weatherIconsDuotone,
      WeatherIconPack.pixel => l.weatherIconsPixel,
      WeatherIconPack.geometric => l.weatherIconsGeometric,
      WeatherIconPack.circled => l.weatherIconsCircled,
    };

    Widget colorRow(
      String title,
      String key,
      Color? value,
      Color effective,
      String inheritLabel,
    ) {
      return FocusableSettingsTile(
        title: Text(title),
        trailing: SettingsColorSwatch(
          color: effective,
          inherited: value == null,
          tooltip: value == null ? inheritLabel : title,
        ),
        onPressed: () async {
          final picked = await showLauncherDialog<(int?,)>(
            context: context,
            builder: (_) => ColorPaletteDialog(
              title: title,
              current: value?.toARGB32(),
              allowDefault: true,
              defaultLabel: inheritLabel,
            ),
          );
          if (picked != null && context.mounted) {
            await service.setInformationAppearance(key, picked.$1, background: background);
          }
        },
      );
    }

    return Column(
      children: [
        FocusableSettingsTile(
          title: Text(l.weatherIconPack),
          trailing: Text(label(appearance.weatherIconPack)),
          onPressed: () async {
            final selected = await showLauncherDialog<WeatherIconPack>(
              context: context,
              builder: (_) => _WeatherIconPackDialog(
                selected: appearance.weatherIconPack,
                color: glyphColor,
                label: label,
              ),
            );
            if (selected != null && context.mounted) {
              await service.setInformationAppearance('weatherIconPack', selected.name, background: background);
            }
          },
        ),
        colorRow(
          l.weatherTextColor,
          'weatherTextColor',
          appearance.weatherTextColor,
          weatherText,
          l.defaultOption,
        ),
        colorRow(
          l.weatherIconColor,
          'weatherIconColor',
          appearance.weatherIconColor,
          glyphColor,
          l.weatherIconFollowsText,
        ),
      ],
    );
  }
}

class _WeatherIconPackDialog extends StatelessWidget {
  const _WeatherIconPackDialog({
    required this.selected,
    required this.color,
    required this.label,
  });
  final WeatherIconPack selected;
  final Color color;
  final String Function(WeatherIconPack) label;

  @override
  Widget build(BuildContext context) => SettingsChoiceDialog<WeatherIconPack>(
    title: Text(AppLocalizations.of(context)!.weatherIconPack),
    value: selected,
    options: WeatherIconPack.values,
    optionBuilder: (pack) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(label(pack)),
        _IconPackSample(pack: pack, color: color),
      ],
    ),
    onSelected: (pack) => Navigator.pop(context, pack),
    actions: [
      LauncherDialogButton(
        onPressed: () => Navigator.pop(context),
        child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
      ),
    ],
  );
}

class _IconPackSample extends StatelessWidget {
  const _IconPackSample({required this.pack, required this.color});

  final WeatherIconPack pack;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.computeLuminance() > .3
          ? const Color(0xff242935)
          : const Color(0xffedf0f8),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          for (final condition in const [
            WeatherCondition.sun,
            WeatherCondition.moon,
            WeatherCondition.partlyCloudy,
            WeatherCondition.rain,
            WeatherCondition.snow,
          ])
            WeatherGlyph(
              condition: condition,
              pack: pack,
              size: 20,
              color: color,
            ),
        ],
      ),
    ),
  );
}
