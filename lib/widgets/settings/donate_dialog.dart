import 'settings_help.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';

import 'focusable_settings_tile.dart';
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
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/providers/settings_service.dart';

class DonateDialog extends StatefulWidget {
  const DonateDialog({super.key});

  @override
  State<DonateDialog> createState() => _DonateDialogState();
}

class _PlatformTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected, autofocus;
  final Color accentColor;
  final VoidCallback onPressed;
  const _PlatformTabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.onPressed,
    this.autofocus = false,
  });
  @override
  Widget build(BuildContext context) => FocusableSettingsTile(
    title: Text(label),
    leading: Icon(icon),
    selected: isSelected,
    autofocus: autofocus,
    onPressed: onPressed,
    trailing: isSelected ? const Icon(Icons.check) : const SizedBox.shrink(),
  );
}

class _DialogActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onPressed;
  const _DialogActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) => LauncherDialogButton(
    onPressed: onPressed,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Flexible(child: Text(label)),
      ],
    ),
  );
}

class _DonateDialogState extends State<DonateDialog> {
  int _selectedOption = 0; // 0: Open Collective, 1: GitHub Sponsors

  static const String _openCollectiveUrl =
      "https://opencollective.com/leanbitlab-org";
  static const String _githubSponsorsUrl =
      "https://github.com/sponsors/LeanBitLab";

  Color _hexToColor(String hex) {
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = context.watch<SettingsService>();
    final accentColor = _hexToColor(settingsService.accentColorHex);

    final currentUrl = _selectedOption == 0
        ? _openCollectiveUrl
        : _githubSponsorsUrl;
    final currentPlatform = _selectedOption == 0
        ? "Open Collective"
        : "GitHub Sponsors";
    final currentBrandColor = _selectedOption == 0
        ? const Color(0xFF1F6FEB)
        : const Color(0xFFEA4AAA);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        width: 440,

        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),

        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Heart Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, color: accentColor, size: 24),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      AppLocalizations.of(context)!.supportLtvLauncher,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SettingsHelp(text: AppLocalizations.of(context)!.scanToDonate),
              const SizedBox(height: 16),

              // Platform Selector Buttons (D-pad friendly)
              LayoutBuilder(
                builder: (context, constraints) {
                  final tabs = <Widget>[
                    _PlatformTabButton(
                      label: "Open Collective",
                      icon: Icons.volunteer_activism,
                      isSelected: _selectedOption == 0,
                      accentColor: accentColor,
                      autofocus: true,
                      onPressed: () => setState(() => _selectedOption = 0),
                    ),

                    _PlatformTabButton(
                      label: "GitHub Sponsors",
                      icon: Icons.favorite_border,
                      isSelected: _selectedOption == 1,
                      accentColor: accentColor,
                      onPressed: () => setState(() => _selectedOption = 1),
                    ),
                  ];
                  return constraints.maxWidth < 300
                      ? Column(
                          children: [
                            tabs[0],
                            const SizedBox(height: 8),
                            tabs[1],
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: tabs[0]),
                            const SizedBox(width: 10),
                            Expanded(child: tabs[1]),
                          ],
                        );
                },
              ),
              const SizedBox(height: 16),

              // QR Code in high-contrast crisp white background
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: currentUrl,
                  version: QrVersions.auto,
                  size: 170.0,
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // URL and platform badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: currentBrandColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: currentBrandColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  currentPlatform,
                  style: TextStyle(
                    color: currentBrandColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                currentUrl,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 12),

              // Actions
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  _DialogActionButton(
                    icon: Icons.open_in_browser,
                    label: AppLocalizations.of(context)!.openInBrowser,
                    accentColor: accentColor,
                    onPressed: () => FLauncherChannel().openUrl(currentUrl),
                  ),
                  _DialogActionButton(
                    icon: Icons.close,
                    label: AppLocalizations.of(context)!.close,
                    accentColor: accentColor,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
