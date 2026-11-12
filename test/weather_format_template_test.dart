import 'package:flauncher/l10n/app_localizations_ru.dart';
import 'package:flauncher/models/weather_data.dart';
import 'package:flauncher/information_formats.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flauncher/weather_format_template.dart';
import 'package:flauncher/weather_text_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ru'));
  final l = AppLocalizationsRu();
  const weather = WeatherData(
    currentTemp: 30,
    todayMaxTemp: 31,
    todayMinTemp: 25,
    location: 'Калуга',
    currentConditionCode: 803,
  );

  test('keyboard punctuation survives parsing, storage and rendering', () {
    const symbols = '() [] / : ; + − ° % · ! ? = _ & @ # \$ " \' \\ 🌤';
    final parsed = parseWeatherTemplate('{TEMP} $symbols {{x}}');
    expect(parsed.issues, isEmpty);
    final saved = WeatherTextFormat.tryDecode(parsed.format!.encode())!;
    expect(saved.format(weather, l, fahrenheit: false), '30°C $symbols {x}');
    expect(parseWeatherTemplate(weatherFormatTemplate(saved, russian: true)).format!.encode(), saved.encode());
  });

  test(
    'renders free text, temperatures, one break and an inline condition icon',
    () {
      final parsed = parseWeatherTemplate(
        'Моя погода: {ТЕМП} / {МАКС} / {МИН} ({ПРЕД}){ПЕР}{ГОРОД} {УСЛ}',
      );
      expect(parsed.issues, isEmpty);
      expect(parsed.format!.explicitLayout, isTrue);
      expect(
        parsed.format!.format(weather, l, fahrenheit: false),
        'Моя погода: 30°C / 31°C / 25°C\nКалуга Облачно $weatherInlineIcon',
      );
      final decoded = WeatherTextFormat.tryDecode(parsed.format!.encode())!;
      expect(decoded.explicitLayout, isTrue);
      expect(decoded.encode(), parsed.format!.encode());
      expect(
        weatherFormatTemplate(decoded, russian: true),
        'Моя погода: {ТЕМП} / {МАКС} / {МИН} ({ПРЕД}){ПЕР}{ГОРОД} {УСЛ}',
      );
    },
  );

  test('accepts Russian and English tokens in any case without changing storage IDs', () {
    expect(
      parseWeatherTemplate('{темп}{ПЕР}{city} {cond}').format!.encode(),
      parseWeatherTemplate('{TEMP}{BR}{ГОРОД} {УСЛ}').format!.encode(),
    );
    for (final field in weatherTemplateNames.keys) {
      final parsed = parseWeatherTemplate(
        '{TEMP} ${weatherTemplateToken(field, russian: true)}',
      );
      expect(parsed.issues, isEmpty, reason: field.name);
    }
  });

  test(
    'reports exact UTF-16 ranges for unknown tokens and unmatched braces',
    () {
      final unknown = parseWeatherTemplate('🌧 {ТЕМПП} {TEMP}');
      expect(unknown.format, isNull);
      expect(unknown.issues.single.error, WeatherTemplateError.unknown);
      expect((unknown.issues.single.start, unknown.issues.single.end), (3, 10));
      for (final source in ['{TEMP', '{TEMP} }', '{{TEMP}', '{TEMP {MIN}']) {
        expect(
          parseWeatherTemplate(source).issues
              .any((e) => e.error == WeatherTemplateError.braces),
          isTrue,
          reason: source,
        );
      }
    },
  );

  test('literal braces and surrounding text survive template round trips', () {
    final source = 'Мой {{TEMP}}: {TEMP}';
    final parsed = parseWeatherTemplate(source);
    expect(
      parsed.format!.format(weather, l, fahrenheit: false),
      'Мой {TEMP}: 30°C',
    );
    final russian = weatherFormatTemplate(parsed.format!, russian: true);
    expect(
      parseWeatherTemplate(russian).format!.encode(),
      parsed.format!.encode(),
    );
  });

  test(
    'counts token and pasted Unicode line breaks together, including CRLF',
    () {
      for (final line in [
        '\n',
        '\r\n',
        '\u0085',
        '\u2028',
        '\u2029',
        '{BR}',
        '{ПЕР}',
      ]) {
        expect(parseWeatherTemplate('{TEMP}${line}text').issues, isEmpty);
        final parsed = parseWeatherTemplate('{TEMP}${line}x{BR}y');
        expect(parsed.format, isNull);
        expect(parsed.issues.single.error, WeatherTemplateError.lineBreaks);
      }
    },
  );

  test('rejects missing values and bounds template size and block count', () {
    expect(
      parseWeatherTemplate('Только мой текст').issues.single.error,
      WeatherTemplateError.missingValue,
    );
    expect(
      parseWeatherTemplate('{TEMP}${'я' * maxWeatherTemplateLength}')
          .issues
          .single
          .error,
      WeatherTemplateError.length,
    );
    expect(
      parseWeatherTemplate('{TEMP}' * (maxWeatherTextBlocks + 1)).format,
      isNull,
    );
    expect(parseWeatherTemplate('🙂' * 70 + '{TEMP}').issues, isEmpty);
  });

  test(
    'conditional warning parentheses disappear for stale or absent warnings',
    () {
      final format = parseWeatherTemplate('{TEMP} ({WARN})').format!;
      final wet = WeatherData.fromJsonString(
        '{"currentTemp":30,"forecasts":[{"conditionCode":500,"precipProbability":80}]}',
      );
      final now = DateTime(2026, 11, 8);
      final warning = format.format(wet, l, fahrenheit: false, now: now);
      expect(warning, contains('(80%'));
      expect(warning, endsWith(')'));
      expect(
        format.format(
          wet,
          l,
          fahrenheit: false,
          warningsAvailable: false,
          now: now,
        ),
        '30°C',
      );
      expect(format.format(weather, l, fahrenheit: false), '30°C');
    },
  );

  test(
    'legacy blocks open with their automatic icon and warning made explicit',
    () {
      expect(
        weatherFormatTemplate(
          WeatherTextFormat.standard,
          russian: true,
          warnings: true,
        ),
        '{ЗНАЧ} {ТЕМП} ({ПРЕД})',
      );
      final format = parseWeatherTemplate('{TEMP}').format!;
      expect(
        weatherFormatTemplate(format, russian: false, warnings: true),
        '{TEMP}',
      );
      expect(
        WeatherTextFormat.tryDecode(WeatherTextFormat.standard.encode()),
        same(WeatherTextFormat.standard),
      );
      expect(WeatherTextFormat.tryDecode('{"version":3,"blocks":[]}'), isNull);
    },
  );

  test('shared weather format validates for backup import and retains units', () {
    final format = parseWeatherTemplate('{TEMP} ({WARN}){BR}{CITY} {COND}')
        .format!;
    final options = WeatherDisplayOptions(
      format: format,
      fahrenheit: true,
      warnings: false,
    );
    final key = sharedInformationWeatherKey;
    expect(
      compatibleSettings({key: options.encode()}, {})[key],
      options.encode(),
    );
    final restored = WeatherDisplayOptions.decode(options.encode())!;
    expect(restored.format.explicitLayout, isTrue);
    expect(restored.fahrenheit, isTrue);
    expect(restored.warnings, isFalse);
    expect(restored.format.encode(), format.encode());
  });
}
