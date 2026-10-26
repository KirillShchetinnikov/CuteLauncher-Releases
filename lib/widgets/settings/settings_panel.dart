import 'traffic_settings_page.dart';
import 'sleep_timer_settings_page.dart';
import 'tv_power_page.dart';
import '../landscape_demo_presentation.dart';
import 'information_settings_page.dart';
import 'panel_clock_style_page.dart';
import 'remote_panel_page.dart';
import '../../providers/remote_panel_service.dart';
import 'inputs_settings_page.dart';
import 'settings_style_page.dart';
import 'settings_panel_style.dart';
import 'automatic_backup_page.dart';
import 'settings_menu_layout.dart';
import '../launcher_dialog.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_service.dart';
import 'watch_next_limits_page.dart';

import 'package:flauncher/theme/launcher_style.dart';
/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
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

import 'appearance_settings_page.dart';
import 'settings_route.dart';
import 'memory_page.dart';
import 'diagnostics_page.dart';
import 'updates_page.dart';
import 'adb_page.dart';
import 'auto_launch_page.dart';
import 'remote_buttons_page.dart';

import 'cloud_backup_page.dart';
import 'night_mode_page.dart';
import 'brightness_page.dart';
import 'appearance_page.dart';
import 'weather_page.dart';
import 'online_wallpaper_page.dart';

import 'package:flauncher/widgets/side_panel_dialog.dart';
import 'package:flauncher/widgets/settings/applications_panel_page.dart';
import 'package:flauncher/widgets/settings/launcher_sections_panel_page.dart';
import 'package:flauncher/widgets/settings/gradient_panel_page.dart';
import 'package:flauncher/widgets/settings/launcher_section_panel_page.dart';
import 'package:flauncher/widgets/settings/settings_panel_page.dart';
import 'package:flauncher/widgets/settings/status_bar_panel_page.dart';
import 'panel_order_page.dart';
import 'package:flauncher/widgets/settings/wallpaper_panel_page.dart';
import 'package:flauncher/widgets/settings/data_usage_period_page.dart';
import 'package:flauncher/widgets/settings/date_time_format_page.dart';
import 'package:flauncher/widgets/settings/app_details_page.dart';
import 'package:flauncher/widgets/settings/accent_color_page.dart';
import 'package:flauncher/widgets/settings/misc_panel_page.dart';
import 'package:flauncher/widgets/settings/interface_settings_page.dart';
import 'package:flauncher/widgets/settings/general_settings_page.dart';
import 'package:flauncher/widgets/settings/screensaver_clock_style_page.dart';
import 'package:flauncher/widgets/settings/accessibility_page.dart';
import 'package:flauncher/widgets/settings/backup_restore_page.dart';
import 'package:flauncher/widgets/settings/app_language_page.dart';
import 'package:flauncher/widgets/settings/blocked_notifications_page.dart';
import 'package:flauncher/widgets/settings/display_settings_page.dart';
import 'package:flauncher/widgets/settings/notifications_settings_page.dart';
import 'package:flauncher/widgets/settings/continue_watching_settings_page.dart';
import 'package:flauncher/widgets/settings/continue_watching_card_size_page.dart';
import 'package:flauncher/widgets/settings/continue_watching_max_items_page.dart';
import 'package:flauncher/widgets/settings/continue_watching_apps_page.dart';
import 'package:flauncher/models/app.dart';
import 'package:flutter/material.dart';

class SettingsPanel extends StatefulWidget {
  final String? initialRoute;

  const SettingsPanel({super.key, this.initialRoute});

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final _observer = _SettingsRouteObserver(_routeChanged);
  bool _topPanel = false;
  RemotePanelService? _previewService;

  @override
  void initState() {
    super.initState();
    _topPanel = _isTopPanelRoute(widget.initialRoute);
  }

  @override
  void dispose() {
    final preview = _previewService;
    if (preview != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => preview.setSettingsPreview(this, false));
    }
    super.dispose();
  }

  static bool _isTopPanelRoute(String? name) => {
      StatusBarPanelPage.routeName,
      RemotePanelPage.routeName,
      StatusBarObjectsPage.routeName,
      InformationSettingsPage.routeName,
      InputsSettingsPage.routeName,
      SleepTimerSettingsPage.routeName,
      SleepTimerOptionsPage.routeName,
      SleepTimerOptionsPage.displayRouteName,
      SleepTimerPresetsPage.routeName,
      SleepTimerEditorPage.routeName,
      TrafficSettingsPage.routeName,
      PanelOrderPage.routeName,
      'panel_appearance',
      PanelClockStylePage.routeName,
      DateTimeFormatPage.routeName,
      DataUsagePeriodPage.routeName,
      WeatherPage.routeName,
      NotificationsSettingsPage.routeName,
      BlockedNotificationsPage.routeName,
    }.contains(name);

  void _routeChanged(String? name, bool remotePreview) {
    final topPanel = remotePreview || _isTopPanelRoute(name);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (remotePreview) {
        _previewService ??= context.read<RemotePanelService?>();
      }
      _previewService?.setSettingsPreview(this, remotePreview);
      if (_topPanel != topPanel) {
        setState(() => _topPanel = topPanel);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final onRight = context.watch<SettingsService>().settingsMenuOnRight;
    return SettingsPanelStyle(
      builder: (context) => SettingsMenuLayout(
        onRight: onRight,
        child: LandscapeDemoPresentation(child: Builder(builder: (context) => _buildPanel(context, onRight))),
      ),
    );
  }

  Widget _buildPanel(BuildContext context, bool onRight) {
    final demoActive = LandscapeDemoScope.activeOf(context);
    return NavigatorPopHandler(
      enabled: !demoActive,
      onPopWithResult: (result) {
        if (!demoActive) _navigatorKey.currentState!.maybePop();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              top: _topPanel ? kToolbarHeight : 0,
              child: const LauncherPanelBackdrop(),
            ),
            // Tap outside to close
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(color: Colors.transparent),
            ),
            // The side panel
            SidePanelDialog(
              topInset: _topPanel ? kToolbarHeight : 0,
              width: LauncherStyle.of(context).settingsWidth,
              isRightSide: onRight,
              child: Navigator(
                observers: [_observer],
                key: _navigatorKey,
                initialRoute:
                    widget.initialRoute ?? SettingsPanelPage.routeName,
                onGenerateRoute: (settings) {
                  switch (settings.name) {
                    case RemotePanelPage.routeName:
                      return SettingsRoute(settings: settings,
                        builder: (_) => const RemotePanelPage());
                    case SettingsStylePage.routeName:
                      return SettingsRoute(settings: settings,
                        builder: (_) => const SettingsStylePage());
                    case SettingsStylePage.notificationsRouteName:
                      return SettingsRoute(settings: settings,
                        builder: (_) => const SettingsStylePage(notifications: true));
                    case AppearanceSettingsPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const AppearanceSettingsPage(),
                      );
                    case 'panel_appearance':
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const AppearancePage(section: 'panel'),
                      );
                    case AppearancePage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const AppearancePage(),
                      );
                    case BrightnessPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const BrightnessPage(),
                      );
                    case SettingsPanelPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => SettingsPanelPage(),
                      );
                    case MemoryPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const MemoryPage(),
                      );
                    case MemorySaverPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const MemorySaverPage(),
                      );
                    case DiagnosticsPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const DiagnosticsPage(),
                      );
                    case GeneralSettingsPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const GeneralSettingsPage(),
                      );
                    case UpdatesPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const UpdatesPage(),
                      );
                    case AdbPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const AdbPage(),
                      );
                    case TvPowerPage.routeName:
                      return SettingsRoute(settings: settings, builder: (_) => const TvPowerPage());
                    case AutoLaunchPage.routeName:
                      return SettingsRoute(settings: settings, builder: (_) => const AutoLaunchPage());
                    case RemoteButtonsPage.routeName:
                      return SettingsRoute(settings: settings, builder: (_) => const RemoteButtonsPage());
                    case CloudBackupPage.routeName:
                      return SettingsRoute(settings: settings, builder: (_) => const CloudBackupPage());

                    case TrafficSettingsPage.routeName:
                      return SettingsRoute(settings: settings, builder: (_) => const TrafficSettingsPage());
                    case SleepTimerSettingsPage.routeName:
                      return SettingsRoute(settings: settings, builder: (_) => const SleepTimerSettingsPage());
                    case InputsSettingsPage.routeName:
                      return SettingsRoute(settings: settings, builder: (_) => const InputsSettingsPage());
                    case NightModePage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const NightModePage(),
                      );
                    case InterfaceSettingsPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => InterfaceSettingsPage(),
                      );
                    case WallpaperPanelPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => WallpaperPanelPage(),
                      );
                    case StatusBarPanelPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => StatusBarPanelPage(),
                      );
                    case StatusBarObjectsPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const StatusBarObjectsPage(),
                      );
                    case PanelOrderPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const PanelOrderPage(),
                      );
                    case WeatherPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const WeatherPage(),
                      );
                    case OnlineWallpaperPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const OnlineWallpaperPage(),
                      );
                    case GradientPanelPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => GradientPanelPage(),
                      );
                    case ApplicationsPanelPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => ApplicationsPanelPage(),
                      );
                    case LauncherSectionsPanelPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => LauncherSectionsPanelPage(),
                      );
                    case LauncherSectionPanelPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => LauncherSectionPanelPage(
                          sectionIndex: settings.arguments as int?,
                        ),
                      );
                    case DataUsagePeriodPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => DataUsagePeriodPage(),
                      );
                    case PanelClockStylePage.routeName:
                      return SettingsRoute(settings: settings, builder: (_) => const PanelClockStylePage());
                    case InformationSettingsPage.routeName:
                      return SettingsRoute(settings: settings, builder: (_) => const InformationSettingsPage());
                    case DateTimeFormatPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => DateTimeFormatPage(),
                      );
                    case MiscPanelPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => MiscPanelPage(),
                      );
                    case ScreensaverClockStylePage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const ScreensaverClockStylePage(),
                      );
                    case AccentColorPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => AccentColorPage(),
                      );
                    case AccessibilityPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const AccessibilityPage(),
                      );
                    case BackupRestorePage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const BackupRestorePage(),
                      );
                    case AppLanguagePage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const AppLanguagePage(),
                      );
                    case BlockedNotificationsPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const BlockedNotificationsPage(),
                      );
                    case DisplaySettingsPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const DisplaySettingsPage(),
                      );
                    case NotificationsSettingsPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const NotificationsSettingsPage(),
                      );
                    case ContinueWatchingSettingsPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const ContinueWatchingSettingsPage(),
                      );
                    case ContinueWatchingCardSizePage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const ContinueWatchingCardSizePage(),
                      );
                    case ContinueWatchingMaxItemsPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const ContinueWatchingMaxItemsPage(),
                      );
                    case AutomaticBackupPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const AutomaticBackupPage(),
                      );
                    case WatchNextLimitsPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const WatchNextLimitsPage(),
                      );
                    case ContinueWatchingAppsPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => const ContinueWatchingAppsPage(),
                      );
                    case AppDetailsPage.routeName:
                      return SettingsRoute(
                        settings: settings,
                        builder: (_) => AppDetailsPage(
                          application: settings.arguments as App,
                        ),
                      );
                    default:
                      throw ArgumentError.value(
                        settings.name,
                        "settings.name",
                        "Route not supported.",
                      );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRouteObserver extends NavigatorObserver {
  final void Function(String?, bool) changed;
  final _routes = <Route<dynamic>>[];
  _SettingsRouteObserver(this.changed);
  void _notify() => changed(_routes.lastOrNull?.settings.name,
      _routes.any((route) => route.settings.name == RemotePanelPage.routeName));
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
    _notify();
  }
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _notify();
  }
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _notify();
  }
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = _routes.indexWhere((route) => identical(route, oldRoute));
    if (index >= 0) {
      if (newRoute == null) { _routes.removeAt(index); }
      else { _routes[index] = newRoute; }
    }
    _notify();
  }
}
