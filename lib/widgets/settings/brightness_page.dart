import 'settings_information.dart';
import 'settings_section.dart';
import 'settings_slider_tile.dart';
import 'adb_permission_tile.dart';
import 'settings_page_layout.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/brightness_service.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';

import 'focusable_settings_tile.dart';

const _brightnessLevels = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100];

class BrightnessPage extends StatefulWidget {
  static const routeName = 'brightness_panel';
  const BrightnessPage({super.key});

  @override
  State<BrightnessPage> createState() => _BrightnessPageState();
}

class _BrightnessPageState extends State<BrightnessPage>
    with WidgetsBindingObserver {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<BrightnessService>().checkPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<BrightnessService>().checkPermission();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _toggle(BrightnessService service, bool enabled) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await service.setEnabled(enabled);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<BrightnessService>();
    return SettingsPageLayout(
      title: Text(
        l.brightnessScheduler,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      child: ListView(
        children: [
          RoundedSwitchListTile(
            autofocus: true,
            value: service.isEnabled,
            onChanged: (value) => _toggle(service, value),
            title: Text(l.brightnessScheduler),
          ),
          SettingsSection(
            key: const ValueKey('nightPermissions'),
            title: l.nightPermissions,
            children: [
              FocusableSettingsTile(
                title: Text(
                  service.hasPermission ? l.granted : l.permissionRequired,
                ),
                leading: const Icon(Icons.security),
                onPressed: service.requestPermission,
              ),
              AdbPermissionTile(
                title: l.nightModeAdbPermission,
                action: 'writeSettings',
                permissionMethod: 'checkWriteSettingsPermission',
                onRefresh: service.checkPermission,
              ),
            ],
          ),
          SettingsSection(
            key: const ValueKey('nightScheduleMenu'),
            title: l.nightScheduleMenu,
            children: [
              RoundedSwitchListTile(
                value: service.solarEnabled,
                title: Text(l.brightnessSolar),
                onChanged: service.setSolarEnabled,
              ),
              SettingsSliderTile(
                title: l.brightnessTransitionTime,
                value: service.transitionMinutes,
                options: [for (var i = 1; i <= 60; i++) i],
                label: (v) => '${v.round()} ${l.weatherMinutes}',
                onChanged: (v) => service.setTransitionMinutes(v.toInt()),
              ),
            ],
          ),
          SettingsSection(
            key: const ValueKey('settingsGroupBrightness'),
            title: l.settingsGroupBrightness,
            children: [
              if (service.solarEnabled) ...[
                for (final sunrise in [true, false])
                  SettingsSliderTile(
                    title: sunrise
                        ? l.brightnessAfterNightEnd
                        : l.brightnessAfterNightStart,
                    value: sunrise
                        ? service.sunriseBrightness
                        : service.sunsetBrightness,
                    options: _brightnessLevels,
                    label: (v) => '$v%',
                    onChanged: (v) =>
                        service.setSolarBrightness(sunrise, v.toInt()),
                  ),
                if (!service.solarAvailable)
                  SettingsMessage(
                    text: l.brightnessSolarUnavailable,
                    kind: SettingsMessageKind.warning,
                  ),
              ] else
                for (final slot in TimeSlot.values)
                  SettingsSliderTile(
                    title: _hours(slot),
                    value: service.getBrightnessForSlot(slot),
                    options: _brightnessLevels,
                    label: (v) => '$v%',
                    onChanged: (v) =>
                        service.setBrightnessForSlot(slot, v.toInt()),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  String _hours(TimeSlot slot) => const [
    '06:00–09:00',
    '09:00–15:00',
    '15:00–18:00',
    '18:00–22:00',
    '22:00–06:00',
  ][slot.index];
}
