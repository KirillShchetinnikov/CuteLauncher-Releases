import 'settings_help.dart';
import 'reset_style_tile.dart';

import 'package:flauncher/widgets/action_notice.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/slideshow_service.dart';
import '../rounded_switch_list_tile.dart';
import 'focusable_settings_tile.dart';
import 'settings_page_layout.dart';
import 'settings_value_stepper.dart';
import '../../bridge_result.dart';
import 'local_file_browser.dart';
import '../file_selection.dart';

class SlideshowPage extends StatelessWidget {
  const SlideshowPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = context.watch<SlideshowService>();
    return SettingsPageLayout(
      title: Text(
        l.wallpaperSlideshow,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      child: ListView(
        children: [
          FocusableSettingsTile(
            autofocus: true,
            title: Text(l.slideshowBrowseFolders),
            trailing: Text(
              s.folder.isEmpty ? l.settingsValueNotSet : s.folder,
              overflow: TextOverflow.ellipsis,
            ),
            leading: const Icon(Icons.folder_open),
            onPressed: () => _localFolder(context, s),
          ),
          FocusableSettingsTile(
            title: Text(l.slideshowEnterFolderPath),
            leading: const Icon(Icons.edit),
            onPressed: () => _localFolder(context, s, manual: true),
          ),
          if (s.folder.isEmpty) Text(l.slideshowFolderRequired),
          RoundedSwitchListTile(
            value: s.recursive,
            title: Text(l.slideshowRecursive),
            onChanged: (v) => s.configure(recursive: v),
          ),
          RoundedSwitchListTile(
            value: s.randomOrder,
            title: Text(l.slideshowRandom),
            onChanged: (v) => s.configure(randomOrder: v),
          ),
          SettingsValueStepper(
            title: l.slideshowInterval,
            options: const [30, 60, 300, 600, 1800, 3600],
            value: s.interval,
            label: (v) => '$v ${l.slideshowSeconds}',
            onChanged: (v) => s.configure(interval: v as int),
          ),
          FocusableSettingsTile(
            leading: const Icon(Icons.skip_next),
            title: Text(l.slideshowNext),
            onPressed: s.loading ? null : s.advance,
          ),
          if (s.loading) const LinearProgressIndicator(),
          if (s.failed)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l.slideshowError),
            ),
          SettingsHelp(title: l.wallpaperSlideshow,
            text: '${l.slideshowStorageHelp}\n\n${l.slideshowHint}'),
          ResetStyleTile(onReset: s.reset),
        ],
      ),
    );
  }

  Future<void> _localFolder(
    BuildContext context,
    SlideshowService service, {
    bool manual = false,
  }) async {
    final l = AppLocalizations.of(context)!;
    try {
      String? path;
      if (service.folder.startsWith('file:')) {
        path = Uri.parse(service.folder).toFilePath(windows: false);
      }
      if (manual) {
        path = await enterWallpaperFolderPath(
          context,
          path ?? '/storage/emulated/0/Pictures',
        );
        if (path == null || !context.mounted) return;
      }
      if (manual) {
        final granted = await wallpaperFolderChannel.invokeMethod<bool>(
          'requestFileStorage',
          {'write': false},
        );
        if (!context.mounted) return;
        if (granted != true) {
          showActionNotice(context, l.slideshowStoragePermission, error: true);
          return;
        }
      }
      if (manual) {
        final folder = await wallpaperFolderChannel
            .invokeMapMethod<String, dynamic>('browseLocalFiles', {
              'path': path,
              'kind': 'folder',
            });
        if (folder != null && context.mounted) {
          await service.setFolder(folder['uri'] as String);
        }
      } else {
        final folder = await FileSelection.select<String>(
          context,
          'pickWallpaperFolder',
          initialPath: path,
        );
        if (folder != null && context.mounted) await service.setFolder(folder);
      }
    } catch (error) {
      if (context.mounted) {
        showActionNotice(
          context,
          error is BridgeException && error.status == BridgeStatus.denied
              ? l.slideshowStoragePermission
              : l.slideshowFolderUnavailable,
          error: true,
        );
      }
    }
  }
}
