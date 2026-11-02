import 'dart:async';

import 'package:flutter/material.dart';

import '../app_image_colors.dart';
import '../image_limits.dart';
import '../tile_image_geometry.dart';

/// Artwork fitting and optional edge colors, independent of focus decoration.
class TileArtwork extends StatefulWidget {
  final ImageProvider image;
  final TileImageMode mode;
  final BorderRadius borderRadius;
  final bool isIcon;
  final double iconScale;
  final double decodeScale;
  final Widget? inlineLabel;
  final Future<ImageProvider?> Function()? loadIcon;
  final ImageFrameBuilder? frameBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;
  const TileArtwork({
    super.key,
    required this.image,
    required this.mode,
    required this.borderRadius,
    this.isIcon = false,
    this.iconScale = 1,
    this.decodeScale = 1,
    this.inlineLabel,
    this.loadIcon,
    this.frameBuilder,
    this.errorBuilder,
  });

  @override
  State<TileArtwork> createState() => _TileArtworkState();
}

class _TileArtworkState extends State<TileArtwork> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ImageProvider? _resolved;
  Size? _source;
  Future<ImageProvider?>? _icon;
  bool _iconFailed = false;

  @override
  void didUpdateWidget(TileArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      _source = null;
      _icon = null;
      _iconFailed = false;
    }
  }

  void _listen(ImageProvider image) {
    if (_resolved == image) return;
    _detach();
    _resolved = image;
    _stream = image.resolve(createLocalImageConfiguration(context));
    var synchronous = true;
    _listener = ImageStreamListener(
      (info, _) {
        final size = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
        info.dispose();
        if (_source == size || !mounted) return;
        if (synchronous) {
          _source = size;
        } else {
          setState(() => _source = size);
        }
      },
      onError: (Object error, StackTrace? stack) {
        // The Image widget owns readiness/error presentation.
      },
    );
    _stream!.addListener(_listener!);
    synchronous = false;
  }

  void _detach() {
    if (_listener != null) _stream?.removeListener(_listener!);
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest;
      final bounds = Offset.zero & size;
      final shape = widget.borderRadius.toRRect(bounds).scaleRadii();
      var area = bounds;
      if (widget.isIcon) {
        area = bounds.deflate(8);
        if (widget.inlineLabel != null) {
          area = Rect.fromLTWH(
            area.left,
            area.top,
            area.width * .4,
            area.height,
          );
        }
        area = Rect.fromCenter(
          center: area.center,
          width: area.width * widget.iconScale,
          height: area.height * widget.iconScale,
        );
      }
      final image = sizedImage(
        widget.image,
        widget.isIcon ? area.size : size,
        MediaQuery.devicePixelRatioOf(context) * widget.decodeScale,
        maximumEdge: 1024,
      );
      _listen(image);
      final source = _source;
      final baselineFit =
          !widget.isIcon && (size.aspectRatio - 16 / 9).abs() < .0001
          ? BoxFit.cover
          : BoxFit.contain;
      final original = source == null
          ? area
          : tileImageRect(source, area, baselineFit);
      final adjust =
          source != null && tileImageNeedsAdjustment(original, shape);
      if (adjust &&
          widget.mode == TileImageMode.icon &&
          !_iconFailed &&
          !widget.isIcon &&
          widget.loadIcon != null) {
        _icon ??= Future.sync(widget.loadIcon!).catchError((Object _) => null);
        return FutureBuilder<ImageProvider?>(
          future: _icon,
          builder: (context, snapshot) {
            if (snapshot.data case final icon?) {
              return TileArtwork(
                image: icon,
                mode: TileImageMode.edgeColor,
                borderRadius: widget.borderRadius,
                isIcon: true,
                iconScale: widget.iconScale,
                decodeScale: widget.decodeScale,
                frameBuilder: widget.frameBuilder,
                errorBuilder: (context, error, stack) {
                  if (!_iconFailed) {
                    _iconFailed = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() {});
                    });
                  }
                  return widget.errorBuilder?.call(context, error, stack) ??
                      const SizedBox.shrink();
                },
              );
            }
            return _art(
              image,
              original,
              source,
              area,
              shape,
              adjust,
              fallback: true,
            );
          },
        );
      }
      return _art(image, original, source, area, shape, adjust);
    },
  );

  Widget _art(
    ImageProvider image,
    Rect original,
    Size? source,
    Rect area,
    RRect shape,
    bool adjust, {
    bool fallback = false,
  }) {
    final mode = fallback ? TileImageMode.edgeColor : widget.mode;
    final rect = !adjust || source == null
        ? original
        : mode == TileImageMode.cover
        ? tileImageRect(source, area, BoxFit.cover)
        : safeTileImageRect(source, area, shape);
    final bytes = widget.image is MemoryImage
        ? (widget.image as MemoryImage).bytes
        : null;
    final fill =
        adjust &&
        (mode == TileImageMode.edgeColor || mode == TileImageMode.icon);
    final content = Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        if (fill && bytes != null)
          FutureBuilder<AppImageColors>(
            future: appImageColors(bytes),
            builder: (context, snapshot) => snapshot.hasData
                ? CustomPaint(painter: TileEdgePainter(snapshot.data!, rect))
                : const SizedBox.shrink(),
          ),
        Positioned.fromRect(
          rect: rect,
          child: Image(
            image: image,
            fit: source == null ? BoxFit.contain : BoxFit.fill,
            gaplessPlayback: true,
            frameBuilder: widget.frameBuilder,
            errorBuilder: widget.errorBuilder,
          ),
        ),
        if (widget.inlineLabel != null)
          Positioned(
            left: shape.width * .4 + 12,
            right: 8,
            top: 8,
            bottom: 8,
            child: Align(
              alignment: Alignment.centerLeft,
              child: widget.inlineLabel,
            ),
          ),
      ],
    );
    return ClipRRect(borderRadius: widget.borderRadius, child: content);
  }
}

/// Four constant-color regions meet at the nearest image edge, with no blur.
class TileEdgePainter extends CustomPainter {
  final AppImageColors colors;
  final Rect imageRect;
  const TileEdgePainter(this.colors, this.imageRect);
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    void region(Color? color, List<Offset> points) {
      if (color == null) return;
      final path = Path()..addPolygon(points, true);
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..isAntiAlias = false,
      );
    }

    region(colors.top, [
      bounds.topLeft,
      bounds.topRight,
      imageRect.topRight,
      imageRect.topLeft,
    ]);
    region(colors.right, [
      bounds.topRight,
      bounds.bottomRight,
      imageRect.bottomRight,
      imageRect.topRight,
    ]);
    region(colors.bottom, [
      bounds.bottomRight,
      bounds.bottomLeft,
      imageRect.bottomLeft,
      imageRect.bottomRight,
    ]);
    region(colors.left, [
      bounds.bottomLeft,
      bounds.topLeft,
      imageRect.topLeft,
      imageRect.bottomLeft,
    ]);
  }

  @override
  bool shouldRepaint(TileEdgePainter oldDelegate) =>
      oldDelegate.colors != colors || oldDelegate.imageRect != imageRect;
}
