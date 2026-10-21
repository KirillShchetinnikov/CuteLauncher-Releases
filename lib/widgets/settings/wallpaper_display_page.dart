import 'reset_style_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/settings_service.dart';
import 'settings_page_layout.dart';
import 'settings_value_stepper.dart';

class WallpaperDisplayPage extends StatelessWidget {
  const WallpaperDisplayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = context.watch<SettingsService>();
    final modes = {
      'cover': l.wallpaperCover,
      'contain': l.wallpaperContain,
      if (!s.memorySaverEnabled) 'blurred': l.wallpaperBlurred,
    };
    return SettingsPageLayout(
      title: Text(
        l.wallpaperDisplay,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      child: ListView(
        children: [
          if (s.backgroundSource != 'app') SettingsValueStepper(
            title: l.wallpaperPlacement,
            valueBelow: true,
            autofocus: true,
            options: modes.keys.toList(),
            value: s.memorySaverEnabled && s.wallpaperFit == 'blurred'
                ? 'contain'
                : s.wallpaperFit,
            label: (v) => modes[v]!,
            onChanged: (v) => s.setWallpaperFit(v as String),
          ),
          for (final item in [
            (
              'wallpaper_brightness',
              l.wallpaperBrightness,
              s.wallpaperBrightness,
            ),
            (
              'wallpaper_saturation',
              l.wallpaperSaturation,
              s.wallpaperSaturation,
            ),
            ('wallpaper_dimming', l.wallpaperDimming, s.wallpaperDimming),
          ])
            SettingsValueStepper(
              title: item.$2,
              options: [for (var i = 0; i <= 20; i++) i / 10],
              value: item.$3,
              label: (v) => '${((v as num) * 100).round()}%',
              onChanged: (v) =>
                  s.setWallpaperAdjustment(item.$1, (v as num).toDouble()),
            ),
          ResetStyleTile(onReset: () => s.resetAppearanceSection('wallpaperDisplay')),
        ],
      ),
    );
  }
}
