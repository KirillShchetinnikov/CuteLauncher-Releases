import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/video_folder_service.dart';
import '../action_notice.dart';
import 'focusable_settings_tile.dart';
import 'reset_style_tile.dart';
import 'settings_choice_tile.dart';
import 'settings_help.dart';
import 'settings_information.dart';
import 'settings_page_layout.dart';
import 'settings_section.dart';
import 'slideshow_page.dart';

class VideoFolderPage extends StatefulWidget {
  const VideoFolderPage({super.key});

  @override
  State<VideoFolderPage> createState() => _VideoFolderPageState();
}

class _VideoFolderPageState extends State<VideoFolderPage> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        showActionNotice(
          context,
          AppLocalizations.of(context)!.videoFolderError,
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<VideoFolderService>();
    final folder = service.folder;
    Future<void> select({bool manual = false}) => _run(
      () => selectWallpaperFolder(
        context,
        folder,
        service.setFolder,
        manual: manual,
        defaultPath: '/storage/emulated/0/Movies',
      ),
    );
    return SettingsPageLayout(
      title: Text(l.videoFolderSource),
      child: ListView(
        children: [
          SettingsSection(
            title: l.settingsGroupSource,
            children: [
              FocusableSettingsTile(
                autofocus: true,
                title: Text(l.slideshowBrowseFolders),
                leading: const Icon(Icons.folder_open),
                trailing: Text(
                  folder.isEmpty
                      ? l.settingsValueNotSet
                      : Uri.decodeFull(folder),
                  overflow: TextOverflow.ellipsis,
                ),
                enabled: !_busy,
                onPressed: () => select(),
              ),
              FocusableSettingsTile(
                title: Text(l.slideshowEnterFolderPath),
                leading: const Icon(Icons.edit),
                enabled: !_busy,
                onPressed: () => select(manual: true),
              ),
            ],
          ),
          SettingsSection(
            title: l.videoFolderPlayback,
            children: [
              SettingsChoiceTile<VideoFolderOrder>(
                title: l.fileBrowserSort,
                value: service.order,
                options: VideoFolderOrder.values,
                label: (order) => switch (order) {
                  VideoFolderOrder.name => l.fileBrowserSortName,
                  VideoFolderOrder.date => l.fileBrowserSortDate,
                  VideoFolderOrder.random => l.slideshowRandom,
                },
                enabled: !_busy,
                onChanged: (value) => _run(() => service.setOrder(value)),
              ),
              FocusableSettingsTile(
                leading: const Icon(Icons.skip_next),
                title: Text(l.videoFolderNext),
                enabled: !_busy && service.canAdvance,
                onPressed: service.next,
              ),
              if (service.loading) const LinearProgressIndicator(),
              if (service.failed)
                SettingsMessage(
                  text: l.videoFolderError,
                  kind: SettingsMessageKind.error,
                ),
            ],
          ),
          SettingsHelp(
            title: l.videoFolderSource,
            text: '${l.videoFolderHelp}\n\n${l.slideshowStorageHelp}',
          ),
          ResetStyleTile(onReset: () => _run(service.reset)),
        ],
      ),
    );
  }
}
