import 'dart:async';

import 'package:flutter/foundation.dart';

import 'bridge_result.dart';
import 'diagnostics_store.dart';

/// Only player initialization/configuration/playback errors can change surfaces.
bool canRecoverBackgroundVideo(String stage) =>
    const {'videoInitialize', 'videoConfigure', 'videoPlay'}.contains(stage);

/// Call after releasing the failed player. Native permits one transition per
/// process, only with Skia on API 29+. No saved device setting or engine restart.
Future<bool> enableBackgroundVideoRecovery(int attempt) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
  bool enabled;
  try {
    enabled =
        await const BridgeChannel('me.efesser.flauncher/method')
            .invokeMethod<bool>('enableBackgroundVideoCompatibility')
            .timeout(const Duration(seconds: 2)) ==
        true;
  } catch (_) {
    enabled = false;
  }
  recordBackgroundVideoRecovery(attempt, enabled ? 'enabled' : 'unavailable');
  return enabled;
}

void recordBackgroundVideoRecovery(int attempt, String result) {
  DiagnosticsStore.instance.record(
    'dart',
    'backgroundVideoRecovery',
    'success',
    'ok',
    context: {
      'details': {'attempt': attempt, 'recovery': result},
    },
  );
}
