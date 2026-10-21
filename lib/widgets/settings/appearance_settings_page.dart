import 'package:flauncher/widgets/launcher_dialog.dart';

import '../../providers/screensaver_service.dart';
import 'screensaver_clock_style_page.dart';
import '../../providers/wallpaper_service.dart';
import 'settings_page_layout.dart';
import '../../providers/slideshow_service.dart';
import '../../providers/settings_service.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/l10n/app_localizations.dart';

import '../../providers/appearance_service.dart';
import 'focusable_settings_tile.dart';
import 'accent_color_page.dart';
import '../../providers/online_wallpaper_service.dart';
import 'settings_style_page.dart';

class AppearanceSettingsPage extends StatelessWidget {
  static const routeName = 'appearance_settings';
  const AppearanceSettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final screensaver = context.watch<ScreensaverService?>();
    return SettingsPageLayout(
      title: Text(
        l.appearanceSettings,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      child: ListView(
        children: [
          FocusableSettingsTile(
            autofocus: true,
            leading: const Icon(Icons.palette_outlined),
            title: Text(l.accentColor),
            onPressed: () =>
                Navigator.of(context).pushNamed(AccentColorPage.routeName),
          ),
          FocusableSettingsTile(
            leading: const Icon(Icons.tune), title: Text(l.settingsStyle),
            onPressed: () => Navigator.of(context).pushNamed(SettingsStylePage.routeName),
          ),
          FocusableSettingsTile(
            leading: const Icon(Icons.notifications_outlined), title: Text(l.notificationStyle),
            onPressed: () => Navigator.of(context).pushNamed(SettingsStylePage.notificationsRouteName),
          ),
          if (screensaver?.capabilities.canChoose == true) ...[
            FocusableSettingsTile(
              leading: const Icon(Icons.watch_later_outlined),
              title: Text(l.screensaverClockStyle),
              onPressed: () =>
                  Navigator.of(context)
                      .pushNamed(ScreensaverClockStylePage.routeName),
            ),
            FocusableSettingsTile(
              leading: const Icon(Icons.screenshot_monitor),
              title: Text(l.screensaverSettings),
              onPressed: () => screensaver!.openSettings(),
            ),
          ],
          FocusableSettingsTile(
            leading: const Icon(Icons.restore),
            title: Text(l.resetAppearance),
            onPressed: () async {
              final service = context.read<AppearanceService>();
              final confirmed = await showLauncherDialog<bool>(
                context: context,
                builder: (c) => LauncherAlertDialog(
                  title: Text(l.resetAppearance),
                  content: Text(l.resetAppearanceHint),
                  actions: [
                    LauncherDialogButton(
                      autofocus: true,
                      onPressed: () => Navigator.pop(c, false),
                      child: Text(
                        MaterialLocalizations.of(c).cancelButtonLabel,
                      ),
                    ),
                    LauncherDialogButton(
                      primary: true,
                      danger: true,
                      onPressed: () => Navigator.pop(c, true),
                      child: Text(l.resetAppearance),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                final settings = context.read<SettingsService>();
                final online = context.read<OnlineWallpaperService>();
                final wallpaper = context.read<WallpaperService?>();
                final slideshow = context.read<SlideshowService?>();
                await service.reset();
                await settings.resetAppearanceSettings();
                await slideshow?.reset();
                await online.configure(const OnlineWallpaperConfiguration());
                await wallpaper?.reset();
              }
            },
          ),
        ],
      ),
    );
  }
}
