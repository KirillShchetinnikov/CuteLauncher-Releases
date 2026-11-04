import 'online_wallpaper_failure.dart';
import 'wallpaper_http.dart';

/// NASA's current APOD feed. One bounded request also covers recent video days.
final apodFeedUri = Uri.https('science.nasa.gov', '/wp-json/wp/v2/apod-basic', {
  'per_page': '7',
});

class ApodWallpaper {
  final Uri uri;
  final String credit;
  final String date;
  const ApodWallpaper(this.uri, this.credit, this.date);
}

String _plainText(Object? value, int limit) {
  if (value is! String) return '';
  var text = value
      .substring(0, value.length.clamp(0, 8000))
      .replaceAll(RegExp(r'<[^>]*>'), ' ');
  text = text.replaceAllMapped(RegExp(r'&#(x[0-9a-fA-F]+|[0-9]+);'), (m) {
    final code = m[1]!.startsWith('x')
        ? int.tryParse(m[1]!.substring(1), radix: 16)
        : int.tryParse(m[1]!);
    return code != null &&
            code >= 32 &&
            code <= 0x10ffff &&
            !(code >= 0xd800 && code <= 0xdfff)
        ? String.fromCharCode(code)
        : '';
  });
  for (final entity in const {
    '&amp;': '&',
    '&quot;': '"',
    '&apos;': "'",
    '&lt;': '<',
    '&gt;': '>',
    '&nbsp;': ' ',
  }.entries) {
    text = text.replaceAll(entity.key, entity.value);
  }
  text = text
      .replaceAll(RegExp(r'[\x00-\x1f\x7f]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return text.substring(0, text.length.clamp(0, limit));
}

ApodWallpaper parseApodWallpapers(List<dynamic> listing) {
  final candidates = <ApodWallpaper>[];
  for (final entry in listing.take(7)) {
    if (entry is! Map || entry['media_type'] != 'image') continue;
    final date = entry['date'];
    if (date is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
      continue;
    }
    final parsed = DateTime.tryParse(date);
    if (parsed == null || parsed.toIso8601String().substring(0, 10) != date) {
      continue;
    }
    final url = entry['hdurl'];
    if (url is! String || url.length > 2048) continue;
    var uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        uri.hasFragment ||
        !['assets.science.nasa.gov', 'apod.nasa.gov'].contains(uri.host) ||
        !RegExp(
          r'\.(jpe?g|png|webp)$',
          caseSensitive: false,
        ).hasMatch(uri.path)) {
      continue;
    }
    // NASA's image service preserves aspect ratio and bounds large originals.
    if (uri.host == 'assets.science.nasa.gov' &&
        uri.path.startsWith('/dynamicimage/')) {
      uri = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          'w': '1920',
          'h': '1080',
          'fit': 'clip',
        },
      );
    }
    final page = entry['permalink'];
    final pageUri = page is String && page.length <= 2048
        ? Uri.tryParse(page)
        : null;
    final credit = [
      'NASA APOD · $date',
      _plainText(entry['title'], 300),
      _plainText(entry['credit'] ?? entry['copyright'], 1000),
      if (pageUri != null &&
          pageUri.scheme == 'https' &&
          pageUri.host == 'science.nasa.gov' &&
          pageUri.userInfo.isEmpty &&
          !pageUri.hasPort &&
          !pageUri.hasFragment)
        pageUri.toString(),
    ].where((s) => s.isNotEmpty).join('\n');
    candidates.add(ApodWallpaper(uri, credit, date));
  }
  if (candidates.isEmpty) {
    throw const WallpaperException(WallpaperFailureReason.noImage);
  }
  candidates.sort((a, b) => b.date.compareTo(a.date));
  return candidates.first;
}

Future<ApodWallpaper> fetchApodWallpaper() async =>
    parseApodWallpapers(await requestWallpaperJsonList(apodFeedUri));
