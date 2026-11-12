import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flauncher/providers/foreground_work.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/models/watch_next_program.dart';
import 'package:flauncher/models/content_load_state.dart';
import 'package:flauncher/diagnostics_store.dart';
import '../mocks.mocks.dart';

class _LocalHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockFLauncherChannel mockChannel;
  late StreamController<dynamic> watchNextStreamController;
  late WatchNextService watchNextService;

  setUp(() {
    DiagnosticsStore.instance.clear();
    mockChannel = MockFLauncherChannel();
    watchNextStreamController = StreamController<dynamic>.broadcast();
    // Default stubs
    when(mockChannel.getWatchNextPrograms()).thenAnswer((_) async => []);
    when(mockChannel.checkWatchNextPermission()).thenAnswer((_) async => true);
    when(mockChannel.addWatchNextChangedListener(any)).thenAnswer((invocation) {
      final void Function(dynamic) listener = invocation.positionalArguments[0];
      return watchNextStreamController.stream.listen(listener);
    });
  });

  tearDown(() {
    watchNextStreamController.close();
  });

  test('refresh failure retains content and a later empty response clears it', () async {
    when(mockChannel.getWatchNextPrograms()).thenAnswer((_) async => [
      {'id': 1, 'title': 'Saved video'},
    ]);
    watchNextService = WatchNextService(mockChannel);
    await Future<void>.delayed(Duration.zero);
    expect(watchNextService.loadState, ContentLoadState.ready);
    final pending = Completer<List<Map<dynamic, dynamic>>>();
    when(mockChannel.getWatchNextPrograms()).thenAnswer((_) => pending.future);
    final refresh = watchNextService.refresh();
    expect(watchNextService.loadState, ContentLoadState.refreshing);
    final observed = <ContentLoadState>[];
    watchNextService.addListener(() => observed.add(watchNextService.loadState));
    pending.completeError(StateError('offline'));
    await refresh;
    expect(watchNextService.loadState, ContentLoadState.error);
    expect(observed.last, ContentLoadState.error);
    expect(watchNextService.programs.single.title, 'Saved video');
    when(mockChannel.getWatchNextPrograms()).thenAnswer((_) async => []);
    await watchNextService.refresh();
    expect(watchNextService.loadState, ContentLoadState.empty);
    watchNextService.dispose();
  });

  test('initial metadata timeout settles and ignores the late answer', () {
    fakeAsync((time) {
      final pending = Completer<List<Map<dynamic, dynamic>>>();
      when(mockChannel.getWatchNextPrograms()).thenAnswer((_) => pending.future);
      final service = WatchNextService(mockChannel);
      expect(service.loadState, ContentLoadState.initial);
      time.elapse(WatchNextService.metadataTimeout);
      expect(service.initialized, isTrue);
      expect(service.loadState, ContentLoadState.error);
      pending.complete([{'id': 1, 'title': 'Too late'}]);
      time.flushMicrotasks();
      expect(service.programs, isEmpty);
      service.dispose();
    });
  });

  test('event bursts wait for remote idle and coalesce poster reloads', () {
    fakeAsync((time) {
      final work = ForegroundWork(now: () => DateTime(2026).add(time.elapsed))..homeReady();
      when(mockChannel.getWatchNextPrograms()).thenAnswer((_) async => [
        {'id': 1, 'title': 'Video', 'posterArtUri': 'content://poster'},
      ]);
      var image = 1;
      when(mockChannel.getWatchNextPoster(any)).thenAnswer((_) async => Uint8List.fromList([image]));
      final service = WatchNextService(mockChannel, work: work);
      time.elapse(const Duration(milliseconds: 350));
      expect(service.initialized, isTrue);
      List<int>? poster;
      service.poster(service.programs.single).then((bytes) => poster = bytes);
      time.flushMicrotasks();
      expect(poster, [1]);
      service.posterRefreshes.addListener(() {
        service.poster(service.programs.single).then((bytes) => poster = bytes);
      });
      clearInteractions(mockChannel);
      image = 2;
      for (var i = 0; i < 20; i++) {
        watchNextStreamController.add(true);
      }
      time.flushMicrotasks();
      work.deferForInput();
      time.elapse(const Duration(milliseconds: 200));
      work.deferForInput();
      time.elapse(const Duration(milliseconds: 349));
      verifyNever(mockChannel.getWatchNextPrograms());
      time.elapse(const Duration(milliseconds: 1));
      verify(mockChannel.getWatchNextPrograms()).called(1);
      verify(mockChannel.getWatchNextPoster('content://poster')).called(1);
      expect(poster, [2]);
      service.dispose();
      work.dispose();
    });
  });

  test('periodic fallback waits for remote idle and dispose cancels queued events', () {
    fakeAsync((time) {
      final work = ForegroundWork(now: () => DateTime(2026).add(time.elapsed))..homeReady();
      final service = WatchNextService(mockChannel, work: work);
      time.elapse(const Duration(milliseconds: 350));
      clearInteractions(mockChannel);
      time.elapse(const Duration(minutes: 5) - const Duration(milliseconds: 100));
      work.deferForInput();
      time.elapse(const Duration(milliseconds: 349));
      verifyNever(mockChannel.getWatchNextPrograms());
      time.elapse(const Duration(milliseconds: 101));
      verify(mockChannel.getWatchNextPrograms()).called(1);
      watchNextStreamController.add(true);
      time.flushMicrotasks();
      service.dispose();
      time.elapse(const Duration(seconds: 1));
      verifyNever(mockChannel.getWatchNextPrograms());
      work.dispose();
    });
  });

  test('events during a manual refresh schedule one follow-up after remote idle', () {
    fakeAsync((time) {
      final work = ForegroundWork(now: () => DateTime(2026).add(time.elapsed))..homeReady();
      final service = WatchNextService(mockChannel, work: work);
      time.elapse(const Duration(milliseconds: 350));
      clearInteractions(mockChannel);
      final pending = Completer<List<Map<dynamic, dynamic>>>();
      when(mockChannel.getWatchNextPrograms()).thenAnswer((_) => pending.future);
      service.refresh();
      time.flushMicrotasks();
      verify(mockChannel.getWatchNextPrograms()).called(1);
      for (var i = 0; i < 20; i++) {
        watchNextStreamController.add(true);
      }
      time.elapse(const Duration(milliseconds: 350));
      work.deferForInput();
      when(mockChannel.getWatchNextPrograms()).thenAnswer((_) async => []);
      pending.complete([]);
      time.flushMicrotasks();
      verifyNever(mockChannel.getWatchNextPrograms());
      time.elapse(const Duration(milliseconds: 350));
      verify(mockChannel.getWatchNextPrograms()).called(1);
      service.dispose();
      work.dispose();
    });
  });

  test('events share the concurrency limit with other background services', () {
    fakeAsync((time) {
      final work = ForegroundWork(concurrency: 1, now: () => DateTime(2026).add(time.elapsed))..homeReady();
      final service = WatchNextService(mockChannel, work: work);
      time.elapse(const Duration(milliseconds: 350));
      clearInteractions(mockChannel);
      final blocker = Completer<void>();
      work.schedule(Object(), () => blocker.future, delay: Duration.zero);
      time.flushMicrotasks();
      watchNextStreamController.add(true);
      time.elapse(const Duration(seconds: 1));
      verifyNever(mockChannel.getWatchNextPrograms());
      blocker.complete();
      time.flushMicrotasks();
      verify(mockChannel.getWatchNextPrograms()).called(1);
      service.dispose();
      work.dispose();
    });
  });

  test('events queued in background run once after resume and keep poster invalidation', () {
    fakeAsync((time) {
      final work = ForegroundWork(now: () => DateTime(2026).add(time.elapsed))..homeReady();
      when(mockChannel.getWatchNextPrograms()).thenAnswer((_) async => [
        {'id': 1, 'title': 'Video', 'posterArtUri': 'content://poster'},
      ]);
      var image = 1;
      when(mockChannel.getWatchNextPoster(any)).thenAnswer((_) async => Uint8List.fromList([image]));
      final service = WatchNextService(mockChannel, work: work);
      time.elapse(const Duration(milliseconds: 350));
      List<int>? poster;
      service.poster(service.programs.single).then((bytes) => poster = bytes);
      time.flushMicrotasks();
      expect(poster, [1]);
      service.posterRefreshes.addListener(() {
        service.poster(service.programs.single).then((bytes) => poster = bytes);
      });
      clearInteractions(mockChannel);
      work.didChangeAppLifecycleState(AppLifecycleState.paused);
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      image = 2;
      for (var i = 0; i < 20; i++) {
        watchNextStreamController.add(true);
      }
      time.flushMicrotasks();
      time.elapse(const Duration(seconds: 1));
      verifyNever(mockChannel.getWatchNextPrograms());
      work.didChangeAppLifecycleState(AppLifecycleState.resumed);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      time.elapse(const Duration(milliseconds: 350));
      verify(mockChannel.getWatchNextPrograms()).called(1);
      expect(poster, [2]);
      service.dispose();
      work.dispose();
    });
  });

  group('WatchNextService Initialization', () {
    test('drops rows without meaningful text and keeps description-only rows', () async {
      when(mockChannel.getWatchNextPrograms()).thenAnswer((_) async => [
        {'id': 1, 'title': '  ', 'description': '\t', 'posterArtUri': 'content://unused'},
        {'id': 2, 'description': '  Episode 2  '},
        {'id': 3, 'title': 'Movie'},
      ]);
      final service = WatchNextService(mockChannel);
      addTearDown(service.dispose);
      await pumpEventQueue();

      expect(service.programs.map((p) => p.id), [3, 2]);
      expect(service.programs.last.displayTitle, 'Episode 2');
      verifyNever(mockChannel.getWatchNextPoster(any));
    });

    test('initializes with empty programs list', () async {
      watchNextService = WatchNextService(mockChannel);
      while (!watchNextService.initialized) {
        await Future.delayed(Duration.zero);
      }

      expect(watchNextService.programs, isEmpty);
      verify(mockChannel.getWatchNextPrograms()).called(1);
    });

    test('refreshes watch next programs when event stream emits change', () async {
      watchNextService = WatchNextService(mockChannel);
      while (!watchNextService.initialized) {
        await Future.delayed(Duration.zero);
      }

      expect(watchNextService.programs, isEmpty);
      verify(mockChannel.getWatchNextPrograms()).called(1);

      final fakePrograms = [
        {
          'id': 10,
          'packageName': 'com.google.android.youtube.tv',
          'title': 'YouTube Video',
          'description': 'Channel Name',
          'watchNextType': 1,
          'lastEngagementTime': 1600000000,
          'playbackPosition': 100,
          'duration': 500,
          'intentUri': 'intent://youtube',
          'posterArtUri': ''
        }
      ];
      when(mockChannel.getWatchNextPrograms()).thenAnswer((_) async => fakePrograms);

      watchNextStreamController.add(true);
      await pumpEventQueue();

      expect(watchNextService.programs.length, 1);
      expect(watchNextService.programs[0].title, 'YouTube Video');
      verify(mockChannel.getWatchNextPrograms()).called(1);
    });

    test('fetches metadata on init and loads poster only on request', () async {
      final fakePrograms = [
        {
          'id': 1,
          'packageName': 'com.netflix.mediaclient',
          'title': 'Stranger Things',
          'description': 'S1:E1 Chapter One',
          'watchNextType': 1,
          'lastEngagementTime': 1600000000,
          'playbackPosition': 500,
          'duration': 3000,
          'intentUri': 'intent://netflix_uri',
          'posterArtUri': 'content://netflix/poster/1'
        }
      ];

      final mockPosterBytes = Uint8List.fromList([1, 2, 3]);

      when(mockChannel.getWatchNextPrograms()).thenAnswer((_) async => fakePrograms);
      when(mockChannel.getWatchNextPoster('content://netflix/poster/1'))
          .thenAnswer((_) async => mockPosterBytes);

      watchNextService = WatchNextService(mockChannel);
      while (!watchNextService.initialized) {
        await Future.delayed(Duration.zero);
      }

      expect(watchNextService.programs.length, 1);
      expect(watchNextService.programs[0].title, 'Stranger Things');
      verifyNever(mockChannel.getWatchNextPoster(any));
      expect(await watchNextService.poster(watchNextService.programs.single), mockPosterBytes);

      verify(mockChannel.getWatchNextPrograms()).called(1);
      verify(mockChannel.getWatchNextPoster('content://netflix/poster/1')).called(1);
    });

    test('sorts watch next programs with most recently watched first', () async {
      final fakePrograms = [
        {
          'id': 1,
          'packageName': 'com.lagradost.cloudstream3',
          'title': 'Older Stream',
          'description': 'Episode 1',
          'watchNextType': 1,
          'lastEngagementTime': 1600000000000,
          'playbackPosition': 500,
          'duration': 3000,
          'intentUri': 'intent://older',
          'posterArtUri': ''
        },
        {
          'id': 2,
          'packageName': 'in.startv.hotstar',
          'title': 'Recent Movie',
          'description': 'Watched Just Now',
          'watchNextType': 1,
          'lastEngagementTime': 1700000000000,
          'playbackPosition': 200,
          'duration': 7200,
          'intentUri': 'intent://recent',
          'posterArtUri': ''
        }
      ];

      when(mockChannel.getWatchNextPrograms()).thenAnswer((_) async => fakePrograms);

      watchNextService = WatchNextService(mockChannel);
      while (!watchNextService.initialized) {
        await Future.delayed(Duration.zero);
      }

      expect(watchNextService.programs.length, 2);
      expect(watchNextService.programs[0].title, 'Recent Movie');
      expect(watchNextService.programs[1].title, 'Older Stream');
    });
    test('handles missing permission by setting hasPermission to false and clearing programs', () async {
      when(mockChannel.checkWatchNextPermission()).thenAnswer((_) async => false);

      watchNextService = WatchNextService(mockChannel);
      while (!watchNextService.initialized) {
        await Future.delayed(Duration.zero);
      }

      expect(watchNextService.hasPermission, isFalse);
      expect(watchNextService.programs, isEmpty);
      verify(mockChannel.checkWatchNextPermission()).called(1);
      verifyNever(mockChannel.getWatchNextPrograms());
    });

    test('handles channel getWatchNextPrograms error gracefully without throwing', () async {
      when(mockChannel.getWatchNextPrograms()).thenThrow(Exception('Channel failure'));

      watchNextService = WatchNextService(mockChannel);
      while (!watchNextService.initialized) {
        await Future.delayed(Duration.zero);
      }

      expect(watchNextService.programs, isEmpty);
      verify(mockChannel.getWatchNextPrograms()).called(1);
    });
  });

  group('WatchNextService Permissions', () {
    test('loads and shares a network cover, then falls back to the thumbnail', () async {
      final image = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aF8UAAAAASUVORK5CYII=',
      );
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      var requests = 0;
      server.listen((request) async {
        ++requests;
        if (request.uri.path == '/poster') {
          request.response.add(image);
        } else {
          request.response.statusCode = HttpStatus.notFound;
        }
        await request.response.close();
      });
      final service = HttpOverrides.runWithHttpOverrides(
        () => WatchNextService(mockChannel),
        _LocalHttpOverrides(),
      );
      addTearDown(service.dispose);
      final base = 'http://127.0.0.1:${server.port}';
      final program = WatchNextProgram.fromMap({'posterArtUri': '$base/poster'});
      expect(await Future.wait([service.poster(program), service.poster(program)]), [image, image]);
      expect(await service.poster(program), image);
      expect(requests, 1);
      verifyNever(mockChannel.getWatchNextPoster(any));

      when(mockChannel.getWatchNextPoster('content://thumbnail'))
          .thenAnswer((_) async => image);
      final fallback = WatchNextProgram.fromMap({
        'posterArtUri': '$base/missing',
        'thumbnailUri': 'content://thumbnail',
      });
      expect(await service.poster(fallback), image);
      expect(requests, 2);
      verify(mockChannel.getWatchNextPoster('content://thumbnail')).called(1);
      final traces = DiagnosticsStore.instance.posterLoads.snapshot()['recent'] as List;
      expect(traces.last['source'], 'watchNext');
      expect(traces.last['variant'], 'thumbnail');
      expect(traces.last['stage'], 'platform');
      expect(traces.last['outcome'], 'loaded');
    });

    test('explicit and event refresh reload poster contents under the same URI', () async {
      when(mockChannel.getWatchNextPrograms()).thenAnswer((_) async => [{'id': 7, 'title': 'Video', 'posterArtUri': 'content://same'}]);
      var image = 1;
      when(mockChannel.getWatchNextPoster(any)).thenAnswer((_) async => Uint8List.fromList([image]));
      watchNextService = WatchNextService(mockChannel);
      await pumpEventQueue();
      try {
        image = 2;
        await watchNextService.refresh(reloadPosters: true);
        expect(await watchNextService.poster(watchNextService.programs.single), [2]);
        image = 3;
        watchNextStreamController.add(true);
        await pumpEventQueue();
        expect(await watchNextService.poster(watchNextService.programs.single), [3]);
      } finally {
        watchNextService.dispose();
      }
    });

    test('poster cache keeps its byte budget and does not prefetch', () async {
      when(mockChannel.getWatchNextPrograms()).thenAnswer((_) async => [
        for (var i = 0; i < 8; i++) {'id': i, 'title': 'Video $i', 'posterArtUri': 'content://poster/$i'},
      ]);
      when(mockChannel.getWatchNextPoster(any)).thenAnswer((_) async => Uint8List(3 * 1024 * 1024));
      watchNextService = WatchNextService(mockChannel);
      await pumpEventQueue();
      try {
        verifyNever(mockChannel.getWatchNextPoster(any));
        for (final program in watchNextService.programs.take(3)) {
          expect(await watchNextService.poster(program), isNotNull);
        }
        expect(watchNextService.posterCacheBytes, 6 * 1024 * 1024);
        expect(watchNextService.posterCacheEntries, 2);
        verify(mockChannel.getWatchNextPoster(any)).called(3);
      } finally { watchNextService.dispose(); }
    });

    test('reuses unchanged poster and reloads it when URI changes', () async {
      var uri = 'content://poster/old';
      when(mockChannel.getWatchNextPrograms()).thenAnswer((_) async => [{'id': 7, 'title': 'Video', 'posterArtUri': uri}]);
      when(mockChannel.getWatchNextPoster(any)).thenAnswer((invocation) async =>
          Uint8List.fromList([invocation.positionalArguments[0] == 'content://poster/old' ? 1 : 2]));
      watchNextService = WatchNextService(mockChannel);
      while (!watchNextService.initialized) {
        await Future.delayed(Duration.zero);
      }
      try {
        await watchNextService.refresh();
        expect(await watchNextService.poster(watchNextService.programs.single), [1]);
        verify(mockChannel.getWatchNextPoster('content://poster/old')).called(1);
        uri = 'content://poster/new';
        await watchNextService.refresh();
        expect(await watchNextService.poster(watchNextService.programs.single), [2]);
        verify(mockChannel.getWatchNextPoster(uri)).called(1);
        uri = '';
        await watchNextService.refresh();
        expect(await watchNextService.poster(watchNextService.programs.single), isNull);
      } finally {
        watchNextService.dispose();
      }
    });

    test('checkPermission queries channel directly', () async {
      when(mockChannel.checkWatchNextPermission()).thenAnswer((_) async => false);
      watchNextService = WatchNextService(mockChannel);
      while (!watchNextService.initialized) {
        await Future.delayed(Duration.zero);
      }

      final result = await watchNextService.checkPermission();
      expect(result, isFalse);
    });

    test('requestPermission requests channel permission and refreshes on grant', () async {
      when(mockChannel.requestWatchNextPermission()).thenAnswer((_) async => true);
      watchNextService = WatchNextService(mockChannel);
      while (!watchNextService.initialized) {
        await Future.delayed(Duration.zero);
      }

      final granted = await watchNextService.requestPermission();
      expect(granted, isTrue);
      verify(mockChannel.requestWatchNextPermission()).called(1);
    });

    test('requestPermission returns false when denied', () async {
      when(mockChannel.requestWatchNextPermission()).thenAnswer((_) async => false);
      watchNextService = WatchNextService(mockChannel);
      while (!watchNextService.initialized) {
        await Future.delayed(Duration.zero);
      }

      final granted = await watchNextService.requestPermission();
      expect(granted, isFalse);
      verify(mockChannel.requestWatchNextPermission()).called(1);
    });
  });

  group('WatchNextService launch', () {
    test('launches program via channel intentUri', () async {
      final counted = <String>[];
      watchNextService = WatchNextService(mockChannel, onAppLaunched: (package) async { counted.add(package); });
      while (!watchNextService.initialized) {
        await Future.delayed(Duration.zero);
      }

      final program = WatchNextProgram(
        id: 1,
        packageName: 'com.netflix.mediaclient',
        title: 'Stranger Things',
        description: 'S1:E1',
        watchNextType: 1,
        lastEngagementTime: 1600000000,
        playbackPosition: 500,
        duration: 3000,
        intentUri: 'intent://netflix_uri',
        posterArtUri: 'content://netflix/poster/1',
      );

      when(mockChannel.launchWatchNextProgram(any)).thenAnswer((_) async => true);

      final success = await watchNextService.launch(program);

      expect(success, isTrue);
      expect(counted, [program.packageName]);
      verify(mockChannel.launchWatchNextProgram('intent://netflix_uri')).called(1);
    });

    test('fallback launches app packageName when intentUri empty', () async {
      watchNextService = WatchNextService(mockChannel);
      while (!watchNextService.initialized) {
        await Future.delayed(Duration.zero);
      }

      final program = WatchNextProgram(
        id: 1,
        packageName: 'com.netflix.mediaclient',
        title: 'Stranger Things',
        description: 'S1:E1',
        watchNextType: 1,
        lastEngagementTime: 1600000000,
        playbackPosition: 500,
        duration: 3000,
        intentUri: '',
        posterArtUri: '',
      );

      when(mockChannel.launchApp(any)).thenAnswer((_) async => true);

      final success = await watchNextService.launch(program);

      expect(success, isTrue);
      verify(mockChannel.launchApp('com.netflix.mediaclient')).called(1);
    });

    test('fallback launches app packageName when intentUri returns false', () async {
      watchNextService = WatchNextService(mockChannel);
      while (!watchNextService.initialized) {
        await Future.delayed(Duration.zero);
      }

      final program = WatchNextProgram(
        id: 1,
        packageName: 'com.netflix.mediaclient',
        title: 'Stranger Things',
        description: 'S1:E1',
        watchNextType: 1,
        lastEngagementTime: 1600000000,
        playbackPosition: 500,
        duration: 3000,
        intentUri: 'intent://invalid_intent',
        posterArtUri: '',
      );

      when(mockChannel.launchWatchNextProgram(any)).thenAnswer((_) async => false);
      when(mockChannel.launchApp(any)).thenAnswer((_) async => true);

      final success = await watchNextService.launch(program);

      expect(success, isTrue);
      verify(mockChannel.launchWatchNextProgram('intent://invalid_intent')).called(1);
      verify(mockChannel.launchApp('com.netflix.mediaclient')).called(1);
    });
  });

  group('WatchNextService deleteProgram', () {
    for (final throwsError in [false, true]) {
      test('keeps card and position when deletion ${throwsError ? 'throws' : 'is denied'}', () async {
        when(mockChannel.getWatchNextPrograms()).thenAnswer((_) async => [
          {'id': 1, 'title': 'First'},
          {'id': 2, 'title': 'Second'},
        ]);
        when(mockChannel.deleteWatchNextProgram(2)).thenAnswer((_) async {
          if (throwsError) throw StateError('unavailable');
          return false;
        });
        watchNextService = WatchNextService(mockChannel);
        while (!watchNextService.initialized) {
          await Future.delayed(Duration.zero);
        }
        try {
          final original = watchNextService.programs;
          expect(await watchNextService.deleteProgram(original.first), isFalse);
          expect(watchNextService.programs, original);
        } finally {
          watchNextService.dispose();
        }
      });
    }

    test('calls mockChannel.deleteWatchNextProgram and removes from programs list', () async {
      final fakePrograms = [
        {
          'id': 42,
          'packageName': 'com.netflix.mediaclient',
          'title': 'Stranger Things',
          'description': 'S1:E1 Chapter One',
          'watchNextType': 1,
          'lastEngagementTime': 1600000000,
          'playbackPosition': 500,
          'duration': 3000,
          'intentUri': 'intent://netflix_uri',
          'posterArtUri': ''
        }
      ];
      when(mockChannel.getWatchNextPrograms()).thenAnswer((_) async => fakePrograms);
      when(mockChannel.deleteWatchNextProgram(42)).thenAnswer((_) async => true);

      watchNextService = WatchNextService(mockChannel);
      while (!watchNextService.initialized) {
        await Future.delayed(Duration.zero);
      }

      expect(watchNextService.programs.length, 1);
      final program = watchNextService.programs.first;

      final result = await watchNextService.deleteProgram(program);

      expect(result, isTrue);
      expect(watchNextService.programs, isEmpty);
      verify(mockChannel.deleteWatchNextProgram(42)).called(1);
    });
  });
}
