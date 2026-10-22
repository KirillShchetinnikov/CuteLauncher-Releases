import 'reset_style_tile.dart';
import '../../providers/slideshow_service.dart';
import 'package:flauncher/widgets/action_notice.dart';
import 'settings_route.dart';
import 'settings_page_layout.dart';
import 'settings_choice_tile.dart';
import 'settings_help.dart';
/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import '../../image_limits.dart';

import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/gradient_panel_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/l10n/app_localizations.dart';

import '../../providers/online_wallpaper_service.dart';
import 'online_wallpaper_page.dart';
import 'wallpaper_display_page.dart';
import 'slideshow_page.dart';
import 'landscape_page.dart';

class WallpaperPanelPage extends StatelessWidget {
  static const String routeName = 'wallpaper_panel';
  final bool parameters;
  const WallpaperPanelPage({super.key, this.parameters = false});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    final source = settings.backgroundSource;
    final sources = {
      'gradient': l.gradient,
      'picture': l.picture,
      'scheduled': l.timeBasedWallpaper,
      'online': l.onlineWallpaper,
      'slideshow': l.wallpaperSlideshow,
      'app': l.appArtworkBackground,
      'landscape': l.adaptiveLandscape,
    };
    return SettingsPageLayout(
      title: Text(
        parameters ? l.backgroundParameters : l.background,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      child: ListView(
        children: [
          if (!parameters) ...[
            SettingsChoiceTile<String>(
                autofocus: true,
                title: l.backgroundSource,
                value: source,
                options: sources.keys.toList(),
                label: (value) => sources[value]!,
                onChanged: (value) async {
                  final online = context.read<OnlineWallpaperService>();
                  final c = online.configuration;
                  await settings.setBackgroundSource(value);
                  await online.configure(
                    c.copyWith(
                      enabled: value == 'online',
                      source: c.validUrl ? c.source : 'bing',
                    ),
                  );
                },
              ),
            const Divider(),
            if (source == 'app') SettingsHelp(text: l.appArtworkBackgroundHelp),
            FocusableSettingsTile(
              title: Text(l.wallpaperDisplay),
              leading: const Icon(Icons.aspect_ratio),
              onPressed: () => Navigator.of(context).push(SettingsRoute<void>(
                builder: (_) => const WallpaperDisplayPage())),
            ),
            FocusableSettingsTile(
              title: Text(l.backgroundParameters),
              leading: const Icon(Icons.tune),
              onPressed: () => Navigator.of(context).push(
                SettingsRoute<void>(
                  builder: (_) => source == 'landscape'
                      ? const LandscapePage()
                      : source == 'app'
                      ? const GradientPanelPage()
                      : source == 'online'
                      ? const OnlineWallpaperPage()
                      : source == 'slideshow'
                      ? const SlideshowPage()
                      : source == 'gradient'
                      ? const GradientPanelPage()
                      : const WallpaperPanelPage(parameters: true),
                ),
              ),
            ),
          ] else ...[
            if (source == 'scheduled') ...[
              FocusableSettingsTile(
                autofocus: true,
                title: Text(l.pickDayWallpaper),
                leading: const Icon(Icons.wb_sunny),
                onPressed: () =>
                    _pickWallpaper(context, (s) => s.pickWallpaperDay(), l),
              ),
              FocusableSettingsTile(
                title: Text(l.pickNightWallpaper),
                leading: const Icon(Icons.nights_stay),
                onPressed: () =>
                    _pickWallpaper(context, (s) => s.pickWallpaperNight(), l),
              ),
            ] else
              FocusableSettingsTile(
                autofocus: true,
                title: Text(l.openImage),
                leading: const Icon(Icons.insert_drive_file_outlined),
                onPressed: () =>
                    _pickWallpaper(context, (s) => s.pickWallpaper(), l),
              ),
          ],
          ResetStyleTile(onReset: () async {
            final wallpaper = context.read<WallpaperService?>();
            if (parameters) {
              await wallpaper?.reset();
              return;
            }
            final online = context.read<OnlineWallpaperService>();
            final slideshow = context.read<SlideshowService?>();
            await settings.resetAppearanceSection('background');
            await settings.setBackgroundSource('gradient');
            await online.configure(const OnlineWallpaperConfiguration());
            await slideshow?.reset();
            await wallpaper?.reset();
          }),
        ],
      ),
    );
  }

  Future<void> _pickWallpaper(
    BuildContext context,
    Future<void> Function(WallpaperService) action,
    AppLocalizations localizations,
  ) async {
    try {
      await action(context.read<WallpaperService>());
    } on ImageInputException {
      if (!context.mounted) return;
      showActionNotice(context, localizations.imageInputRejected, error: true);
    } on PlatformException {
      if (!context.mounted) return;
      showActionNotice(context, localizations.wallpaperChangeFailed, error: true);
    } on NoFileExplorerException {
      if (!context.mounted) return;
      showActionNotice(context, localizations.dialogTextNoFileExplorer,
          error: true, duration: const Duration(seconds: 8));
    }
  }
}
