import 'dart:convert';
import 'dart:io';

import 'image_limits.dart';
import 'online_wallpaper_failure.dart';

/// Bounded metadata request preserving HTTP failures for every wallpaper source.
Future<Map<String, dynamic>> requestWallpaperJson(
  Uri uri, {
  int limit = 2 * 1024 * 1024,
  Duration timeout = const Duration(seconds: 20),
}) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
  client.userAgent = 'CuteLauncher (+https://github.com/KirillShchetinnikov/CuteLauncher-Releases)';
  try {
    return await (() async {
      final request = await client.getUrl(uri);
      request.followRedirects = false;
      final response = await request.close();
      if (response.statusCode != 200) {
        throw WallpaperException(
          WallpaperFailureReason.http,
          httpStatus: response.statusCode,
        );
      }
      if (response.contentLength > limit) {
        throw const WallpaperException(WallpaperFailureReason.tooLarge);
      }
      final bytes = await readBoundedImage(response, limit: limit);
      return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    })().timeout(timeout);
  } finally {
    client.close(force: true);
  }
}
