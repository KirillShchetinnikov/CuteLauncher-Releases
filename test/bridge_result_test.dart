import 'package:flauncher/bridge_result.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const native = MethodChannel('me.efesser.flauncher/method');
  const bridge = BridgeChannel('me.efesser.flauncher/method');
  void reply(Future<dynamic> Function(MethodCall) handler) =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(native, handler);
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(native, null));

  test('false permission query and empty data are successful results',
      () async {
    reply((call) async => call.method == 'getApplications' ? [] : false);
    expect((await bridge.invokeResult<bool>('checkOverlayPermission')).status,
        BridgeStatus.success);
    expect((await bridge.invokeResult<List>('getApplications')).value, isEmpty);
  });
  test('failed action is typed but preserves the legacy bool', () async {
    reply((_) async => false);
    expect(
        (await bridge.invokeResult<bool>('launchApp', 'private.package'))
            .status,
        BridgeStatus.error);
    expect(
        await bridge.invokeMethod<bool>('launchApp', 'private.package'), false);
  });
  test('permission errors are denied and discard native text/details',
      () async {
    reply((_) async => throw PlatformException(
        code: 'PERMISSION_DENIED',
        message: 'secret-key',
        details: '/private/path'));
    final result = await bridge.invokeResult<int>('getDailyDataUsage');
    expect(result.status, BridgeStatus.denied);
    expect(result.code, 'permission_denied');
    expect(
        () => result.unwrap(),
        throwsA(isA<BridgeException>()
            .having((e) => e.message, 'message', null)
            .having((e) => e.details, 'details', null)));
  });
  test('missing method is unsupported', () async {
    reply((_) async => throw MissingPluginException());
    expect((await bridge.invokeResult<void>('unsupported')).status,
        BridgeStatus.unsupported);
  });
  test('unexpected payload is error, not an empty successful result', () async {
    reply((_) async => 'unexpected');
    expect((await bridge.invokeResult<int>('getDailyDataUsage')).code,
        'invalid_response');
  });
  test('document cancellation remains nullable', () async {
    reply((_) async => null);
    expect((await bridge.invokeResult<String>('pickImageDocument')).status,
        BridgeStatus.cancelled);
    expect(await bridge.invokeMethod<String>('pickImageDocument'), null);
  });
  test('ADB authorization and update permission use the common status',
      () async {
    const adb = BridgeChannel('cutelauncher/adb');
    const updates = BridgeChannel('cutelauncher/updates');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        adb, (_) async => {'status': 'authorization'});
    messenger.setMockMethodCallHandler(updates, (_) async => 'permission');
    expect((await adb.invokeResult<Map>('action')).status, BridgeStatus.denied);
    expect((await updates.invokeResult<String>('install')).status,
        BridgeStatus.denied);
    expect(await updates.invokeMethod<String>('install'), 'permission');
    messenger.setMockMethodCallHandler(adb, null);
    messenger.setMockMethodCallHandler(updates, null);
  });
  test('auto launch validation failure remains a typed error with its response', () async {
    const channel = BridgeChannel('cutelauncher/auto_launch');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => {'status': 'invalid'});
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final result = await channel.invokeResult<Map>('save');
    expect(result.status, BridgeStatus.error);
    expect(result.code, 'invalid_argument');
    expect(result.unwrap(), {'status': 'invalid'});
  });
}
