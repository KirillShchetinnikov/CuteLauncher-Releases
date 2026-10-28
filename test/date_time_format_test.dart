import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/date_time_format.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting());
  test('reused formatter follows midnight and backwards clock corrections', () {
    final time = LauncherDateFormatter('HH:mm:ss', 'en');
    expect(time.format(DateTime(2026, 10, 27, 23, 59, 59)), '23:59:59');
    expect(time.format(DateTime(2026, 10, 28)), '00:00:00');
    expect(time.format(DateTime(2026, 10, 27, 22, 5, 4)), '22:05:04');
    final date = LauncherDateFormatter(compactDateFormat, 'ru_RU');
    expect(date.format(DateTime(2026, 10, 27)), 'ВТР 27 Окт');
    expect(date.format(DateTime(2026, 10, 28)), 'СРД 28 Окт');
  });
  test('compact date matches requested Russian spelling', () {
    expect(formatLauncherDate(compactDateFormat, DateTime(2026, 10, 2), 'ru_RU'), 'ПТН 2 Окт');
    expect(formatLauncherDate(compactDateFormat, DateTime(2026, 10, 4), 'ru'), 'ВСК 4 Окт');
    expect(formatLauncherDate(compactDateFormat, DateTime(2026, 12, 31), 'ru'), 'ЧТВ 31 Дек');
    expect(formatLauncherDate(compactDateFormat, DateTime(2026, 10, 2), 'en'), 'Fri 2 Oct');
  });
}
