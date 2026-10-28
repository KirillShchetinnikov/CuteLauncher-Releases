import 'package:intl/intl.dart';

const compactDateFormat = 'cute_compact_date';

/// Reuse the parsed pattern for a live clock; create a new instance on locale or
/// pattern changes. It holds no timestamp, so clock corrections remain visible.
class LauncherDateFormatter {
  final DateFormat? _formatter;
  LauncherDateFormatter(String pattern, String locale)
      : _formatter = pattern == compactDateFormat && locale.split(RegExp('[_-]')).first == 'ru'
          ? null
          : DateFormat(pattern == compactDateFormat ? 'E d MMM' : pattern, locale);

  String format(DateTime date) {
    if (_formatter != null) return _formatter.format(date);
    const weekdays = ['ПНД', 'ВТР', 'СРД', 'ЧТВ', 'ПТН', 'СБТ', 'ВСК'];
    const months = ['Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'];
    return '${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
  }
}

String formatLauncherDate(String pattern, DateTime date, String locale) =>
    LauncherDateFormatter(pattern, locale).format(date);
