import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'adaptive_landscape.dart';
import 'landscape_schedule.dart';
import 'location_coordinates.dart';
import 'document_files.dart';
import 'diagnostics_store.dart';
import 'tv_compatibility_report.dart';
import 'permission_recovery_diagnostics.dart';
import 'diagnostic_catalog.dart';
import 'media_capabilities.dart';
import 'providers/apps_service.dart';
import 'providers/night_mode_service.dart';
import 'providers/settings_service.dart';
import 'providers/weather_service.dart';
import 'weather_sources.dart';

const _channel = MethodChannel('me.efesser.flauncher/method');
const _metadataTimeout = Duration(seconds: 5);
Future<void>? _pendingStart;

Future<void> startDiagnosticsRecording() => _pendingStart ??= _startRecording()
    .whenComplete(() => _pendingStart = null);

Future<void> _startRecording() async {
  final store = DiagnosticsStore.instance;
  if (store.recording.value != DiagnosticRecordingState.idle) return;
  final generation = store.generation;
  try {
    final started = await _channel
        .invokeMethod<bool>('startNativeShellDiagnostics')
        .timeout(_metadataTimeout);
    if (started != true || generation != store.generation) {
      throw StateError('Could not start native diagnostics');
    }
  } catch (_) {
    await _controlNativeShell('clearNativeShellDiagnostics');
    rethrow;
  }
  store.startRecording(
    onStop: () {
      unawaited(_controlNativeShell('stopNativeShellDiagnostics'));
    },
  );
}

Future<void> _controlNativeShell(String method) async {
  try {
    await _channel.invokeMethod<bool>(method).timeout(_metadataTimeout);
  } catch (_) {
    // The native recording has its own deadline.
  }
}

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
  bool extended = false,
  AppsService? apps,
  SettingsService? settings,
  NightModeService? nightMode,
  WeatherService? weather,
}) async {
  final store = DiagnosticsStore.instance;
  if (extended) store.finishRecording();
  final capturedAt = DateTime.now();
  final diagnostics = store.snapshot(extended: extended)
    ..['reportMode'] = extended ? 'extended' : 'basic';
  String? version, build;
  Map<dynamic, dynamic>? environment;
  try {
    final info = await PackageInfo.fromPlatform().timeout(_metadataTimeout);
    version = info.version;
    build = info.buildNumber;
  } catch (_) {}
  try {
    environment = await _channel
        .invokeMapMethod('getDiagnosticEnvironment')
        .timeout(_metadataTimeout);
  } catch (_) {}
  diagnostics.addAll(
    DiagnosticsStore.reportMetadata(
      version: version,
      build: build,
      environment: environment,
    ),
  );
  if (!extended) {
    diagnostics
      ..remove('memory')
      ..['schemaVersion'] = 3
      ..['reportType'] = 'diagnostics'
      ..['capturedAt'] = capturedAt.toUtc().toIso8601String();
    return diagnostics;
  }

  Map<String, Object>? compatibility;
  Map<String, Object>? permissionRecovery;
  Map<String, Object>? media;
  final sections = diagnosticSections(apps, settings);
  Map<String, Object>? landscape;
  if (settings != null && settings.backgroundSource == 'landscape') {
    final now = DateTime.now();
    final config = settings.landscape;
    final schedule = resolveLandscapeSchedule(now, config, nightMode, weather);
    landscape =
        landscapeLightingDiagnostics(
            now,
            config,
            solarDays: schedule.days,
            scheduleSource: schedule.source,
            demoActive: settings.landscapeDemo.value != null,
          )
          ..['locationAvailable'] =
              landscapeCoordinates(nightMode?.configuration, weather) != null;
  }
  final locations = locationSetupDiagnostics(
    nightMode?.configuration,
    weather?.configuration,
  );
  List<dynamic>? installed;
  try {
    installed = await _channel
        .invokeListMethod<dynamic>('getDiagnosticApplications')
        .timeout(const Duration(seconds: 15));
  } catch (_) {}
  Map<dynamic, dynamic>? memory;
  try {
    memory = await _channel
        .invokeMapMethod('getProcessMemoryUsage')
        .timeout(_metadataTimeout);
  } catch (_) {}
  try {
    final shell = await _channel
        .invokeMapMethod('getNativeShellDiagnostics')
        .timeout(_metadataTimeout);
    diagnostics['nativeShell'] = DiagnosticsStore.shellSnapshot(shell);
  } catch (_) {}
  try {
    final raw = await _channel
        .invokeMapMethod('getTvCompatibilityDiagnostics')
        .timeout(const Duration(seconds: 15));
    if (raw == null || raw['identity'] is! Map || raw['checks'] is! Map) {
      throw StateError('Compatibility snapshot unavailable');
    }
    if (raw['permissionRecovery'] is Map) {
      permissionRecovery = permissionRecoveryDiagnostics(
        raw['permissionRecovery'] as Map,
      );
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
  diagnostics.addAll(
    DiagnosticsStore.reportMetadata(
      version: version,
      build: build,
      environment: environment,
      memory: memory,
    ),
  );
  if (permissionRecovery != null) {
    diagnostics['permissionRecovery'] = permissionRecovery;
  }
  if (media != null) diagnostics['mediaCapabilities'] = media;
  if (landscape != null) diagnostics['landscapeLighting'] = landscape;
  if (locations.isNotEmpty) diagnostics['locationSetup'] = locations;
  diagnostics['installedApplications'] = diagnosticApplications(
    installed,
    apps,
  );
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
    'sunSource':
        scheduleSource ??
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
      'activeCoordinates':
          coordinatesFrom(night.latitude, night.longitude) != null,
      'automaticLocation': night.automaticLocation,
    },
  if (weather != null)
    'weather': {
      'cityConfigured': weather.location.trim().isNotEmpty,
      'coordinatesStored':
          weather.validCityCoordinates ||
          weather.manualCoordinates != null ||
          coordinatesFrom(weather.latitude, weather.longitude) != null,
      'manualCoordinatesConfigured': weather.manualCoordinates != null,
      'activeCoordinates': weather.selectedCoordinates != null,
      'automaticLocation':
          weather.locationMode == WeatherLocationMode.automatic,
    },
};

Future<void> discardDiagnosticsRecording() {
  DiagnosticsStore.instance.discardRecording();
  return _controlNativeShell('clearNativeShellDiagnostics');
}

Future<void> clearDiagnostics() {
  DiagnosticsStore.instance.clear();
  return _controlNativeShell('clearNativeShellDiagnostics');
}
