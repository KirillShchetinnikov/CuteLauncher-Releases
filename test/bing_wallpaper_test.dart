import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/bing_wallpaper.dart';
import 'package:flauncher/providers/online_wallpaper_service.dart';

void main() {
  test('StartGrid metadata yields 1080p URL, copyright, and next day plus ten minutes', () {
    final image = BingWallpaper.parse({'images': [{'urlbase': '/th?id=OHR.Example_EN-US123',
      'fullstartdate': '202610030700', 'copyright': 'Mountains (© Example Photographer)'}]});
    expect(image.uri.toString(), 'https://www.bing.com/th?id=OHR.Example_EN-US123_1920x1080.jpg');
    expect(image.expiresAt, DateTime.utc(2026, 10, 4, 7, 10));
    expect(image.copyright, contains('Example Photographer'));
    expect(validOnlineWallpaperConfiguration(const OnlineWallpaperConfiguration(enabled: true, source: 'bing').encode()), isTrue);
  });
  test('malformed metadata cannot redirect a Bing image to another host', () {
    expect(() => BingWallpaper.parse({'images': [{'urlbase': '//other.example/picture', 'fullstartdate': '202610030000'}]}), throwsFormatException);
    expect(() => BingWallpaper.parse({'images': [{'urlbase': '/th?id=Example', 'fullstartdate': '202613500000'}]}), throwsFormatException);
    expect(validOnlineWallpaperConfiguration('{"enabled":true,"source":"unknown","url":"","intervalHours":24}'), isFalse);
  });
}
