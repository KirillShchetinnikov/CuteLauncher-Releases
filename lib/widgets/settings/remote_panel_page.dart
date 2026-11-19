import 'settings_help.dart';
import 'appearance_page.dart';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'settings_page_layout.dart';
import 'focusable_settings_tile.dart';
import 'settings_route.dart';
import 'panel_order_page.dart';
import 'remote_buttons_page.dart';

class RemotePanelPage extends StatelessWidget {
  static const routeName = 'remote_panel_settings';
  const RemotePanelPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SettingsPageLayout(
      title: Text(l.remotePanel),
      child: ListView(
        children: [
          FocusableSettingsTile(
            autofocus: true,
            title: Text(l.appearanceSettings),
            leading: const Icon(Icons.palette_outlined),
            onPressed: () => Navigator.of(context).push(
              SettingsRoute(
                settings: const RouteSettings(
                  name: AppearancePage.remotePanelRouteName,
                ),
                builder: (_) =>
                    const AppearancePage(section: 'panel', remotePanel: true),
              ),
            ),
          ),
          FocusableSettingsTile(
            title: Text(l.topPanelObjects),
            leading: const Icon(Icons.widgets_outlined),
            onPressed: () => Navigator.of(context).push(
              SettingsRoute(
                settings: const RouteSettings(
                  name: RemotePanelObjectsPage.routeName,
                ),
                builder: (_) => const RemotePanelObjectsPage(),
              ),
            ),
          ),
          SettingsHelp(title: l.remotePanel, text: l.remotePanelDescription),
          FocusableSettingsTile(
            title: Text(l.remoteButtonsTitle),
            leading: const Icon(Icons.settings_remote_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed(RemoteButtonsPage.routeName),
          ),
        ],
      ),
    );
  }
}

class RemotePanelObjectsPage extends StatelessWidget {
  static const routeName = 'remote_panel_objects';
  const RemotePanelObjectsPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const PanelOrderPage(remotePanel: true, editVisibility: true);
}
