import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../background_information_geometry.dart';
import '../../information_placement.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/appearance_service.dart';
import '../../providers/settings_service.dart';
import 'settings_slider_tile.dart';

/// Live limits use the same measured content and fixed anchor as the wallpaper.
class BackgroundInformationLayoutControl extends StatelessWidget {
  final bool sizeControl;
  const BackgroundInformationLayoutControl.size({super.key})
    : sizeControl = true;
  const BackgroundInformationLayoutControl.verticalOffset({super.key})
    : sizeControl = false;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AppearanceService>();
    final appearance = service.appearance;
    final settings = context.watch<SettingsService>();
    final l = AppLocalizations.of(context)!;
    final screen = MediaQuery.sizeOf(context);
    final geometry = BackgroundInformationGeometry(
      screen,
      appearance.backgroundInformationVerticalOffset,
    );
    return ValueListenableBuilder<BackgroundInformationMetrics?>(
      valueListenable: service.backgroundInformationMetrics,
      builder: (context, metrics, _) {
        final placement = InformationPlacement(appearance, settings);
        var members = InformationPlacement.ids
            .where(placement.onBackground)
            .toSet();
        if (members.isEmpty) members = InformationPlacement.ids.toSet();
        final textScale = MediaQuery.textScalerOf(context).scale(96) / 96;
        final fallback = Size(
          16 + 96 * 3.2 * textScale,
          16 +
              members.fold<double>(
                0,
                (height, id) =>
                    height +
                    (id == 'time' ? 96 * 1.1 : 96 * .27 * 1.3) * textScale,
              ),
        );
        final natural = metrics?.screen == screen ? metrics!.natural : fallback;
        final maximumScale = natural.isEmpty
            ? 0.0
            : math.max(
                0.0,
                math.min(
                  (screen.width - 48) / natural.width,
                  geometry.availableHeight / natural.height,
                ),
              );
        final maximum = (maximumScale * 96 + .000001).floor().clamp(
          0,
          BackgroundInformationGeometry.maximumStoredSize,
        );
        final value = appearance.backgroundInformationSize
            .clamp(0, maximum)
            .floor();
        if (sizeControl) {
          final first = math.min(48, maximum);
          final options = <int>{
            for (var size = first; size <= maximum; size += 4) size,
            value,
            maximum,
          }.toList()..sort();
          return SettingsSliderTile(
            title: l.informationSize,
            value: value,
            options: options,
            enabled: maximum > 0 && options.length > 1,
            label: (value) => '${value.round()}',
            sliderTextDirection: TextDirection.ltr,
            onChanged: (value) =>
                service.set('panelBackgroundInformationSize', value),
          );
        }
        final renderedHeight =
            natural.height *
            math.min(appearance.backgroundInformationSize / 96, maximumScale);
        final maximumOffset = geometry.maximumOffsetForHeight(renderedHeight);
        final offset = appearance.backgroundInformationVerticalOffset
            .clamp(0, maximumOffset)
            .round();
        final options = <int>{
          0,
          offset,
          maximumOffset,
          for (var offset = 0; offset <= maximumOffset; offset += 5) offset,
        }.toList()..sort();
        return SettingsSliderTile(
          title: l.informationBackgroundVerticalOffset,
          value: offset,
          options: options,
          enabled: maximum > 0 && options.length > 1,
          label: (value) => '${value.round()}%',
          sliderTextDirection: TextDirection.ltr,
          onChanged: service.setBackgroundInformationVerticalOffset,
        );
      },
    );
  }
}
