import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';

import '../bridge_result.dart';
import '../cloud_account.dart';
import 'cloud_backup_service.dart';

/// Per-operation cancellation and sanitized native errors; no password reads.
class SmbBackupCalls {
  static const channel = BridgeChannel(
    'cutelauncher/smb_backup',
    preserveErrorCodes: true,
  );
  final String profile;
  final Set<String> _active = {};
  int _generation = 0;
  SmbBackupCalls(this.profile);

  Future<T?> call<T>(
    String method, [
    Map<String, Object?> fields = const {},
  ]) async {
    final generation = _generation;
    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    _active.add(id);
    try {
      final result = await channel
          .invokeMethod<T>(method, {
            ...fields,
            'profile': profile,
            'operationId': id,
          })
          .timeout(
            const Duration(seconds: 95),
            onTimeout: () {
              _cancel(id);
              throw const CloudBackupException('timeout');
            },
          );
      if (_generation != generation) {
        throw const CloudBackupException('cancelled');
      }
      return result;
    } on PlatformException catch (error) {
      throw CloudBackupException(error.code);
    } finally {
      _active.remove(id);
    }
  }

  void _cancel(String id) {
    unawaited(
      channel
          .invokeMethod<void>('cancel', {'operationId': id})
          .catchError((_) {}),
    );
  }

  void cancel() {
    _generation++;
    for (final id in _active.toList()) {
      _cancel(id);
    }
  }
}

/// Reuses the credential page contract, with native SMB validation and storage.
class SmbBackupService extends CloudBackupService {
  final String profile;
  late final SmbBackupCalls calls = SmbBackupCalls(profile);
  bool _smbDisposed = false;
  SmbBackupService({this.profile = 'default'});

  @override
  Future<void> refreshAccount() async {
    final data = await calls.call<Map>('info');
    if (_smbDisposed) return;
    if (data == null) throw const CloudBackupException('storage');
    account = CloudAccountInfo(
      configured: data['configured'] == true,
      url: data['url'] as String,
      user: data['user'] as String,
    );
    notifyListeners();
  }

  @override
  Future<void> signIn(String url, String user, String password) async {
    if (busy || _smbDisposed) throw const CloudBackupException('busy');
    busy = true;
    notifyListeners();
    try {
      if (await calls.call<bool>('connect', {
            'url': url,
            'user': user,
            'password': password,
          }) !=
          true) {
        throw const CloudBackupException('storage');
      }
      await refreshAccount();
    } finally {
      busy = false;
      if (!_smbDisposed) notifyListeners();
    }
  }

  @override
  Future<void> checkAccount() async {
    if (busy || _smbDisposed) throw const CloudBackupException('busy');
    busy = true;
    notifyListeners();
    try {
      final identity = await calls.call<String>('identity');
      if (await calls.call<bool>('check', {'identity': identity}) != true) {
        throw const CloudBackupException('storage');
      }
    } finally {
      busy = false;
      if (!_smbDisposed) notifyListeners();
    }
  }

  @override
  Future<void> disconnect() async {
    if (await calls.call<bool>('disconnect') != true) {
      throw const CloudBackupException('storage');
    }
    await refreshAccount();
  }

  @override
  void cancel() {
    calls.cancel();
  }

  @override
  void dispose() {
    _smbDisposed = true;
    super.dispose();
  }
}
