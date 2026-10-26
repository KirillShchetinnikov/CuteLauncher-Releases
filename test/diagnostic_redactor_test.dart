import 'dart:convert';
import 'dart:typed_data';

import 'package:flauncher/diagnostic_redactor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('redacts network, credentials, paths and personal identifiers', () {
    final result = DiagnosticRedactor.text('''ID: 0 SSID: "My home"
cname=com.google.android.tungsten.setupwraith
connect 192.168.1.73 ::1 fe80::abcd 00:11:22:33:44:55
failed /private/backup.json C:\\Users\\Alice\\backup.json
https://alice:pass@example.com/report alice@example.com
password=hunter2
token=abcdef
com.private.application
java.lang.SecurityException: Permission Denial''');
    for (final secret in [
      'My home',
      '192.168',
      '::1',
      'fe80',
      '00:11:22',
      'Alice',
      'alice',
      'hunter2',
      'abcdef',
      'com.private.application',
      '/private/',
    ]) {
      expect(result, isNot(contains(secret)), reason: secret);
    }
    expect(result, contains('com.google.android.tungsten.setupwraith'));
    expect(result, contains('Permission Denial'));
  });
  test(
    'structured data redacts sensitive fields, omits binary and limits size',
    () {
      final result = DiagnosticRedactor.excerpt({
        'status': 'failed',
        'password': 'hunter2',
        'uri': 'private',
        'name': 'Alice',
        'packages': ['private.app'],
        'bytes': Uint8List(100),
        'nested': {'apiKey': 'secret', 'code': 403},
        'long': 'x' * 30000,
      });
      expect(result.length, lessThanOrEqualTo(8210));
      expect(result, contains('403'));
      for (final secret in ['hunter2', 'Alice', 'private', 'secret']) {
        expect(result, isNot(contains(secret)));
      }
      final cycle = <String, Object?>{};
      cycle['cycle'] = cycle;
      expect(
        jsonEncode(DiagnosticRedactor.value(cycle)),
        contains('depth limit'),
      );
    },
  );
}
