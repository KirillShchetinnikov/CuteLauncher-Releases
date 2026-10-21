import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_artwork.dart';
import 'wallpaper_background.dart';

/// One current texture, one decode at a time, and only the latest focus request.
class AppArtworkBackground extends StatefulWidget {
  final ValueListenable<ImageProvider?> images;
  final Gradient gradient;
  final bool enabled;
  final double brightness, saturation, dimming;
  const AppArtworkBackground({super.key, required this.images, required this.gradient,
    this.enabled = true, this.brightness = 1, this.saturation = 1, this.dimming = 1});

  @override
  State<AppArtworkBackground> createState() => _AppArtworkBackgroundState();
}

class _AppArtworkBackgroundState extends State<AppArtworkBackground> with WidgetsBindingObserver {
  ui.Image? _image;
  Timer? _timer;
  Timer? _decodeTimeout;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  Completer<ImageInfo?>? _pending;
  bool _busy = false, _resumed = true;
  int _generation = 0;
  bool get _active => mounted && widget.enabled && _resumed;

  @override
  void initState() {
    super.initState();
    _resumed = ![AppLifecycleState.paused, AppLifecycleState.hidden, AppLifecycleState.detached]
        .contains(WidgetsBinding.instance.lifecycleState);
    WidgetsBinding.instance.addObserver(this);
    widget.images.addListener(_request);
  }

  @override
  void didChangeDependencies() { super.didChangeDependencies(); _request(); }

  @override
  void didUpdateWidget(AppArtworkBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images != widget.images) {
      oldWidget.images.removeListener(_request);
      widget.images.addListener(_request);
    }
    if (oldWidget.images != widget.images || oldWidget.enabled != widget.enabled) _request();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _request();
  }

  void _request() {
    ++_generation;
    _timer?.cancel();
    _cancelDecode();
    if (!_active) {
      final old = _image;
      if (mounted) setState(() => _image = null);
      old?.dispose();
      return;
    }
    if (!_busy) _timer = Timer(const Duration(milliseconds: 120), _load);
  }

  Future<void> _load() async {
    if (!_active || _busy) return;
    final generation = _generation;
    final provider = widget.images.value;
    _busy = true;
    ui.Image? result;
    ImageInfo? source;
    try {
      if (provider != null) {
        final completion = _pending = Completer<ImageInfo?>();
        _stream = ResizeImage(provider, width: 48, height: 27,
          policy: ResizeImagePolicy.fit, allowUpscaling: false)
            .resolve(createLocalImageConfiguration(context));
        _listener = ImageStreamListener((info, _) {
          if (completion.isCompleted) { info.dispose(); return; }
          completion.complete(info);
        }, onError: (Object error, StackTrace? stack) {
          if (!completion.isCompleted) completion.complete(null);
        });
        _decodeTimeout = Timer(const Duration(seconds: 5), () {
          if (!completion.isCompleted) completion.complete(null);
        });
        _stream!.addListener(_listener!);
        source = await completion.future;
        if (!_active || generation != _generation) return;
        if (source == null) {
          final old = _image;
          setState(() => _image = null);
          old?.dispose();
          return;
        }
        final image = source.image;
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (data != null && _active && generation == _generation) {
          final pixels = softenAppArtwork(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), image.width, image.height);
          final decoded = Completer<ui.Image>();
          ui.decodeImageFromPixels(pixels, image.width, image.height, ui.PixelFormat.rgba8888, decoded.complete);
          result = await decoded.future;
        }
      }
      if (_active && generation == _generation) {
        final old = _image;
        setState(() { _image = result; result = null; });
        old?.dispose();
      }
    } catch (_) {
      if (_active && generation == _generation) {
        final old = _image;
        setState(() => _image = null);
        old?.dispose();
      }
    } finally {
      _cancelDecode();
      _pending = null;
      source?.dispose();
      result?.dispose();
      _busy = false;
      if (_active && generation != _generation) _timer = Timer(const Duration(milliseconds: 120), _load);
    }
  }

  void _cancelDecode() {
    _decodeTimeout?.cancel();
    final listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    _listener = null;
    _stream = null;
    final pending = _pending;
    if (pending != null && !pending.isCompleted) pending.complete(null);
  }

  @override
  void dispose() {
    ++_generation;
    _timer?.cancel();
    _cancelDecode();
    widget.images.removeListener(_request);
    WidgetsBinding.instance.removeObserver(this);
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => WallpaperBackground(
    image: null, gradient: widget.gradient,
    artwork: _image == null ? null : RawImage(image: _image, fit: BoxFit.cover, filterQuality: FilterQuality.medium),
    brightness: widget.brightness, saturation: widget.saturation, dimming: widget.dimming,
  );
}
