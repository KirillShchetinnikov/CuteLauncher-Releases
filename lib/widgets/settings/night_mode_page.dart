import 'settings_help.dart';
import '../../providers/tv_inputs_service.dart';
import '../../models/tv_input.dart';
import '../tv_input_icon.dart';
import '../application_list_icon.dart';
import 'city_search_dialog.dart';
import '../action_notice.dart';

import 'package:flauncher/widgets/launcher_dialog.dart';

import 'settings_slider_tile.dart';
import 'settings_choice_tile.dart';
import 'settings_time_tile.dart';
import 'adb_permission_tile.dart';
import 'settings_page_layout.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/night_mode_service.dart';
import '../../providers/apps_service.dart';
import 'settings_route.dart';
import '../rounded_switch_list_tile.dart';
import 'focusable_settings_tile.dart';

class NightModePage extends StatefulWidget {
  static const routeName = 'night_mode_panel';
  final String section;
  const NightModePage({super.key, this.section = 'main'});
  @override
  State<NightModePage> createState() => _NightModePageState();
}

class _NightModePageState extends State<NightModePage> {
  bool _locating = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NightModeService>().refreshSystem();
        if (widget.section == 'inputs') _refreshInputs();
        if (widget.section == 'picture') { context.read<NightModeService>().refreshPictureMode(); }
      }
    });
  }

  Future<void> _refreshInputs() async {
    try { await context.read<TvInputsService?>()?.refreshInputs(); }
    catch (e) { debugPrint('Unable to refresh TV inputs: $e'); }
  }

  void open(String section) => Navigator.of(context).push(
    SettingsRoute(
      settings: RouteSettings(name: "night_$section"),
      builder: (_) => Material(
        color: Colors.transparent,
        child: NightModePage(section: section),
      ),
    ),
  );
  Future<void> _openBatterySettings(
    BuildContext context,
    NightModeService service,
  ) async {
    final l = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final status = await service.openBatterySettings(
      guide: {
        'title': 'CuteLauncher',
        'hint': l.nightBatteryGuide,
        'surface': colors.surface.toARGB32(),
        'text': colors.onSurface.toARGB32(),
        'primary': colors.primary.toARGB32(),
      },
    );
    if (status != 'hintRequired' || !context.mounted) return;
    final proceed = await showLauncherDialog<bool>(
      context: context,
      builder: (context) => LauncherAlertDialog(
        title: Text(l.nightBatteryTitle),
        content: SingleChildScrollView(child: Text(l.nightBatteryGuide)),
        actions: [
          LauncherDialogButton(
            onPressed: () => Navigator.pop(context, false),
            isCancel: true,
            child: Text(l.cancel),
          ),
          LauncherDialogButton(
            autofocus: true,
            primary: true,
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.nightBatteryOpenApps),
          ),
        ],
      ),
    );
    if (proceed == true && context.mounted) {
      await service.openBatterySettings(withoutOverlay: true);
    }
  }

  List<Widget> _excluded(BuildContext context, NightModeService service) {
    final names = {
      for (final category in context.watch<AppsService>().categories)
        if (category.systemKey == 'all_apps')
          for (final app in category.applications) app.packageName: app.name,
    };
    final selected = service.configuration.excludedPackages.toSet();
    final packages = names.keys.toList()
      ..sort((a, b) {
        final order =
            (selected.contains(b) ? 1 : 0) - (selected.contains(a) ? 1 : 0);
        return order != 0
            ? order
            : (names[a] ?? a).toLowerCase().compareTo(
                (names[b] ?? b).toLowerCase(),
              );
      });
    return [
      for (final package in packages)
        RoundedSwitchListTile(
          key: ValueKey(package),
          secondary: ApplicationListIcon(packageName: package),
          title: Text(names[package] ?? package),
          value: selected.contains(package),
          enabled: selected.contains(package) || selected.length < 128,
          onChanged: (value) {
            final next = service.configuration.excludedPackages.toSet();
            value ? next.add(package) : next.remove(package);
            service.configure(
              service.configuration.copyWith(excludedPackages: next.toList()),
            );
          },
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<NightModeService>();
    final c = service.configuration;
    final inputs = context.watch<TvInputsService?>()?.inputs.where((i) => i.type == TvInputType.hdmi && i.parentId == null).toList() ?? <TvInput>[];
    final l = AppLocalizations.of(context)!;
    final pictureModes = <int, String>{
      0: l.nightPictureStandard, 1: l.nightPictureDynamic,
      3: l.nightPictureMovie, 4: l.nightPictureSport,
      10: l.nightPictureIntelligent,
      16: '${l.nightPictureStandard} (HDR)',
      17: '${l.nightPictureDynamic} (HDR)',
      19: '${l.nightPictureMovie} (HDR)',
      20: '${l.nightPictureSport} (HDR)',
      26: '${l.nightPictureIntelligent} (HDR)',
      27: 'IMAX (HDR)', 29: 'FILMMAKER MODE (HDR)',
      46: l.nightPictureBright, 51: 'Dolby Vision IQ',
      53: 'FILMMAKER MODE (Dolby Vision)', 60: 'FILMMAKER MODE',
    };
    for (final mode in c.ignoredPictureModes) {
      pictureModes.putIfAbsent(mode, () => '${l.nightPictureCode} $mode');
    }
    String modeLabel(int mode) => pictureModes[mode] ?? '${l.nightPictureCode} $mode';
    final pictureGroups = <String, List<int>>{
      l.nightPictureOrdinary: [0, 1, 3, 4, 10, 60],
      'HDR': [16, 17, 19, 20, 26, 27, 29],
      'Dolby Vision': [46, 51, 53],
    };
    Widget pictureTile(int mode) => Semantics(
      checked: c.ignoredPictureModes.contains(mode),
      child: FocusableSettingsTile(
        title: Text(modeLabel(mode)),
        trailing: Icon(c.ignoredPictureModes.contains(mode)
            ? Icons.check_box : Icons.check_box_outline_blank),
        onPressed: () {
          final selected = c.ignoredPictureModes.toSet();
          if (!selected.add(mode)) selected.remove(mode);
          service.configure(c.copyWith(ignoredPictureModes: selected.toList()));
        },
      ),
    );
    Future<void> update(NightModeConfiguration value) =>
        service.configure(value);
    String clock(int minute) =>
        '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
    String date(DateTime? value) => value == null
        ? '—'
        : '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')} ${clock(value.hour * 60 + value.minute)}';
    Widget time(String label, int value, ValueChanged<int> changed) =>
        SettingsTimeTile(title: label, value: value, onChanged: changed);
    Widget offset(String label, int value, ValueChanged<int> changed) =>
        SettingsSliderTile(
          title: label,
          value: value,
          options: ({for (var i = -180; i <= 180; i += 15) i, value}.toList()
            ..sort()),
          label: (v) => v == 0
              ? l.nightNoOffset
              : '${v < 0 ? '−' : '+'}${clock(v.abs().toInt())}',
          onChanged: (v) => changed(v.toInt()),
        );
    final now = DateTime.now();
    final intervals =
        c
            .intervals(now, solarDays: service.solarDays)
            .where((interval) => interval.$2.isAfter(now))
            .toList()
          ..sort((a, b) => a.$1.compareTo(b.$1));
    final actualStart = intervals.isEmpty ? null : intervals.first.$1;
    final actualEnd = intervals.isEmpty ? null : intervals.first.$2;
    final overrideActive =
        c.overrideMode != 'none' &&
        c.overrideUntil > DateTime.now().millisecondsSinceEpoch;
    return SettingsPageLayout(
      title: Text(switch (widget.section) {
        'filter' => l.nightFilterSettings,
        'schedule' => l.nightScheduleMenu,
        'excluded' => l.nightExcludedApps,
        'inputs' => l.nightInputExclusions,
        'picture' => l.nightPictureExclusions,
        _ => l.nightModeTitle,
      }, style: Theme.of(context).textTheme.titleLarge),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (widget.section == 'main') ...[
            RoundedSwitchListTile(
              autofocus: true,
              value: c.enabled,
              title: Text(l.nightModeEnabled),
              onChanged: (v) =>
                  update(c.copyWith(enabled: v, clearOverrides: true)),
            ),
            FocusableSettingsTile(
              leading: const Icon(Icons.tune),
              title: Text(l.nightFilterSettings),
              onPressed: () => open('filter'),
            ),
            FocusableSettingsTile(
              leading: const Icon(Icons.schedule),
              title: Text(l.nightScheduleMenu),
              onPressed: () => open('schedule'),
            ),
            FocusableSettingsTile(
              leading: const Icon(Icons.filter_alt_off),
              title: Text(
                '${l.nightExcludedApps} (${c.excludedPackages.length})',
              ),
              onPressed: () => open('excluded'),
            ),
            FocusableSettingsTile(leading: const Icon(Icons.settings_input_hdmi),
              title: Text(l.nightInputExclusions), onPressed: () => open('inputs')),
            FocusableSettingsTile(
              leading: const Icon(Icons.image_outlined),
              title: Text('${l.nightPictureExclusions} (${c.ignoredPictureModes.length})'),
              onPressed: () => open('picture'),
            ),
          ],
          if (widget.section == 'picture') ...[
            SettingsHelp(text: l.nightPictureExclusionsHint),
            if (service.pictureModeKnown && service.pictureMode == null)
              SettingsHelp(text: l.nightPictureUnavailable),
            if (service.pictureMode != null)
              Text('${l.nightPictureCurrent}: ${modeLabel(service.pictureMode!)}'),
            FocusableSettingsTile(
              autofocus: true,
              leading: const Icon(Icons.refresh),
              title: Text(l.nightPictureRefresh),
              onPressed: service.refreshPictureMode,
            ),
            for (final group in pictureGroups.entries) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Semantics(
                  header: true,
                  child: Text(group.key, style: Theme.of(context).textTheme.titleMedium),
                ),
              ),
              for (final mode in group.value) pictureTile(mode),
            ],
            for (final mode in pictureModes.keys.where((mode) =>
                !pictureGroups.values.any((codes) => codes.contains(mode))))
              pictureTile(mode),
          ],
          if (widget.section == 'inputs') ...[
            RoundedSwitchListTile(autofocus: true, value: c.ignoreHdmiInputs,
              title: Text(l.nightIgnoreHdmiInputs),
              onChanged: (v) => update(c.copyWith(ignoreHdmiInputs: v))),
            SettingsHelp(text: l.nightIgnoreHdmiInputsHint),
            if (!service.usagePermission) FocusableSettingsTile(
              title: Text(l.nightUsageAccess), onPressed: service.requestUsagePermission),
            if (c.ignoreHdmiInputs) ...[
              RoundedSwitchListTile(value: c.selectHdmiInputs,
                title: Text(l.nightSelectInputs),
                onChanged: (v) => update(c.copyWith(selectHdmiInputs: v))),
              if (c.selectHdmiInputs) ...[
                if (inputs.isEmpty) SettingsHelp(text: l.inputsUnavailableHint),
                if (c.ignoredHdmiInputIds.isEmpty) SettingsHelp(text: l.nightNoInputsSelected),
                for (final input in inputs) Semantics(
                  checked: c.ignoredHdmiInputIds.contains(input.id),
                  child: FocusableSettingsTile(leading: Icon(tvInputIcon(input)), title: Text(input.label),
                    trailing: Icon(c.ignoredHdmiInputIds.contains(input.id) ? Icons.check_box : Icons.check_box_outline_blank),
                    onPressed: () {
                      final selected = c.ignoredHdmiInputIds.toSet();
                      if (!selected.add(input.id)) selected.remove(input.id);
                      update(c.copyWith(ignoredHdmiInputIds: selected.toList()));
                    }),
                ),
              ],
            ],
          ],
          if (widget.section == 'excluded') ...[
            if (!service.usagePermission) ...[
              FocusableSettingsTile(
                autofocus: true,
                leading: const Icon(Icons.security),
                title: Text(l.nightUsageAccess),
                onPressed: service.requestUsagePermission,
              ),
              AdbPermissionTile(
                title: '${l.nightUsageAccess} · ADB',
                action: 'usage',
                permissionMethod: 'checkUsageStatsPermission',
                onRefresh: service.refreshSystem,
              ),
            ],
            ..._excluded(context, service),
          ],
          if (widget.section == 'schedule') ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  !c.enabled || !c.scheduled
                      ? l.nightScheduleInactive
                      : '${c.solar ? l.nightSolarSchedule : l.nightManualSchedule}\n${l.nightModeStart}: ${date(actualStart)}\n${l.nightModeEnd}: ${date(actualEnd)}'
                            '${overrideActive ? "\n${c.overrideMode == 'on' ? l.nightTemporaryOn : l.nightTemporaryOff}: ${date(DateTime.fromMillisecondsSinceEpoch(c.overrideUntil))}" : ""}',
                ),
              ),
            ),
            RoundedSwitchListTile(
              autofocus: true,
              value: c.scheduled,
              title: Text(l.nightModeScheduled),
              onChanged: (v) =>
                  update(c.copyWith(scheduled: v, clearOverrides: true)),
            ),
            if (c.scheduled) ...[
              if (service.intensity > 0)
                FocusableSettingsTile(
                  leading: const Icon(Icons.pause_circle_outline),
                  title: Text(l.nightSkipUntilNext),
                  onPressed: service.nextStart == null
                      ? null
                      : () => service.temporaryMode(false),
                )
              else
                FocusableSettingsTile(
                  leading: const Icon(Icons.wb_twilight),
                  title: Text(l.nightEnableUntilMorning),
                  onPressed: service.nextEnd == null
                      ? null
                      : () => service.temporaryMode(true),
                ),
              if (overrideActive) ...[
                Text(
                  '${c.overrideMode == 'on' ? l.nightTemporaryOn : l.nightTemporaryOff}: ${date(DateTime.fromMillisecondsSinceEpoch(c.overrideUntil))}',
                ),
                FocusableSettingsTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: Text(l.nightResumeSchedule),
                  onPressed: service.clearTemporaryMode,
                ),
              ],
            ],
            ...[
              const Divider(),
              Text(
                l.nightScheduleSettings,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SettingsChoiceTile<bool>(
                title: l.nightScheduleSource,
                value: c.solar,
                options: const [false, true],
                label: (v) => v ? l.nightSolarSchedule : l.nightManualSchedule,
                onChanged: (v) =>
                    update(c.copyWith(solar: v, clearOverrides: true)),
              ),
              if (!c.solar) ...[
                time(
                  l.nightModeStart,
                  c.startHour * 60 + c.startMinute,
                  (v) => update(
                    c.copyWith(
                      startHour: v ~/ 60,
                      startMinute: v % 60,
                      clearOverrides: true,
                    ),
                  ),
                ),
                time(
                  l.nightModeEnd,
                  c.endHour * 60 + c.endMinute,
                  (v) => update(
                    c.copyWith(
                      endHour: v ~/ 60,
                      endMinute: v % 60,
                      clearOverrides: true,
                    ),
                  ),
                ),
              ] else ...[
                SettingsChoiceTile<bool>(
                  title: l.nightLocation,
                  value: c.automaticLocation,
                  enabled: !_locating,
                  options: const [true, false],
                  label: (v) =>
                      v ? l.nightLocationAutomatic : l.nightLocationManual,
                  onChanged: (v) => update(c.copyWith(automaticLocation: v)),
                ),
                if (c.automaticLocation)
                  FocusableSettingsTile(
                    title: Text(l.weatherGetLocation),
                    trailing: Text(
                      c.latitude == null
                          ? l.settingsValueNotSet
                          : '${c.latitude!.toStringAsFixed(3)}, ${c.longitude!.toStringAsFixed(3)}',
                    ),
                    enabled: !_locating,
                    onPressed: () async {
                      setState(() => _locating = true);
                      try {
                        final point = await service.locate();
                        if (!mounted) return;
                        await update(
                          service.configuration.copyWith(
                            city: '',
                            latitude: (point['latitude'] as num).toDouble(),
                            longitude: (point['longitude'] as num).toDouble(),
                            clearOverrides: true,
                          ),
                        );
                        await service.refreshSolar();
                      } catch (_) {
                        if (context.mounted) {
                          setState(() => _locating = false);
                          showActionNotice(
                            context,
                            l.nightLocationFailed,
                            error: true,
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _locating = false);
                      }
                    },
                  )
                else
                  FocusableSettingsTile(
                    valueIcon: Icons.edit_outlined,
                    title: Text(l.nightCityName),
                    trailing: Text(
                      c.city.isEmpty ? l.settingsValueNotSet : c.city,
                    ),
                    onPressed: () async {
                      final city =
                          await showLauncherDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (_) => CitySearchDialog(
                              searchCities: (query) =>
                                  service.searchCities(query, 'en'),
                            ),
                          );
                      if (city != null && context.mounted) {
                        await update(
                          service.configuration.copyWith(
                            city: city['city'] as String,
                            latitude: (city['latitude'] as num).toDouble(),
                            longitude: (city['longitude'] as num).toDouble(),
                            clearOverrides: true,
                          ),
                        );
                        await service.refreshSolar();
                      }
                    },
                  ),
                if (_locating) const LinearProgressIndicator(),

                offset(
                  l.nightSunsetOffset,
                  c.sunsetOffset,
                  (v) =>
                      update(c.copyWith(sunsetOffset: v, clearOverrides: true)),
                ),
                offset(
                  l.nightSunriseOffset,
                  c.sunriseOffset,
                  (v) => update(
                    c.copyWith(sunriseOffset: v, clearOverrides: true),
                  ),
                ),
                if (service.solarLoading) const LinearProgressIndicator(),
                if (!service.solarLoading &&
                    (service.nextStart == null || service.nextEnd == null))
                  SettingsHelp(text: l.nightSolarUnavailable),
                if (service.solarUpdated > 0 &&
                    DateTime.now().millisecondsSinceEpoch -
                            service.solarUpdated >
                        86400000)
                  SettingsHelp(text: l.nightSolarCached),
              ],
            ],
            SettingsSliderTile(
              title: l.nightTransitionTime,
              value: c.transitionMinutes,
              options: [for (var i = 15; i <= 120; i += 15) i],
              label: (v) => '${v.round()} ${l.weatherMinutes}',
              onChanged: (v) =>
                  update(c.copyWith(transitionMinutes: v.toInt())),
            ),
            if (c.solar)
              FocusableSettingsTile(
                leading: const Icon(Icons.refresh),
                title: Text(l.nightRefreshSun),
                onPressed: service.solarLoading ? null : service.refreshSolar,
              ),
          ],
          if (widget.section == 'filter') ...[
            _NightSlider(
              label: l.nightModeDim,
              max: 95,
              value: c.dim,
              onChanged: (v) => update(service.configuration.copyWith(dim: v)),
            ),
            _NightSlider(
              label: l.nightModeWarmth,
              value: c.warmth,
              onChanged: (v) =>
                  update(service.configuration.copyWith(warmth: v)),
            ),
            _NightSlider(
              label: l.nightTemperature,
              value: c.temperature,
              min: 1000,
              max: 6500,
              step: 100,
              unit: 'K',
              onChanged: (v) =>
                  update(service.configuration.copyWith(temperature: v)),
            ),
            const Divider(),
            RoundedSwitchListTile(
              value: c.tclScheduled,
              enabled: service.tclFilterAvailable || c.tclScheduled,
              title: Text(l.tclBlueLightTitle),
              onChanged: (v) => update(
                c.copyWith(
                  tclScheduled: v,
                  tclOverrideMode: 'none',
                  tclOverrideUntil: 0,
                ),
              ),
            ),
            if (service.tclFilterBusy) const LinearProgressIndicator(),
            if (service.tclFilterStatus == 'unsupported')
              Text(l.tclBlueLightUnsupported),
            if (service.tclFilterStatus == 'error') Text(l.tclBlueLightError),
          ],
          if (widget.section == 'main') ...[
            const Divider(),
            Text(
              l.nightPermissions,
              style: Theme.of(context).textTheme.titleMedium,
            ),

            FocusableSettingsTile(
              leading: Icon(
                service.batteryExempt == null
                    ? Icons.help_outline
                    : service.batteryExempt!
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.nightBatteryTitle),
                  Text(
                    service.batteryExempt == null
                        ? l.nightBatteryUnknown
                        : service.batteryExempt!
                        ? l.nightBatteryExempt
                        : l.nightBatteryOptimized,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              onPressed: () => _openBatterySettings(context, service),
            ),
            SettingsHelp(text: l.nightBatteryHint),
            if (service.batterySettingsUnavailable)
              Text(l.nightBatteryUnavailable),
            ListTile(
              leading: Icon(
                !service.overlayPermissionKnown
                    ? Icons.help_outline
                    : service.overlayPermission
                    ? Icons.check_circle
                    : Icons.layers,
              ),
              title: Text(
                !service.overlayPermissionKnown
                    ? l.nightPermissionUnknown
                    : service.overlayPermission
                    ? l.nightModePermissionGranted
                    : l.nightModePermission,
              ),
              onTap: service.requestOverlayPermission,
            ),
            AdbPermissionTile(
              title: l.nightModeAdbPermission,
              action: 'overlay',
              permissionMethod: 'checkOverlayPermission',
              onRefresh: service.refreshSystem,
            ),
            SettingsHelp(text: l.nightOverlayBrief),
          ],
        ],
      ),
    );
  }
}

class _NightSlider extends StatelessWidget {
  final String label, unit;
  final int value, min, max, step;
  final ValueChanged<int> onChanged;
  const _NightSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 90,
    this.step = 5,
    this.unit = '%',
  });
  @override
  Widget build(BuildContext context) => SettingsSliderTile(
    title: label,
    value: value,
    options: [for (var i = min; i <= max; i += step) i],
    label: (v) => '${v.round()}$unit',
    onChanged: (v) => onChanged(v.toInt()),
  );
}
