import 'dart:ui';

/// Small, bounded cloud sprites. Owned and disposed by the scene, never global.
class LandscapeCloudCache {
  static const maxBytes = 4 * 1024 * 1024;
  final _images = <Image>[];
  final _bounds = <Rect>[];
  Object? _key;
  int bytes = 0;
  final _paint = Paint()..filterQuality = FilterQuality.low;

  bool prepare(
    Size size,
    double ratio,
    List<Path> paths,
    Paint paint,
    Object key,
  ) {
    final identity = (size, ratio, key);
    if (_key == identity) return _images.isNotEmpty;
    clear();
    _key = identity;
    if (!ratio.isFinite || ratio <= 0) return false;
    final bounds = [
      for (final path in paths)
        Rect.fromLTRB(
          (path.getBounds().left * ratio).floorToDouble() / ratio - 1 / ratio,
          (path.getBounds().top * ratio).floorToDouble() / ratio - 1 / ratio,
          (path.getBounds().right * ratio).ceilToDouble() / ratio + 1 / ratio,
          (path.getBounds().bottom * ratio).ceilToDouble() / ratio + 1 / ratio,
        ),
    ];
    final requiredBytes = bounds.fold<int>(
      0,
      (total, rect) =>
          total +
          (rect.width * ratio).ceil() * (rect.height * ratio).ceil() * 4,
    );
    if (requiredBytes > maxBytes) return false;
    try {
      for (var i = 0; i < paths.length; i++) {
        final rect = bounds[i];
        final recorder = PictureRecorder();
        Canvas(recorder)
          ..scale(ratio)
          ..translate(-rect.left, -rect.top)
          ..drawPath(paths[i], paint);
        final picture = recorder.endRecording();
        try {
          _images.add(
            picture.toImageSync(
              (rect.width * ratio).ceil(),
              (rect.height * ratio).ceil(),
            ),
          );
          _bounds.add(rect);
        } finally {
          picture.dispose();
        }
      }
      bytes = requiredBytes;
      return true;
    } catch (_) {
      clear();
      _key =
          identity; // Fall back to paths until the scene configuration changes.
      return false;
    }
  }

  void draw(Canvas canvas, int index, double x) {
    final image = _images[index];
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      _bounds[index].shift(Offset(x, 0)),
      _paint,
    );
  }

  void clear() {
    for (final image in _images) {
      image.dispose();
    }
    _images.clear();
    _bounds.clear();
    bytes = 0;
    _key = null;
  }
}
