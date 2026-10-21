import 'settings_value_stepper.dart';
import 'settings_slider_tile.dart';
import 'adb_permission_tile.dart';
import 'settings_page_layout.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/brightness_service.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';

import 'focusable_settings_tile.dart';

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
          if (service.solarEnabled) ...[
            for (final sunrise in [true, false])
              SettingsValueStepper(
                title: sunrise
                    ? l.brightnessAfterNightEnd
                    : l.brightnessAfterNightStart,
                value: sunrise
                    ? service.sunriseBrightness
                    : service.sunsetBrightness,
                options: [for (var i = 0; i <= 100; i += 5) i],
                label: (v) => '$v%',
                onChanged: (v) => service.setSolarBrightness(sunrise, v as int),
              ),
            if (!service.solarAvailable) Text(l.brightnessSolarUnavailable),
          ] else
            for (final slot in TimeSlot.values)
              SettingsValueStepper(
                title: _hours(slot),
                value: service.getBrightnessForSlot(slot),
                options: const [10, 20, 40, 50, 60, 80, 100],
                label: (v) => '$v%',
                onChanged: (v) => service.setBrightnessForSlot(slot, v as int),
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
