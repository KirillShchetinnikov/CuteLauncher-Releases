import 'settings_option_tile.dart';
import 'reset_style_tile.dart';
import 'settings_page_layout.dart';
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

class AccentColorPage extends StatelessWidget {
  static const String routeName = "accent_color_panel";

  // Define accent color presets with names
  static List<(String hex, String name)> colorPresets(AppLocalizations l10n) =>
      [
        (ACCENT_COLOR_PURPLE, l10n.colorPurple),
        (ACCENT_COLOR_TEAL, l10n.colorTeal),
        (ACCENT_COLOR_BLUE, l10n.colorBlue),
        (ACCENT_COLOR_ORANGE, l10n.colorOrange),
        (ACCENT_COLOR_PINK, l10n.colorPink),
        (ACCENT_COLOR_GREEN, l10n.colorGreen),
        (ACCENT_COLOR_WHITE, l10n.colorWhite),
        (ACCENT_COLOR_YELLOW, l10n.colorYellow),
        (ACCENT_COLOR_RED, l10n.colorRed),
        (ACCENT_COLOR_CYAN, l10n.colorCyan),
        (ACCENT_COLOR_INDIGO, l10n.colorIndigo),
        (ACCENT_COLOR_LIME, l10n.colorLime),
        (ACCENT_COLOR_AMBER, l10n.colorAmber),
        (ACCENT_COLOR_ROSE, l10n.colorRose),
        (ACCENT_COLOR_ICE_BLUE, l10n.colorIceBlue),
      ];

  const AccentColorPage({super.key});

  Color _hexToColor(String hex) {
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;
    return Consumer<SettingsService>(
      builder: (context, settingsService, _) {
        final currentColorHex = settingsService.accentColorHex;
        final currentColor = _hexToColor(currentColorHex);

        return SettingsPageLayout(
          title: Text(
            localizations.accentColor,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          child: CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final (hex, name) = colorPresets(localizations)[index];
                  final isSelected = currentColorHex == hex;

                  return SettingsOptionTile(
                    title: Text(name),
                    leading: Icon(Icons.circle, color: _hexToColor(hex)),
                    selected: isSelected,
                    autofocus: isSelected,
                    onPressed: () => settingsService.setAccentColor(hex),
                  );
                }, childCount: colorPresets(localizations).length),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Minimalist Accent Preview Indicator
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: currentColor.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: currentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!.selectedAccent,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ResetStyleTile(
                      onReset: () =>
                          settingsService.resetAppearanceSection('accent'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
