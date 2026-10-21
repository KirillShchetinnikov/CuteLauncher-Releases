import 'package:flauncher/flauncher_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('process memory preserves unavailable metrics and Android byte values', () async {
    const channel = MethodChannel('me.efesser.flauncher/method');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => {'pssBytes': 1024, 'rssBytes': null});
    try {
      expect(await FLauncherChannel().getProcessMemoryUsage(), {'pssBytes': 1024, 'rssBytes': null});
    } finally { messenger.setMockMethodCallHandler(channel, null); }
  });
}
