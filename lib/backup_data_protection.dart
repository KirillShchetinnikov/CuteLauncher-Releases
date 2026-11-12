import 'dart:io';

import 'package:flutter/services.dart';

/// Raw channel: passwords and private paths must not enter diagnostic arguments.
class BackupDataProtection {
  static const _channel = MethodChannel('cutelauncher/native_sync');
  final String mode;
  const BackupDataProtection(this.mode);
  Future<bool> configured() async {
    try {
      return await _channel.invokeMethod<bool>('passwordInfo', {
            'mode': mode,
          }) ??
          false;
    } on MissingPluginException {
      if (Platform.isAndroid) rethrow;
      return false;
    }
  }

  Future<void> setPassword(String password) => _channel.invokeMethod(
    'setPassword',
    {'mode': mode, 'password': password},
  );
  Future<void> transform(File file, {required bool encrypt}) async {
    try {
      await _channel.invokeMethod(encrypt ? 'encryptFile' : 'decryptFile', {
        'mode': mode,
        'path': file.path,
      });
    } on MissingPluginException {
      if (Platform.isAndroid) rethrow;
      /* Desktop tests use plain backup fixtures. */
    }
  }
}
