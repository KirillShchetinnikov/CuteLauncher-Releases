import 'settings_help.dart';
import 'reset_style_tile.dart';
import '../remote_text_input.dart';

import 'package:flauncher/widgets/launcher_dialog.dart';

import 'settings_choice_tile.dart';

import 'package:flauncher/widgets/action_notice.dart';

import 'settings_page_layout.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/online_wallpaper_service.dart';
import '../../reddit_wallpaper.dart';
import 'focusable_settings_tile.dart';

class OnlineWallpaperPage extends StatelessWidget {
  static const routeName = 'online_wallpaper_panel';
  const OnlineWallpaperPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<OnlineWallpaperService>();
    final config = service.configuration;
    return SettingsPageLayout(
      title: Text(
        l.onlineWallpaper,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SettingsChoiceTile<String>(
            autofocus: true,
            title: l.onlineWallpaperSource,
            value: config.source,
            options: const ['bing', 'url', if (redditWallpapersAvailable) 'reddit'],
            enabled: !service.loading,
            label: (v) =>
                v == 'reddit' ? 'Reddit' : v == 'bing' ? l.bingWallpaper : l.onlineWallpaperUrlSource,
            onChanged: (v) => service.configure(config.copyWith(source: v)),
          ),
          if (config.source == 'url')
            FocusableSettingsTile(
              title: Text(l.onlineWallpaperAddress),
              trailing: Text(
                config.url.isEmpty ? l.settingsValueNotSet : config.url,
                overflow: TextOverflow.ellipsis,
              ),
              valueIcon: Icons.edit_outlined,
              enabled: !service.loading,
              onPressed: () => _source(context, service),
            ),
          if (redditWallpapersAvailable && config.source == 'reddit') ...[
            SettingsChoiceTile<String>(
              title: l.redditWallpaperTheme,
              value: config.redditTheme,
              options: redditWallpaperThemes.keys.toList(),
              enabled: !service.loading,
              valueBelow: true,
              label: (v) => '${switch (v) {
                'nature' => l.redditThemeNature,
                'space' => l.redditThemeSpace,
                'city' => l.redditThemeCity,
                'minimal' => l.redditThemeMinimal,
                _ => l.redditThemeAll,
              }} · r/${redditWallpaperThemes[v]}',
              onChanged: (v) => service.configure(config.copyWith(redditTheme: v)),
            ),
            SettingsChoiceTile<String>(
              title: l.redditWallpaperResolution,
              value: config.redditResolution,
              options: redditWallpaperResolutions,
              enabled: !service.loading,
              valueBelow: true,
              label: (v) => switch (v) {
                'hd' => 'HD · 1280 × 720',
                '4k' => '4K · 3840 × 2160',
                _ => 'Full HD · 1920 × 1080',
              },
              onChanged: (v) => service.configure(config.copyWith(redditResolution: v)),
            ),
            SettingsChoiceTile<int>(
              title: l.onlineWallpaperInterval,
              value: config.intervalHours,
              options: const [1, 6, 12, 24],
              enabled: !service.loading,
              label: (v) => '$v ${l.onlineWallpaperHours}',
              onChanged: (v) => service.configure(config.copyWith(intervalHours: v)),
            ),
          ],
          FocusableSettingsTile(
            leading: const Icon(Icons.refresh),
            title: Text(l.weatherRefresh),
            onPressed: service.loading || !config.enabled
                ? null
                : () async {
                    if (!config.validUrl) {
                      showActionNotice(
                        context,
                        l.onlineWallpaperUrlError,
                        error: true,
                      );
                      return;
                    }
                    try {
                      await service.refresh(force: true);
                      if (!context.mounted) return;
                      showActionNotice(
                        context,
                        service.failed
                            ? l.onlineWallpaperError
                            : l.actionCompleted,
                        error: service.failed,
                      );
                    } catch (_) {
                      if (context.mounted) {
                        showActionNotice(
                          context,
                          l.onlineWallpaperError,
                          error: true,
                        );
                      }
                    }
                  },
          ),
          if (service.loading) const LinearProgressIndicator(),
          if (service.failed)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(l.onlineWallpaperError),
            ),
          SettingsHelp(text: [
            if (config.source == 'bing' && service.copyright.isNotEmpty)
              service.copyright,
            config.source == 'reddit' ? l.redditWallpaperHint : l.onlineWallpaperHint,
          ].join('\n\n')),
          ResetStyleTile(onReset: () => service.configure(OnlineWallpaperConfiguration(
            enabled: config.enabled, source: 'bing'))),
        ],
      ),
    );
  }

  Future<void> _source(
    BuildContext context,
    OnlineWallpaperService service,
  ) async {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: service.configuration.url);
    String? error;
    try {
      final url = await showLauncherDialog<String>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setState) => LauncherAlertDialog(
            title: Text(l.onlineWallpaperSource),
            content: RemoteTextInput(
              child: TextField(
                autofocus: true,
                controller: controller,
                maxLength: 2048,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: l.onlineWallpaperAddress,
                  errorText: error,
                  errorMaxLines: 3,
                ),
              ),
            ),
            actions: [
              LauncherDialogButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
              LauncherDialogButton(
                primary: true,
                onPressed: () {
                  final value = controller.text.trim();
                  if (!OnlineWallpaperConfiguration(url: value).validUrl) {
                    setState(() => error = l.onlineWallpaperUrlError);
                    return;
                  }
                  Navigator.pop(dialogContext, value);
                },
                child: Text(MaterialLocalizations.of(context).okButtonLabel),
              ),
            ],
          ),
        ),
      );
      if (url != null) {
        await service.configure(
          OnlineWallpaperConfiguration(
            enabled: service.configuration.enabled,
            url: url,
            intervalHours: service.configuration.intervalHours,
            redditTheme: service.configuration.redditTheme,
            redditResolution: service.configuration.redditResolution,
          ),
        );
      }
    } finally {
      controller.dispose();
    }
  }
}
