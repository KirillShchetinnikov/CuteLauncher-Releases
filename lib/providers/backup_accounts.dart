import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../cloud_account.dart';
import 'cloud_backup_service.dart';
import 'drive_backup_service.dart';
import 'smb_backup_service.dart';

/// Profiles refer to independent AndroidKeyStore-backed credential slots.
class BackupAccounts {
  final SharedPreferences preferences;
  final Map<String, CloudBackupService> _webdav;
  final Map<String, DriveBackupService> _drive;
  final Map<String, DriveBackupService> _yandex = {};
  final Map<String, SmbBackupService> _smb = {};
  SmbBackupService smb(String id) =>
      _smb.putIfAbsent(id, () => SmbBackupService(profile: id));
  DriveBackupService yandex(String id) => _yandex.putIfAbsent(
    id,
    () => DriveBackupService(profile: id, yandex: true),
  );
  BackupAccounts(
    this.preferences,
    CloudBackupService webdav,
    DriveBackupService drive,
  ) : _webdav = {'default': webdav},
      _drive = {'default': drive};
  List<String> ids(bool google, {bool yandex = false, bool smb = false}) => [
    'default',
    ...preferences.getStringList(
          'backup_transport_accounts_${smb
              ? 'smb'
              : yandex
              ? 'yandex'
              : google
              ? 'drive'
              : 'webdav'}',
        ) ??
        [],
  ];
  CloudBackupService webdav(String id) => _webdav.putIfAbsent(
    id,
    () =>
        CloudBackupService(accounts: NativeCloudAccountRepository(profile: id)),
  );
  DriveBackupService drive(String id) =>
      _drive.putIfAbsent(id, () => DriveBackupService(profile: id));
  Future<String> create(
    bool google, {
    bool yandex = false,
    bool smb = false,
  }) async {
    if (ids(google, yandex: yandex, smb: smb).length >= 20) {
      throw StateError('Account limit');
    }
    final id = List.generate(
      16,
      (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    if (!await preferences.setStringList(
      'backup_transport_accounts_${smb
          ? 'smb'
          : yandex
          ? 'yandex'
          : google
          ? 'drive'
          : 'webdav'}',
      [...ids(google, yandex: yandex, smb: smb).skip(1), id],
    )) {
      throw StateError('Profile save failed');
    }
    return id;
  }

  String? usedByOther(
    String mode,
    bool google,
    String id, {
    bool yandex = false,
    bool smb = false,
  }) {
    final other = mode == 'backup' ? 'synchronization' : 'backup';
    final prefix = 'backup_transport_profile_${other}_backup_transport_';
    if (preferences.getBool('${prefix}setup_complete') != true ||
        preferences.getInt('${prefix}destination') !=
            (smb
                ? 4
                : yandex
                ? 3
                : google
                ? 1
                : 0)) {
      return null;
    }
    return (preferences.getString(
                  '${prefix}account_${smb
                      ? 'smb'
                      : yandex
                      ? 'yandexDisk'
                      : google
                      ? 'googleDrive'
                      : 'webdav'}',
                ) ??
                'default') ==
            id
        ? other
        : null;
  }

  void dispose() {
    for (final service in _smb.values) {
      service.dispose();
    }
    for (final service in _yandex.values) {
      service.dispose();
    }
    for (final e in _webdav.entries) {
      if (e.key != 'default') e.value.dispose();
    }
    for (final e in _drive.entries) {
      if (e.key != 'default') e.value.dispose();
    }
  }
}
