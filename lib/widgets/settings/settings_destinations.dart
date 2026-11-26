import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../flauncher_channel.dart';
import '../../providers/screensaver_service.dart';
import '../../providers/tv_inputs_service.dart';

import 'package:provider/provider.dart';

import 'adb_page.dart';
import 'access_settings_links.dart';
import 'app_permissions_page.dart';
import 'auto_launch_page.dart';
import 'diagnostics_page.dart';
import 'brightness_page.dart';
import 'focusable_settings_tile.dart';
import 'recent_apps_page.dart';
import 'remote_buttons_page.dart';
import 'remote_panel_page.dart';
import 'render_compatibility_tile.dart';
import 'screensaver_clock_style_page.dart';
import 'settings_page_layout.dart';
import 'settings_route.dart';
import 'settings_section.dart';
import 'status_bar_panel_page.dart';
import 'tv_cleaner_page.dart';
import 'tv_power_page.dart';
import 'information_settings_page.dart';
import 'inputs_settings_page.dart';
import 'network_speed_settings_page.dart';
import 'night_mode_page.dart';
import 'notifications_settings_page.dart';
import 'quick_actions_settings_page.dart';
import 'sleep_timer_settings_page.dart';
import 'system_widget_settings_page.dart';
import 'traffic_settings_page.dart';
import 'volume_widget_settings_page.dart';
import 'vpn_settings_page.dart';
import 'widget_placement_page.dart';

class LauncherFunctionsPage extends StatelessWidget {
  static const routeName = 'launcher_functions';
  const LauncherFunctionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final screensaver = context.watch<ScreensaverService?>();
    return SettingsPageLayout(
      title: Text(l.launcherFunctions),
      child: ListView(
        children: [
          SettingsSection(
            title: l.settingsGroupControl,
            children: [
              FocusableSettingsTile(
                leading: const Icon(Icons.settings_remote_outlined),
                title: Text(l.remoteButtonsTitle),
                onPressed: () =>
                    Navigator.of(context)
                        .pushNamed(RemoteButtonsPage.routeName),
              ),
              FocusableSettingsTile(
                leading: const Icon(Icons.filter_none_outlined),
                title: Text(l.recentAppsTitle),
                onPressed: () =>
                    Navigator.of(context).pushNamed(RecentAppsPage.routeName),
              ),
              FocusableSettingsTile(
                leading: const Icon(Icons.power_settings_new),
                title: Text(l.tvPowerTitle),
                onPressed: () =>
                    Navigator.of(context).pushNamed(TvPowerPage.routeName),
              ),
            ],
          ),
          SettingsSection(
            title: l.automationAndComfort,
            children: [
              FocusableSettingsTile(
                leading: const Icon(Icons.play_circle_outline),
                title: Text(l.autoLaunchTitle),
                onPressed: () =>
                    Navigator.of(context).pushNamed(AutoLaunchPage.routeName),
              ),
              FocusableSettingsTile(
                leading: const Icon(Icons.nightlight_outlined),
                title: Text(l.nightModeTitle),
                onPressed: () =>
                    Navigator.of(context).pushNamed(NightModePage.routeName),
              ),
              FocusableSettingsTile(
                leading: const Icon(Icons.brightness_6),
                title: Text(l.scheduledBrightness),
                onPressed: () =>
                    Navigator.of(context).pushNamed(BrightnessPage.routeName),
              ),
            ],
          ),
          SettingsSection(
            title: l.settingsMaintenanceGroup,
            children: [
              FocusableSettingsTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: Text(l.appPermissionsTitle),
                onPressed: () => Navigator.of(context).push(
                  SettingsRoute(builder: (_) => const AppPermissionsPage()),
                ),
              ),
              FocusableSettingsTile(
                leading: const Icon(Icons.app_blocking_outlined),
                title: Text(l.cleanerTitle),
                onPressed: () => Navigator.of(context)
                    .push(SettingsRoute(builder: (_) => const TvCleanerPage())),
              ),
            ],
          ),
          if (screensaver?.capabilities.canChoose == true)
            SettingsSection(
              title: l.settingsScreensaverGroup,
              children: [
                FocusableSettingsTile(
                  leading: const Icon(Icons.watch_later_outlined),
                  title: Text(l.screensaverClockStyle),
                  onPressed: () =>
                      Navigator.of(context)
                          .pushNamed(ScreensaverClockStylePage.routeName),
                ),
                FocusableSettingsTile(
                  leading: const Icon(Icons.desktop_windows_outlined),
                  title: Text(l.screensaverSettings),
                  onPressed: () => screensaver!.openSettings(),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class LauncherAccessPage extends StatelessWidget {
  static const routeName = 'launcher_access';
  const LauncherAccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SettingsPageLayout(
      title: Text(l.launcherDefaultAndAdb),
      child: ListView(
        children: [
          SettingsSection(
            title: l.adbDefaultBlock,
            children: [
              FocusableSettingsTile(
                leading: const Icon(Icons.open_in_new),
                title: Text(l.launcherChooseInAndroid),
                onPressed: () => FLauncherChannel().openDefaultLauncherSettings(),
              ),
              FocusableSettingsTile(
                leading: const Icon(Icons.home_outlined),
                title: Text(l.defaultLauncherViaAdb),
                onPressed: () => Navigator.of(context).push(
                  SettingsRoute(
                    builder: (_) => const AdbPage(section: 'launcher'),
                  ),
                ),
              ),
              FocusableSettingsTile(
                leading: const Icon(Icons.accessibility_new),
                title: Text(l.adbHomeBlock),
                onPressed: () => Navigator.of(context).push(
                  SettingsRoute(builder: (_) => const AdbPage(section: 'home')),
                ),
              ),
            ],
          ),
          SettingsSection(
            title: l.settingsGroupAccess,
            children: const [AccessibilitySettingsLink(), AdbConnectionLink()],
          ),
        ],
      ),
    );
  }
}

class LauncherDiagnosticsPage extends StatelessWidget {
  static const routeName = 'launcher_diagnostics';
  const LauncherDiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SettingsPageLayout(
      title: Text(l.diagnosticsHubTitle),
      child: ListView(
        children: [
          SettingsSection(
            children: [
              FocusableSettingsTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: Text(l.diagnosticsReportsAndRecording),
                onPressed: () =>
                    Navigator.of(context).pushNamed(DiagnosticsPage.routeName),
              ),
            ],
          ),
          SettingsSection(
            title: l.compatibilityGroup,
            children: const [RenderCompatibilityTile()],
          ),
        ],
      ),
    );
  }
}

class WidgetsAndPanelsPage extends StatelessWidget {
  static const routeName = 'widgets_and_panels';
  const WidgetsAndPanelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SettingsPageLayout(
      title: Text(l.widgetsAndPanels),
      child: ListView(
        children: [
          FocusableSettingsTile(
            leading: const Icon(Icons.widgets_outlined),
            title: Text(l.widgetsSettingsTitle),
            onPressed: () =>
                Navigator.of(context).pushNamed(WidgetSettingsPage.routeName),
          ),
          FocusableSettingsTile(
            leading: const Icon(Icons.web_asset),
            title: Text(l.topPanel),
            onPressed: () =>
                Navigator.of(context).pushNamed(StatusBarPanelPage.routeName),
          ),
          FocusableSettingsTile(
            leading: const Icon(Icons.tune),
            title: Text(l.remotePanel),
            onPressed: () =>
                Navigator.of(context).pushNamed(RemotePanelPage.routeName),
          ),
        ],
      ),
    );
  }
}

class WidgetSettingsPage extends StatelessWidget {
  static const routeName = 'widget_settings';
  const WidgetSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final inputs = context.watch<TvInputsService?>();
    Widget link(
      String title,
      IconData icon,
      String route, {
      bool enabled = true,
      String? detail,
    }) => FocusableSettingsTile(
      title: Text(title),
      trailing: detail == null ? null : Text(detail),
      leading: Icon(icon),
      enabled: enabled,
      onPressed: () => Navigator.of(context).pushNamed(route),
    );
    Widget placement(String title, IconData icon, String id) =>
        FocusableSettingsTile(
          title: Text(title),
          leading: Icon(icon),
          onPressed: () => Navigator.of(context).push(
            SettingsRoute(
              settings: const RouteSettings(name: WidgetPlacementPage.routeName),
              builder: (_) => WidgetPlacementPage(id: id, title: title),
            ),
          ),
        );
    return SettingsPageLayout(
      title: Text(l.widgetsSettingsTitle),
      child: ListView(
        children: [
          SettingsSection(
            title: l.informationGroup,
            children: [
              link(
                l.settings,
                Icons.settings_outlined,
                InformationSettingsPage.routeName,
              ),
            ],
          ),
          SettingsSection(
            title: l.networkSummary,
            children: [
              placement(l.networkSummary, Icons.wifi, 'network'),
              link(
                l.vpnTitle,
                Icons.vpn_key_outlined,
                VpnSettingsPage.routeName,
              ),
              link(
                l.networkSpeedTitle,
                Icons.speed,
                NetworkSpeedSettingsPage.routeName,
              ),
              link(
                l.trafficTitle,
                Icons.data_usage,
                TrafficSettingsPage.routeName,
              ),
            ],
          ),
          SettingsSection(
            title: l.soundAndInputsGroup,
            children: [
              link(
                l.audioStatusTitle,
                Icons.volume_up_outlined,
                VolumeWidgetSettingsPage.routeName,
              ),
              placement(l.remoteBatteryTitle, Icons.battery_std, 'remoteBattery'),
              link(
                l.inputs,
                Icons.settings_input_hdmi,
                InputsSettingsPage.routeName,
                enabled: inputs?.hasInputs == true,
                detail: inputs != null && inputs.initialized && !inputs.hasInputs
                    ? l.inputsUnavailableStatus
                    : null,
              ),
            ],
          ),
          SettingsSection(
            title: l.storageDevicesGroup,
            children: [
              placement(l.usbStorageTitle, Icons.usb, 'usb'),
              placement(l.networkStorageTitle, Icons.storage, 'nas'),
            ],
          ),
          SettingsSection(
            title: l.systemAndNotifications,
            children: [
              link(
                l.system,
                Icons.monitor_heart_outlined,
                SystemWidgetSettingsPage.routeName,
              ),
              link(
                l.notifications,
                Icons.notifications_outlined,
                NotificationsSettingsPage.routeName,
              ),
              link(
                l.quickActionsTitle,
                Icons.bolt_outlined,
                QuickActionsSettingsPage.routeName,
              ),
            ],
          ),
          SettingsSection(
            title: l.timerAndNightModeGroup,
            children: [
              link(
                l.sleepTimer,
                Icons.timer_outlined,
                SleepTimerSettingsPage.routeName,
              ),
              link(
                l.nightModeTitle,
                Icons.nightlight_outlined,
                NightModePage.routeName,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
