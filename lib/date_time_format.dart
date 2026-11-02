import 'package:intl/intl.dart';

const compactDateFormat = 'cute_compact_date';
const shortWeekdayDateFormat = 'cute_short_weekday_date';

/// Reuse the parsed pattern for a live clock; create a new instance on locale or
/// pattern changes. It holds no timestamp, so clock corrections remain visible.
class LauncherDateFormatter {
  final DateFormat? _formatter;
  final bool _shortWeekday;
  LauncherDateFormatter(String pattern, String locale)
      : _shortWeekday = pattern == shortWeekdayDateFormat,
        _formatter = (pattern == compactDateFormat || pattern == shortWeekdayDateFormat) &&
              locale.split(RegExp('[_-]')).first == 'ru'
          ? null
          : DateFormat(switch (pattern) {
              compactDateFormat => 'E d MMM',
              shortWeekdayDateFormat => 'E, d MMM',
              _ => pattern,
            }, locale);

  String format(DateTime date) {
    if (_formatter != null) return _formatter.format(date);
    const weekdays = ['ПНД', 'ВТР', 'СРД', 'ЧТВ', 'ПТН', 'СБТ', 'ВСК'];
    const shortWeekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    const months = ['Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'];
    if (_shortWeekday) {
      final month = date.month == 11 ? 'Нояб' : months[date.month - 1];
      return '${shortWeekdays[date.weekday - 1]}, ${date.day} $month';
    }
    return '${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
  }
}

String formatLauncherDate(String pattern, DateTime date, String locale) =>
    LauncherDateFormatter(pattern, locale).format(date);
