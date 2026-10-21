import 'settings_value_stepper.dart';
import 'settings_page_layout.dart';
/*
 * FLauncher
 * Copyright (C) 2026 LeanBitLab
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

class ContinueWatchingCardSizePage extends StatelessWidget {
  static const String routeName = "continue_watching_card_size_panel";

  const ContinueWatchingCardSizePage({super.key});

  static List<(int, String, String)> cardSizePresets(AppLocalizations l10n) => [
    (80, '80 dp • ${l10n.sizeExtraSmall}', '142 × 80 dp'),
    (90, '90 dp • ${l10n.sizeVerySmall}', '160 × 90 dp'),
    (100, '100 dp • ${l10n.sizeSmall}', '178 × 100 dp'),
    (110, '110 dp • ${l10n.sizeCompact}', '196 × 110 dp'),
    (120, '120 dp • ${l10n.sizeMediumSmall}', '213 × 120 dp'),
    (130, '130 dp • ${l10n.sizeMedium}', '231 × 130 dp'),
    (135, '135 dp • ${l10n.sizeStandardDefault}', '240 × 135 dp'),
    (140, '140 dp • ${l10n.sizeMediumLarge}', '249 × 140 dp'),
    (150, '150 dp • ${l10n.sizeLarge}', '267 × 150 dp'),
    (160, '160 dp • ${l10n.sizeVeryLarge}', '284 × 160 dp'),
    (170, '170 dp • ${l10n.sizeExtraLarge}', '302 × 170 dp'),
    (180, '180 dp • ${l10n.sizeHuge}', '320 × 180 dp'),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    final raw = settings.continueWatchingCardSize;
    final height =
        int.tryParse(raw) ??
        (raw == 'compact'
            ? 112
            : raw == 'large'
            ? 157
            : 135);
    return SettingsPageLayout(
      title: Text(l.cardSize),
      child: ListView(
        children: [
          SettingsValueStepper(
            title: l.cardSize,
            autofocus: true,
            options: cardSizePresets(l).map((preset) => preset.$1).toList(),
            value: height,
            label: (v) => '$v dp',
            onChanged: (v) => settings.setContinueWatchingCardSize('$v'),
          ),
        ],
      ),
    );
  }
}
