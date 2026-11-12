import 'package:flutter/services.dart';

/// Values crossing this channel are configuration or authenticated ciphertext.
/// Never use BridgeChannel: its diagnostic recorder captures arguments.
class NativeSync {
  static const _channel = MethodChannel('cutelauncher/native_sync');
  const NativeSync();
  Future<Map<String, String>> capture() async {
    try {
      return Map<String, String>.from(
        await _channel.invokeMethod<Map>('capture') ?? {},
      );
    } on MissingPluginException {
      // Desktop unit tests have no Android private stores.
      return {};
    }
  }

  Future<bool> keyConfigured() async {
    try {
      return await _channel.invokeMethod<bool>('keyInfo') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<String> generateKey() async =>
      (await _channel.invokeMethod<String>('generateKey'))!;
  Future<String> readKey() async =>
      (await _channel.invokeMethod<String>('readKey'))!;
  Future<Map<String, int>> changeTimes() async {
    try {
      return Map<String, int>.from(
        await _channel.invokeMethod<Map>('changeTimes') ?? {},
      );
    } on MissingPluginException {
      return {};
    }
  }

  Future<void> changed(String record) async {
    try {
      await _channel.invokeMethod<void>('changed', {'record': record});
    } on MissingPluginException {
      /* Desktop weather tests use private files. */
    }
  }

  Future<void> setKey(String key) =>
      _channel.invokeMethod('setKey', {'key': key});
  Future<String?> identity(String account, {String profile = 'default'}) async {
    try {
      return await _channel.invokeMethod<String>('identity', {
        'account': account,
        'profile': profile,
      });
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> validate(Map<String, String> values) async {
    if (values.isNotEmpty) {
      await _channel.invokeMethod<void>('validate', values);
    }
  }

  Future<void> begin(Map<String, String> values) async {
    if (values.isEmpty) return;
    await _channel.invokeMethod<void>('begin', values);
  }

  Future<void> commit() async {
    try {
      await _channel.invokeMethod<void>('commit');
    } on MissingPluginException {
      /* No native transaction on desktop. */
    }
  }

  Future<void> rollback() async {
    try {
      await _channel.invokeMethod<void>('rollback');
    } on MissingPluginException {
      /* No native transaction on desktop. */
    }
  }
}

bool isNativeSyncKey(String key) =>
    key.startsWith('native_config_') || key.startsWith('native_secret_');

/// Inventory of native preference stores. New stores need an explicit decision.
const nativeSyncStorePolicy = <String, String>{
  'auto_launch': 'portable',
  'background_startup': 'portable',
  'recent_apps': 'portable',
  'launcher_control': 'portable',
  'vpn_widget': 'portable',
  'FlutterSharedPreferences': 'Flutter settings registry',
  'adb_connection': 'device authorization',
  'adb_recovery': 'device recovery',
  'app_permissions': 'device permissions',
  'update_permissions': 'device permissions',
  'brightness_restore': 'hardware recovery',
  'crash_loop': 'process recovery',
  'notification_popup_style': 'derived from Flutter appearance',
  'night_overlay':
      'derived from Flutter night settings and local hardware state',
  'night_solar': 'computed cache',
  'overlay_widget_anchors': 'measured screen geometry',
  'render_compatibility': 'hardware workaround',
  'sleep_timer': 'running timer',
  'sync_change_times': 'local synchronization history',
};
