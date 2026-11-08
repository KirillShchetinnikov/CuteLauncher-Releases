import 'weather_text_format.dart';

const maxWeatherTemplateLength = 2048;

/// Names are editor syntax only. Stored formats use language-neutral field IDs.
const weatherTemplateNames = <WeatherTextField, (String, String)>{
  WeatherTextField.temperature: ('ТЕМП', 'TEMP'),
  WeatherTextField.feelsLike: ('ОЩУЩ', 'FEELS'),
  WeatherTextField.high: ('МАКС', 'MAX'),
  WeatherTextField.low: ('МИН', 'MIN'),
  WeatherTextField.warning: ('ПРЕД', 'WARN'),
  WeatherTextField.lineBreak: ('ПЕР', 'BR'),
  WeatherTextField.city: ('ГОРОД', 'CITY'),
  WeatherTextField.conditionsIcon: ('УСЛ', 'COND'),
  WeatherTextField.conditions: ('ОПИС', 'DESC'),
  WeatherTextField.icon: ('ЗНАЧ', 'ICON'),
  WeatherTextField.wind: ('ВЕТЕР', 'WIND'),
  WeatherTextField.humidity: ('ВЛАЖ', 'HUM'),
};

String weatherTemplateToken(WeatherTextField field, {required bool russian}) {
  final names = weatherTemplateNames[field]!;
  return '{${russian ? names.$1 : names.$2}}';
}

String weatherFormatTemplate(
  WeatherTextFormat format, {
  required bool russian,
  bool warnings = false,
}) {
  String escape(String text) =>
      text.replaceAll('{', '{{').replaceAll('}', '}}');
  return [
    if (!format.explicitLayout)
      '${weatherTemplateToken(WeatherTextField.icon, russian: russian)} ',
    for (final block in format.blocks)
      if (block.field == WeatherTextField.text)
        escape(block.before)
      else
        '${escape(block.before)}${weatherTemplateToken(block.field, russian: russian)}${escape(block.after)}',
    if (!format.explicitLayout && warnings)
      ' (${weatherTemplateToken(WeatherTextField.warning, russian: russian)})',
  ].join();
}

enum WeatherTemplateError { braces, unknown, lineBreaks, missingValue, length }

class WeatherTemplateIssue {
  const WeatherTemplateIssue(this.error, this.start, this.end);
  final WeatherTemplateError error;
  final int start, end;
}

class WeatherTemplateResult {
  const WeatherTemplateResult(this.format, this.issues);
  final WeatherTextFormat? format;
  final List<WeatherTemplateIssue> issues;
}

/// Literal braces are doubled. Parentheses containing exactly one value are
/// conditional affixes, so `({WARN})` never leaves empty parentheses behind.
WeatherTemplateResult parseWeatherTemplate(String source) {
  final issues = <WeatherTemplateIssue>[];
  final blocks = <WeatherTextBlock>[];
  if (source.length > maxWeatherTemplateLength) {
    return WeatherTemplateResult(null, [
      WeatherTemplateIssue(
        WeatherTemplateError.length,
        maxWeatherTemplateLength,
        source.length,
      ),
    ]);
  }
  var literal = StringBuffer();
  var breaks = 0;
  void flush() {
    final text = literal.toString();
    // Split long free text into storage-sized pieces without splitting Unicode.
    var chunk = StringBuffer();
    var size = 0;
    for (final rune in text.runes) {
      chunk.writeCharCode(rune);
      if (++size == maxWeatherBlockText) {
        blocks.add(
          WeatherTextBlock(WeatherTextField.text, before: chunk.toString()),
        );
        chunk = StringBuffer();
        size = 0;
      }
    }
    if (chunk.isNotEmpty) {
      blocks.add(
        WeatherTextBlock(WeatherTextField.text, before: chunk.toString()),
      );
    }
    literal = StringBuffer();
  }

  for (var i = 0; i < source.length;) {
    final start = i;
    final c = source[i];
    if ((c == '{' || c == '}') && i + 1 < source.length && source[i + 1] == c) {
      literal.write(c);
      i += 2;
      continue;
    }
    WeatherTextField? field;
    if (weatherTextLineBreak.hasMatch(c)) {
      field = WeatherTextField.lineBreak;
      i += c == '\r' && i + 1 < source.length && source[i + 1] == '\n' ? 2 : 1;
    } else if (c == '{') {
      final end = source.indexOf('}', i + 1);
      if (end < 0 || source.substring(i + 1, end).contains('{')) {
        issues.add(
          WeatherTemplateIssue(
            WeatherTemplateError.braces,
            i,
            end < 0 ? source.length : end + 1,
          ),
        );
        i = end < 0 ? source.length : end + 1;
        continue;
      }
      final name = source.substring(i + 1, end).toUpperCase();
      for (final entry in weatherTemplateNames.entries) {
        if (name == entry.value.$1 || name == entry.value.$2) field = entry.key;
      }
      i = end + 1;
      if (field == null) {
        issues.add(
          WeatherTemplateIssue(WeatherTemplateError.unknown, start, i),
        );
        continue;
      }
    } else if (c == '}') {
      issues.add(WeatherTemplateIssue(WeatherTemplateError.braces, i, ++i));
      continue;
    } else {
      literal.write(c);
      i++;
      continue;
    }
    flush();
    if (field == WeatherTextField.lineBreak && ++breaks > 1) {
      issues.add(
        WeatherTemplateIssue(WeatherTemplateError.lineBreaks, start, i),
      );
    }
    blocks.add(WeatherTextBlock(field));
  }
  flush();

  // Turn balanced parentheses around one value into conditional affixes.
  for (var i = 1; i + 1 < blocks.length; i++) {
    final before = blocks[i - 1];
    final value = blocks[i];
    final after = blocks[i + 1];
    if (!value.field.isValue ||
        before.field != WeatherTextField.text ||
        after.field != WeatherTextField.text) {
      continue;
    }
    final open = before.before.lastIndexOf('(');
    final close = after.before.indexOf(')');
    if (open < 0 ||
        close < 0 ||
        before.before.substring(open + 1).contains(')') ||
        after.before.substring(0, close).contains('(')) {
      continue;
    }
    blocks[i - 1] = WeatherTextBlock(
      WeatherTextField.text,
      before: before.before.substring(0, open),
    );
    blocks[i] = WeatherTextBlock(
      value.field,
      before: before.before.substring(open),
      after: after.before.substring(0, close + 1),
    );
    blocks[i + 1] = WeatherTextBlock(
      WeatherTextField.text,
      before: after.before.substring(close + 1),
    );
  }
  blocks.removeWhere(
    (b) => b.field == WeatherTextField.text && b.before.isEmpty,
  );
  if (!blocks.any((b) => b.field.isValue)) {
    issues.add(
      WeatherTemplateIssue(WeatherTemplateError.missingValue, 0, source.length),
    );
  }
  if (blocks.length > maxWeatherTextBlocks) {
    issues.add(
      WeatherTemplateIssue(WeatherTemplateError.length, 0, source.length),
    );
  }
  final format = issues.isEmpty
      ? WeatherTextFormat.fromBlocks(blocks, explicitLayout: true)
      : null;
  if (format == null && issues.isEmpty) {
    issues.add(
      WeatherTemplateIssue(WeatherTemplateError.length, 0, source.length),
    );
  }
  return WeatherTemplateResult(format, List.unmodifiable(issues));
}
