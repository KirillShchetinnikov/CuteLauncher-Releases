import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'adaptive_landscape.dart';
import 'landscape_schedule.dart';
import 'location_coordinates.dart';
import 'document_files.dart';
import 'bridge_result.dart';
import 'diagnostics_store.dart';
import 'background_video_diagnostics.dart';
import 'tv_compatibility_report.dart';
import 'permission_recovery_diagnostics.dart';
import 'diagnostic_catalog.dart';
import 'media_capabilities.dart';
import 'providers/apps_service.dart';
import 'providers/night_mode_service.dart';
import 'providers/settings_service.dart';
import 'providers/weather_service.dart';
import 'weather_sources.dart';

Future<String?> saveDiagnosticsReport(
  Map<String, Object> report, {
  DocumentExporter? exporter,
}) async {
  final directory = await (await getTemporaryDirectory()).createTemp(
    'diagnostics-',
  );
  try {
    final file = File('${directory.path}/report.json');
    await file.writeAsString(DiagnosticsStore.instance.encode(report));
    return await (exporter ?? DocumentFiles.saveDiagnostics)(
      file,
      name:
          'cutelauncher_diagnostics_${DateTime.now().millisecondsSinceEpoch}.json',
    );
  } finally {
    await directory.delete(recursive: true);
  }
}

Future<Map<String, Object>> collectDiagnostics({
  AppsService? apps,
  SettingsService? settings,
  NightModeService? nightMode,
  WeatherService? weather,
}) async {
  const channel = BridgeChannel('me.efesser.flauncher/method');
  String? version, build;
  Map<dynamic, dynamic>? environment, memory, shell;
  Map<String, Object>? compatibility;
  Map<String, Object>? permissionRecovery;
  Map<String, Object>? media;
  // Capture the current launcher state before asynchronous platform queries.
  final sections = diagnosticSections(apps, settings);
  Map<String, Object>? landscape;
  if (settings != null && settings.backgroundSource == 'landscape') {
    final now = DateTime.now();
    final config = settings.landscape;
    final schedule = resolveLandscapeSchedule(now, config, nightMode, weather);
    landscape = landscapeLightingDiagnostics(
      now,
      config,
      solarDays: schedule.days,
      scheduleSource: schedule.source,
      demoActive: settings.landscapeDemo.value != null,
    )..['locationAvailable'] =
        landscapeCoordinates(nightMode?.configuration, weather) != null;
  }
  final locations = locationSetupDiagnostics(
    nightMode?.configuration,
    weather?.configuration,
  );
  List<dynamic>? installed;
  try {
    installed = await channel.invokeListMethod<dynamic>('getDiagnosticApplications')
        .timeout(const Duration(seconds: 15));
  } catch (_) {}
  try {
    final info = await PackageInfo.fromPlatform();
    version = info.version;
    build = info.buildNumber;
  } catch (_) {
    /* Unavailable metadata is omitted; never store exception text. */
  }
  try {
    environment = await channel.invokeMapMethod('getDiagnosticEnvironment');
  } catch (_) {}
  try {
    memory = await channel.invokeMapMethod('getProcessMemoryUsage');
  } catch (_) {}
  try {
    shell = await channel.invokeMapMethod('getNativeShellDiagnostics');
  } catch (_) {}
  final capturedAt = DateTime.now();
  try {
    final raw = await channel
        .invokeMapMethod('getTvCompatibilityDiagnostics')
        .timeout(const Duration(seconds: 15));
    if (raw == null || raw['identity'] is! Map || raw['checks'] is! Map) {
      throw StateError('Compatibility snapshot unavailable');
    }
    if (raw['permissionRecovery'] is Map) {
      permissionRecovery = permissionRecoveryDiagnostics(raw['permissionRecovery'] as Map);
    }
    media = mediaCapabilities(raw['mediaCapabilities']);
    compatibility = createTvCompatibilityReport(
      raw,
      capturedAt: capturedAt,
      version: version,
      build: build,
    );
  } catch (error, stack) {
    DiagnosticsStore.instance.recordException(
      'getTvCompatibilityDiagnostics',
      error,
      stack,
    );
  }
  await BackgroundVideoDiagnostics.flush();
  final diagnostics = DiagnosticsStore.instance.snapshot(
    version: version,
    build: build,
    environment: environment,
    memory: memory,
    nativeShell: shell,
  );
  if (permissionRecovery != null) diagnostics['permissionRecovery'] = permissionRecovery;
  if (media != null) diagnostics['mediaCapabilities'] = media;
  if (landscape != null) diagnostics['landscapeLighting'] = landscape;
  if (locations.isNotEmpty) diagnostics['locationSetup'] = locations;
  diagnostics['installedApplications'] = diagnosticApplications(installed, apps);
  diagnostics['launcherSections'] = sections;
  diagnostics['privacy'] = <String, Object>{
    ...diagnostics['privacy'] as Map<String, Object>,
    'catalogIdentifiers': 'packageIdsAppLabelsAndSectionNamesIncluded',
  };
  return combineDiagnosticsReport(
    diagnostics,
    compatibility,
    capturedAt: capturedAt,
  );
}

/// Explains the normal scene's expected lighting without reading its pixels
/// or exposing coordinates, city, or installed applications.
Map<String, Object> landscapeLightingDiagnostics(
  DateTime now,
  LandscapeConfiguration config, {
  required List<Map<String, dynamic>> solarDays,
  required bool demoActive,
  String? scheduleSource,
}) {
  final sun = landscapeSunTimes(now, solarDays);
  final light = landscapeLight(now, config, solarDays: solarDays);
  return {
    'sampledAt': now.toUtc().toIso8601String(),
    'utcOffsetMinutes': now.timeZoneOffset.inMinutes,
    'variant': config.variant,
    'timeOfDay': config.timeOfDay,
    'demoActive': demoActive,
    'schedule': config.schedule.name,
    'sunSource': scheduleSource ??
        (sun.usesSchedule ? 'nightModeSchedule' : 'landscapeDefault'),
    'sunrise': sun.sunrise.toUtc().toIso8601String(),
    'sunset': sun.sunset.toUtc().toIso8601String(),
    'phase': landscapePhase(now, config, solarDays: solarDays).name,
    'paletteFrom': light.from.name,
    'paletteTo': light.to.name,
    'paletteMix': light.mix,
  };
}

/// Reports which location inputs are populated without exporting their values.
Map<String, Object> locationSetupDiagnostics(
  NightModeConfiguration? night,
  WeatherConfiguration? weather,
) => {
  if (night != null)
    'nightMode': {
      'cityConfigured': night.city.trim().isNotEmpty,
      'coordinatesStored': night.hasSavedCoordinates,
      'manualCoordinatesConfigured': night.hasManualCoordinates,
      'activeCoordinates': coordinatesFrom(night.latitude, night.longitude) != null,
      'automaticLocation': night.automaticLocation,
    },
  if (weather != null)
    'weather': {
      'cityConfigured': weather.location.trim().isNotEmpty,
      'coordinatesStored': weather.validCityCoordinates ||
          weather.manualCoordinates != null ||
          coordinatesFrom(weather.latitude, weather.longitude) != null,
      'manualCoordinatesConfigured': weather.manualCoordinates != null,
      'activeCoordinates': weather.selectedCoordinates != null,
      'automaticLocation': weather.locationMode == WeatherLocationMode.automatic,
    },
};

Future<void> clearDiagnostics() async {
  try {
    await const BridgeChannel('me.efesser.flauncher/method')
        .invokeMethod<bool>('clearNativeShellDiagnostics');
  } catch (_) {}
  DiagnosticsStore.instance.clear();
}
