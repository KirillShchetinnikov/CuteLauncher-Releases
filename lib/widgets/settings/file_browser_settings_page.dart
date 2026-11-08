import 'settings_section.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../file_browser_options.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/settings_service.dart';
import '../action_notice.dart';
import '../rounded_switch_list_tile.dart';
import 'settings_choice_tile.dart';
import 'settings_help.dart';
import 'settings_page_layout.dart';

class FileBrowserSettingsPage extends StatefulWidget {
  static const routeName = 'file_browser_settings';
  const FileBrowserSettingsPage({super.key});

  @override
  State<FileBrowserSettingsPage> createState() =>
      _FileBrowserSettingsPageState();
}

class _FileBrowserSettingsPageState extends State<FileBrowserSettingsPage> {
  bool _saving = false;

  Future<void> _save(FileBrowserOptions value) async {
    if (_saving) return;
    _saving = true;
    try {
      await context.read<SettingsService>().setFileBrowserOptions(value);
    } catch (_) {
      if (mounted) {
        showActionNotice(
          context,
          AppLocalizations.of(context)!.fileBrowserSaveFailed,
          error: true,
        );
      }
    } finally {
      _saving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final options = context.select<SettingsService, FileBrowserOptions>(
      (s) => s.fileBrowserOptions,
    );
    return SettingsPageLayout(
      title: Text(l.filePickerBuiltIn),
      child: ListView(
        children: [
          SettingsChoiceTile<FileBrowserStart>(
            title: l.fileBrowserStartFolder,
            value: options.start,
            options: FileBrowserStart.values,
            label: (value) => switch (value) {
              FileBrowserStart.storage => l.fileBrowserStorage,
              FileBrowserStart.downloads => l.fileBrowserDownloads,
              FileBrowserStart.last => l.fileBrowserLastFolder,
            },
            onChanged: (value) => _save(options.copyWith(start: value)),
          ),
          SettingsSection(
            title: l.fileBrowserSort,
            children: [
              SettingsChoiceTile<FileBrowserSort>(
                title: l.fileBrowserSort,
                value: options.sort,
                options: FileBrowserSort.values,
                label: (value) => switch (value) {
                  FileBrowserSort.name => l.fileBrowserSortName,
                  FileBrowserSort.date => l.fileBrowserSortDate,
                  FileBrowserSort.size => l.fileBrowserSortSize,
                },
                onChanged: (value) => _save(options.copyWith(sort: value)),
              ),
              SettingsChoiceTile<bool>(
                title: l.fileBrowserOrder,
                value: options.descending,
                options: const [false, true],
                label: (value) =>
                    value ? l.fileBrowserDescending : l.fileBrowserAscending,
                onChanged: (value) =>
                    _save(options.copyWith(descending: value)),
              ),
              RoundedSwitchListTile(
                title: Text(l.fileBrowserFoldersFirst),
                value: options.foldersFirst,
                onChanged: (value) =>
                    _save(options.copyWith(foldersFirst: value)),
              ),
            ],
          ),
          SettingsSection(
            title: l.settingsGroupDisplay,
            children: [
              RoundedSwitchListTile(
                title: Text(l.fileBrowserShowHidden),
                value: options.showHidden,
                onChanged: (value) =>
                    _save(options.copyWith(showHidden: value)),
              ),
              RoundedSwitchListTile(
                title: Text(l.fileBrowserShowDetails),
                value: options.showDetails,
                onChanged: (value) =>
                    _save(options.copyWith(showDetails: value)),
              ),
            ],
          ),
          SettingsHelp(
            title: l.filePickerBuiltIn,
            text: l.fileBrowserOptionsHelp,
          ),
        ],
      ),
    );
  }
}
