import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../flauncher_app.dart';
import '../../recent_apps_client.dart';
import '../action_notice.dart';
import 'accessibility_page.dart';
import 'adb_page.dart';
import 'focusable_settings_tile.dart';
import 'settings_route.dart';

Future<void> _openSettings(
  BuildContext context,
  String route,
  Widget page,
  Future<void> Function()? onReturn,
) async {
  // A service-owned panel has no Activity ADB channel. Open the same page
  // in the launcher's engine before the service dismisses its own window.
  if (context.findAncestorWidgetOfExactType<FLauncherApp>()?.remotePanel ==
      true) {
    try {
      final opened = await RecentAppsClient().setup(
        route == AccessibilityPage.routeName ? 'accessibility' : 'adb',
      );
      if (opened) return;
    } catch (_) {}
    if (context.mounted) {
      showActionNotice(
        context,
        AppLocalizations.of(context)!.appError,
        error: true,
      );
    }
    return;
  }
  await Navigator.of(context).push(
    SettingsRoute<void>(
      settings: RouteSettings(name: route),
      builder: (_) => Material(type: MaterialType.transparency, child: page),
    ),
  );
  if (context.mounted) await onReturn?.call();
}

class AccessibilitySettingsLink extends StatelessWidget {
  const AccessibilitySettingsLink({
    super.key,
    this.onReturn,
    this.autofocus = false,
    this.busy = false,
  });

  final Future<void> Function()? onReturn;
  final bool autofocus;
  final bool busy;

  static Future<void> open(
    BuildContext context, {
    Future<void> Function()? onReturn,
  }) => _openSettings(
    context,
    AccessibilityPage.routeName,
    const AccessibilityPage(),
    onReturn,
  );

  @override
  Widget build(BuildContext context) => FocusableSettingsTile(
    title: Text(AppLocalizations.of(context)!.accessibility),
    leading: const Icon(Icons.accessibility_new),
    autofocus: autofocus,
    busy: busy,
    onPressed: () => open(context, onReturn: onReturn),
  );
}

class AdbConnectionLink extends StatelessWidget {
  const AdbConnectionLink({
    super.key,
    this.onReturn,
    this.autofocus = false,
    this.busy = false,
  });

  final Future<void> Function()? onReturn;
  final bool autofocus;
  final bool busy;

  static Future<void> open(
    BuildContext context, {
    Future<void> Function()? onReturn,
  }) => _openSettings(
    context,
    AdbPage.connectionRouteName,
    const AdbPage(section: 'connection'),
    onReturn,
  );

  @override
  Widget build(BuildContext context) => FocusableSettingsTile(
    title: Text(AppLocalizations.of(context)!.adbConnectionBlock),
    leading: const Icon(Icons.link),
    autofocus: autofocus,
    busy: busy,
    onPressed: () => open(context, onReturn: onReturn),
  );
}
