import 'diagnostic_redactor.dart';
import 'models/category.dart';
import 'providers/apps_service.dart';
import 'providers/settings_service.dart';

const diagnosticAppLimit = 2000;
const diagnosticSectionLimit = 200;
const diagnosticMembershipLimit = 10000;

String? _package(Object? value) =>
    value is String &&
        value.length <= 255 &&
        RegExp(r'^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z0-9_]+)*$').hasMatch(value)
    ? value
    : null;
String _label(String value) => DiagnosticRedactor.text(
  value.length > 512 ? value.substring(0, 512) : value,
);

/// Explicit structured exception to log redaction: identifiers allow catalog matching.
Map<String, Object> diagnosticApplications(
  List<dynamic>? source,
  AppsService? apps,
) {
  if (source == null) return {'status': 'unavailable'};
  final cached = {
    for (final app in apps?.applications ?? []) app.packageName: app,
  };
  final rows = <Map<String, Object>>[];
  final seen = <String>{};
  var skipped = 0;
  for (final item in source) {
    if (item is! Map) {
      skipped++;
      continue;
    }
    final package = _package(item['packageName']);
    if (package == null || !seen.add(package)) {
      skipped++;
      continue;
    }
    if (rows.length >= diagnosticAppLimit) continue;
    rows.add({
      'packageName': package,
      for (final key in ['name', 'version'])
        if (item[key] is String) key: _label(item[key] as String),
      for (final key in ['system', 'launchable', 'sideloaded', 'enabled'])
        if (item[key] is bool) key: item[key] as bool,
      if (item['enabledSetting'] is int &&
          item['enabledSetting'] >= 0 &&
          item['enabledSetting'] <= 4)
        'enabledSetting': item['enabledSetting'] as int,
      if (item['versionCode'] is int && item['versionCode'] >= 0)
        'versionCode': item['versionCode'] as int,
      if (cached[package] != null) 'hidden': cached[package]!.hidden,
    });
  }
  rows.sort(
    (a, b) =>
        (a['packageName'] as String).compareTo(b['packageName'] as String),
  );
  return {
    'status': 'complete',
    'sourceCount': source.length,
    'skippedCount': skipped,
    'truncated': seen.length > rows.length,
    'applications': rows,
  };
}

Map<String, Object> diagnosticSections(
  AppsService? apps,
  SettingsService? settings,
) {
  if (apps == null || !apps.initialized) return {'status': 'unavailable'};
  final source = apps.launcherSections;
  final applications = apps.applications;
  var remaining = diagnosticMembershipLimit;
  var truncated = source.length > diagnosticSectionLimit;
  List<String> bounded(Iterable<String> values) {
    final valid = values.where((value) => _package(value) != null).toList();
    final count = valid.length.clamp(0, remaining);
    if (count < valid.length) truncated = true;
    remaining -= count;
    return valid.take(count).toList();
  }

  final rows = <Map<String, Object>>[];
  for (final section in source.take(diagnosticSectionLimit)) {
    if (section is Category) {
      final members =
          applications
              .where((app) => app.categoryOrders.containsKey(section.id))
              .toList()
            ..sort(
              (a, b) => a.categoryOrders[section.id]!.compareTo(
                b.categoryOrders[section.id]!,
              ),
            );
      rows.add({
        'id': section.id,
        'order': section.order,
        'type': 'category',
        'name': _label(section.name),
        if (section.systemKey != null &&
            Category.systemKeys.contains(section.systemKey))
          'systemKey': section.systemKey!,
        'automatic': section.isAutomatic,
        'visible': section.visible,
        'sort': section.sort.name,
        'layout': section.type.name,
        'columnsCount': section.columnsCount,
        'rowHeight': section.rowHeight,
        'applicationCount': section.applications.length,
        'applications': bounded(
          section.applications.map((app) => app.packageName),
        ),
        // Automatic links encode order only. Manual links can include filtered tiles.
        'storedOrder': bounded(members.map((app) => app.packageName)),
      });
    } else if (section is LauncherSpacer) {
      rows.add({
        'id': section.id,
        'order': section.order,
        'type': 'spacer',
        'height': section.height,
      });
    }
  }
  return {
    'status': 'complete',
    'truncated': truncated,
    'sourceCount': source.length,
    'sections': rows,
    if (settings != null)
      'continueWatching': {
        'enabled': settings.showContinueWatching,
        'order': settings.continueWatchingOrder,
      },
  };
}
