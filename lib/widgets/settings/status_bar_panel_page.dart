/*
 * FLauncher
 * Copyright (C) 2024 Oscar Rojas
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

import '../../l10n/app_localizations.dart';
import 'focusable_settings_tile.dart';
import 'panel_order_page.dart';
import 'settings_page_layout.dart';

class StatusBarObjectsPage extends StatelessWidget {
  static const routeName = 'status_bar_objects';
  const StatusBarObjectsPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const PanelOrderPage(editVisibility: true);
}

class StatusBarPanelPage extends StatelessWidget {
  static const routeName = 'status_bar_panel';
  const StatusBarPanelPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SettingsPageLayout(
      title: Text(l.topPanel),
      child: ListView(
        children: [
          FocusableSettingsTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l.appearanceSettings),
            onPressed: () =>
                Navigator.of(context).pushNamed('panel_appearance'),
          ),
          FocusableSettingsTile(
            leading: const Icon(Icons.widgets_outlined),
            title: Text(l.topPanelObjects),
            onPressed: () =>
                Navigator.of(context).pushNamed(StatusBarObjectsPage.routeName),
          ),
        ],
      ),
    );
  }
}
