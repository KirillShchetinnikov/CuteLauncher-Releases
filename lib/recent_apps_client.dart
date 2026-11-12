import 'dart:typed_data';

import 'bridge_result.dart';

const recentAppsChannel = BridgeChannel(
  'cutelauncher/recent_apps',
  preserveErrorCodes: true,
);

class RecentApp {
  final String packageName, name;
  final bool userApp;
  const RecentApp(this.packageName, this.name, this.userApp);
  factory RecentApp.fromMap(Map value) => RecentApp(
    value['packageName'] as String,
    value['name'] as String,
    value['userApp'] == true,
  );
}

enum RecentAppMemoryStatus { running, unloaded, unavailable }

class RecentAppMemory {
  final RecentAppMemoryStatus status;
  final int? bytes;
  const RecentAppMemory.unavailable()
    : status = RecentAppMemoryStatus.unavailable,
      bytes = null;
  const RecentAppMemory._(this.status, this.bytes);

  factory RecentAppMemory.fromMap(Map value) {
    if (value['status'] == 'unloaded') {
      return const RecentAppMemory._(RecentAppMemoryStatus.unloaded, null);
    }
    final bytes = value['pssBytes'];
    if (value['status'] == 'running' && bytes is int && bytes >= 0) {
      return RecentAppMemory._(RecentAppMemoryStatus.running, bytes);
    }
    return const RecentAppMemory.unavailable();
  }
}

class RecentAppsClient {
  Future<Map<String, dynamic>> ram() async =>
      await recentAppsChannel.invokeMapMethod<String, dynamic>('ram') ?? {};
  Future<RecentAppMemory> memory(String packageName) async =>
      RecentAppMemory.fromMap(
        await recentAppsChannel.invokeMapMethod<String, dynamic>('memory', {
              'packageName': packageName,
            }) ??
            {},
      );
  Future<void> cancelMemory() async {
    try {
      await recentAppsChannel.invokeMethod<void>('cancelMemory');
    } catch (_) {
      // The service window may already have disposed its channel.
    }
  }

  Future<Map<String, dynamic>> access() async =>
      await recentAppsChannel.invokeMapMethod<String, dynamic>('access') ?? {};
  Future<bool> setup(String destination) async =>
      await recentAppsChannel.invokeMethod<bool>('setup', {
        'destination': destination,
      }) ==
      true;
  Future<Map<String, dynamic>> info() async =>
      await recentAppsChannel.invokeMapMethod<String, dynamic>('info') ?? {};
  Future<bool> setMode(String mode) async =>
      await recentAppsChannel.invokeMethod<bool>('mode', mode) == true;
  Future<bool> open() async =>
      await recentAppsChannel.invokeMethod<bool>('open') == true;
  Future<Map<String, dynamic>> action(
    String action, [
    String? packageName,
  ]) async =>
      await recentAppsChannel.invokeMapMethod<String, dynamic>(action, {
        'packageName': packageName,
      }) ??
      (throw StateError('No task response'));
  Future<Uint8List?> icon(String packageName) => recentAppsChannel
      .invokeMethod<Uint8List>('icon', {'packageName': packageName});
}
