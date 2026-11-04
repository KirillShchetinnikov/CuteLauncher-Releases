import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/custom_date_format.dart';
import 'package:flauncher/settings_import.dart';

void main() {
  test(
    'date fields, separators, quoted text and escaped quotes are accepted',
    () {
      for (final pattern in [
        'EEEE, d. MMMM yyyy',
        'dd/MM/yy',
        'yyyy-MM-dd',
        'EEE d MMM',
        "'Дата:' d MMMM yyyy",
        "d 'o''clock' MMMM",
        "''yyyy",
        "'🌙' d MMMM",
        'G y D LLLL',
      ]) {
        expect(
          validateCustomDatePattern(pattern).valid,
          isTrue,
          reason: pattern,
        );
      }
    },
  );
  test('errors retain exact offsets for highlighting', () {
    expect(validateCustomDatePattern('dd.mm.yyyy').errors, [(3, 4), (4, 5)]);
    expect(validateCustomDatePattern("d 'month").errors, [(2, 8)]);
    for (final pattern in [
      '',
      '  ',
      "'only text'",
      'HH:mm:ss',
      'yyyy z',
      'Дата d',
      'dd\nMM',
      'LLLLL',
    ]) {
      expect(
        validateCustomDatePattern(pattern).valid,
        isFalse,
        reason: pattern,
      );
    }
    expect(validateCustomDatePattern('y' * 129).valid, isFalse);
  });
  test('backup imports custom dates but excludes invalid date patterns', () {
    expect(
      compatibleSettings(
        {'date_format': 'EEEE, d. MMMM yyyy'},
        {'date_format': ''},
      ),
      {'date_format': 'EEEE, d. MMMM yyyy'},
    );
    expect(
      compatibleSettings({'date_format': "yyyy '"}, {'date_format': ''}),
      isEmpty,
    );
    expect(
      compatibleSettings(
        {'date_format': 'cute_compact_date'},
        {'date_format': ''},
      ),
      {'date_format': 'cute_compact_date'},
    );
  });
}
