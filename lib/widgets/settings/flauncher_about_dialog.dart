import 'support_developer_tile.dart';
import 'settings_help.dart';
import 'focusable_settings_tile.dart';

import 'package:flauncher/widgets/launcher_dialog.dart';
/*
 * FLauncher
 * Copyright (C) 2024 LeanBitLab
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

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flauncher/providers/update_service.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'link_qr_code.dart';

class CuteLauncherAboutDialog extends StatelessWidget {
  static const repositoryUrl =
      'https://github.com/$updateRepository';
  static const discussionUrl =
      'https://4pda.to/forum/index.php?showtopic=1128313';
  final PackageInfo packageInfo;

  const CuteLauncherAboutDialog({super.key, required this.packageInfo});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final abis =
        context.watch<UpdateService?>()?.supportedAbis.join(', ') ?? '';
    const revision = String.fromEnvironment('BUILD_COMMIT');
    const mode = kReleaseMode
        ? 'release'
        : (kProfileMode ? 'profile' : 'debug');

    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 520,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/about-icon.png',
                              height: 56,
                              width: 56,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CuteLauncher',
                                  style: theme.textTheme.titleLarge,
                                ),
                                Text(
                                  'v${displayAppVersion(packageInfo.version)}',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(l.launcherAuthor, style: theme.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        [
                          packageInfo.packageName,
                          [
                            if (abis.isNotEmpty) abis,
                            mode,
                            if (revision.isNotEmpty) revision,
                          ].join(' · '),
                        ].join('\n'),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      SettingsHelp(
                        title: l.projectCredits,
                        text: l.launcherCredits,
                      ),
                      for (final (label, url) in [
                        (l.showRepositoryQrCode, repositoryUrl),
                        (l.discussionQrCode, discussionUrl),
                      ])
                        FocusableSettingsTile(
                          leading: const Icon(Icons.qr_code),
                          title: Text(label),
                          onPressed: () => showLauncherDialog<void>(
                            context: context,
                            builder: (_) => _LinkQrDialog(title: label, url: url),
                          ),
                        ),
                      const SupportDeveloperTile(),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: LauncherDialogButton(
                  autofocus: true,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkQrDialog extends StatelessWidget {
  const _LinkQrDialog({required this.title, required this.url});

  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return LauncherAlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 280,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinkQrCode(url: url, label: title),
              const SizedBox(height: 12),
              Text(url, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
      actions: [
        LauncherDialogButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.close),
        ),
      ],
    );
  }
}
