import 'dart:math';

import 'image_limits.dart';
import 'online_wallpaper_failure.dart';
import 'wallpaper_http.dart';

const wallhavenWallpaperThemes = {
  'all': '',
  'nature': 'nature',
  'space': 'space',
  'city': 'city',
  'minimal': 'minimalism',
};

class WallhavenWallpaper {
  final Uri uri;
  final String credit;
  const WallhavenWallpaper(this.uri, this.credit);
}

typedef WallhavenWallpaperLookup = Future<WallhavenWallpaper> Function(
  String theme,
  String? previousUrl,
);

Uri wallhavenSearchUri(String theme) {
  final query = wallhavenWallpaperThemes[theme];
  if (query == null) throw const FormatException('Invalid Wallhaven theme');
  return Uri.https('wallhaven.cc', '/api/v1/search', {
    'purity': '100',
    'categories': '100',
    'sorting': 'random',
    'atleast': '1920x1080',
    'ratios': '16x9',
    if (query.isNotEmpty) 'q': query,
  });
}

List<WallhavenWallpaper> parseWallhavenWallpapers(
  Map<String, dynamic> listing,
  String? previousUrl,
) {
  final entries = listing['data'];
  if (entries is! List) {
    throw const FormatException('Invalid Wallhaven listing');
  }
  final result = <String, WallhavenWallpaper>{};
  for (final entry in entries.take(24)) {
    if (entry is! Map) continue;
    final width = entry['dimension_x'], height = entry['dimension_y'];
    final size = entry['file_size'];
    if (entry['purity'] != 'sfw' ||
        entry['category'] != 'general' ||
        width is! int ||
        height is! int ||
        width < 1920 ||
        height < 1080 ||
        (width / height - 16 / 9).abs() > 0.02 ||
        width * height > maximumImagePixels ||
        size is! int ||
        size <= 0 ||
        size > maximumImageInputBytes ||
        ![
          'image/jpeg',
          'image/png',
          'image/webp',
        ].contains(entry['file_type'])) {
      continue;
    }
    final url = entry['path'];
    if (url is! String || url == previousUrl) continue;
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'w.wallhaven.cc' ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        uri.hasQuery ||
        uri.hasFragment ||
        !RegExp(
          r'^/full/[a-z0-9]{2}/wallhaven-[a-z0-9]{6}\.(jpg|jpeg|png|webp)$',
        ).hasMatch(uri.path)) {
      continue;
    }
    final id = uri.pathSegments.last.split('.').first.substring(10);
    result[url] = WallhavenWallpaper(
      uri,
      'Wallhaven · https://wallhaven.cc/w/$id',
    );
  }
  return result.values.toList();
}

Future<WallhavenWallpaper> fetchWallhavenWallpaper(
  String theme,
  String? previousUrl,
) async {
  final uri = wallhavenSearchUri(theme);
  final candidates = parseWallhavenWallpapers(await requestWallpaperJson(uri), previousUrl);
  if (candidates.isEmpty) {
    throw const WallpaperException(WallpaperFailureReason.noImage);
  }
  return candidates[Random().nextInt(candidates.length)];
}
