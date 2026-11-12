import 'package:shared_preferences/shared_preferences.dart';

/// Separate transport state; portable preferences and device identity stay shared.
class BackupPreferences implements SharedPreferences {
  final SharedPreferences source;
  final String mode;
  BackupPreferences(this.source, this.mode);
  static const shared = {
    'backup_transport_device',
    'backup_transport_device_label',
    'backup_transport_sequence',
    'backup_transport_local_migrated',
  };
  String key(String key) =>
      (key.startsWith('backup_transport_') && !shared.contains(key)) ||
          key.startsWith('sync_member_')
      ? 'backup_transport_profile_${mode}_$key'
      : key;
  Future<void> migrate() async {
    if (source.getBool(key('backup_transport_migrated')) == true) return;
    Future<void> persist(Future<bool> write) async {
      if (!await write) throw StateError('Backup preferences migration failed');
    }

    final previousMode = source.getInt('backup_transport_mode') ?? 0;
    final selected = previousMode == (mode == 'backup' ? 0 : 1);
    if (selected) {
      for (final k
          in source
              .getKeys()
              .where(
                (k) =>
                    (k.startsWith('backup_transport_') ||
                        k.startsWith('sync_member_')) &&
                    !k.startsWith('backup_transport_profile_') &&
                    !shared.contains(k),
              )
              .toList()) {
        final v = source.get(k);
        if (v is bool) await persist(setBool(k, v));
        if (v is int) await persist(setInt(k, v));
        if (v is String) await persist(setString(k, v));
        if (v is double) await persist(setDouble(k, v));
        if (v is List<String>) await persist(setStringList(k, v));
      }
    }
    await persist(
      setBool(
        'backup_transport_enabled',
        selected &&
            (source.getBool('backup_transport_enabled') ??
                source.getBool('automatic_backup_enabled') ??
                false),
      ),
    );
    await persist(
      setBool(
        'backup_transport_setup_complete',
        selected && source.containsKey('backup_transport_destination'),
      ),
    );
    await persist(setBool('backup_transport_migrated', true));
  }

  @override
  Set<String> getKeys() => {
    for (final k in source.getKeys())
      if (k.startsWith('backup_transport_profile_${mode}_'))
        k.substring('backup_transport_profile_${mode}_'.length)
      else if (!k.startsWith('backup_transport_profile_'))
        k,
  };
  @override
  Object? get(String k) => source.get(key(k));
  @override
  bool containsKey(String k) => source.containsKey(key(k));
  @override
  bool? getBool(String k) => source.getBool(key(k));
  @override
  int? getInt(String k) => source.getInt(key(k));
  @override
  double? getDouble(String k) => source.getDouble(key(k));
  @override
  String? getString(String k) => source.getString(key(k));
  @override
  List<String>? getStringList(String k) => source.getStringList(key(k));
  @override
  Future<bool> setBool(String k, bool v) => source.setBool(key(k), v);
  @override
  Future<bool> setInt(String k, int v) => source.setInt(key(k), v);
  @override
  Future<bool> setDouble(String k, double v) => source.setDouble(key(k), v);
  @override
  Future<bool> setString(String k, String v) => source.setString(key(k), v);
  @override
  Future<bool> setStringList(String k, List<String> v) =>
      source.setStringList(key(k), v);
  @override
  Future<bool> remove(String k) => source.remove(key(k));
  @override
  Future<void> reload() => source.reload();
  @override
  Future<bool> commit() async => true;
  @override
  Future<bool> clear() =>
      throw UnsupportedError('Scoped preferences cannot clear shared data');
}
