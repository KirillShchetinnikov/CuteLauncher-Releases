import 'package:intl/intl.dart';

const compactDateFormat = 'cute_compact_date';

String formatLauncherDate(String pattern, DateTime date, String locale) {
  if (pattern != compactDateFormat) return DateFormat(pattern, locale).format(date);
  if (locale.split(RegExp('[_-]')).first != 'ru') {
    return DateFormat('E d MMM', locale).format(date);
  }
  const weekdays = ['ПНД', 'ВТР', 'СРД', 'ЧТВ', 'ПТН', 'СБТ', 'ВСК'];
  const months = ['Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'];
  return '${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
}
