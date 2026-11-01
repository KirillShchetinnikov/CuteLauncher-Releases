import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/wallhaven_wallpaper.dart';
import 'package:flauncher/providers/online_wallpaper_service.dart';
import 'package:flauncher/settings_import.dart';

void main() {
  Map<String, dynamic> entry(
    String id, [
    Map<String, dynamic> overrides = const {},
  ]) => {
    'path': 'https://w.wallhaven.cc/full/ab/wallhaven-$id.jpg',
    'purity': 'sfw',
    'category': 'general',
    'dimension_x': 1920,
    'dimension_y': 1080,
    'file_size': 100000,
    'file_type': 'image/jpeg',
    ...overrides,
  };
  test('all themes use anonymous SFW Full HD widescreen random search', () {
    for (final theme in wallhavenWallpaperThemes.keys) {
      final uri = wallhavenSearchUri(theme);
      expect(uri.queryParameters['purity'], '100');
      expect(uri.queryParameters['categories'], '100');
      expect(uri.queryParameters['ratios'], '16x9');
      expect(uri.queryParameters['atleast'], '1920x1080');
      expect(uri.queryParameters['sorting'], 'random');
      expect(uri.queryParameters.containsKey('apikey'), isFalse);
      expect(uri.queryParameters['q'] ?? '', wallhavenWallpaperThemes[theme]);
    }
    expect(() => wallhavenSearchUri('invalid'), throwsFormatException);
  });
  test(
    'filters unsafe, malformed, oversized, duplicate and previous images',
    () {
      final previous = entry('ab0000')['path'] as String;
      final candidates = parseWallhavenWallpapers({
        'data': [
          entry('ab0000'),
          entry('ab0001'),
          entry('ab0001'),
          entry('ab0002', {'purity': 'nsfw'}),
          entry('ab0003', {'category': 'people'}),
          entry('ab0004', {'dimension_x': 1280}),
          entry('ab0005', {'dimension_y': 1920}),
          entry('ab0006', {'dimension_x': 16000, 'dimension_y': 9000}),
          entry('ab0007', {'file_size': 9 * 1024 * 1024}),
          entry('ab0008', {'file_type': 'image/gif'}),
          entry('ab0009', {
            'path': 'https://example.com/full/ab/wallhaven-ab0009.jpg',
          }),
          entry('ab0010', {
            'path': 'http://w.wallhaven.cc/full/ab/wallhaven-ab0010.jpg',
          }),
          entry('ab0011', {
            'path': 'https://user@w.wallhaven.cc/full/ab/wallhaven-ab0011.jpg',
          }),
          entry('ab0012', {
            'path': 'https://w.wallhaven.cc:444/full/ab/wallhaven-ab0012.jpg',
          }),
          entry('ab0013', {
            'path':
                'https://w.wallhaven.cc/full/ab/wallhaven-ab0013.jpg?token=x',
          }),
          entry('ab0014', {'file_size': -1}),
          {},
          null,
        ],
      }, previous);
      expect(candidates.map((e) => e.uri.toString()), [
        entry('ab0001')['path'],
      ]);
      expect(
        candidates.single.credit,
        'Wallhaven · https://wallhaven.cc/w/ab0001',
      );
      expect(() => parseWallhavenWallpapers({}, null), throwsFormatException);
      expect(parseWallhavenWallpapers({'data': []}, null), isEmpty);
    },
  );
  test('settings and backup retain Wallhaven theme and interval', () {
    const config = OnlineWallpaperConfiguration(
      enabled: true,
      source: 'wallhaven',
      wallhavenTheme: 'nature',
      intervalHours: 6,
    );
    final restored = OnlineWallpaperConfiguration.decode(config.encode());
    expect(restored.validUrl, isTrue);
    expect(restored.identity, 'wallhaven:nature');
    expect(restored.intervalHours, 6);
    expect(
      restored.copyWith(wallhavenTheme: 'city').identity,
      'wallhaven:city',
    );
    expect(validOnlineWallpaperConfiguration(config.encode()), isTrue);
    expect(
      compatibleSettings({
        onlineWallpaperKey: config.encode(),
      }, {})[onlineWallpaperKey],
      config.encode(),
    );
    expect(
      validOnlineWallpaperConfiguration(
        config.encode().replaceAll('nature', 'invalid'),
      ),
      isFalse,
    );
    expect(
      OnlineWallpaperConfiguration.decode(
        config.encode().replaceAll('nature', 'invalid'),
      ).wallhavenTheme,
      'all',
    );
  });
}
