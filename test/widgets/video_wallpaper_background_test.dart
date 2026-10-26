import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flauncher/diagnostics_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/video_wallpaper_background.dart';

import '../fake_background_video.dart';

// Platform event subscriptions may finish cancellation on the real async zone.
Future<void> settleVideo(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  late FakeBackgroundVideo fake;
  late VideoPlayerPlatform previous;
  const channel = MethodChannel('me.efesser.flauncher/method');
  setUp(() {
    DiagnosticsStore.instance.clear();
    previous = VideoPlayerPlatform.instance;
    fake = FakeBackgroundVideo();
    VideoPlayerPlatform.instance = fake;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => false);
  });
  tearDown(() {
    VideoPlayerPlatform.instance = previous;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  Widget background(
    bool enabled, {
    String mode = 'cover',
    bool economy = false,
  }) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: VideoWallpaperBackground(
      file: File('test.mp4'),
      enabled: enabled,
      mode: mode,
      memorySaver: economy,
    ),
  );

  testWidgets(
    'silent loop pauses when hidden and on lifecycle, disposes decoder',
    (tester) async {
      await tester.pumpWidget(background(true));
      await settleVideo(tester);
      expect(fake.calls, containsAll(['volume:0.0', 'loop:true', 'play']));
      expect(fake.preventsSleep, false);
      await tester.pumpWidget(background(false));
      await settleVideo(tester);
      expect(fake.calls.last, 'pause');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(fake.calls.last, 'pause');
      await tester.pumpWidget(background(true, mode: 'blurred'));
      await settleVideo(tester);
      expect(fake.calls.last, 'play');
      expect(find.byType(ImageFiltered), findsOneWidget);
      await tester.pumpWidget(background(true, mode: 'blurred', economy: true));
      await settleVideo(tester);
      expect(find.byType(ImageFiltered), findsNothing);
      expect(fake.streams.length, 1);
      await tester.pumpWidget(const SizedBox());
      await settleVideo(tester);
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      expect(fake.calls, contains('dispose'));
    },
  );

  testWidgets(
    'decoder failure reports the codec problem and releases the player',
    (tester) async {
      fake.reject = true;
      await tester.pumpWidget(background(true));
      await settleVideo(tester);
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      final l = AppLocalizations.of(
        tester.element(find.byType(VideoWallpaperBackground)),
      )!;
      expect(find.text(l.backgroundVideoCodecError), findsOneWidget);
      expect(fake.calls, contains('dispose'));
      expect(fake.calls, isNot(contains('play')));
      await tester.pumpWidget(const SizedBox());
      await settleVideo(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('playback error records the player description once', (
    tester,
  ) async {
    await tester.pumpWidget(background(true));
    await settleVideo(tester);
    fake.streams[0]!.addError(
      PlatformException(
        code: 'VideoError',
        message: 'OMX.amlogic.avc.decoder: playback failed',
      ),
    );
    await settleVideo(tester);
    final failures = DiagnosticsStore.instance.snapshot()['failures'] as List;
    expect(
      failures.where((e) => e['operation'] == 'dart.backgroundVideoPlayback'),
      hasLength(1),
    );
    final failure = failures.firstWhere(
      (e) => e['operation'] == 'dart.backgroundVideoPlayback',
    );
    expect(failure['details']['stage'], 'videoPlay');
    expect(failure['details']['visible'], true);
    expect(failure['errorDetails'], contains('OMX.amlogic.avc.decoder'));
    await tester.pumpWidget(const SizedBox());
    await settleVideo(tester);
  });

  testWidgets('initialization timeout records its own reason', (tester) async {
    fake.delay = true;
    await tester.pumpWidget(background(true));
    await tester.pump(const Duration(seconds: 21));
    await settleVideo(tester);
    final failure =
        (DiagnosticsStore.instance.snapshot()['failures'] as List).first;
    expect(failure['details']['stage'], 'videoInitialize');
    expect(failure['details']['reason'], 'video_timeout');
    await tester.pumpWidget(const SizedBox());
    await settleVideo(tester);
  });

  testWidgets('late initialization after page closes cannot start playback', (
    tester,
  ) async {
    fake.delay = true;
    await tester.pumpWidget(background(true));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    // The disposed player no longer consumes initialization events.
    await settleVideo(tester);
    expect(fake.calls, isNot(contains('play')));
    expect(tester.takeException(), isNull);
  });

  for (final duringPlayback in [false, true]) {
    testWidgets(
      'recovery recreates silent player; playback failure=$duringPlayback',
      (tester) async {
        if (!duringPlayback) fake.failuresRemaining = 1;
        var requests = 0;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              expect(call.method, 'enableBackgroundVideoCompatibility');
              expect(fake.calls.where((c) => c == 'dispose'), hasLength(1));
              requests++;
              return true;
            });
        await tester.pumpWidget(background(true));
        await settleVideo(tester);
        if (duringPlayback) {
          fake.streams[0]!.addError(
            PlatformException(code: 'VideoError', message: 'Decoder failed'),
          );
          await settleVideo(tester);
        }
        expect(requests, 1);
        expect(fake.streams, hasLength(2));
        expect(fake.calls, containsAll(['volume:0.0', 'loop:true', 'play']));
        final l = AppLocalizations.of(
          tester.element(find.byType(VideoWallpaperBackground)),
        )!;
        expect(find.text(l.backgroundVideoCodecError), findsNothing);
        await tester.pumpWidget(background(false));
        await settleVideo(tester);
        expect(fake.calls.last, 'pause');
        await tester.pumpWidget(const SizedBox());
        await settleVideo(tester);
        expect(fake.calls.where((c) => c == 'dispose'), hasLength(2));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'failed fallback stops after two attempts and displays one error',
    (tester) async {
      fake.reject = true;
      var requests = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async {
            requests++;
            return true;
          });
      await tester.pumpWidget(background(true));
      await settleVideo(tester);
      expect(requests, 1);
      expect(fake.streams, hasLength(2));
      final l = AppLocalizations.of(
        tester.element(find.byType(VideoWallpaperBackground)),
      )!;
      expect(find.text(l.backgroundVideoCodecError), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await settleVideo(tester);
      expect(fake.calls.where((c) => c == 'dispose'), hasLength(2));
    },
  );

  testWidgets('unmount while enabling fallback cannot create a new player', (
    tester,
  ) async {
    fake.reject = true;
    final response = Completer<bool>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) => response.future);
    await tester.pumpWidget(background(true));
    await settleVideo(tester);
    await tester.pumpWidget(const SizedBox());
    response.complete(true);
    await settleVideo(tester);
    expect(fake.streams, hasLength(1));
    expect(fake.calls.where((c) => c == 'dispose'), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home hidden during recovery stays paused after fallback', (
    tester,
  ) async {
    fake.failuresRemaining = 1;
    final response = Completer<bool>();
    var requested = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) {
          requested = true;
          return response.future;
        });
    await tester.pumpWidget(background(true));
    await settleVideo(tester);
    expect(requested, isTrue);
    await tester.pumpWidget(background(false));
    response.complete(true);
    await settleVideo(tester);
    expect(fake.streams, hasLength(2));
    expect(fake.calls, isNot(contains('play')));
    expect(fake.calls.last, 'pause');
    await tester.pumpWidget(const SizedBox());
    await settleVideo(tester);
    expect(fake.calls.where((c) => c == 'dispose'), hasLength(2));
  });
}
