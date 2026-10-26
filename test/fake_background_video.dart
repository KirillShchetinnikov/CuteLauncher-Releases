import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class FakeBackgroundVideo extends VideoPlayerPlatform {
  final streams = <int, StreamController<VideoEvent>>{};
  final calls = <String>[];
  Size size = const Size(1920, 1080);
  bool reject = false;
  bool delay = false;
  bool? preventsSleep;
  @override
  Future<void> init() async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    preventsSleep =
        options.videoPlayerOptions?.preventsDisplaySleepDuringVideoPlayback;
    final id = streams.length;
    streams[id] = StreamController<VideoEvent>();
    if (!delay) complete(id);
    return id;
  }

  void complete(int id) {
    if (reject) {
      streams[id]!.addError(
        PlatformException(code: 'VideoError', message: 'Unsupported codec'),
      );
    } else {
      streams[id]!.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          size: size,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => streams[playerId]!.stream;
  @override
  Future<void> dispose(int playerId) async {
    calls.add('dispose');
    await streams[playerId]?.close();
  }

  @override
  Future<void> play(int playerId) async {
    calls.add('play');
  }

  @override
  Future<void> pause(int playerId) async {
    calls.add('pause');
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {
    calls.add('loop:$looping');
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {
    calls.add('volume:$volume');
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
  @override
  Future<void> setPreventsDisplaySleepDuringVideoPlayback(
    int playerId,
    bool preventsDisplaySleepDuringVideoPlayback,
  ) async {}
  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
  @override
  Widget buildView(int playerId) => const ColoredBox(color: Color(0xFF123456));
}
