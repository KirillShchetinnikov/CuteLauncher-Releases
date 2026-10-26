import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../l10n/app_localizations.dart';
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
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;
  bool _resumed = true;
  Timer? _initializationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resumed =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _controller = VideoPlayerController.file(
      widget.file,
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        // Lifecycle is owned here so plugin auto-resume cannot restart a hidden Home.
        allowBackgroundPlayback: true,
        preventsDisplaySleepDuringVideoPlayback: false,
      ),
    );
    _controller.addListener(_onValue);
    _initializationTimer = Timer(const Duration(seconds: 20), _fail);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      _initializationTimer?.cancel();
      if (!mounted || _failed) return;
      await _controller.setVolume(0);
      await _controller.setLooping(true);
      if (!mounted || _failed) return;
      setState(() => _ready = true);
      await _syncPlayback();
    } catch (_) {
      _initializationTimer?.cancel();
      _fail();
    }
  }

  void _onValue() {
    if (_controller.value.hasError) _fail();
  }

  void _fail() {
    if (!mounted || _failed) return;
    setState(() => _failed = true);
    _initializationTimer?.cancel();
    unawaited(_controller.dispose().catchError((Object _) {}));
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
    if (!_ready || _failed || !mounted) return;
    try {
      if (widget.enabled && _resumed) {
        await _controller.play();
      } else {
        await _controller.pause();
      }
    } catch (_) {
      _fail();
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
    unawaited(_controller.dispose());
    super.dispose();
  }

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
