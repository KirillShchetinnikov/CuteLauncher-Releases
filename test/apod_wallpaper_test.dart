import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/apod_wallpaper.dart';
import 'package:flauncher/online_wallpaper_failure.dart';
import 'package:flauncher/providers/online_wallpaper_service.dart';
import 'package:flauncher/settings_import.dart';

void main() {
  Map<String, dynamic> entry(
    String date, [
    Map<String, dynamic> overrides = const {},
  ]) => {
    'date': date,
    'media_type': 'image',
    'title': 'Galaxy &amp; stars',
    'hdurl': 'https://assets.science.nasa.gov/dynamicimage/assets/science/galaxy.png?w=4144&h=2822&fit=clip',
    'url': 'https://science.nasa.gov/image-article/today/',
    'credit':
        '<b>Image Credit:</b> <a href="https://example.com/">Author &#169;</a>',
    'permalink': 'https://science.nasa.gov/image-article/today/',
    ...overrides,
  };
  test('official bounded feed has no API key; image comes from hdurl, never page url', () {
    expect(apodFeedUri.host, 'science.nasa.gov');
    expect(apodFeedUri.queryParameters, {'per_page': '7'});
    final image = parseApodWallpapers([entry('2026-11-04')]);
    expect(image.uri.host, 'assets.science.nasa.gov');
    expect(image.uri.queryParameters['w'], '1920');
    expect(image.uri.queryParameters['h'], '1080');
    expect(image.credit, contains('Galaxy & stars'));
    expect(image.credit, contains('Image Credit: Author ©'));
    expect(
      image.credit,
      contains('https://science.nasa.gov/image-article/today/'),
    );
    expect(image.credit, isNot(contains('<b>')));
  });
  test(
    'selects latest valid static image, skipping videos and malformed records',
    () {
      final image = parseApodWallpapers([
        entry('2026-11-02'),
        entry('2026-11-04', {'media_type': 'video'}),
        entry('2026-11-05', {'media_type': 'iframe'}),
        entry('2026-11-03'),
        entry('2026-02-31'),
        null,
      ]);
      expect(image.date, '2026-11-03');
      expect(
        () => parseApodWallpapers([
          entry('2026-11-04', {'media_type': 'video'}),
        ]),
        throwsA(
          isA<WallpaperException>().having(
            (e) => e.reason,
            'reason',
            WallpaperFailureReason.noImage,
          ),
        ),
      );
    },
  );
  test('rejects unsafe, unsupported and missing image addresses', () {
    for (final url in [
      null,
      '',
      'https://science.nasa.gov/image-article/today/',
      'http://apod.nasa.gov/apod/image/a.jpg',
      'https://evil.example/a.jpg',
      'https://user@assets.science.nasa.gov/a.jpg',
      'https://assets.science.nasa.gov:444/a.jpg',
      'https://assets.science.nasa.gov/a.gif',
      'https://assets.science.nasa.gov/a.jpg#part',
    ]) {
      expect(
        () => parseApodWallpapers([
          entry('2026-11-04', {'hdurl': url}),
        ]),
        throwsA(isA<WallpaperException>()),
        reason: '$url',
      );
    }
    final image = parseApodWallpapers([
      entry('2026-11-04', {
        'hdurl': 'https://apod.nasa.gov/apod/image/2611/a.jpg',
        'credit': null,
        'copyright': 'Artist',
      }),
    ]);
    expect(image.uri.host, 'apod.nasa.gov');
    expect(image.credit, contains('Artist'));
  });
  test(
    'APOD configuration and backup preserve source and fixed hourly check',
    () {
      const config = OnlineWallpaperConfiguration(
        enabled: true,
        source: 'apod',
      );
      final restored = OnlineWallpaperConfiguration.decode(config.encode());
      expect(restored.source, 'apod');
      expect(restored.identity, 'apod');
      expect(restored.validUrl, isTrue);
      expect(restored.intervalHours, 1);
      expect(validOnlineWallpaperConfiguration(config.encode()), isTrue);
      final imported = compatibleSettings(
        {onlineWallpaperKey: config.encode()},
        {onlineWallpaperKey: ''},
      );
      expect(
        OnlineWallpaperConfiguration.decode(imported[onlineWallpaperKey])
            .source,
        'apod',
      );
    },
  );
}
