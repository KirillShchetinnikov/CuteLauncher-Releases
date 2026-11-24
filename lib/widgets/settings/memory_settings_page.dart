import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/settings_service.dart';
import '../action_notice.dart';
import '../rounded_switch_list_tile.dart';
import 'focusable_settings_tile.dart';
import 'memory_page.dart';
import 'settings_choice_tile.dart';
import 'settings_help.dart';
import 'settings_page_layout.dart';
import 'settings_route.dart';
import 'settings_section.dart';

Future<void> _save(BuildContext context, Future<void> Function() change) async {
  try {
    await change();
  } catch (_) {
    if (context.mounted) {
      showActionNotice(
        context,
        AppLocalizations.of(context)!.memoryLimitsFailed,
        error: true,
      );
    }
  }
}

class MemorySettingsSection extends StatelessWidget {
  const MemorySettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    return SettingsSection(
      title: l.memoryTitle,
      children: [
        FocusableSettingsTile(
          leading: const Icon(Icons.memory_outlined),
          title: Text(l.memoryUsage),
          onPressed: () =>
              Navigator.of(context).pushNamed(MemoryPage.routeName),
        ),
        FocusableSettingsTile(
          leading: const Icon(Icons.tune),
          title: Text(l.memorySettings),
          onPressed: () =>
              Navigator.of(context).pushNamed(MemorySettingsPage.routeName),
        ),
        RoundedSwitchListTile(
          key: const Key('memory-economy'),
          secondary: const Icon(Icons.eco_outlined),
          title: Text(l.memorySaver),
          value: settings.memorySaverEnabled,
          onChanged: (value) =>
              _save(context, () => settings.setMemorySaverEnabled(value)),
        ),
        SettingsHelp(title: l.memorySaverHelp, text: l.memorySaverDescription),
      ],
    );
  }
}

String _sectionName(AppLocalizations l, PosterCacheSection section) =>
    section == PosterCacheSection.appChannels
    ? l.appChannelsTitle
    : l.continueWatching;

class PosterMemoryLink extends StatelessWidget {
  const PosterMemoryLink(this.section, {super.key, this.fromSection = false});
  final PosterCacheSection section;
  final bool fromSection;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return FocusableSettingsTile(
      title: Text(fromSection ? l.memorySettings : _sectionName(l, section)),
      leading: const Icon(Icons.photo_library_outlined),
      onPressed: () => Navigator.of(context).push(
        SettingsRoute<void>(
          builder: (_) => MemorySettingsPage(section: section),
        ),
      ),
    );
  }
}

class MemorySettingsPage extends StatelessWidget {
  static const routeName = 'memory_settings';
  const MemorySettingsPage({super.key, this.section, this.advanced = false});
  final PosterCacheSection? section;
  final bool advanced;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    final locked = settings.memorySaverEnabled;
    Widget choice(MemoryLimit limit, String title, {bool autofocus = false}) =>
        SettingsChoiceTile<int>(
          title: title,
          enabled: !locked,
          autofocus: autofocus,
          value: settings.memoryLimit(limit),
          options: limit.choices,
          label: (n) {
            final value = MaterialLocalizations.of(context).formatDecimal(n);
            return limit == MemoryLimit.preload
                ? value
                : '$value ${l.memoryUnit}';
          },
          onChanged: (value) =>
              _save(context, () => settings.setMemoryLimit(limit, value)),
        );
    final group = section;
    return SettingsPageLayout(
      title: Text(
        group != null
            ? _sectionName(l, group)
            : advanced
            ? l.advancedSettings
            : l.memorySettings,
      ),
      child: ListView(
        children: [
          if (locked) SettingsSection(children: [Text(l.memoryLimitsLocked)]),
          if (group != null)
            SettingsSection(
              children: [
                choice(group.ram, l.posterCacheRam, autofocus: true),
                choice(group.disk, l.posterCacheDisk),
              ],
            )
          else if (advanced)
            SettingsSection(
              children: [
                choice(
                  MemoryLimit.decodedApps,
                  l.memoryDecodedApps,
                  autofocus: true,
                ),
                choice(MemoryLimit.decodedPosters, l.memoryDecodedPosters),
              ],
            )
          else ...[
            SettingsSection(
              title: l.memoryImages,
              children: [
                for (final section in PosterCacheSection.values)
                  PosterMemoryLink(section),
                choice(MemoryLimit.icons, l.memoryAppIcons),
                choice(MemoryLimit.banners, l.memoryAppBanners),
                choice(MemoryLimit.preload, l.memoryPreload),
                FocusableSettingsTile(
                  title: Text(l.advancedSettings),
                  onPressed: () => Navigator.of(context).push(
                    SettingsRoute<void>(
                      builder: (_) => const MemorySettingsPage(advanced: true),
                    ),
                  ),
                ),
              ],
            ),
            SettingsSection(
              children: [
                RoundedSwitchListTile(
                  title: Text(l.memoryBackgroundClear),
                  enabled: !locked,
                  value: settings.clearCachesOnBackground,
                  onChanged: (v) => _save(
                    context,
                    () => settings.setClearCachesOnBackground(v),
                  ),
                ),
                FocusableSettingsTile(
                  leading: const Icon(Icons.restore),
                  title: Text(l.memoryResetLimits),
                  enabled: !locked,
                  onPressed: () => _save(context, settings.resetMemoryLimits),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
