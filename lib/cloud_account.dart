import 'dart:convert';

import 'bridge_result.dart';

class CloudBackupException implements Exception {
  final String code;
  const CloudBackupException(this.code);
  @override
  String toString() => 'Cloud backup operation failed ($code)';
}

Uri cloudDirectory(String input) {
  final uri = Uri.tryParse(input);
  if (input.length > 2048 ||
      uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      uri.port <= 0 ||
      uri.port > 65535 ||
      input.contains(RegExp(r'[\x00-\x20\x7f]'))) {
    throw const CloudBackupException('configuration');
  }
  return Uri.parse(input.endsWith('/') ? input : '$input/');
}

String cloudBasicAuthorization(String user, String password) {
  if (user.trim().isEmpty ||
      user.length > 256 ||
      user.contains(':') ||
      password.isEmpty ||
      password.length > 4096 ||
      '$user$password'.contains(RegExp(r'[\x00-\x1f\x7f]'))) {
    throw const CloudBackupException('configuration');
  }
  return 'Basic ${base64Encode(utf8.encode('$user:$password'))}';
}

class CloudAccountInfo {
  final bool configured;
  final String url, user;
  const CloudAccountInfo({
    this.configured = false,
    this.url = '',
    this.user = '',
  });
  factory CloudAccountInfo.parse(Map map) {
    if (map['configured'] == false) return const CloudAccountInfo();
    if (map['configured'] != true ||
        map['url'] is! String ||
        map['user'] is! String) {
      throw const CloudBackupException('storage');
    }
    cloudDirectory(map['url'] as String);
    if ((map['user'] as String).length > 256 ||
        (map['user'] as String).isEmpty) {
      throw const CloudBackupException('storage');
    }
    return CloudAccountInfo(
      configured: true,
      url: map['url'] as String,
      user: map['user'] as String,
    );
  }
}

class CloudAuthorization {
  final Uri directory;
  final String header;
  CloudAuthorization(this.directory, this.header);
}

abstract class CloudAccountRepository {
  Future<CloudAccountInfo> info();
  Future<CloudAuthorization> authorization();
  Future<void> save(String url, String user, String password);
  Future<void> disconnect();
}

class NativeCloudAccountRepository implements CloudAccountRepository {
  static const _channel = BridgeChannel('cutelauncher/cloud_account');
  static Future<T?> _invoke<T>(
    String method, [
    Map<String, Object>? arguments,
  ]) async {
    try {
      return await _channel
          .invokeMethod<T>(method, arguments)
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw const CloudBackupException('storage');
    }
  }

  @override
  Future<CloudAccountInfo> info() async {
    final map = await _invoke<Map>('info');
    if (map == null) throw const CloudBackupException('storage');
    return CloudAccountInfo.parse(map);
  }

  @override
  Future<CloudAuthorization> authorization() async {
    final map = await _invoke<Map>('authorization');
    if (map == null ||
        map['url'] is! String ||
        map['authorization'] is! String ||
        !(map['authorization'] as String).startsWith('Basic ') ||
        (map['authorization'] as String).length > 32768 ||
        (map['authorization'] as String).contains(RegExp(r'[\r\n]'))) {
      throw const CloudBackupException('storage');
    }
    return CloudAuthorization(
      cloudDirectory(map['url'] as String),
      map['authorization'] as String,
    );
  }

  @override
  Future<void> save(String url, String user, String password) async {
    final saved = await _invoke<bool>('save', {
      'url': url,
      'user': user,
      'password': password,
    });
    if (saved != true) throw const CloudBackupException('storage');
  }

  @override
  Future<void> disconnect() async {
    if (await _invoke<bool>('disconnect') != true) {
      throw const CloudBackupException('storage');
    }
  }
}
