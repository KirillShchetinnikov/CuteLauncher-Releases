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

class ContinueWatchingMaxItemsPage extends StatelessWidget {
  static const String routeName = "continue_watching_max_items_panel";

  const ContinueWatchingMaxItemsPage({super.key});

  static const maxItemsPresets = [5, 10, 15, 20, 0];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    return SettingsPageLayout(
      title: Text(l.maximumItems),
      child: ListView(
        children: [
          SettingsValueStepper(
            title: l.maximumItems,
            autofocus: true,
            options: maxItemsPresets,
            value: settings.continueWatchingMaxItems,
            label: (v) => v == 0 ? l.unlimitedItems : l.itemsCount(v as int),
            onChanged: (v) => settings.setContinueWatchingMaxItems(v as int),
          ),
        ],
      ),
    );
  }
}
