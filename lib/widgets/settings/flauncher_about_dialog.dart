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
import 'package:flauncher/flauncher_channel.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flauncher/providers/settings_service.dart';

class CuteLauncherAboutDialog extends StatelessWidget {
  static const repositoryUrl =
      'https://github.com/KirillShchetinnikov/CuteLauncher';
  final PackageInfo packageInfo;

  const CuteLauncherAboutDialog({super.key, required this.packageInfo});

  Color _hexToColor(String hex) {
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = context.watch<SettingsService>();
    final accentColor = _hexToColor(settingsService.accentColorHex);
    final abis =
        context.watch<UpdateService?>()?.supportedAbis.join(', ') ?? '';
    const revision = String.fromEnvironment('BUILD_COMMIT');
    const mode = kReleaseMode
        ? 'release'
        : (kProfileMode ? 'profile' : 'debug');

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        width: 380,

        padding: const EdgeInsets.all(20),

        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Clean App Icon
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  "assets/icon.png",
                  height: 56,
                  width: 56,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),

              // Title & Version
              const Text(
                "CuteLauncher",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "${AppLocalizations.of(context)!.updateInstalled}: v${packageInfo.version}+${packageInfo.buildNumber}",
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
              Text(
                [
                  packageInfo.packageName,
                  if (abis.isNotEmpty) abis,
                  mode,
                  if (revision.isNotEmpty) revision,
                ].join('\n'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.launcherAuthor,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),

              // About info description
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SettingsHelp(text: AppLocalizations.of(context)!.launcherCredits),
              ),
              const SizedBox(height: 14),

              // Social Links Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLocalizations.of(context)!.projectCredits,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              _AboutButton(
                icon: Icons.code,
                iconColor: Colors.white70,
                label: AppLocalizations.of(context)!.launcherRepository,
                accentColor: accentColor,
                onPressed: () {
                  FLauncherChannel().openUrl(repositoryUrl);
                },
              ),

              const SizedBox(height: 8),
              _AboutButton(
                icon: Icons.qr_code,
                iconColor: Colors.white70,
                label: AppLocalizations.of(context)!.showRepositoryQrCode,
                accentColor: accentColor,
                onPressed: () => showLauncherDialog<void>(
                  context: context,
                  builder: (context) => const _RepositoryQrDialog(),
                ),
              ),

              const SizedBox(height: 10),
              // Close Action
              LauncherDialogButton(
                autofocus: true,
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  AppLocalizations.of(context)!.close,
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RepositoryQrDialog extends StatelessWidget {
  const _RepositoryQrDialog();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return LauncherAlertDialog(
      title: Text(l.launcherRepository),
      content: SizedBox(
        width: 280,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: CuteLauncherAboutDialog.repositoryUrl,
                size: 240,
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(color: Colors.black),
                dataModuleStyle: const QrDataModuleStyle(color: Colors.black),
                semanticsLabel: l.launcherRepository,
              ),
              const SizedBox(height: 12),
              const Text(
                CuteLauncherAboutDialog.repositoryUrl,
                textAlign: TextAlign.center,
              ),
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

class _AboutButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor, accentColor;
  final String label;
  final VoidCallback onPressed;
  const _AboutButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.accentColor,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) => FocusableSettingsTile(
    leading: Icon(icon),
    title: Text(label),
    onPressed: onPressed,
  );
}
