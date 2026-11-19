import 'package:shared_preferences/shared_preferences.dart';

/// Old active folder sources keep their path and playback settings when unified.
Map<String, Object> migrateMediaFolderSettings(Map<String, dynamic> values) {
  final source = values['background_source'];
  if (source != 'slideshow' && source != 'videoFolder') return {};
  final photos = source == 'slideshow';
  final folderKey = photos ? 'slideshow_folder' : 'wallpaper_video_folder';
  return {
    if (values[folderKey] is String)
      'wallpaper_media_folder': values[folderKey] as String,
    'wallpaper_media_order': photos
        ? (values['slideshow_random'] == true ? 'random' : 'name')
        : values['wallpaper_video_order'] as String? ?? 'name',
    'wallpaper_media_recursive':
        photos && values['slideshow_recursive'] != false,
    'wallpaper_media_interval': values['slideshow_interval'] as int? ?? 300,
    'background_source': 'mediaFolder',
  };
}

Future<void> migrateMediaFolderPreferences(
  SharedPreferences preferences,
) async {
  final changes = migrateMediaFolderSettings({
    for (final key in preferences.getKeys()) key: preferences.get(key),
  });
  final previous = {for (final key in changes.keys) key: preferences.get(key)};
  Future<bool> write(String key, Object? value) => switch (value) {
    null => preferences.remove(key),
    String value => preferences.setString(key, value),
    bool value => preferences.setBool(key, value),
    int value => preferences.setInt(key, value),
    _ => throw ArgumentError.value(value),
  };
  try {
    // Source is last: a failed earlier write leaves the legacy source active.
    for (final entry in changes.entries) {
      if (!await write(entry.key, entry.value)) {
        throw StateError('Folder migration failed');
      }
    }
  } catch (_) {
    for (final entry in previous.entries) {
      await write(entry.key, entry.value);
    }
    rethrow;
  }
}
