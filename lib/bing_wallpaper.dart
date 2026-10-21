import 'weather_sources.dart';

/// Port of StartGrid src/js/api/bingImageDay.js, using its bounded 1080p path.
class BingWallpaper {
  final Uri uri;
  final String copyright;
  final DateTime expiresAt;
  const BingWallpaper(this.uri, this.copyright, this.expiresAt);
  factory BingWallpaper.parse(Map<String, dynamic> data) {
    final image = (data['images'] as List).first as Map;
    final base = image['urlbase'] as String;
    final date = image['fullstartdate'] as String;
    if (!base.startsWith('/') || !RegExp(r'^\d{12}$').hasMatch(date)) throw const FormatException('Invalid Bing image');
    final uri = Uri.parse('https://www.bing.com').resolve('${base}_1920x1080.jpg');
    if (uri.scheme != 'https' || uri.host != 'www.bing.com') throw const FormatException('Invalid Bing host');
    final start = DateTime.utc(int.parse(date.substring(0, 4)), int.parse(date.substring(4, 6)), int.parse(date.substring(6, 8)), int.parse(date.substring(8, 10)), int.parse(date.substring(10, 12)));
    if (start.month != int.parse(date.substring(4, 6)) || start.day != int.parse(date.substring(6, 8))) throw const FormatException('Invalid Bing date');
    final credit = image['copyright'] as String? ?? '';
    return BingWallpaper(uri, credit.substring(0, credit.length.clamp(0, 500)), start.add(const Duration(days: 1, minutes: 10)));
  }
}
Future<BingWallpaper> fetchBingWallpaper() async => BingWallpaper.parse(await HttpWeatherTransport().request(
  Uri.https('www.bing.com', '/HPImageArchive.aspx', {'format': 'js', 'idx': '0', 'n': '1', 'mkt': 'en-US'})));
