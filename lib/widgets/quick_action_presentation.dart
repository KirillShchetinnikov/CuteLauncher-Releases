import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../quick_actions.dart';

extension QuickActionPresentation on QuickAction {
  String label(AppLocalizations l) => switch (this) {
    QuickAction.sleep => l.quickActionsSleep,
    QuickAction.shutdown => l.tvPowerOff,
    QuickAction.reboot => l.tvPowerReboot,
    QuickAction.screensaver => l.dialogOptionBackButtonActionShowScreensaver,
    QuickAction.wallpaper => l.wallpaperRefresh,
  };

  IconData get icon => switch (this) {
    QuickAction.sleep => Icons.bedtime_outlined,
    QuickAction.shutdown => Icons.power_settings_new,
    QuickAction.reboot => Icons.restart_alt,
    QuickAction.screensaver => Icons.desktop_windows_outlined,
    QuickAction.wallpaper => Icons.wallpaper_outlined,
  };
}
