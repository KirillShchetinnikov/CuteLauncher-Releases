import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/video_wallpaper_background.dart';

import '../fake_background_video.dart';

void main() {
  late FakeBackgroundVideo fake;
  late VideoPlayerPlatform previous;
  setUp(() {
    previous = VideoPlayerPlatform.instance;
    fake = FakeBackgroundVideo();
    VideoPlayerPlatform.instance = fake;
  });
  tearDown(() {
    VideoPlayerPlatform.instance = previous;
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
      await tester.pumpAndSettle();
      expect(fake.calls, containsAll(['volume:0.0', 'loop:true', 'play']));
      expect(fake.preventsSleep, false);
      await tester.pumpWidget(background(false));
      await tester.pumpAndSettle();
      expect(fake.calls.last, 'pause');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(fake.calls.last, 'pause');
      await tester.pumpWidget(background(true, mode: 'blurred'));
      await tester.pumpAndSettle();
      expect(fake.calls.last, 'play');
      expect(find.byType(ImageFiltered), findsOneWidget);
      await tester.pumpWidget(background(true, mode: 'blurred', economy: true));
      await tester.pumpAndSettle();
      expect(find.byType(ImageFiltered), findsNothing);
      expect(fake.streams.length, 1);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
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
      await tester.pumpAndSettle();
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
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('late initialization after page closes cannot start playback', (
    tester,
  ) async {
    fake.delay = true;
    await tester.pumpWidget(background(true));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    // The disposed player no longer consumes initialization events.
    await tester.pumpAndSettle();
    expect(fake.calls, isNot(contains('play')));
    expect(tester.takeException(), isNull);
  });
}
