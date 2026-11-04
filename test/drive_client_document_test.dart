import 'dart:io';

import 'package:flauncher/document_files.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('me.efesser.flauncher/method');
  String? selected;
  setUp(() {
    selected = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'pickDriveClientDocument');
          return selected;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test('cancelled selection returns no text', () async {
    expect(await DocumentFiles.pickDriveClientText(), isNull);
  });

  test(
    'staged files are deleted after success, invalid UTF-8 or size failure',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'drive-client-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final staged = File('${directory.path}/selected.bin');
      selected = staged.path;
      await staged.writeAsString('{"installed":{}}');
      expect(await DocumentFiles.pickDriveClientText(), '{"installed":{}}');
      expect(await staged.exists(), false);
      for (final bytes in [
        List.filled(65537, 65),
        [0xff],
      ]) {
        await staged.writeAsBytes(bytes);
        await expectLater(
          DocumentFiles.pickDriveClientText(),
          throwsFormatException,
        );
        expect(await staged.exists(), false);
      }
    },
  );
}
