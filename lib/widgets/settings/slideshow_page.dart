import 'settings_information.dart';
import 'settings_section.dart';
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
          SettingsSection(
            key: const ValueKey('settingsGroupSource'),
            title: l.settingsGroupSource,
            children: [
              FocusableSettingsTile(
                autofocus: true,
                title: Text(l.slideshowBrowseFolders),
                trailing: Text(
                  s.folder.isEmpty ? l.settingsValueNotSet : s.folder,
                  overflow: TextOverflow.ellipsis,
                ),
                leading: const Icon(Icons.folder_open),
                onPressed: () =>
                    selectWallpaperFolder(context, s.folder, s.setFolder),
              ),
              FocusableSettingsTile(
                title: Text(l.slideshowEnterFolderPath),
                leading: const Icon(Icons.edit),
                onPressed: () => selectWallpaperFolder(
                  context,
                  s.folder,
                  s.setFolder,
                  manual: true,
                ),
              ),
              if (s.folder.isEmpty)
                SettingsMessage(text: l.slideshowFolderRequired),
              RoundedSwitchListTile(
                value: s.recursive,
                title: Text(l.slideshowRecursive),
                onChanged: (v) => s.configure(recursive: v),
              ),
            ],
          ),
          SettingsSection(
            key: const ValueKey('settingsGroupImageChange'),
            title: l.settingsGroupImageChange,
            children: [
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
              SizedBox(
                child: s.loading ? const LinearProgressIndicator() : null,
              ),
              if (s.failed)
                SettingsMessage(
                  text: l.slideshowError,
                  kind: SettingsMessageKind.error,
                ),
            ],
          ),
          SettingsHelp(
            title: l.wallpaperSlideshow,
            text: '${l.slideshowStorageHelp}\n\n${l.slideshowHint}',
          ),
          ResetStyleTile(onReset: s.reset),
        ],
      ),
    );
  }
}

Future<void> selectWallpaperFolder(
  BuildContext context,
  String currentFolder,
  Future<void> Function(String) setFolder, {
  bool manual = false,
  String defaultPath = '/storage/emulated/0/Pictures',
}) async {
  final l = AppLocalizations.of(context)!;
  try {
    String? path;
    if (currentFolder.startsWith('file:')) {
      path = Uri.parse(currentFolder).toFilePath(windows: false);
    }
    if (manual) {
      path = await enterWallpaperFolderPath(context, path ?? defaultPath);
      if (path == null || !context.mounted) return;
    }
    if (manual) {
      final granted = await FileSelection.requestStorage(context, write: false);
      if (!context.mounted) return;
      if (!granted) return;
    }
    if (manual) {
      final folder = await wallpaperFolderChannel
          .invokeMapMethod<String, dynamic>('browseLocalFiles', {
            'path': path,
            'kind': 'folder',
          });
      if (folder != null && context.mounted) {
        await setFolder(folder['uri'] as String);
      }
    } else {
      final folder = await FileSelection.select<String>(
        context,
        'pickWallpaperFolder',
        initialPath: path ?? (currentFolder.isEmpty ? null : currentFolder),
      );
      if (folder != null && context.mounted) await setFolder(folder);
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
