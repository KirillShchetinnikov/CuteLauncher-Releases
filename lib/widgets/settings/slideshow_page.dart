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
            title: Text(l.slideshowFolder),
            trailing: Text(s.folder.isEmpty ? l.settingsValueNotSet : s.folder, overflow: TextOverflow.ellipsis),
            leading: const Icon(Icons.folder_open),
            onPressed: () async {
              try {
                await s.pickFolder();
              } catch (_) {
                if (context.mounted) {
                  showActionNotice(context, l.slideshowError, error: true);
                }
              }
            },
          ),
          SettingsHelp(text: s.folder.isEmpty ? l.slideshowFolderRequired : l.slideshowFolderSelected),
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
          SettingsHelp(text: l.slideshowHint),
          ResetStyleTile(onReset: s.reset),
        ],
      ),
    );
  }
}
