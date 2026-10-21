import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/reddit_wallpaper.dart';
import 'package:flauncher/providers/online_wallpaper_service.dart';

void main() {
  Map<String, dynamic> post(
    String name, {
    int width = 3840,
    int height = 2160,
    bool adult = false,
    bool video = false,
    String? url,
  }) => {
    'data': {
      'url': url ?? 'https://i.redd.it/$name.jpg',
      'over_18': adult,
      'is_video': video,
      'title': name,
      'author': 'artist',
      'subreddit': 'wallpapers',
      'preview': {
        'images': [
          {
            'source': {'width': width, 'height': height},
            'variants': {},
          },
        ],
      },
    },
  };
  Map<String, dynamic> listing(List<Object> posts) => {
    'data': {'children': posts},
  };

  test(
    'filters minimum resolution, landscape, adult, video and previous image',
    () {
      final data = listing([
        post('last'),
        post('new'),
        post('small', width: 1920, height: 1080),
        post('portrait', width: 2160, height: 3840),
        post('adult', adult: true),
        post('video', video: true),
        post('external', url: 'https://example.com/image.jpg'),
        post('insecure', url: 'http://i.redd.it/image.jpg'),
        {'data': {}},
      ]);
      final result = parseRedditWallpapers(
        data,
        '4k',
        'https://i.redd.it/last.jpg',
      );
      expect(result.map((v) => v.uri.toString()), [
        'https://i.redd.it/new.jpg',
      ]);
      expect(result.single.credit, 'new — u/artist · r/wallpapers');
      expect(
        parseRedditWallpapers(
          data,
          'fullHd',
          'https://i.redd.it/last.jpg',
        ).length,
        2,
      );
    },
  );
  test(
    'rejects animation, spoilers, galleries, duplicate and authenticated URLs',
    () {
      final animated = post('animated');
      ((animated['data'] as Map)['preview']['images'] as List)
          .first['variants'] = {
        'gif': {},
      };
      final spoiler = post('spoiler');
      (spoiler['data'] as Map)['spoiler'] = true;
      expect(
        parseRedditWallpapers(
          listing([
            animated,
            spoiler,
            post('gallery', url: 'https://www.reddit.com/gallery/abc'),
            post('credentials', url: 'https://user:password@i.redd.it/a.jpg'),
            post('new'),
            post('new'),
          ]),
          'hd',
          null,
        ).length,
        1,
      );
      expect(
        parseRedditWallpapers(
          listing([post('last')]),
          'hd',
          'https://i.redd.it/last.jpg',
        ),
        isEmpty,
      );
    },
  );
  test('unavailable Reddit configuration falls back to Bing and rejects invalid filters', () {
    const config = OnlineWallpaperConfiguration(
      enabled: true,
      source: 'reddit',
      intervalHours: 6,
      redditTheme: 'nature',
      redditResolution: '4k',
    );
    final restored = OnlineWallpaperConfiguration.decode(config.encode());
    expect(redditWallpapersAvailable, isFalse);
    expect(restored.source, 'bing');
    expect(restored.enabled, isTrue);
    expect(restored.redditTheme, 'nature');
    expect(restored.redditResolution, '4k');
    expect(restored.intervalHours, 1);
    expect(validOnlineWallpaperConfiguration(config.encode()), isTrue);
    expect(
      validOnlineWallpaperConfiguration(
        config.encode().replaceFirst('nature', 'unknown'),
      ),
      isFalse,
    );
    expect(
      validOnlineWallpaperConfiguration(
        config.encode().replaceFirst('4k', '8k'),
      ),
      isFalse,
    );
    expect(restored.copyWith(source: 'bing').intervalHours, 1);
    expect(
      restored
          .copyWith(source: 'bing')
          .copyWith(source: 'reddit')
          .intervalHours,
      6,
    );
  });
}
