import 'dart:convert';
import 'dart:io';
import 'package:flauncher/tv_compatibility_report.dart';

const identityKeys = ['manufacturer', 'model', 'device', 'fingerprint'];
const propertyNames = {
  'manufacturer': 'ro.product.manufacturer', 'model': 'ro.product.model',
  'device': 'ro.product.device', 'fingerprint': 'ro.build.fingerprint',
  'firmware': 'ro.build.display.id', 'android': 'ro.build.version.release',
  'sdk': 'ro.build.version.sdk', 'abis': 'ro.product.cpu.abilist',
  'emulator': 'ro.kernel.qemu',
};

Map<String, dynamic> readJson(String path) => jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// Evidence belongs to a particular build and scenario, never to a brand as a whole.
List<String> validateCatalog(Map<String, dynamic> catalog, String evidence) {
  final errors = <String>[];
  if (catalog['schemaVersion'] != 1) errors.add('Unknown schemaVersion');
  final devices = catalog['devices'];
  if (devices is! List || devices.isEmpty) return [...errors, 'devices must be a non-empty list'];
  final ids = <String>{}, identities = <String>{};
  for (final entry in devices) {
    if (entry is! Map) { errors.add('Device is not an object'); continue; }
    final id = entry['id'];
    if (entry['label'] is! String || (entry['label'] as String).trim().isEmpty) errors.add('$id: label missing');
    if (id is! String || !RegExp(r'^[a-z0-9-]+$').hasMatch(id) || !ids.add(id)) errors.add('Invalid/duplicate id: $id');
    if (!['physical', 'emulator'].contains(entry['kind'])) errors.add('$id: invalid kind');
    final identity = entry['identity'];
    if (identity is! Map) { errors.add('$id: identity missing'); continue; }
    for (final key in [...identityKeys, 'firmware', 'android', 'sdk', 'abis']) {
      if (!identity.containsKey(key) || (identity[key] != null && (identity[key] is! String || (identity[key] as String).trim().isEmpty))) {
        errors.add('$id: invalid identity.$key');
      }
    }
    final complete = identityKeys.every((key) => identity[key] is String && (identity[key] as String).trim().isNotEmpty);
    if (entry['exactMatch'] is! bool || (entry['exactMatch'] == true && !complete)) errors.add('$id: exactMatch needs complete identity');
    if (entry['exactMatch'] == true && !identities.add(identityKeys.map((key) => identity[key]).join('\n'))) errors.add('$id: duplicate exact identity');
    final results = entry['results'];
    if (results is! List || results.isEmpty) { errors.add('$id: results missing'); continue; }
    final features = <String>{};
    for (final result in results) {
      if (result is! Map) { errors.add('$id: invalid result'); continue; }
      final feature = result['feature'];
      if (feature is! String || feature.trim().isEmpty || !features.add(feature)) errors.add('$id: invalid/duplicate feature');
      if (!['verified', 'failed', 'limitation', 'unverified'].contains(result['status'])) errors.add('$id/$feature: invalid status');
      for (final key in ['summary', 'appBuild', 'date', 'evidenceSection']) {
        if (result[key] is! String || (result[key] as String).trim().isEmpty) errors.add('$id/$feature: missing $key');
      }
      final date = result['date'];
      if (date is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) ||
          DateTime.tryParse(date)?.toIso8601String().split('T').first != date) {
        errors.add('$id/$feature: invalid date');
      }
      if (!evidence.split('\n').any((line) => line.trimRight() == '## ${result['evidenceSection']}')) {
        errors.add('$id/$feature: evidence heading not found');
      }
    }
  }
  return errors;
}

List<Map<String, dynamic>> matchingDevices(Map<String, dynamic> catalog, Map<String, dynamic> profile) {
  if (profile['schemaVersion'] == 3 && profile['reportType'] == 'diagnostics') {
    profile = parseTvCompatibilityReport(profile);
  }
  final identity = profile['identity'];
  if (profile['schemaVersion'] != 1) return [];
  if (identity is! Map || !identityKeys.every((key) => identity[key] is String && (identity[key] as String).isNotEmpty)) return [];
  return (catalog['devices'] as List).whereType<Map<String, dynamic>>().where((entry) =>
    entry['exactMatch'] == true && entry['kind'] == profile['kind'] &&
    identityKeys.every((key) => (entry['identity'] as Map)[key] == identity[key])).toList();
}

typedef DeviceReader = Future<String> Function(List<String> arguments);

/// Only whitelisted properties and the launcher's version are read. No identifiers of networks/accounts.
Future<Map<String, dynamic>> captureProfile(DeviceReader read, DateTime now) async {
  final identity = <String, dynamic>{};
  for (final property in propertyNames.entries) {
    final value = (await read(['shell', 'getprop', property.value])).trim();
    identity[property.key] = value.isEmpty ? null : value;
  }
  if (!identityKeys.every((key) => identity[key] is String)) throw const FormatException('Device identity incomplete; report was not saved');
  final kind = identity.remove('emulator') == '1' ? 'emulator' : 'physical';
  final version = await read(['shell', 'dumpsys package io.github.kirillshchetinnikov.cutelauncher | grep -E "versionCode=|versionName="']);
  return {
    'schemaVersion': 1, 'capturedAt': now.toUtc().toIso8601String(), 'kind': kind,
    'identity': identity,
    'installedLauncher': {
      'versionName': RegExp(r'versionName=([^\s]+)').firstMatch(version)?.group(1),
      'versionCode': RegExp(r'versionCode=(\d+)').firstMatch(version)?.group(1),
    },
    'note': 'Identity and installed version only. No function was tested.',
  };
}

Future<String> runAdb(String executable, String serial, List<String> args) async {
  final process = await Process.start(executable, ['-s', serial, ...args]);
  final output = process.stdout.transform(utf8.decoder).join();
  final errors = process.stderr.drain<void>();
  try {
    final code = await process.exitCode.timeout(const Duration(seconds: 15));
    await errors;
    if (code != 0) throw const ProcessException('adb', [], 'Read failed; check the explicit device connection');
    return await output;
  } finally { process.kill(); }
}

/// Sanitize an explicitly supplied app report before putting it under version control.
File archiveDeviceReport(Map<String, dynamic> report, Directory directory, String id) {
  if (!RegExp(r'^[a-z0-9][a-z0-9-]{0,79}$').hasMatch(id)) throw const FormatException('Invalid device report id');
  final safe = publicTvCompatibilityReport(report);
  directory.createSync(recursive: true);
  final target = File('${directory.path}/$id.json');
  target.createSync(exclusive: true);
  target.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(safe)}\n');
  return target;
}

List<String> validateArchivedProfiles(Directory directory) {
  if (!directory.existsSync()) return [];
  final problems = <String>[];
  for (final file in directory.listSync().whereType<File>().where((file) => file.path.endsWith('.json'))) {
    try {
      if (file.lengthSync() > 64 * 1024) throw const FormatException('Report too large');
      final report = readJson(file.path);
      final safe = publicTvCompatibilityReport(report);
      if (jsonEncode(_ordered(report)) != jsonEncode(_ordered(safe))) throw const FormatException('Report contains unknown or invalid data');
    } catch (_) { problems.add('Invalid archived profile: ${file.uri.pathSegments.last}'); }
  }
  return problems;
}

Object? _ordered(Object? value) => value is Map
    ? {for (final key in (value.keys.cast<String>().toList()..sort())) key: _ordered(value[key])}
    : value is List ? value.map(_ordered).toList() : value;

Future<void> main(List<String> arguments) async {
  try {
    final args = [...arguments];
    if (args.isEmpty) throw const FormatException('Use validate, list, capture or match');
    final action = args.removeAt(0);
    String? option(String key) {
      final index = args.indexOf(key);
      if (index < 0) return null;
      if (index + 1 >= args.length) throw FormatException('Missing value for $key');
      final value = args[index + 1];
      args.removeRange(index, index + 2);
      return value;
    }
    final catalogPath = option('--catalog') ?? File.fromUri(Platform.script.resolve('../catalog/devices.json')).path;
    final serial = option('--serial'), executable = option('--adb') ?? 'adb', output = option('--output'), id = option('--id');
    final profiles = Directory.fromUri(File(catalogPath).absolute.uri.resolve('devices/'));
    if (action == 'archive') {
      if (args.length != 1 || id == null || serial != null || output != null) throw const FormatException('archive REPORT --id ID');
      final reportFile = File(args.single);
      if (reportFile.lengthSync() > 8 * 1024 * 1024) throw const FormatException('Report too large');
      final saved = archiveDeviceReport(readJson(args.single), profiles, id);
      stdout.writeln('Archived sanitized device observations: ${saved.path}. No functional verification is implied.');
      return;
    }
    if (id != null) throw const FormatException('--id is only valid for archive');
    if (action == 'capture') {
      if (args.isNotEmpty || serial == null || serial.trim().isEmpty || output == null) throw const FormatException('capture requires --serial ID --output PATH [--adb PATH]');
      final file = File(output);
      if (file.existsSync()) throw const FormatException('Output already exists; use a new report path');
      final profile = await captureProfile((args) => runAdb(executable, serial, args), DateTime.now());
      file.parent.createSync(recursive: true);
      // Exclusive creation prevents a competing capture from replacing an existing report.
      file.createSync(exclusive: true);
      final handle = file.openSync(mode: FileMode.writeOnly);
      try { handle.writeStringSync('${const JsonEncoder.withIndent('  ').convert(profile)}\n'); }
      finally { handle.closeSync(); }
      stdout.writeln('Saved identity report. Function compatibility remains unverified.');
      return;
    }
    if (serial != null || output != null) throw const FormatException('Device options are only valid for capture');
    final catalog = readJson(catalogPath);
    final evidenceFile = File.fromUri(File(catalogPath).absolute.uri.resolve('../docs/TESTING_RU.md'));
    final problems = [...validateCatalog(catalog, evidenceFile.readAsStringSync()), ...validateArchivedProfiles(profiles)];
    if (problems.isNotEmpty) throw FormatException(problems.join('\n'));
    if (action == 'validate' && args.isEmpty) {
      stdout.writeln('Catalog OK: ${(catalog['devices'] as List).length} records; evidence headings checked.');
    } else if (action == 'list' && args.isEmpty) {
      for (final entry in catalog['devices'] as List) {
        stdout.writeln('${entry['id']} (${entry['kind']}, ${entry['exactMatch'] ? 'exact identity' : 'historical partial identity'})');
        for (final result in entry['results']) {
          stdout.writeln('  ${result['feature']}: ${result['status']} — ${result['date']}, ${result['appBuild']}');
        }
      }
    } else if (action == 'match' && args.length == 1) {
      final matches = matchingDevices(catalog, readJson(args.single));
      if (matches.isEmpty) { stdout.writeln('No exact model/firmware match. Compatibility is unknown.'); return; }
      for (final entry in matches) {
        stdout.writeln('Identity match: ${entry['id']}. Historical results apply only to their recorded app builds:');
        for (final result in entry['results']) {
          stdout.writeln('  ${result['feature']}: ${result['status']} — ${result['date']}, ${result['appBuild']}\n    ${result['summary']}');
        }
      }
    } else { throw const FormatException('Use validate | list | match PROFILE | capture --serial ID --output PATH | archive REPORT --id ID'); }
  } catch (error) {
    stderr.writeln('Device catalog: $error');
    exitCode = 1;
  }
}
