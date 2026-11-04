import 'dart:convert';

import 'package:flauncher/drive_client_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String document(Object? fields) => jsonEncode({'installed': fields});

  test(
    'reads installed fields, trims edges and ignores endpoint overrides',
    () {
      final client = DriveClientConfiguration.parse(
        document({
          'client_id': ' test.apps.googleusercontent.com ',
          'client_secret': ' test-secret ',
          'token_uri': 'https://untrusted.invalid/token',
        }),
      );
      expect(client.clientId, 'test.apps.googleusercontent.com');
      expect(client.clientSecret, 'test-secret');
    },
  );

  test('rejects malformed documents without retaining secret input', () {
    for (final source in [
      '{"client_secret":"private-value",',
      '[]',
      'null',
      jsonEncode({
        'web': {'client_id': 'id', 'client_secret': 'private-value'},
      }),
      document(null),
      document({'client_id': 'id'}),
      document({'client_id': 123, 'client_secret': 'private-value'}),
      document({'client_id': 'id', 'client_secret': ''}),
      document({'client_id': 'id', 'client_secret': 'bad\nsecret'}),
      document({'client_id': 'x' * 257, 'client_secret': 'private-value'}),
      ' ' * (DriveClientConfiguration.maximumBytes + 1),
    ]) {
      try {
        DriveClientConfiguration.parse(source);
        fail('Invalid document accepted');
      } on FormatException catch (error) {
        expect(error.source, isNull);
        expect(error.toString(), isNot(contains('private-value')));
      }
    }
  });
}
