import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../adaptive_landscape.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/settings_service.dart';
import '../../providers/night_mode_service.dart';
import '../rounded_switch_list_tile.dart';
import 'settings_choice_tile.dart';
import 'settings_help.dart';
import 'focusable_settings_tile.dart';
import 'settings_page_layout.dart';
import 'reset_style_tile.dart';

class LandscapePage extends StatefulWidget {
  const LandscapePage({super.key});
  @override
  State<LandscapePage> createState() => _LandscapePageState();
}

class _LandscapePageState extends State<LandscapePage>
    with WidgetsBindingObserver {
  Timer? _demoTimer;
  SettingsService? _settings;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = context.read<SettingsService>();
    if (identical(settings, _settings)) return;
    _settings?.landscapeDemo.removeListener(_demoChanged);
    _settings = settings;
    settings.landscapeDemo.addListener(_demoChanged);
  }

  void _demoChanged() {
    if (_settings!.landscapeDemo.value == null && _demoTimer != null) {
      setState(() {
        _demoTimer?.cancel();
        _demoTimer = null;
      });
    }
  }

  void _stop({bool deferNotification = false}) {
    _demoTimer?.cancel();
    _demoTimer = null;
    final settings = _settings;
    if (settings == null || settings.isDisposed) return;
    final frame = settings.landscapeDemo.value;
    if (deferNotification && frame != null) {
      scheduleMicrotask(() {
        if (!settings.isDisposed &&
            identical(settings.landscapeDemo.value, frame)) {
          settings.landscapeDemo.value = null;
        }
      });
    } else {
      settings.landscapeDemo.value = null;
    }
  }

  void _toggle() {
    if (_demoTimer != null) {
      setState(_stop);
      return;
    }
    final start = DateTime.now();
    _settings = context.read<SettingsService>();
    final timeline = LandscapeDemoTimeline(
      start,
      solarDays: context.read<NightModeService?>()?.solarDays ?? const [],
    );
    _settings!.landscapeDemo.value = LandscapeDemoFrame(
      Duration.zero,
      start,
      timeline: timeline,
    );
    setState(() {
      _demoTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        final elapsed = Duration(milliseconds: timer.tick * 100);
        final frame = LandscapeDemoFrame(elapsed, start, timeline: timeline);
        if (frame.isComplete) {
          setState(_stop);
          return;
        }
        _settings!.landscapeDemo.value = frame;
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _demoTimer != null) {
      setState(_stop);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settings?.landscapeDemo.removeListener(_demoChanged);
    _stop(deferNotification: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    final config = settings.landscape;
    Widget effect(String title, String key) => RoundedSwitchListTile(
      title: Text(title),
      value: config.toJson()[key] == true,
      onChanged: (value) =>
          settings.setLandscape(settings.landscape.withValue(key, value)),
    );
    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _stop();
      },
      child: SettingsPageLayout(
        title: Text(l.adaptiveLandscape),
        child: ListView(
          children: [
            FocusableSettingsTile(
              title: Text(l.landscapeDemoStart),
              leading: const Icon(Icons.play_arrow),
              onPressed: _toggle,
            ),
            SettingsChoiceTile<String>(
              autofocus: true,
              title: l.landscapeVariant,
              value: config.variant,
              options: const ['illustrated', 'realistic'],
              label: (v) => v == 'realistic'
                  ? l.landscapeRealistic
                  : l.landscapeIllustrated,
              onChanged: (v) => settings.setLandscape(
                settings.landscape.withValue('variant', v),
              ),
            ),
            effect(l.landscapeTimeOfDay, 'timeOfDay'),
            effect(l.landscapeCelestialBodies, 'celestialBodies'),
            effect(l.landscapeStarRotation, 'starRotation'),
            effect(l.landscapeSeasons, 'seasons'),
            SettingsChoiceTile<String>(
              title: l.landscapeHemisphere,
              value: config.hemisphere,
              options: const ['auto', 'north', 'south'],
              label: (v) => switch (v) {
                'north' => l.landscapeNorth,
                'south' => l.landscapeSouth,
                _ => l.landscapeAuto,
              },
              onChanged: (v) => settings.setLandscape(
                settings.landscape.withValue('hemisphere', v),
              ),
            ),
            effect(l.landscapeClouds, 'clouds'),
            effect(l.landscapePrecipitation, 'precipitation'),
            effect(l.landscapeFog, 'fog'),
            effect(l.landscapeMotion, 'motion'),
            SettingsHelp(text: l.landscapeHelp),
            ResetStyleTile(
              onReset: () =>
                  settings.setLandscape(const LandscapeConfiguration()),
            ),
          ],
        ),
      ),
    );
  }
}
