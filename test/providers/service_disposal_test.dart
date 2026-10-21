import 'dart:async';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/brightness_service.dart';
import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/providers/notifications_service.dart';
import 'package:flauncher/providers/tv_inputs_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('weather disposed during init creates no listener or timer', () {
    fakeAsync((async) {
      final channel = MockFLauncherChannel();
      final pending = Completer<bool>();
      when(channel.isBreezyWeatherInstalled()).thenAnswer((_) => pending.future);
      final service = WeatherService(channel);
      service.dispose();
      pending.complete(true);
      async.flushMicrotasks();
      expect(service.isBreezyInstalled, isFalse);
      expect(service.initialized, isFalse);
      verifyNever(channel.getLatestWeatherData());
      verifyNever(channel.addWeatherChangedListener(any));
      expect(async.periodicTimerCount, 0);
    });
  });

  test('watch next disposed during init drops queued refresh and subscription', () {
    fakeAsync((async) {
      final channel = MockFLauncherChannel();
      final pending = Completer<List<Map<dynamic, dynamic>>>();
      when(channel.checkWatchNextPermission()).thenAnswer((_) async => true);
      when(channel.getWatchNextPrograms()).thenAnswer((_) => pending.future);
      final service = WatchNextService(channel);
      async.flushMicrotasks();
      service.refresh(reloadPosters: true);
      service.dispose();
      pending.complete([{'id': 1, 'title': 'Late'}]);
      async.flushMicrotasks();
      expect(service.programs, isEmpty);
      verify(channel.getWatchNextPrograms()).called(1);
      verifyNever(channel.addWatchNextChangedListener(any));
      expect(async.periodicTimerCount, 0);
    });
  });

  test('network cancels stream and ignores late permission and events', () {
    fakeAsync((async) {
      final channel = MockFLauncherChannel();
      final pending = Completer<bool>();
      final stream = StreamController<Map<String, dynamic>>.broadcast();
      late void Function(Map<String, dynamic>) callback;
      when(channel.addNetworkChangedListener(any)).thenAnswer((call) {
        callback = call.positionalArguments[0];
        return stream.stream.listen(callback);
      });
      when(channel.getActiveNetworkInformation()).thenAnswer((_) async => {});
      when(channel.checkUsageStatsPermission()).thenAnswer((_) => pending.future);
      final service = NetworkService(channel);
      expect(stream.hasListener, isTrue);
      service.dispose();
      pending.complete(true);
      callback({'name': 'NETWORK_UNAVAILABLE'});
      async.flushMicrotasks();
      expect(stream.hasListener, isFalse);
      expect(service.hasUsageStatsPermission, isFalse);
      verifyNever(channel.getDailyDataUsage());
      expect(async.periodicTimerCount, 0);
      stream.close();
    });
  });

  test('TV input late response does not initialize disposed service', () {
    fakeAsync((async) {
      final channel = MockFLauncherChannel();
      final pending = Completer<List<Map<dynamic, dynamic>>>();
      when(channel.getTvInputs()).thenAnswer((_) => pending.future);
      final service = TvInputsService(channel);
      service.dispose();
      pending.complete([{'id': 'late', 'label': 'HDMI'}]);
      async.flushMicrotasks();
      expect(service.inputs, isEmpty);
      expect(service.initialized, isFalse);
    });
  });

  test('notification permission check cannot resubscribe after disposal', () async {
    final channel = MockFLauncherChannel();
    when(channel.checkNotificationListenerPermission()).thenAnswer((_) async => false);
    when(channel.checkOverlayPermission()).thenAnswer((_) async => false);
    final service = NotificationsService(channel);
    await pumpEventQueue();
    final pending = Completer<List<Map<dynamic, dynamic>>>();
    when(channel.checkNotificationListenerPermission()).thenAnswer((_) async => true);
    when(channel.getActiveNotifications()).thenAnswer((_) => pending.future);
    final checking = service.checkPermission();
    await pumpEventQueue();
    service.dispose();
    pending.complete([{'packageName': 'late', 'count': 1}]);
    await checking;
    expect(service.notifications, isEmpty);
    verifyNever(channel.addNotificationsChangedListener(any));
  });

  test('apps disposed during initial system query do not persist or subscribe', () {
    fakeAsync((async) {
      final channel = MockFLauncherChannel();
      final db = MockFLauncherDatabase();
      final pending = Completer<List<Map<dynamic, dynamic>>>();
      when(channel.getApplications()).thenAnswer((_) => pending.future);
      when(db.getApplications()).thenAnswer((_) async => []);
      when(db.getCategories()).thenAnswer((_) async => []);
      when(db.getAppsCategories()).thenAnswer((_) async => []);
      when(db.getLauncherSpacers()).thenAnswer((_) async => []);
      final service = AppsService(channel, db);
      service.dispose();
      pending.complete([]);
      async.flushMicrotasks();
      verifyNever(db.persistApps(any));
      verifyNever(channel.addAppsChangedListener(any));
      expect(service.initialized, isFalse);
    });
  });

  test('apps cancel active subscription and next instance has one listener', () async {
    final channel = MockFLauncherChannel();
    final db = MockFLauncherDatabase();
    final events = StreamController<Map<String, dynamic>>.broadcast();
    when(channel.addAppsChangedListener(any)).thenAnswer((call) => events.stream.listen(call.positionalArguments[0]));
    when(channel.getApplications()).thenAnswer((_) async => []);
    when(db.getApplications()).thenAnswer((_) async => []);
    when(db.getCategories()).thenAnswer((_) async => []);
    when(db.getAppsCategories()).thenAnswer((_) async => []);
    when(db.getLauncherSpacers()).thenAnswer((_) async => []);
    when(db.wasCreated).thenReturn(false);
    when(db.transaction(any)).thenAnswer((call) => call.positionalArguments[0]());
    when(db.persistApps(any)).thenAnswer((_) async {});
    final first = AppsService(channel, db);
    await pumpEventQueue();
    expect(events.hasListener, isTrue);
    first.dispose();
    expect(events.hasListener, isFalse);
    final second = AppsService(channel, db);
    await pumpEventQueue();
    var count = 0;
    second.addListener(() => count++);
    events.add({'action': 'UNKNOWN'});
    await pumpEventQueue();
    expect(count, 1);
    second.dispose();
    expect(events.hasListener, isFalse);
    await events.close();
  });

  test('late poster cannot mutate card after disposal', () {
    fakeAsync((async) {
      final channel = MockFLauncherChannel();
      final pending = Completer<Uint8List?>();
      when(channel.checkWatchNextPermission()).thenAnswer((_) async => true);
      when(channel.getWatchNextPrograms()).thenAnswer((_) async => [{'id': 1, 'posterArtUri': 'content://late'}]);
      when(channel.getWatchNextPoster(any)).thenAnswer((_) => pending.future);
      final service = WatchNextService(channel);
      async.flushMicrotasks();
      final card = service.programs.single;
      service.dispose();
      pending.complete(Uint8List.fromList([1]));
      async.flushMicrotasks();
      expect(card.posterBytes, isNull);
      verifyNever(channel.addWatchNextChangedListener(any));
      expect(async.periodicTimerCount, 0);
    });
  });

  test('wallpaper disposed before directory resolves cannot restart timer', () {
    final previous = PathProviderPlatform.instance;
    fakeAsync((async) {
      final pending = Completer<String?>();
      PathProviderPlatform.instance = _PendingPathProvider(pending.future);
      final settings = MockSettingsService();
      when(settings.timeBasedWallpaperEnabled).thenReturn(true);
      final service = WallpaperService(MockFLauncherChannel(), settings);
      service.dispose();
      pending.complete('.');
      async.flushMicrotasks();
      expect(service.wallpaper, isNull);
      expect(async.periodicTimerCount, 0);
    });
    PathProviderPlatform.instance = previous;
  });

  test('settings pending save does not notify after disposal', () async {
    final settings = SettingsService(await SharedPreferences.getInstance());
    final saving = settings.setShowTimeInStatusBar(false);
    settings.dispose();
    await saving;
  });

  test('disposed brightness drops permission response and queued enable', () async {
    const platform = MethodChannel('me.efesser.flauncher/method');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final pending = Completer<bool>();
    final calls = <String>[];
    messenger.setMockMethodCallHandler(platform, (call) {
      calls.add(call.method);
      return pending.future;
    });
    final prefs = await SharedPreferences.getInstance();
    final service = BrightnessService(prefs);
    final enabling = service.setEnabled(true);
    service.dispose();
    pending.complete(true);
    await enabling;
    await pumpEventQueue();
    expect(service.hasPermission, isFalse);
    expect(service.isEnabled, isFalse);
    expect(calls, ['checkWriteSettingsPermission']);
    messenger.setMockMethodCallHandler(platform, null);
  });
}

class _PendingPathProvider extends PathProviderPlatform {
  final Future<String?> pending;
  _PendingPathProvider(this.pending);
  @override
  Future<String?> getApplicationDocumentsPath() => pending;
}
