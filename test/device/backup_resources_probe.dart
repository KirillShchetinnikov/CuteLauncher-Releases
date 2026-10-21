import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flauncher/database.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/backup_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Explicit emulator entry point; never touches the launcher's DB or preferences.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!Platform.isAndroid) throw StateError('Android emulator only');
  final hardware = await Process.run('/system/bin/getprop', ['ro.hardware']);
  if (!['ranchu', 'goldfish'].contains(hardware.stdout.toString().trim())) {
    throw StateError('Emulator only');
  }
  final originalPaths = PathProviderPlatform.instance;
  final cache = await getTemporaryDirectory();
  final result = File('${cache.path}/backup-resource-probe-result.json');
  final root = await cache.createTemp('backup-resource-probe-');
  SharedPreferences.setPrefix('backup_resource_probe.');
  final preferences = await SharedPreferences.getInstance();
  final previous = {
    for (final key in preferences.getKeys()) key: preferences.get(key),
  };
  final database = FLauncherDatabase.inMemory();
  AppsService? apps;
  Uint8List? displayed;
  final report = <String, Object>{};
  try {
    PathProviderPlatform.instance = _ProbePaths(root.path);
    await preferences.clear();
    apps = AppsService(FLauncherChannel(), database);
    await (() async {
      while (!apps!.initialized) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    })().timeout(const Duration(seconds: 20));
    const package = 'probe.banner.app';
    final image = await _png(const Color(0xff20a060));
    final changed = await _png(const Color(0xffb02040));
    final source = File('${root.path}/source/banner.png');
    await source.parent.create();
    await source.writeAsBytes(image);
    await apps.setCustomAppBanner(package, source.path);
    final backup = BackupService(database, preferences);
    final archive = File(await backup.exportBackup());
    final data = jsonDecode(await archive.readAsString()) as Map;
    if ((data['settings'] as Map).containsKey('custom_banner_$package')) {
      throw StateError('Source path was exported');
    }
    await source.writeAsBytes(changed);
    await apps.setCustomAppBanner(package, source.path);
    if (!listEquals(await apps.getAppBanner(package), changed)) {
      throw StateError('Changed banner did not enter cache');
    }
    await source.parent.delete(recursive: true);
    await backup.importBackup(archive);
    await apps
        .refreshState(); // Same invalidation used by public/automatic restore.
    final restored = preferences.getString('custom_banner_$package')!;
    if (restored == source.path || !File(restored).existsSync()) {
      throw StateError('Restored banner is not an independent file');
    }
    displayed = await apps.getAppBanner(package);
    if (!listEquals(displayed, image)) throw StateError('Stale cached banner');
    final codec = await ui.instantiateImageCodec(displayed);
    final frame = await codec.getNextFrame();
    if (frame.image.width != 48 || frame.image.height != 27) {
      throw StateError('Restored image decode failed');
    }
    frame.image.dispose();
    codec.dispose();
    // A second restore must still work after the first staging directory is removed.
    await File(restored).parent.delete(recursive: true);
    await backup.importBackup(archive);
    await apps.refreshState();
    if (!listEquals(await apps.getAppBanner(package), image)) {
      throw StateError('Repeated restore failed');
    }
    report['status'] = 'PASS';
    report['checks'] = 'Android private paths, portable banner, warm cache invalidation, native image decode, repeated restore';
  } catch (error) {
    report['status'] = 'FAIL';
    report['error'] = error.toString();
  } finally {
    apps?.dispose();
    await database.close();
    PathProviderPlatform.instance = originalPaths;
    await preferences.clear();
    for (final entry in previous.entries) {
      final value = entry.value;
      if (value is String) await preferences.setString(entry.key, value);
      if (value is bool) await preferences.setBool(entry.key, value);
      if (value is int) await preferences.setInt(entry.key, value);
      if (value is double) await preferences.setDouble(entry.key, value);
      if (value is List<String>) {
        await preferences.setStringList(entry.key, value);
      }
    }
    await root.delete(recursive: true);
    await result.writeAsString(jsonEncode(report), flush: true);
  }
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(report['status'] as String),
              if (displayed != null) Image.memory(displayed),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<Uint8List> _png(Color color) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder)
      .drawRect(const Rect.fromLTWH(0, 0, 48, 27), Paint()..color = color);
  final picture = recorder.endRecording();
  final image = await picture.toImage(48, 27);
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
      .asUint8List();
  image.dispose();
  picture.dispose();
  return bytes;
}

class _ProbePaths extends PathProviderPlatform {
  final String root;
  _ProbePaths(this.root);
  @override
  Future<String?> getApplicationDocumentsPath() async => root;
  @override
  Future<String?> getApplicationSupportPath() async => root;
  @override
  Future<String?> getDownloadsPath() async => root;
  @override
  Future<String?> getExternalStoragePath() async => root;
}
