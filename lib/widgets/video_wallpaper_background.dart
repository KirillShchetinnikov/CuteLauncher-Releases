import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../l10n/app_localizations.dart';
import '../background_video_diagnostics.dart';
import '../background_video_recovery.dart';
import 'action_notice.dart';

/// One silent decoder, released with the background and paused outside Home.
class VideoWallpaperBackground extends StatefulWidget {
  final File file;
  final bool enabled;
  final String mode;
  final bool memorySaver;
  const VideoWallpaperBackground({
    super.key,
    required this.file,
    required this.enabled,
    required this.mode,
    required this.memorySaver,
  });

  @override
  State<VideoWallpaperBackground> createState() =>
      _VideoWallpaperBackgroundState();
}

class _VideoWallpaperBackgroundState extends State<VideoWallpaperBackground>
    with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;
  bool _resumed = true;
  Timer? _initializationTimer;
  late BackgroundVideoDiagnostics _diagnostics;
  bool _recovering = false;
  bool _retried = false;
  final _disposals = <VideoPlayerController, Future<bool>>{};
  String _stage = 'videoInitialize';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resumed =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _startPlayer();
  }

  void _startPlayer() {
    _diagnostics = BackgroundVideoDiagnostics('backgroundVideoPlayback');
    _stage = 'videoInitialize';
    _controller = VideoPlayerController.file(
      widget.file,
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        // Lifecycle is owned here so plugin auto-resume cannot restart a hidden Home.
        allowBackgroundPlayback: true,
        preventsDisplaySleepDuringVideoPlayback: false,
      ),
    );
    final controller = _controller;
    controller.addListener(_onValue);
    unawaited(_diagnostics.inspect(widget.file));
    _initializationTimer = Timer(
      const Duration(seconds: 20),
      () => _fail(
        TimeoutException('Video initialization exceeded 20 seconds'),
        StackTrace.current,
        controller,
      ),
    );
    unawaited(_initialize(controller));
  }

  bool _active(VideoPlayerController controller) =>
      mounted && !_failed && !_recovering && identical(controller, _controller);

  Future<void> _initialize(VideoPlayerController controller) async {
    try {
      await controller.initialize();
      if (!_active(controller)) return;
      _initializationTimer?.cancel();
      _stage = 'videoConfigure';
      await controller.setVolume(0);
      if (!_active(controller)) return;
      await controller.setLooping(true);
      if (!_active(controller)) return;
      setState(() => _ready = true);
      await _syncPlayback();
      if (_retried && _active(controller)) {
        recordBackgroundVideoRecovery(_diagnostics.attempt, 'succeeded');
      }
    } catch (error, stack) {
      if (_active(controller)) {
        _initializationTimer?.cancel();
        _fail(error, stack, controller);
      }
    }
  }

  void _onValue() {
    if ((_ready || _stage != 'videoInitialize') && _controller.value.hasError) {
      _fail(
        StateError(
          _controller.value.errorDescription ?? 'Video playback failed',
        ),
        StackTrace.current,
        _controller,
      );
    }
  }

  void _fail(Object error, StackTrace stack, VideoPlayerController controller) {
    if (!_active(controller)) return;
    _diagnostics.failure(
      _stage,
      error,
      stack,
      controller.value,
      visible: widget.enabled,
      resumed: _resumed,
    );
    final mayRetry = !_retried && canRecoverBackgroundVideo(_stage);
    _initializationTimer?.cancel();
    controller.removeListener(_onValue);
    setState(() {
      _ready = false;
      _recovering = true;
    });
    unawaited(_recover(controller, mayRetry));
  }

  Future<void> _recover(VideoPlayerController controller, bool mayRetry) async {
    final released = await _disposePlayer(controller);
    if (!mounted) return;
    if (mayRetry &&
        released &&
        await enableBackgroundVideoRecovery(_diagnostics.attempt)) {
      if (!mounted) return;
      _retried = true;
      _recovering = false;
      _startPlayer();
      return;
    }
    if (!mounted) return;
    if (_retried) recordBackgroundVideoRecovery(_diagnostics.attempt, 'failed');
    setState(() {
      _failed = true;
      _recovering = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showActionNotice(
          context,
          AppLocalizations.of(context)!.backgroundVideoCodecError,
          error: true,
        );
      }
    });
  }

  Future<void> _syncPlayback() async {
    final controller = _controller;
    if (!_ready || !_active(controller)) return;
    try {
      if (widget.enabled && _resumed) {
        _stage = 'videoPlay';
        await controller.play();
      } else {
        _stage = 'videoPause';
        await controller.pause();
      }
    } catch (error, stack) {
      _fail(error, stack, controller);
    }
  }

  @override
  void didUpdateWidget(covariant VideoWallpaperBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) unawaited(_syncPlayback());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    unawaited(_syncPlayback());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _initializationTimer?.cancel();
    _controller.removeListener(_onValue);
    unawaited(_disposePlayer(_controller));
    super.dispose();
  }

  Future<bool> _disposePlayer(VideoPlayerController controller) =>
      _disposals.putIfAbsent(controller, () async {
        try {
          await controller.dispose().timeout(const Duration(seconds: 3));
          return true;
        } catch (error, stack) {
          _diagnostics.failure('videoDispose', error, stack, controller.value);
          return false;
        }
      });

  @override
  Widget build(BuildContext context) {
    if (!_ready || _failed) return const SizedBox.shrink();
    Widget video(BoxFit fit) => SizedBox.expand(
      child: FittedBox(
        fit: fit,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.mode == 'blurred' && !widget.memorySaver)
            ClipRect(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: video(BoxFit.cover),
              ),
            ),
          video(widget.mode == 'cover' ? BoxFit.cover : BoxFit.contain),
        ],
      ),
    );
  }
}
