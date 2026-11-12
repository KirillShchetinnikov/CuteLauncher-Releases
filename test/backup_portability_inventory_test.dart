import 'dart:io';

import 'package:flauncher/native_sync.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new native preference stores require a portability decision', () {
    final names = <String>{};
    final pattern = RegExp(r'getSharedPreferences\("([^\"]+)"');
    for (final file in Directory(
      'android/app/src/main/java/com/leanbitlab/ltvL',
    ).listSync().whereType<File>()) {
      if (!file.path.endsWith('.java')) continue;
      names.addAll(
        pattern.allMatches(file.readAsStringSync()).map((m) => m[1]!),
      );
    }
    expect(
      names.difference(nativeSyncStorePolicy.keys.toSet()),
      isEmpty,
      reason: 'Classify new native stores and add portable adapters before release.',
    );
  });
  test('global channel limits travel; provider IDs and measured history stay local', () {
    expect(isDeviceLocalBackupKey('app_channel_card_limit'), false);
    for (final key in [
      'selected_app_channels',
      'app_channel_formats',
      'app_channel_detected_formats',
      'slideshow_folder',
    ]) {
      expect(isDeviceLocalBackupKey(key), true, reason: key);
    }
    // New primitive Flutter preferences are portable, not silently omitted by an allowlist.
    expect(compatibleSettings({'future_user_setting': false}, {}), {
      'future_user_setting': false,
    });
  });
}
