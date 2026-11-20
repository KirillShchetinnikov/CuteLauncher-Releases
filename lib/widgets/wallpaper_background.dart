import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../image_limits.dart';
import 'background_raster_cache.dart';

/// Reveal a new online picture only after its first viewport-sized frame exists.
class OnlineWallpaperTransition extends StatefulWidget {
  const OnlineWallpaperTransition({
    super.key,
    required this.image,
    required this.background,
    required this.animate,
  });
  final ImageProvider image;
  final Widget Function(ImageProvider?) background;
  final bool animate;

  @override
  State<OnlineWallpaperTransition> createState() =>
      _OnlineWallpaperTransitionState();
}

class _OnlineWallpaperTransitionState extends State<OnlineWallpaperTransition>
    with SingleTickerProviderStateMixin {
  late final _progress =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 240),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed && _previous != null) {
          setState(() => _previous = null);
        }
      });
  ImageProvider? _previous, _current;
  ImageStream? _pending;
  ImageStreamListener? _listener;
  ImageProvider? _requested;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(OnlineWallpaperTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.animate && _previous != null) _progress.value = 1;
    _resolve();
  }

  void _resolve() {
    final image = widget.image;
    final sized = sizedImage(
      image,
      MediaQuery.sizeOf(context),
      MediaQuery.devicePixelRatioOf(context),
    );
    if (sized == _requested) return;
    _requested = sized;
    _detach();
    final stream = sized.resolve(createLocalImageConfiguration(context));
    _pending = stream;
    _listener = ImageStreamListener(
      (info, _) {
        info.dispose();
        if (!mounted || _pending != stream) return;
        // Keep the decoded frame live until Image has attached its own listener.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pending == stream) _detach();
        });
        if (_current == image) return;
        setState(() {
          _previous = widget.animate ? _current : null;
          _current = image;
        });
        if (_previous != null) _progress.forward(from: 0);
      },
      onError: (Object _, StackTrace? _) {
        if (_pending == stream) _detach();
      },
    );
    stream.addListener(_listener!);
  }

  void _detach() {
    if (_listener != null) _pending?.removeListener(_listener!);
    _pending = null;
    _listener = null;
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    Widget layer(ImageProvider? image, {bool incoming = true}) => ClipRect(
      key: ValueKey(image),
      clipper: _previous == null
          ? null
          : _WallpaperReveal(_progress, incoming, rtl),
      clipBehavior: _previous == null ? Clip.none : Clip.hardEdge,
      child: widget.background(image),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_previous != null) layer(_previous, incoming: false),
        layer(_current),
      ],
    );
  }

  @override
  void dispose() {
    _detach();
    _progress.dispose();
    super.dispose();
  }
}

class _WallpaperReveal extends CustomClipper<Rect> {
  _WallpaperReveal(this.progress, this.incoming, this.rtl)
    : super(reclip: progress);
  final Animation<double> progress;
  final bool incoming, rtl;

  @override
  Rect getClip(Size size) {
    final fraction = Curves.easeInOut.transform(progress.value);
    final edge = size.width * (rtl ? 1 - fraction : fraction);
    return incoming != rtl
        ? Rect.fromLTRB(0, 0, edge, size.height)
        : Rect.fromLTRB(edge, 0, size.width, size.height);
  }

  @override
  bool shouldReclip(_WallpaperReveal old) =>
      old.progress != progress || old.incoming != incoming || old.rtl != rtl;
}

/// Bounded image decoding shared by the foreground and its optional blurred copy.
class WallpaperBackground extends StatelessWidget {
  final ImageProvider? image;
  final Gradient gradient;
  final String mode;
  final double brightness;
  final double saturation;
  final double dimming;
  final bool memorySaver;
  final Widget? artwork;

  /// Lets an opaque live source omit the fallback while it covers the viewport.
  final Widget Function(Widget fallback)? artworkBuilder;

  /// Only for artwork backed by a still image, never an external video Texture.
  final bool cacheArtwork;

  /// Flatten only static underlay/dimming around externally updated textures.
  final bool cacheStaticLayers;

  const WallpaperBackground({
    super.key,
    required this.image,
    required this.gradient,
    this.mode = 'cover',
    this.brightness = 1,
    this.saturation = 1,
    this.dimming = 1,
    this.memorySaver = false,
    this.artwork,
    this.artworkBuilder,
    this.cacheArtwork = false,
    this.cacheStaticLayers = false,
  }) : assert(artwork == null || artworkBuilder == null);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final cacheLayers =
        cacheStaticLayers &&
        !memorySaver &&
        (size.width * ratio).ceil() * (size.height * ratio).ceil() * 8 <=
            16 * 1024 * 1024;
    Widget staticLayer(Widget child) => cacheStaticLayers
        ? BackgroundRasterCache(enabled: cacheLayers, child: child)
        : child;
    final provider = image;
    Widget fallback() =>
        DecoratedBox(decoration: BoxDecoration(gradient: gradient));
    Widget picture(BoxFit fit) => Image(
      image: sizedImage(
        provider!,
        size,
        MediaQuery.devicePixelRatioOf(context),
      ),
      fit: fit,
      width: size.width,
      height: size.height,
      // Keep the displayed slide until the replacement finishes decoding.
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => fallback(),
    );
    Widget background = artworkBuilder != null
        ? artworkBuilder!(staticLayer(fallback()))
        : artwork == null
        ? fallback()
        : Stack(
            fit: StackFit.expand,
            children: [staticLayer(fallback()), artwork!],
          );
    if (provider != null) {
      background = Stack(
        fit: StackFit.expand,
        children: [
          if (mode == 'blurred' && !memorySaver)
            ClipRect(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(
                  sigmaX: 20,
                  sigmaY: 20,
                  tileMode: TileMode.clamp,
                ),
                child: picture(BoxFit.cover),
              ),
            ),
          picture(mode == 'cover' ? BoxFit.cover : BoxFit.contain),
        ],
      );
    }
    final inverse = 1 - saturation;
    final r = inverse * .2126;
    final g = inverse * .7152;
    final b = inverse * .0722;
    final composition = Stack(
      fit: StackFit.expand,
      children: [
        if (brightness == 1 && saturation == 1)
          background
        else
          ColorFiltered(
            colorFilter: ColorFilter.matrix([
              (r + saturation) * brightness,
              g * brightness,
              b * brightness,
              0,
              0,
              r * brightness,
              (g + saturation) * brightness,
              b * brightness,
              0,
              0,
              r * brightness,
              g * brightness,
              (b + saturation) * brightness,
              0,
              0,
              0,
              0,
              0,
              1,
              0,
            ]),
            child: background,
          ),
        staticLayer(
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  for (final alpha in [.35, .15, .45])
                    Colors.black.withValues(
                      alpha: (alpha * dimming).clamp(0, 1),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
    // Only still backgrounds can be flattened. A video Texture updates outside
    // Flutter paint; caching artwork here could freeze playback.
    return (artwork == null && artworkBuilder == null) || cacheArtwork
        ? BackgroundRasterCache(enabled: !memorySaver, child: composition)
        : composition;
  }
}
