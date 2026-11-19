import '../../theme/interface_style.dart';
import '../../theme/launcher_style.dart';
import 'settings_choice_tile.dart';

import 'package:flauncher/widgets/launcher_dialog.dart';

import '../../providers/wallpaper_service.dart';
import 'settings_page_layout.dart';
import '../../providers/slideshow_service.dart';
import '../../providers/video_folder_service.dart';
import '../../providers/settings_service.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/l10n/app_localizations.dart';

import '../../providers/appearance_service.dart';
import 'focusable_settings_tile.dart';
import '../../providers/online_wallpaper_service.dart';
import 'settings_style_page.dart';

class InterfaceStyleChoice extends StatelessWidget {
  const InterfaceStyleChoice({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<AppearanceService>();
    final appearance = service.appearance;
    return SettingsChoiceTile<String>(
      title: l.interfaceStyle,
      value: appearance.interfaceStyle,
      options: const ['standard', 'glass', 'soft', 'outline', 'calm'],
      label: (id) => switch (id) {
        'glass' => l.interfaceGlass,
        'soft' => l.interfaceSoft,
        'outline' => l.interfaceOutline,
        'calm' => l.interfaceCalm,
        _ => l.interfaceStandard,
      },
      decorateOption: (id, row) => Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final skin = InterfaceSkin(interfaceStyleFrom(id));
          return Theme(
            data: theme.copyWith(
              extensions: [
                ...theme.extensions.values,
                skin,
                LauncherStyle.of(context).copyWith(rowRadius: skin.radius),
              ],
            ),
            child: row,
          );
        },
      ),
      onChanged: (v) => service.set('settingsInterfaceStyle', v),
    );
  }
}

class AppearanceSettingsPage extends StatelessWidget {
  static const routeName = 'appearance_settings';
  const AppearanceSettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SettingsPageLayout(
      title: Text(l.appearanceSettings),
      child: ListView(children: appearanceSettingsTiles(context)),
    );
  }
}

List<Widget> appearanceSettingsTiles(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  return [
    FocusableSettingsTile(
      leading: const Icon(Icons.palette_outlined),
      title: Text(l.settingsStyle),
      onPressed: () =>
          Navigator.of(context).pushNamed(SettingsStylePage.routeName),
    ),
    FocusableSettingsTile(
      leading: const Icon(Icons.notifications_outlined),
      title: Text(l.notificationStyle),
      onPressed: () =>
          Navigator.of(context)
              .pushNamed(SettingsStylePage.notificationsRouteName),
    ),
    FocusableSettingsTile(
      leading: const Icon(Icons.restore),
      trailing: const SizedBox.shrink(),
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
          final videos = context.read<VideoFolderService?>();
          await service.reset();
          await settings.resetAppearanceSettings();
          await slideshow?.reset();
          await videos?.reset(all: true);
          await online.configure(const OnlineWallpaperConfiguration());
          await wallpaper?.reset();
        }
      },
    ),
  ];
}
