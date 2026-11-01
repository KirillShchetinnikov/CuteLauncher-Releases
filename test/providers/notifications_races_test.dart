import 'dart:async';

import 'package:flauncher/providers/notifications_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockFLauncherChannel channel;
  late StreamController<List<Map<dynamic, dynamic>>> events;
  NotificationsService? service;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    channel = MockFLauncherChannel();
    events = StreamController.broadcast();
    when(channel.checkNotificationListenerPermission())
        .thenAnswer((_) async => true);
    when(channel.checkOverlayPermission()).thenAnswer((_) async => false);
    when(channel.getActiveNotifications()).thenAnswer((_) async => []);
    when(channel.addNotificationsChangedListener(any)).thenAnswer(
      (call) => events.stream.listen(call.positionalArguments.single),
    );
  });
  tearDown(() async {
    service?.dispose();
    service = null;
    await events.close();
  });
  Future<void> start() async {
    service = NotificationsService(channel);
    await pumpEventQueue();
    expect(service!.initialized, isTrue);
  }

  test(
    'revoking permission clears notifications and detaches events',
    () async {
      when(channel.getActiveNotifications()).thenAnswer(
        (_) async => [
          {'key': 'old', 'packageName': 'player', 'isClearable': true},
        ],
      );
      await start();
      expect(events.hasListener, isTrue);
      when(channel.checkNotificationListenerPermission())
          .thenAnswer((_) async => false);
      await service!.checkPermission();
      expect(service!.notifications, isEmpty);
      expect(service!.notificationCounts, isEmpty);
      expect(events.hasListener, isFalse);
      events.add([
        {'key': 'late', 'packageName': 'player'},
      ]);
      await pumpEventQueue();
      expect(service!.notifications, isEmpty);
    },
  );

  test('late snapshot cannot replace a newer notification event', () async {
    await start();
    final pending = Completer<List<Map<dynamic, dynamic>>>();
    when(channel.getActiveNotifications()).thenAnswer((_) => pending.future);
    final refresh = service!.refreshNotifications();
    await pumpEventQueue();
    events.add([
      {'key': 'fresh', 'packageName': 'player', 'title': 'Fresh'},
    ]);
    await pumpEventQueue();
    pending.complete([
      {'key': 'old', 'packageName': 'player', 'title': 'Old'},
    ]);
    await refresh;
    expect(service!.notifications.single.key, 'fresh');
  });

  test(
    'permission recheck during initialization does not abandon loading',
    () async {
      final overlay = Completer<bool>();
      when(channel.checkOverlayPermission()).thenAnswer((_) => overlay.future);
      service = NotificationsService(channel);
      await pumpEventQueue();
      final check = service!.checkPermission();
      overlay.complete(false);
      await check;
      await pumpEventQueue();
      expect(service!.initialized, isTrue);
      expect(events.hasListener, isTrue);
    },
  );

  test(
    'unavailable native permission query does not escape initialization',
    () async {
      final errors = <Object>[];
      when(channel.checkNotificationListenerPermission()).thenAnswer(
        (_) async => throw StateError('notification listener unavailable'),
      );
      await runZonedGuarded(() async {
        service = NotificationsService(channel);
        await pumpEventQueue();
      }, (error, _) => errors.add(error));
      expect(errors, isEmpty);
      expect(service!.initialized, isTrue);
      expect(service!.hasPermission, isFalse);
    },
  );
}
