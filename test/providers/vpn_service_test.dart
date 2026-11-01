import 'dart:async';

import 'package:flauncher/providers/vpn_service.dart';
import 'package:flauncher/providers/foreground_work.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../mocks.mocks.dart';

void main() {
  const channel = MethodChannel('cutelauncher/vpn');
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Map<String, Object> state;
  late List<MethodCall> calls;
  setUp(() {
    state = {
      'active': false,
      'target': 'org.amnezia.awg',
      'owner': '',
      'profile': 'home',
      'selected': '',
      'canControl': true,
      'bootApp': '',
      'clients': [
        {
          'app': 'org.amnezia.awg',
          'name': 'AmneziaWG',
          'supported': true,
          'permission': true,
        },
      ],
    };
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'snapshot') return Map<String, Object>.from(state);
      if (call.method == 'save') {
        final args = call.arguments as Map;
        state[args['key'] as String] = args['value'] as Object;
        return true;
      }
      if (call.method == 'command') {
        state['active'] = (call.arguments as Map)['up'] as bool;
        state['owner'] = state['active'] == true ? 'org.amnezia.awg' : '';
        return 'sent';
      }
      return true;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  testWidgets('automatic identification waits for Home and idle input', (
    tester,
  ) async {
    final work = ForegroundWork(now: () => tester.binding.clock.now());
    final network = MockNetworkService();
    final vpn = VpnService(network, work: work);
    await vpn.initialLoad;
    final callback =
        verify(network.addListener(captureAny)).captured.single as VoidCallback;
    expect(calls.single.arguments, {'identify': false});
    callback();
    callback();
    await tester.pump(const Duration(seconds: 1));
    expect(calls.length, 1);
    work.homeReady();
    work.deferForInput();
    await tester.pump(const Duration(milliseconds: 200));
    work.deferForInput();
    await tester.pump(const Duration(milliseconds: 200));
    expect(calls.length, 1);
    await tester.pump(const Duration(milliseconds: 150));
    expect(calls.length, 2);
    expect(calls.last.arguments, {'identify': true});
    vpn.dispose();
    work.dispose();
  });

  testWidgets(
    'background and dispose cancel queued identification; manual refresh bypasses it',
    (tester) async {
      final work = ForegroundWork(now: () => tester.binding.clock.now());
      final vpn = VpnService(MockNetworkService(), work: work);
      await vpn.initialLoad;
      vpn.didChangeAppLifecycleState(AppLifecycleState.paused);
      work.homeReady();
      await tester.pump(const Duration(seconds: 1));
      expect(calls.length, 1);
      vpn.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 200));
      expect(calls.length, 1);
      await vpn.refresh();
      expect(calls.length, 2);
      vpn.dispose();
      await tester.pump(const Duration(seconds: 1));
      expect(calls.length, 2);
      work.dispose();
    },
  );

  testWidgets(
    'manual connection is refreshed from network events without enabling startup',
    (tester) async {
      final network = MockNetworkService();
      final vpn = VpnService(network);
      await vpn.initialLoad;
      final callback =
          verify(network.addListener(captureAny)).captured.single
              as VoidCallback;
      state.addAll({'active': true, 'owner': 'org.amnezia.awg'});
      callback();
      await tester.pump(const Duration(milliseconds: 301));
      await tester.pump();
      expect(vpn.active, isTrue);
      expect(vpn.target, 'org.amnezia.awg');
      expect(vpn.profile, 'home');
      expect(vpn.bootApp, isEmpty);
      expect(calls.where((call) => call.method == 'command'), isEmpty);
      vpn.dispose();
      verify(network.removeListener(callback)).called(1);
    },
  );

  testWidgets(
    'identical nested snapshots do not notify; changes and recovery do',
    (tester) async {
      final vpn = VpnService(MockNetworkService());
      await vpn.initialLoad;
      var notifications = 0;
      vpn.addListener(() => notifications++);
      await vpn.refresh();
      expect(notifications, 0);
      state['active'] = true;
      await vpn.refresh();
      expect(notifications, 1);
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: 'unavailable'),
      );
      await vpn.refresh();
      await vpn.refresh();
      expect(notifications, 2);
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => Map<String, Object>.from(state),
      );
      await vpn.refresh();
      expect(notifications, 3);
      expect(vpn.failed, isFalse);
      vpn.dispose();
    },
  );

  testWidgets(
    'successful broadcast requires observed connection before success',
    (tester) async {
      final vpn = VpnService(MockNetworkService());
      await vpn.initialLoad;
      final command = vpn.toggle();
      await tester.pump();
      expect(vpn.busy, isTrue);
      expect(vpn.result, isNot('connected'));
      await tester.pump(const Duration(milliseconds: 751));
      await tester.pump();
      expect(await command, 'connected');
      expect(vpn.active, isTrue);
      vpn.dispose();
    },
  );

  testWidgets('unknown owner never sends control command', (tester) async {
    state.addAll({
      'active': true,
      'owner': '',
      'target': '',
      'canControl': false,
    });
    final vpn = VpnService(MockNetworkService());
    await vpn.initialLoad;
    expect(await vpn.toggle(), 'unavailable');
    expect(calls.where((call) => call.method == 'command'), isEmpty);
    vpn.dispose();
  });

  testWidgets('startup selection is independent of widget selection', (
    tester,
  ) async {
    final vpn = VpnService(MockNetworkService());
    await vpn.initialLoad;
    expect(await vpn.save('bootApp', 'org.amnezia.awg'), isTrue);
    expect(vpn.selected, isEmpty);
    expect(vpn.bootApp, 'org.amnezia.awg');
    expect(await vpn.save('bootApp', ''), isTrue);
    expect(vpn.target, 'org.amnezia.awg');
    expect(calls.where((call) => call.method == 'command'), isEmpty);
    vpn.dispose();
  });

  testWidgets('late responses cannot publish after dispose', (tester) async {
    final pending = Completer<Map<String, Object>>();
    messenger.setMockMethodCallHandler(channel, (_) => pending.future);
    final vpn = VpnService(MockNetworkService());
    var changes = 0;
    vpn.addListener(() => changes++);
    vpn.dispose();
    pending.complete(state);
    await vpn.initialLoad;
    expect(changes, 0);
    expect(vpn.initialized, isFalse);
  });

  testWidgets('snapshot failures keep control unavailable', (tester) async {
    final vpn = VpnService(MockNetworkService());
    await vpn.initialLoad;
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'unavailable'),
    );
    await vpn.refresh();
    expect(vpn.failed, isTrue);
    expect(vpn.canControl, isFalse);
    vpn.dispose();
  });

  testWidgets('MantaRay confirmation can take longer than connection timeout', (
    tester,
  ) async {
    state.addAll({
      'target': 'com.mantaray.vpn',
      'profile': '',
      'requiresProfile': false,
    });
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'command') return 'sent';
      return Map<String, Object>.from(state);
    });
    final vpn = VpnService(MockNetworkService());
    await vpn.initialLoad;
    final pending = vpn.toggle();
    vpn.didChangeAppLifecycleState(AppLifecycleState.paused);
    await tester.pump();
    await tester.pump(const Duration(seconds: 40));
    expect(vpn.busy, isTrue);
    expect(vpn.result, 'pending');
    state.addAll({'active': true, 'owner': 'com.mantaray.vpn'});
    vpn.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();
    expect(await pending, 'connected');
    vpn.dispose();
  });

  testWidgets('Happ confirmation survives its brief no-UI activity pause', (
    tester,
  ) async {
    state.addAll({
      'target': 'com.happproxy',
      'profile': '',
      'requiresProfile': false,
    });
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'command') {
        state.addAll({'active': true, 'owner': 'com.happproxy'});
        return 'sent';
      }
      return Map<String, Object>.from(state);
    });
    final vpn = VpnService(MockNetworkService());
    await vpn.initialLoad;
    final pending = vpn.toggle();
    vpn.didChangeAppLifecycleState(AppLifecycleState.inactive);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(vpn.busy, isTrue);
    vpn.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();
    expect(await pending, 'connected');
    vpn.dispose();
  });
}
