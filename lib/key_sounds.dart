import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'flauncher_channel.dart';
import 'providers/settings_service.dart';

/// Marks Home controls; settings routes use their own independent preference.
class HomeKeySoundScope extends InheritedWidget {
  const HomeKeySoundScope({super.key, required super.child});

  static bool contains(BuildContext context) =>
      context.getInheritedWidgetOfExactType<HomeKeySoundScope>() != null;

  @override
  bool updateShouldNotify(HomeKeySoundScope oldWidget) => false;
}

void playKeySound(BuildContext context) {
  final settings = context.read<SettingsService?>();
  final enabled = HomeKeySoundScope.contains(context)
      ? settings?.homeKeyClickEnabled
      : settings?.appKeyClickEnabled;
  if (enabled == true) FLauncherChannel().playClickSound();
}
