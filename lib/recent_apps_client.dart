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

class RecentAppsClient {
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
