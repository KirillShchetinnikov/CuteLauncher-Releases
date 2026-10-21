import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/models/watch_next_program.dart';
import '../mocks.mocks.dart';

void main() {
  late MockFLauncherChannel mockChannel;
  late StreamController<dynamic> watchNextStreamController;
  late WatchNextService watchNextService;

  setUp(() {
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

  group('WatchNextService Initialization', () {
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

    test('fetches watch next programs and poster art on init', () async {
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
      expect(watchNextService.programs[0].posterBytes, mockPosterBytes);

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
    test('explicit and event refresh reload poster contents under the same URI', () async {
      when(mockChannel.getWatchNextPrograms()).thenAnswer((_) async => [{'id': 7, 'posterArtUri': 'content://same'}]);
      var image = 1;
      when(mockChannel.getWatchNextPoster(any)).thenAnswer((_) async => Uint8List.fromList([image]));
      watchNextService = WatchNextService(mockChannel);
      await pumpEventQueue();
      try {
        image = 2;
        await watchNextService.refresh(reloadPosters: true);
        expect(watchNextService.programs.single.posterBytes, [2]);
        image = 3;
        watchNextStreamController.add(true);
        await pumpEventQueue();
        expect(watchNextService.programs.single.posterBytes, [3]);
      } finally {
        watchNextService.dispose();
      }
    });

    test('poster byte budget also releases bytes held by program models', () async {
      when(mockChannel.getWatchNextPrograms()).thenAnswer((_) async => [
        for (var i = 0; i < 8; i++) {'id': i, 'posterArtUri': 'content://poster/$i'},
      ]);
      when(mockChannel.getWatchNextPoster(any)).thenAnswer((_) async => Uint8List(3));
      watchNextService = WatchNextService(mockChannel);
      watchNextService.configureImageCache(posterBytes: 4, windowSize: 3);
      await pumpEventQueue();
      try {
        expect(watchNextService.posterCacheBytes, lessThanOrEqualTo(4));
        expect(watchNextService.programs.where((p) => p.posterBytes != null).length, 1);
        verify(mockChannel.getWatchNextPoster(any)).called(3);
      } finally { watchNextService.dispose(); }
    });

    test('reuses unchanged poster and reloads it when URI changes', () async {
      var uri = 'content://poster/old';
      when(mockChannel.getWatchNextPrograms()).thenAnswer((_) async => [{'id': 7, 'posterArtUri': uri}]);
      when(mockChannel.getWatchNextPoster(any)).thenAnswer((invocation) async =>
          Uint8List.fromList([invocation.positionalArguments[0] == 'content://poster/old' ? 1 : 2]));
      watchNextService = WatchNextService(mockChannel);
      while (!watchNextService.initialized) {
        await Future.delayed(Duration.zero);
      }
      try {
        await watchNextService.refresh();
        expect(watchNextService.programs.single.posterBytes, [1]);
        verify(mockChannel.getWatchNextPoster('content://poster/old')).called(1);
        uri = 'content://poster/new';
        await watchNextService.refresh();
        expect(watchNextService.programs.single.posterBytes, [2]);
        verify(mockChannel.getWatchNextPoster(uri)).called(1);
        uri = '';
        await watchNextService.refresh();
        expect(watchNextService.programs.single.posterBytes, isNull);
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
        when(mockChannel.getWatchNextPrograms()).thenAnswer((_) async => [{'id': 1}, {'id': 2}]);
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
