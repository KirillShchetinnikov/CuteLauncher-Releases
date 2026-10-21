import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flauncher/database.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Two cold starts of a signed release. Emulator only; separate paths/preferences.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hardware = await Process.run('/system/bin/getprop', ['ro.hardware']);
  if (!Platform.isAndroid || !['ranchu', 'goldfish'].contains(hardware.stdout.toString().trim())) {
    throw StateError('Emulator required');
  }
  final cache = await getTemporaryDirectory();
  final root = Directory('${cache.path}/release-runtime-probe');
  await root.create(recursive: true);
  final reportFile = File('${cache.path}/release-runtime-probe.json');
  final paths = PathProviderPlatform.instance;
  PathProviderPlatform.instance = _ProbePaths(root.path);
  SharedPreferences.setPrefix('release_runtime_probe.');
  final preferences = await SharedPreferences.getInstance();
  final settings = SettingsService(preferences);
  final database = FLauncherDatabase(DatabaseConnection(NativeDatabase(File('${root.path}/database.sqlite'))));
  final wallpaper = WallpaperService(FLauncherChannel(), settings);
  final secondStart = preferences.getBool('written') == true;
  final report = <String, Object>{};
  try {
    final sqlite = await database.customSelect('SELECT sqlite_version() AS version').getSingle();
    report['sqlite'] = sqlite.read<String>('version');
    if (!secondStart) {
      await settings.setMemorySaverEnabled(true);
      await settings.setAppLanguage('ru');
      await database.customStatement('CREATE TABLE probe_marker (value TEXT NOT NULL)');
      await database.customStatement("INSERT INTO probe_marker VALUES ('persisted')");
      await wallpaper.reset();
      await wallpaper.pickWallpaper().timeout(const Duration(seconds: 30));
      if (wallpaper.wallpaper == null) throw StateError('Picker did not save wallpaper');
      await preferences.setBool('written', true);
      report['status'] = 'WRITTEN';
    } else {
      if (!settings.memorySaverEnabled || settings.appLanguage != 'ru') {
        throw StateError('Settings did not survive cold start');
      }
      final marker = await database.customSelect('SELECT value FROM probe_marker').getSingle();
      if (marker.read<String>('value') != 'persisted') throw StateError('SQLite persistence failed');
      // refresh waits until initialization has selected the persisted local file.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await wallpaper.refresh();
      if (wallpaper.wallpaper == null) throw StateError('Wallpaper not restored');
      final codec = await ui.instantiateImageCodec(await File('${root.path}/wallpaper').readAsBytes());
      final frame = await codec.getNextFrame();
      if (frame.image.width != 640 || frame.image.height != 360) throw StateError('Image decode failed');
      frame.image.dispose();
      codec.dispose();
      report['status'] = 'PASS';
      report['checks'] = 'SQLite load/write/cold reopen; native SharedPreferences; native document picker/content copy; wallpaper cold reload and decode';
    }
  } catch (error) {
    report['status'] = 'FAIL';
    report['error'] = error.toString();
  } finally {
    wallpaper.dispose();
    settings.dispose();
    await database.close();
    PathProviderPlatform.instance = paths;
    if (secondStart || report['status'] == 'FAIL') {
      await preferences.clear();
      await root.delete(recursive: true);
    }
    await reportFile.writeAsString(jsonEncode(report), flush: true);
  }
  runApp(MaterialApp(home: Scaffold(body: Center(child: Text(report['status'] as String)))));
}

class _ProbePaths extends PathProviderPlatform {
  final String root;
  _ProbePaths(this.root);
  @override
  Future<String?> getApplicationDocumentsPath() async => root;
}
