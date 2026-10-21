import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../bridge_result.dart';
import '../cloud_account.dart';

class DriveBackupService extends ChangeNotifier with WidgetsBindingObserver {
  static const scope = 'https://www.googleapis.com/auth/drive.file';
  static const _channel = BridgeChannel('cutelauncher/drive_account');
  final HttpClient Function() clientFactory;
  String clientId = '', clientSecret = '', code = '', verificationUrl = '';
  String? _refreshToken, _accessToken;
  DateTime _expires = DateTime(1970);
  bool busy = false, configured = false, failed = false;
  String? failureCode;
  int _generation = 0;
  bool _disposed = false;
  Timer? _pollTimer;
  HttpClient? _client;
  DriveBackupService({HttpClient Function()? clientFactory})
    : clientFactory = clientFactory ?? HttpClient.new {
    WidgetsBinding.instance.addObserver(this);
  }
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> refreshAccount() async {
    final generation = _generation;
    final data = await _channel
        .invokeMethod<Map>('read')
        .timeout(const Duration(seconds: 10));
    if (_disposed || generation != _generation) return;
    configured = false;
    if (data != null) {
      clientId = data['clientId'] as String;
      final payload = jsonDecode(data['payload'] as String) as Map;
      clientSecret = payload['clientSecret'] as String;
      if (payload['scope'] != scope) {
        _refreshToken = null;
        _accessToken = null;
        _notify();
        return;
      }
      _refreshToken = payload['refreshToken'] as String;
      configured = true;
    }
    _notify();
  }

  Future<Map<String, dynamic>> _oauth(
    String endpoint,
    Map<String, String> fields,
  ) async {
    final client = clientFactory()
      ..connectionTimeout = const Duration(seconds: 8);
    _client = client;
    try {
      return await (() async {
        final request = await client.postUrl(
          Uri.https('oauth2.googleapis.com', endpoint),
        );
        request.followRedirects = false;
        request.headers.contentType = ContentType(
          'application',
          'x-www-form-urlencoded',
        );
        request.write(
          fields.entries
              .map(
                (e) =>
                    '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
              )
              .join('&'),
        );
        final response = await request.close();
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
          if (bytes.length > 65536) throw const CloudBackupException('size');
        }
        if (response.statusCode >= 300 && response.statusCode < 400) {
          throw const CloudBackupException('redirect');
        }
        final result = Map<String, dynamic>.from(
          jsonDecode(utf8.decode(bytes)) as Map,
        );
        final error = result['error'];
        if (error != null &&
            error != 'authorization_pending' &&
            error != 'slow_down') {
          throw CloudBackupException(switch (error) {
            'invalid_client' ||
            'unauthorized_client' ||
            'invalid_request' => 'configuration',
            'access_denied' || 'invalid_grant' => 'authorization',
            'expired_token' => 'expired',
            _ => 'response',
          });
        }
        return result;
      })().timeout(const Duration(seconds: 30));
    } finally {
      client.close(force: true);
      if (identical(_client, client)) _client = null;
    }
  }

  Future<void> connect(String id, String secret) async {
    cancel();
    id = id.trim();
    secret = secret.trim();
    failed = false;
    failureCode = null;
    if (id.isEmpty ||
        id.length > 256 ||
        secret.isEmpty ||
        secret.length > 256) {
      failed = true;
      failureCode = 'configuration';
      _notify();
      throw const CloudBackupException('configuration');
    }
    final generation = _generation;
    busy = true;
    failed = false;
    _notify();
    try {
      final result = await _oauth('/device/code', {
        'client_id': id,
        'scope': scope,
      });
      if (_disposed || generation != _generation) return;
      if (result['device_code'] is! String ||
          result['user_code'] is! String ||
          result['verification_url'] is! String ||
          result['expires_in'] is! int) {
        throw const CloudBackupException('response');
      }
      code = result['user_code'] as String;
      verificationUrl = result['verification_url'] as String;
      final deadline = DateTime.now().add(
        Duration(seconds: (result['expires_in'] as int).clamp(1, 3600)),
      );
      _notify();
      _poll(
        id,
        secret,
        result['device_code'] as String,
        deadline,
        Duration(seconds: ((result['interval'] as int?) ?? 5).clamp(5, 60)),
        generation,
      );
    } catch (error) {
      if (!_disposed && generation == _generation) {
        busy = false;
        failed = true;
        failureCode = _failureCode(error);
        _notify();
      }
      rethrow;
    }
  }

  void _poll(
    String id,
    String secret,
    String deviceCode,
    DateTime deadline,
    Duration delay,
    int generation,
  ) {
    _pollTimer = Timer(delay, () async {
      if (_disposed || generation != _generation) return;
      try {
        if (DateTime.now().isAfter(deadline)) {
          throw const CloudBackupException('expired');
        }
        final result = await _oauth('/token', {
          'client_id': id,
          'client_secret': secret,
          'device_code': deviceCode,
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
        });
        if (_disposed || generation != _generation) return;
        if (result['error'] == 'authorization_pending' ||
            result['error'] == 'slow_down') {
          _poll(
            id,
            secret,
            deviceCode,
            deadline,
            result['error'] == 'slow_down'
                ? delay + const Duration(seconds: 5)
                : delay,
            generation,
          );
          return;
        }
        if (result['refresh_token'] is! String ||
            result['access_token'] is! String) {
          throw const CloudBackupException('response');
        }
        final saved = await _channel.invokeMethod<bool>('save', {
          'clientId': id,
          'payload': jsonEncode({
            'clientSecret': secret,
            'refreshToken': result['refresh_token'],
            'scope': scope,
          }),
        });
        if (saved != true) throw const CloudBackupException('storage');
        if (_disposed || generation != _generation) return;
        clientId = id;
        clientSecret = secret;
        _refreshToken = result['refresh_token'] as String;
        _accessToken = result['access_token'] as String;
        _expires = DateTime.now().add(
          Duration(seconds: (result['expires_in'] as int?) ?? 3600),
        );
        configured = true;
        busy = false;
        code = '';
        verificationUrl = '';
        _notify();
      } catch (error) {
        if (!_disposed && generation == _generation) {
          busy = false;
          failed = true;
          failureCode = _failureCode(error);
          code = '';
          verificationUrl = '';
          _notify();
        }
      }
    });
  }

  Future<String> authorization() async {
    if (busy) throw const CloudBackupException('busy');
    if (_accessToken != null &&
        DateTime.now().isBefore(
          _expires.subtract(const Duration(minutes: 1)),
        )) {
      return 'Bearer $_accessToken';
    }
    if (_refreshToken == null) await refreshAccount();
    if (!configured) throw const CloudBackupException('configuration');
    final generation = _generation;
    final result = await _oauth('/token', {
      'client_id': clientId,
      'client_secret': clientSecret,
      'refresh_token': _refreshToken!,
      'grant_type': 'refresh_token',
    });
    if (_disposed || generation != _generation) {
      throw const CloudBackupException('cancelled');
    }
    if (result['access_token'] is! String) {
      throw const CloudBackupException('authorization');
    }
    _accessToken = result['access_token'] as String;
    _expires = DateTime.now().add(
      Duration(seconds: (result['expires_in'] as int?) ?? 3600),
    );
    return 'Bearer $_accessToken';
  }

  static String _failureCode(Object error) => switch (error) {
    CloudBackupException(:final code) => code,
    TimeoutException() => 'timeout',
    SocketException() => 'network',
    _ => 'unknown',
  };

  void cancel() {
    _generation++;
    unawaited(
      _channel.invokeMethod<bool>('invalidate').catchError((_) => false),
    );
    _pollTimer?.cancel();
    _client?.close(force: true);
    busy = false;
    code = '';
    verificationUrl = '';
    _notify();
  }

  Future<void> disconnect() async {
    cancel();
    if (await _channel.invokeMethod<bool>('disconnect') != true) {
      throw const CloudBackupException('storage');
    }
    configured = false;
    _refreshToken = null;
    _accessToken = null;
    clientId = '';
    clientSecret = '';
    _notify();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      cancel();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
