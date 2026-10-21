import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flauncher/bing_wallpaper.dart';
import 'package:flauncher/providers/online_wallpaper_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Explicit network probe; isolated prefs/files, no device network changes.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!Platform.isAndroid) throw StateError('Android only');
  final hardware = (await Process.run('/system/bin/getprop', [
    'ro.hardware',
  ])).stdout.toString().trim();
  if (!['ranchu', 'goldfish'].contains(hardware)) {
    final model = (await Process.run('/system/bin/getprop', [
      'ro.product.model',
    ])).stdout.toString().trim();
    if (!const bool.fromEnvironment('ALLOW_TCL_PROBE') ||
        model != 'Smart TV Pro') {
      throw StateError('Explicit TCL probe build required');
    }
  }
  final cache = await getTemporaryDirectory();
  final root = await cache.createTemp('online-wallpaper-probe-');
  SharedPreferences.setPrefix('online_wallpaper_probe.');
  final preferences = await SharedPreferences.getInstance();
  final previous = {
    for (final key in preferences.getKeys()) key: preferences.get(key),
  };
  final report = <String, Object>{};
  OnlineWallpaperService? service;
  try {
    await preferences.clear();
    final bing = await fetchBingWallpaper();
    service = OnlineWallpaperService(preferences, directory: () async => root);
    while (!service.initialized) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    final source = OnlineWallpaperConfiguration(
      enabled: true,
      url: bing.uri.toString(),
    );
    await service.configure(source);
    if (service.failed || service.wallpaper == null) {
      throw StateError('Live HTTPS download failed');
    }
    final file = File('${root.path}/online-wallpaper');
    final first = await file.readAsBytes();
    final metadata = preferences.getString(onlineWallpaperCacheKey);
    final version = service.version;
    final codec = await ui.instantiateImageCodec(first);
    final frame = await codec.getNextFrame();
    report['dimensions'] = '${frame.image.width}x${frame.image.height}';
    frame.image.dispose();
    codec.dispose();
    // Reserved .invalid name exercises the real DNS/HTTP failure path without
    // disconnecting the TV's Wi-Fi (the only route for restoring ADB access).
    await service.configure(
      const OnlineWallpaperConfiguration(
        enabled: true,
        url: 'https://offline.invalid/wallpaper.jpg',
      ),
    );
    if (!service.failed ||
        service.wallpaper == null ||
        service.version != version ||
        !listEquals(await file.readAsBytes(), first) ||
        preferences.getString(onlineWallpaperCacheKey) != metadata) {
      throw StateError('Failed network request changed the last success');
    }
    await service.configure(source);
    if (service.failed ||
        service.wallpaper == null ||
        service.version != version + 1) {
      throw StateError('Recovery to reachable HTTPS source failed');
    }
    if (File('${file.path}.tmp').existsSync()) {
      throw StateError('Temporary download remains');
    }
    report['status'] = 'PASS';
    report['checks'] = 'Live Bing metadata, direct HTTPS image, real DNS failure preserves file/cache, reachable-source recovery';
    report['bytes'] = first.length;
  } catch (error) {
    report['status'] = 'FAIL';
    report['error'] = error.toString();
  } finally {
    service?.dispose();
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
    await File('${cache.path}/online-wallpaper-probe-result.json')
        .writeAsString(jsonEncode(report), flush: true);
  }
  runApp(
    MaterialApp(
      home: Scaffold(body: Center(child: Text(report['status'] as String))),
    ),
  );
}
