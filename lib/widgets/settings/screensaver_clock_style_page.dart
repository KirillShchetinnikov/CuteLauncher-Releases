import 'reset_style_tile.dart';
import 'focusable_settings_tile.dart';
import 'settings_page_layout.dart';
import 'settings_help.dart';
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
import 'package:provider/provider.dart';

import '../../providers/settings_service.dart';

class ScreensaverClockStylePage extends StatelessWidget {
  static const String routeName = "screensaver_clock_style_panel";

  const ScreensaverClockStylePage({super.key});

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;
    return Selector<SettingsService, String>(
      selector: (_, settingsService) => settingsService.screensaverClockStyle,
      builder: (context, currentStyle, _) {
        final settingsService = context.read<SettingsService>();

        return SettingsPageLayout(
          title: Text(
            localizations.screensaverClockStyle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StyleRadioTile(
                  title: AppLocalizations.of(context)!.clockMinimal,
                  value: 'minimal',
                  groupValue: currentStyle,
                  onChanged: (value) =>
                      settingsService.setScreensaverClockStyle(value!),
                  autofocus: currentStyle == 'minimal',
                ),
                _StyleRadioTile(
                  title: AppLocalizations.of(context)!.clockBold,
                  value: 'bold',
                  groupValue: currentStyle,
                  onChanged: (value) =>
                      settingsService.setScreensaverClockStyle(value!),
                  autofocus: currentStyle == 'bold',
                ),
                _StyleRadioTile(
                  title: AppLocalizations.of(context)!.clockRetro,
                  value: 'retro',
                  groupValue: currentStyle,
                  onChanged: (value) =>
                      settingsService.setScreensaverClockStyle(value!),
                  autofocus: currentStyle == 'retro',
                ),
                _StyleRadioTile(
                  title: AppLocalizations.of(context)!.clockElegant,
                  value: 'elegant',
                  groupValue: currentStyle,
                  onChanged: (value) =>
                      settingsService.setScreensaverClockStyle(value!),
                  autofocus: currentStyle == 'elegant',
                ),
                _StyleRadioTile(
                  title: AppLocalizations.of(context)!.clockNeon,
                  value: 'neon',
                  groupValue: currentStyle,
                  onChanged: (value) =>
                      settingsService.setScreensaverClockStyle(value!),
                  autofocus: currentStyle == 'neon',
                ),
                _StyleRadioTile(
                  title: AppLocalizations.of(context)!.clockPixel,
                  value: 'pixel',
                  groupValue: currentStyle,
                  onChanged: (value) =>
                      settingsService.setScreensaverClockStyle(value!),
                  autofocus: currentStyle == 'pixel',
                ),
                _StyleRadioTile(
                  title: AppLocalizations.of(context)!.clockDigital,
                  value: 'digital',
                  groupValue: currentStyle,
                  onChanged: (value) =>
                      settingsService.setScreensaverClockStyle(value!),
                  autofocus: currentStyle == 'digital',
                ),
                SettingsHelp(text: [
                  '${localizations.clockMinimal}: ${localizations.clockMinimalDescription}',
                  '${localizations.clockBold}: ${localizations.clockBoldDescription}',
                  '${localizations.clockRetro}: ${localizations.clockRetroDescription}',
                  '${localizations.clockElegant}: ${localizations.clockElegantDescription}',
                  '${localizations.clockNeon}: ${localizations.clockNeonDescription}',
                  '${localizations.clockPixel}: ${localizations.clockPixelDescription}',
                  '${localizations.clockDigital}: ${localizations.clockDigitalDescription}',
                ].join('\n\n')),
                ResetStyleTile(onReset: () => settingsService.resetAppearanceSection('clock')),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StyleRadioTile extends StatelessWidget {
  final String title, value, groupValue;
  final ValueChanged<String?> onChanged;
  final bool autofocus;
  const _StyleRadioTile({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.autofocus = false,
  });
  @override
  Widget build(BuildContext context) => FocusableSettingsTile(
    autofocus: autofocus,
    title: Text(title),
    trailing: value == groupValue
        ? const Icon(Icons.check)
        : const SizedBox.shrink(),
    onPressed: () => onChanged(value),
  );
}
