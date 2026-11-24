import 'dart:io';

import 'package:flauncher/native_sync.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/native_store_inventory.dart';

void main() {
  test('new native preference stores require a portability decision', () {
    final inventory = nativeStoreInventory(
      Directory('android/app/src/main/java/com/leanbitlab/ltvL'),
    );
    // These two dynamic accesses are bounded by NativeSyncBridge.SETTINGS:
    // capture iterates its keys; install validates records before applying them.
    // Equality also flags obsolete exceptions when either call is removed.
    expect(inventory.unresolved, {
      'NativeSyncBridge.java: area',
      'NativeSyncBridge.java: id',
    }, reason: 'Resolve or explicitly review every dynamic preference store.');
    expect(
      inventory.names.difference(nativeSyncStorePolicy.keys.toSet()),
      isEmpty,
      reason: 'Classify new native stores and add portable adapters before release.',
    );
  });
  test(
    'inventory finds constants and nested files, flags dynamic expressions',
    () {
      final root = Directory.systemTemp.createTempSync('native-stores-');
      addTearDown(() => root.deleteSync(recursive: true));
      File('${root.path}/Owner.java').writeAsStringSync('''
class Owner {
  static final String PREFS = "owner_store", KEY = "value";
  void read() { context.getSharedPreferences( PREFS, 0); }
  // context.getSharedPreferences("comment_only", 0);
}
''');
      Directory('${root.path}/nested').createSync();
      File('${root.path}/nested/Consumer.java').writeAsStringSync('''
class Consumer {
  void read() {
    context.getSharedPreferences(
      "literal_store", 0);
    context.getSharedPreferences(Owner.PREFS, 0);
    context.getSharedPreferences(prefix + "suffix", 0);
    context.getSharedPreferences(Unknown.PREFS, 0);
  }
}
''');
      final inventory = nativeStoreInventory(root);
      expect(inventory.names, {'owner_store', 'literal_store'});
      expect(inventory.unresolved, {
        'nested/Consumer.java: prefix + "suffix"',
        'nested/Consumer.java: Unknown.PREFS',
      });
    },
  );
  test('global channel limits travel; provider IDs and measured history stay local', () {
    expect(isDeviceLocalBackupKey('app_channel_card_limit'), false);
    for (final key in [
      'memory_limit_icons',
      'memory_limit_preload',
      'memory_limit_clear_on_background',
      'poster_cache_feeds_ram',
      'poster_cache_feeds_disk',
      'poster_cache_watch_next_ram',
      'poster_cache_watch_next_disk',
      'selected_app_channels',
      'app_channels_order',
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
