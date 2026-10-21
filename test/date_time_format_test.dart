import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/date_time_format.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting());
  test('compact date matches requested Russian spelling', () {
    expect(formatLauncherDate(compactDateFormat, DateTime(2026, 10, 2), 'ru_RU'), 'ПТН 2 Окт');
    expect(formatLauncherDate(compactDateFormat, DateTime(2026, 10, 4), 'ru'), 'ВСК 4 Окт');
    expect(formatLauncherDate(compactDateFormat, DateTime(2026, 12, 31), 'ru'), 'ЧТВ 31 Дек');
    expect(formatLauncherDate(compactDateFormat, DateTime(2026, 10, 2), 'en'), 'Fri 2 Oct');
  });
}
