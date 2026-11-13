import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../l10n/app_localizations.dart';
import '../background_video_diagnostics.dart';
import '../background_video_recovery.dart';
import '../local_background_media.dart';
import '../providers/video_folder_service.dart';
import 'action_notice.dart';

/// One silent decoder, released with the background and paused outside Home.
class VideoWallpaperBackground extends StatefulWidget {
  final File? file;
  final VideoFolderClip? clip;
  final VoidCallback? onCompleted;
  final ValueChanged<bool>? onFailure;
  final bool queueFailed;
  final bool enabled;
  final String mode;
  final bool memorySaver;
  final Widget background;
  const VideoWallpaperBackground({
    super.key,
    required this.file,
    required this.enabled,
    required this.mode,
    required this.memorySaver,
    this.background = const SizedBox.shrink(),
  }) : clip = null,
       onCompleted = null,
       onFailure = null,
       queueFailed = false;

  const VideoWallpaperBackground.folder({
    super.key,
    required this.clip,
    required this.enabled,
    required this.mode,
    required this.memorySaver,
    required this.background,
    required this.onCompleted,
    required this.onFailure,
    this.queueFailed = false,
  }) : file = null;

  @override
  State<VideoWallpaperBackground> createState() =>
      _VideoWallpaperBackgroundState();
}

class _VideoWallpaperBackgroundState extends State<VideoWallpaperBackground>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;
  bool _resumed = true;
  Timer? _initializationTimer;
  BackgroundVideoDiagnostics? _diagnostics;
  bool _recovering = false;
  bool _retried = false;
  Future<bool>? _disposal;
  bool _switching = false;
  bool _completed = false;
  String _stage = 'videoInitialize';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resumed =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (widget.file != null || (widget.enabled && _resumed)) _startPlayer();
  }

  void _startPlayer() {
    final uri = widget.clip?.uri;
    final file =
        widget.file ?? (uri?.scheme == 'file' ? File.fromUri(uri!) : null);
    if (uri == null && file == null) return;
    final diagnostics = _diagnostics = BackgroundVideoDiagnostics(
      'backgroundVideoPlayback',
    );
    _stage = 'videoInitialize';
    final options = VideoPlayerOptions(
      mixWithOthers: true,
      // Lifecycle is owned here so plugin auto-resume cannot restart a hidden Home.
      allowBackgroundPlayback: true,
      preventsDisplaySleepDuringVideoPlayback: false,
    );
    final controller = _controller = file == null
        ? VideoPlayerController.contentUri(uri!, videoPlayerOptions: options)
        : VideoPlayerController.file(file, videoPlayerOptions: options);
    _disposal = null;
    controller.addListener(_onValue);
    if (file != null) unawaited(diagnostics.inspect(file));
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
      mounted &&
      !_failed &&
      !_switching &&
      !_recovering &&
      identical(controller, _controller);

  Future<void> _initialize(VideoPlayerController controller) async {
    try {
      await controller.initialize();
      if (!_active(controller)) return;
      _initializationTimer?.cancel();
      if (widget.clip != null) {
        _stage = 'videoMetadata';
        validateBackgroundVideoMetadata(controller.value);
      }
      _stage = 'videoConfigure';
      await controller.setVolume(0);
      if (!_active(controller)) return;
      await controller.setLooping(widget.onCompleted == null);
      if (!_active(controller)) return;
      setState(() => _ready = true);
      await _syncPlayback();
      if (_retried && _active(controller)) {
        recordBackgroundVideoRecovery(_diagnostics!.attempt, 'succeeded');
      }
    } catch (error, stack) {
      if (_active(controller)) {
        _initializationTimer?.cancel();
        _fail(error, stack, controller);
      }
    }
  }

  void _onValue() {
    final controller = _controller;
    if (controller == null || !_active(controller)) return;
    if ((_ready || _stage != 'videoInitialize') && controller.value.hasError) {
      _fail(
        StateError(
          controller.value.errorDescription ?? 'Video playback failed',
        ),
        StackTrace.current,
        controller,
      );
    } else if (_ready &&
        !_completed &&
        controller.value.isCompleted &&
        widget.onCompleted != null) {
      _completed = true;
      widget.onCompleted!();
    }
  }

  void _fail(Object error, StackTrace stack, VideoPlayerController controller) {
    if (!_active(controller)) return;
    _diagnostics!.failure(
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
    final diagnostics = _diagnostics!;
    final released = await _disposePlayer(controller);
    if (!mounted || _switching || !identical(_controller, controller)) return;
    if (mayRetry &&
        released &&
        await enableBackgroundVideoRecovery(diagnostics.attempt)) {
      if (!mounted || _switching || !identical(_controller, controller)) return;
      _retried = true;
      _recovering = false;
      _startPlayer();
      return;
    }
    if (!mounted || _switching || !identical(_controller, controller)) return;
    if (_retried) recordBackgroundVideoRecovery(diagnostics.attempt, 'failed');
    setState(() {
      _failed = true;
      _recovering = false;
    });
    final onFailure = widget.onFailure;
    if (onFailure != null) {
      onFailure(released);
      return;
    }
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
    if (_switching) return;
    if (_controller == null && !_failed && widget.enabled && _resumed) {
      _startPlayer();
      return;
    }
    final controller = _controller;
    if (controller == null || !_ready || _completed || !_active(controller)) {
      return;
    }
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
    if (!oldWidget.queueFailed && widget.queueFailed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.queueFailed) {
          showActionNotice(
            context,
            AppLocalizations.of(context)!.videoFolderError,
            error: true,
          );
        }
      });
    }
    if (!identical(oldWidget.clip, widget.clip)) {
      unawaited(_switchClip());
    } else if (oldWidget.enabled != widget.enabled) {
      unawaited(_syncPlayback());
    }
  }

  Future<void> _switchClip() async {
    if (_switching) return;
    _switching = true;
    _ready = false;
    _initializationTimer?.cancel();
    final controller = _controller;
    if (controller != null) {
      controller.removeListener(_onValue);
      final released = await _disposePlayer(controller);
      if (!mounted) return;
      if (!released) {
        _switching = false;
        _failed = true;
        widget.onFailure?.call(false);
        return;
      }
    }
    _controller = null;
    _switching = false;
    _failed = false;
    _recovering = false;
    _retried = false;
    _completed = false;
    if (widget.enabled && _resumed) _startPlayer();
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
    final controller = _controller;
    if (controller != null) {
      controller.removeListener(_onValue);
      unawaited(_disposePlayer(controller));
    }
    super.dispose();
  }

  Future<bool> _disposePlayer(VideoPlayerController controller) =>
      _disposal ??= () async {
        final diagnostics = _diagnostics!;
        try {
          await controller.dispose().timeout(const Duration(seconds: 3));
          return true;
        } catch (error, stack) {
          diagnostics.failure('videoDispose', error, stack, controller.value);
          return false;
        }
      }();

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !_ready || _failed) return widget.background;
    Widget video(BoxFit fit) => SizedBox.expand(
      child: FittedBox(
        fit: fit,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = constraints.biggest;
          final coversViewport =
              viewport.isFinite &&
              viewport.height > 0 &&
              (viewport.aspectRatio - controller.value.aspectRatio).abs() <
                  1e-9;
          return Stack(
            fit: StackFit.expand,
            children: [
              if (widget.mode != 'cover' &&
                  !coversViewport &&
                  (widget.mode != 'blurred' || widget.memorySaver))
                widget.background,
              if (widget.mode == 'blurred' &&
                  !widget.memorySaver &&
                  !coversViewport)
                ClipRect(
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: video(BoxFit.cover),
                  ),
                ),
              video(widget.mode == 'cover' ? BoxFit.cover : BoxFit.contain),
            ],
          );
        },
      ),
    );
  }
}
