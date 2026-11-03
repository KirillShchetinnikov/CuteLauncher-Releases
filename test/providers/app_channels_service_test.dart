import 'dart:async';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/providers/app_channels_service.dart';
import 'package:flauncher/providers/foreground_work.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/settings_import.dart';

import '../support/app_channels.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FeedChannel channel;
  late SettingsService settings;
  late SharedPreferences preferences;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    settings = SettingsService(preferences);
    channel = FeedChannel()..data = [feed(1), feed(2), feed(3, count: 0)];
  });
  tearDown(() async {
    settings.dispose();
    await channel.events.close();
  });

  test('opt-in, independent feeds, persistence and device-local IDs', () async {
    final service = AppChannelsService(channel, settings);
    addTearDown(service.dispose);
    expect(channel.requests, isEmpty);
    await service.refresh();
    expect(service.channels.map((c) => c.key), [
      'video.app:1',
      'video.app:2',
      'video.app:3',
    ]);
    await settings.setSelectedAppChannels(['video.app:2', 'video.app:1']);
    expect(SettingsService(preferences).selectedAppChannels, [
      'video.app:2',
      'video.app:1',
    ]);
    expect(isDeviceLocalBackupKey('selected_app_channels'), isTrue);
    expect(
      compatibleSettings({
        'selected_app_channels': ['foreign:1'],
      }, {}),
      isEmpty,
    );
    await expectLater(
      settings.setSelectedAppChannels(List.generate(17, (i) => 'video.app:$i')),
      throwsFormatException,
    );
    await expectLater(
      settings.setSelectedAppChannels(['invalid']),
      throwsFormatException,
    );
    expect(settings.selectedAppChannels, ['video.app:2', 'video.app:1']);
  });

  test('reordering selected feeds keeps catalogue and poster requests unchanged', () async {
    final service = AppChannelsService(channel, settings);
    addTearDown(service.dispose);
    await settings.setSelectedAppChannels(['video.app:1', 'video.app:2']);
    await service.refresh();
    final requests = channel.requests.length;
    final original = service.channels.first;
    await settings.setSelectedAppChannels(['video.app:2', 'video.app:1']);
    await Future<void>.delayed(Duration.zero);
    expect(channel.requests.length, requests);
    expect(channel.posters, isEmpty);
    expect(service.channels.first, same(original));
    expect(SettingsService(preferences).selectedAppChannels, ['video.app:2', 'video.app:1']);
  });

  test(
    'unchanged catalogue is silent, errors retain content and recovery works',
    () async {
      final service = AppChannelsService(channel, settings);
      addTearDown(service.dispose);
      await service.refresh();
      var changes = 0;
      service.addListener(() => changes++);
      await service.refresh();
      expect(changes, 0);
      channel.fail = true;
      await service.refresh();
      expect(service.unavailable, isTrue);
      expect(service.channels, hasLength(3));
      expect(changes, 1);
      await service.refresh();
      expect(changes, 1);
      channel.fail = false;
      await service.refresh();
      expect(service.channels, hasLength(3));
      expect(service.unavailable, isFalse);
    },
  );

  test(
    'events and resume preserve unchanged models and cached artwork',
    () async {
      final service = AppChannelsService(channel, settings);
      addTearDown(service.dispose);
      service.openCatalog();
      await service.refresh();
      final original = service.channels.first;
      channel.posterResponse = () async => Uint8List.fromList([1, 2]);
      final poster = await service.poster('content://poster/shared');
      var changes = 0;
      service.addListener(() => changes++);
      channel.events.add(true);
      await service.refresh();
      expect(changes, 0);
      expect(identical(service.channels.first, original), isTrue);
      expect(
        identical(await service.poster('content://poster/shared'), poster),
        isTrue,
      );
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await service.refresh();
      expect(changes, 0);
      expect(identical(service.channels.first, original), isTrue);
      expect(
        identical(await service.poster('content://poster/shared'), poster),
        isTrue,
      );
    },
  );

  test('a changed feed reuses unaffected channels and programs', () async {
    final service = AppChannelsService(channel, settings);
    addTearDown(service.dispose);
    await service.refresh();
    final first = service.channels.first;
    final second = service.channels[1];
    channel.data = [feed(1), feed(2), feed(3, count: 0)];
    final programs = channel.data[0]['programs'] as List;
    (programs[1] as Map)['title'] = 'Updated content';
    await service.refresh();
    expect(identical(service.channels[1], second), isTrue);
    expect(
      identical(service.channels.first.programs.first, first.programs.first),
      isTrue,
    );
    expect(service.channels.first.programs[1].title, 'Updated content');
  });

  test(
    'late catalogue and poster responses are discarded after pause and dispose',
    () async {
      final service = AppChannelsService(channel, settings);
      final pending = Completer<List<Map<dynamic, dynamic>>>();
      channel.response = () => pending.future;
      final request = service.refresh();
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      pending.complete([feed(9)]);
      await request;
      expect(service.channels, isEmpty);
      await service.refresh();
      expect(channel.requests, hasLength(1));
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      final image = Completer<Uint8List?>();
      channel.posterResponse = () => image.future;
      final poster = service.poster('content://image/1');
      await Future<void>.delayed(Duration.zero);
      service.dispose();
      image.complete(Uint8List.fromList([1]));
      expect(await poster, isNull);
    },
  );

  test(
    'posters share pending work and cache; launch passes content URI and owner',
    () async {
      final launched = <String>[];
      final service = AppChannelsService(
        channel,
        settings,
        onAppLaunched: (p) async {
          launched.add(p);
        },
      );
      addTearDown(service.dispose);
      channel.posterResponse = () async => Uint8List.fromList([1, 2]);
      await Future.wait([
        service.poster('content://poster/1'),
        service.poster('content://poster/1'),
      ]);
      await service.poster('content://poster/1');
      expect(channel.posters, ['content://poster/1']);
      await service.refresh();
      final program = service.channels.first.programs.first;
      expect(await service.launch(program), isTrue);
      expect(channel.launches.single, ('video://watch/1/0', 'video.app'));
      expect(launched, ['video.app']);
      channel.launchResult = false;
      expect(await service.launch(program), isFalse);
      expect(launched, hasLength(1));
    },
  );

  test(
    'startup, remote input, events and resume share ForegroundWork',
    () async {
      await settings.setSelectedAppChannels(['video.app:1']);
      fakeAsync((time) {
        final work = ForegroundWork(
          now: () => DateTime(2026).add(time.elapsed),
        );
        final service = AppChannelsService(channel, settings, work: work);
        time.flushMicrotasks();
        expect(channel.requests, isEmpty);
        work.homeReady();
        time.elapse(const Duration(milliseconds: 300));
        work.deferForInput();
        time.elapse(const Duration(milliseconds: 300));
        expect(channel.requests, isEmpty);
        time.elapse(const Duration(milliseconds: 100));
        time.flushMicrotasks();
        expect(channel.requests, hasLength(1));
        for (var i = 0; i < 30; i++) {
          channel.events.add(true);
        }
        time.flushMicrotasks();
        time.elapse(const Duration(milliseconds: 400));
        time.flushMicrotasks();
        expect(channel.requests, hasLength(2));
        service.didChangeAppLifecycleState(AppLifecycleState.paused);
        channel.events.add(true);
        time.elapse(const Duration(seconds: 3));
        time.flushMicrotasks();
        expect(channel.requests, hasLength(2));
        service.didChangeAppLifecycleState(AppLifecycleState.resumed);
        time.elapse(const Duration(milliseconds: 400));
        time.flushMicrotasks();
        expect(channel.requests, hasLength(3));
        service.dispose();
        work.dispose();
      });
    },
  );

  test('an invalidated poster request cannot replace the new image at the same URI', () async {
    final service = AppChannelsService(channel, settings);
    addTearDown(service.dispose);
    service.openCatalog();
    final old = Completer<Uint8List?>();
    channel.posterResponse = () => old.future;
    final first = service.poster('content://poster/shared');
    await Future<void>.delayed(Duration.zero);
    channel.events.add(true);
    channel.posterResponse = () async => Uint8List.fromList([2]);
    final second = service.poster('content://poster/shared');
    old.complete(Uint8List.fromList([1]));
    expect(await first, isNull);
    expect(await second, [2]);
    expect(await service.poster('content://poster/shared'), [2]);
  });
}
