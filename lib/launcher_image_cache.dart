import 'package:flutter/widgets.dart';

/// A key for a decoded poster, including any resize parameters.
abstract interface class PosterCacheKey {}

class LauncherWidgetsBinding extends WidgetsFlutterBinding {
  LauncherWidgetsBinding._();

  static LauncherWidgetsBinding? _instance;

  static LauncherWidgetsBinding ensureInitialized() =>
      _instance ??= LauncherWidgetsBinding._();

  @override
  ImageCache createImageCache() => LauncherImageCache();
}

void configureLauncherImageCache({
  bool economy = false,
  bool secondaryEngine = false,
  int applicationMiB = 20,
  int posterMiB = 30,
}) {
  final cache = PaintingBinding.instance.imageCache;
  final (apps, posters, entries, applicationShare) = switch ((secondaryEngine, economy)) {
    (true, _) => (8, 0, 20, 100),
    (false, true) => (8, 8, 64, 50),
    (false, false) => (applicationMiB, posterMiB, 100, 40),
  };
  if (cache is LauncherImageCache) {
    cache._applicationShare = applicationShare;
    cache._applications.maximumSizeBytes = apps * 1024 * 1024;
    cache._posters.maximumSizeBytes = posters * 1024 * 1024;
  } else {
    cache.maximumSizeBytes = (apps + posters) * 1024 * 1024;
  }
  cache.maximumSize = entries;
}

/// Routes keys to independent Flutter LRUs while exposing their combined budget.
class LauncherImageCache extends ImageCache {
  LauncherImageCache() {
    maximumSizeBytes = 50 * 1024 * 1024;
    maximumSize = 100;
  }

  final _applications = ImageCache();
  final _posters = ImageCache();
  int _applicationShare = 40;

  ImageCache _cacheFor(Object key) =>
      key is PosterCacheKey ? _posters : _applications;

  Map<String, Map<String, int>> get partitions => {
    'applications': _snapshot(_applications),
    'posters': _snapshot(_posters),
  };

  Map<String, int> _snapshot(ImageCache cache) => {
    'bytes': cache.currentSizeBytes,
    'maximumBytes': cache.maximumSizeBytes,
    'entries': cache.currentSize,
    'maximumEntries': cache.maximumSize,
    'live': cache.liveImageCount,
  };

  @override
  int get maximumSize => _applications.maximumSize + _posters.maximumSize;

  @override
  set maximumSize(int value) {
    final applications = value * _applicationShare ~/ 100;
    _applications.maximumSize = applications;
    _posters.maximumSize = value - applications;
  }

  @override
  int get maximumSizeBytes =>
      _applications.maximumSizeBytes + _posters.maximumSizeBytes;

  @override
  set maximumSizeBytes(int value) {
    final applications = value * _applicationShare ~/ 100;
    _applications.maximumSizeBytes = applications;
    _posters.maximumSizeBytes = value - applications;
  }

  @override
  int get currentSize => _applications.currentSize + _posters.currentSize;

  @override
  int get currentSizeBytes =>
      _applications.currentSizeBytes + _posters.currentSizeBytes;

  @override
  int get liveImageCount =>
      _applications.liveImageCount + _posters.liveImageCount;

  @override
  int get pendingImageCount =>
      _applications.pendingImageCount + _posters.pendingImageCount;

  @override
  void clear() {
    _applications.clear();
    _posters.clear();
  }

  @override
  void clearLiveImages() {
    _applications.clearLiveImages();
    _posters.clearLiveImages();
  }

  @override
  bool containsKey(Object key) => _cacheFor(key).containsKey(key);

  @override
  ImageCacheStatus statusForKey(Object key) => _cacheFor(key).statusForKey(key);

  @override
  bool evict(Object key, {bool includeLive = true}) =>
      _cacheFor(key).evict(key, includeLive: includeLive);

  @override
  ImageStreamCompleter? putIfAbsent(
    Object key,
    ImageStreamCompleter Function() loader, {
    ImageErrorListener? onError,
  }) => _cacheFor(key).putIfAbsent(key, loader, onError: onError);
}

/// ResizeImage hides its source key. Tag the final key used by the cache.
class PosterTileImage extends ImageProvider<PosterTileCacheKey> {
  const PosterTileImage(this.image);

  final ResizeImage image;

  @override
  Future<PosterTileCacheKey> obtainKey(
    ImageConfiguration configuration,
  ) => image.obtainKey(configuration).then(PosterTileCacheKey._);

  @override
  ImageStreamCompleter loadImage(
    PosterTileCacheKey key,
    ImageDecoderCallback decode,
  ) => image.loadImage(key._resizeKey, decode);

  @override
  bool operator ==(Object other) =>
      other is PosterTileImage && image == other.image;

  @override
  int get hashCode => Object.hash(PosterTileImage, image);
}

final class PosterTileCacheKey implements PosterCacheKey {
  const PosterTileCacheKey._(this._resizeKey);

  final ResizeImageKey _resizeKey;

  @override
  bool operator ==(Object other) =>
      other is PosterTileCacheKey && _resizeKey == other._resizeKey;

  @override
  int get hashCode => Object.hash(PosterTileCacheKey, _resizeKey);
}
