/// Date fields supported by both intl and the native screensaver formatter.
/// Letters inside quotes are literal text; time fields are intentionally absent.
const customDateFields = 'yMLdEDG';
const maximumDatePatternLength = 128;

class DatePatternValidation {
  final List<(int, int)> errors;
  final bool hasDate;
  const DatePatternValidation(this.errors, this.hasDate);
  bool get valid => hasDate && errors.isEmpty;
}

DatePatternValidation validateCustomDatePattern(String pattern) {
  final errors = <(int, int)>[];
  var hasDate = false;
  int? quote;
  for (var i = 0; i < pattern.length; i++) {
    final char = pattern[i];
    if (char == "'") {
      if (i + 1 < pattern.length && pattern[i + 1] == "'") {
        i++;
      } else {
        quote = quote == null ? i : null;
      }
    } else if (char.codeUnitAt(0) < 32 || char.codeUnitAt(0) == 127) {
      errors.add((i, i + 1));
    } else if (quote == null) {
      if (char == 'L' && i >= 4 && pattern.substring(i - 4, i) == 'LLLL') {
        errors.add((i, i + 1));
      } else if (customDateFields.contains(char)) {
        hasDate = true;
      } else if (RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(char)) {
        errors.add((i, i + 1));
      }
    }
  }
  if (quote != null) errors.add((quote, pattern.length));
  if (pattern.length > maximumDatePatternLength) {
    errors.add((maximumDatePatternLength, pattern.length));
  }
  return DatePatternValidation(errors, hasDate);
}
