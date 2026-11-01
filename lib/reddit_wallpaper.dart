import 'dart:math';

import 'online_wallpaper_failure.dart';
import 'wallpaper_http.dart';

// Keep disabled in every build until API access is resolved and verified.
const redditWallpapersAvailable = false;

const redditWallpaperThemes = {
  'all': 'wallpapers',
  'nature': 'EarthPorn',
  'space': 'spaceporn',
  'city': 'CityPorn',
  'minimal': 'MinimalWallpaper',
};
const redditWallpaperResolutions = ['hd', 'fullHd', '4k'];

class RedditWallpaper {
  final Uri uri;
  final String credit;
  const RedditWallpaper(this.uri, this.credit);
}

typedef RedditWallpaperLookup = Future<RedditWallpaper> Function(
  String theme,
  String resolution,
  String? previousUrl,
);

/// Only static landscape images hosted by Reddit; no external image crawlers.
List<RedditWallpaper> parseRedditWallpapers(
  Map<String, dynamic> listing,
  String resolution,
  String? previousUrl,
) {
  final (minimumWidth, minimumHeight) = switch (resolution) {
    'hd' => (1280, 720),
    '4k' => (3840, 2160),
    _ => (1920, 1080),
  };
  final result = <String, RedditWallpaper>{};
  final children = listing['data']?['children'];
  if (children is! List) throw const FormatException('Invalid Reddit listing');
  for (final child in children.take(100)) {
    try {
      final post = child['data'] as Map;
      if (post['over_18'] != false ||
          post['spoiler'] == true ||
          post['is_video'] == true ||
          post['stickied'] == true) {
        continue;
      }
      final image = (post['preview']['images'] as List).first as Map;
      if (image['variants'] is Map &&
          ((image['variants'] as Map).containsKey('gif') ||
              (image['variants'] as Map).containsKey('mp4'))) {
        continue;
      }
      final source = image['source'] as Map;
      final width = source['width'] as int;
      final height = source['height'] as int;
      if (width < minimumWidth || height < minimumHeight || width <= height) {
        continue;
      }
      final url = post['url_overridden_by_dest'] ?? post['url'];
      if (url is! String || url == previousUrl) continue;
      final uri = Uri.tryParse(url);
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host != 'i.redd.it' ||
          uri.userInfo.isNotEmpty ||
          uri.hasPort ||
          !RegExp(
            r'\.(jpg|jpeg|png|webp)$',
            caseSensitive: false,
          ).hasMatch(uri.path)) {
        continue;
      }
      final author = post['author'] as String? ?? '';
      final subreddit = post['subreddit'] as String? ?? '';
      final title = post['title'] as String? ?? '';
      final credit = '$title — u/$author · r/$subreddit';
      result[url] = RedditWallpaper(
        uri,
        credit.substring(0, min(credit.length, 500)),
      );
    } catch (_) {
      /* Ignore malformed or unsupported posts. */
    }
  }
  return result.values.toList();
}

Future<RedditWallpaper> fetchRedditWallpaper(
  String theme,
  String resolution,
  String? previousUrl,
) async {
  if (!redditWallpapersAvailable) throw StateError('Reddit wallpapers are not available');
  final subreddit = redditWallpaperThemes[theme];
  if (subreddit == null || !redditWallpaperResolutions.contains(resolution)) {
    throw const FormatException('Invalid Reddit wallpaper settings');
  }
  final candidates = parseRedditWallpapers(
    await requestWallpaperJson(Uri.https('www.reddit.com', '/r/$subreddit/top.json', {
      't': 'month', 'limit': '100', 'raw_json': '1',
    })), resolution, previousUrl);
  if (candidates.isEmpty) {
    throw const WallpaperException(WallpaperFailureReason.noImage);
  }
  return candidates[Random().nextInt(candidates.length)];
}
