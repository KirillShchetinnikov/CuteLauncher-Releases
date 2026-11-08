import 'package:flauncher/l10n/app_localizations_ru.dart';
import 'package:flauncher/models/weather_data.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flauncher/weather_text_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final l = AppLocalizationsRu();
  final format = WeatherTextFormat.fromBlocks(const [
    WeatherTextBlock(WeatherTextField.temperature),
    WeatherTextBlock(WeatherTextField.lineBreak),
    WeatherTextBlock(WeatherTextField.feelsLike, before: '(ощ. ', after: ')'),
  ])!;

  test('keeps the second line only when its weather value is available', () {
    expect(
      format.format(
        const WeatherData(currentTemp: 6, feelsLikeTemp: 0),
        l,
        fahrenheit: false,
      ),
      '6°C\n(ощ. 0°C)',
    );
    expect(
      format.format(
        const WeatherData(currentTemp: 6, feelsLikeTemp: 0),
        l,
        fahrenheit: true,
      ),
      '43°F\n(ощ. 32°F)',
    );
    expect(
      format.format(const WeatherData(currentTemp: 6), l, fahrenheit: false),
      '6°C',
    );
    expect(format.format(null, l, fahrenheit: false), '—');
  });

  test('formats blocks and literal text in the chosen order', () {
    final custom = WeatherTextFormat.fromBlocks(const [
      WeatherTextBlock(WeatherTextField.city),
      WeatherTextBlock(WeatherTextField.text, before: ' • '),
      WeatherTextBlock(WeatherTextField.conditions),
      WeatherTextBlock(WeatherTextField.wind, before: ' (', after: ')'),
      WeatherTextBlock(WeatherTextField.humidity, before: ', '),
      WeatherTextBlock(WeatherTextField.low, before: ' / '),
      WeatherTextBlock(WeatherTextField.high, before: '…'),
    ])!;
    const weather = WeatherData(
      location: 'Москва',
      currentConditionCode: 803,
      windSpeed: 4.5,
      currentHumidity: 82,
      todayMinTemp: 3,
      todayMaxTemp: 8,
    );
    expect(
      custom.format(weather, l, fahrenheit: false),
      'Москва • Облачно (4,5 м/с), 82% / 3°C…8°C',
    );
  });

  test('missing values remove affixes while zero remains a value', () {
    final custom = WeatherTextFormat.fromBlocks(const [
      WeatherTextBlock(WeatherTextField.temperature),
      WeatherTextBlock(WeatherTextField.feelsLike, before: ' (', after: ')'),
      WeatherTextBlock(WeatherTextField.wind, before: ' / '),
      WeatherTextBlock(WeatherTextField.humidity, before: ' / '),
      WeatherTextBlock(WeatherTextField.low, before: ' [', after: ']'),
    ])!;
    expect(
      custom.format(const WeatherData(currentTemp: -5), l, fahrenheit: false),
      '-5°C',
    );
    expect(
      custom.format(
        const WeatherData(
          currentTemp: 0,
          feelsLikeTemp: 0,
          windSpeed: 0,
          currentHumidity: 0,
          todayMinTemp: 0,
        ),
        l,
        fahrenheit: false,
      ),
      '0°C (0°C) / 0 м/с / 0% [0°C]',
    );
    expect(
      custom.format(
        const WeatherData(windSpeed: double.infinity),
        l,
        fahrenheit: false,
      ),
      '—',
    );
  });

  test('provider text cannot introduce extra lines; empty lines collapse', () {
    final custom = WeatherTextFormat.fromBlocks(const [
      WeatherTextBlock(WeatherTextField.city),
      WeatherTextBlock(WeatherTextField.lineBreak),
      WeatherTextBlock(WeatherTextField.conditions),
    ])!;
    expect(
      custom.format(
        const WeatherData(
          location: 'Москва\r\nцентр\u2028район',
          currentCondition: 'Облачно\u0085Дождь',
        ),
        l,
        fahrenheit: false,
      ),
      'Москва центр район\nОблачно Дождь',
    );
    expect(
      custom.format(
        const WeatherData(currentCondition: 'Облачно'),
        l,
        fahrenheit: false,
      ),
      'Облачно',
    );
    expect(custom.format(const WeatherData(), l, fahrenheit: false), '—');
  });

  test(
    'literal separators are unconditional; value affixes are conditional',
    () {
      final literal = WeatherTextFormat.fromBlocks(const [
        WeatherTextBlock(WeatherTextField.temperature),
        WeatherTextBlock(WeatherTextField.text, before: ' · '),
        WeatherTextBlock(WeatherTextField.feelsLike),
      ])!;
      final conditional = WeatherTextFormat.fromBlocks(const [
        WeatherTextBlock(WeatherTextField.temperature),
        WeatherTextBlock(WeatherTextField.feelsLike, before: ' · '),
      ])!;
      const weather = WeatherData(currentTemp: 6);
      expect(literal.format(weather, l, fahrenheit: false), '6°C ·');
      expect(conditional.format(weather, l, fahrenheit: false), '6°C');
    },
  );

  test('block limits, unicode text and immutable round trip', () {
    final blocks = List.generate(
      maxWeatherTextBlocks,
      (_) => const WeatherTextBlock(WeatherTextField.temperature),
    );
    final accepted = WeatherTextFormat.fromBlocks(blocks)!;
    blocks.add(const WeatherTextBlock(WeatherTextField.city));
    expect(WeatherTextFormat.fromBlocks(blocks), isNull);
    expect(accepted.blocks.length, maxWeatherTextBlocks);
    expect(() => accepted.blocks.clear(), throwsUnsupportedError);
    expect(
      WeatherTextFormat.tryDecode(accepted.encode())!.encode(),
      accepted.encode(),
    );
    expect(
      WeatherTextFormat.fromBlocks([
        WeatherTextBlock(WeatherTextField.city, before: 'я' * 60),
      ]),
      isNotNull,
    );
    expect(
      WeatherTextFormat.fromBlocks([
        WeatherTextBlock(WeatherTextField.city, before: 'я' * 61),
      ]),
      isNull,
    );
    for (final newline in ['\r', '\n', '\u0085', '\u2028', '\u2029']) {
      expect(
        WeatherTextFormat.fromBlocks([
          WeatherTextBlock(WeatherTextField.city, before: newline),
        ]),
        isNull,
      );
    }
    for (final raw in <Object?>[
      null,
      7,
      '{}',
      'null',
      '[[]]',
      '[["temperature","",7]]',
      '[["lineBreak","x",""],["temperature","",""]]',
      '[["text","x","y"],["temperature","",""]]',
    ]) {
      expect(WeatherTextFormat.tryDecode(raw), isNull, reason: '$raw');
    }
  });

  test(
    'reloads and imports the format with validation and a legacy default',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      addTearDown(settings.dispose);
      expect(settings.weatherTextFormat, WeatherTextFormat.standard);
      await settings.setWeatherTextFormat(format);
      final copy = settings.exportSettingsMap()[weatherTextFormatKey];
      expect(copy, format.encode());
      settings.reload();
      expect(settings.weatherTextFormat.encode(), copy);
      for (final invalid in [
        '[]',
        '[["newField","",""]]',
        '[["text","only text",""]]',
        '[["temperature","",""],["lineBreak","",""],["lineBreak","",""]]',
        r'[["temperature","first\nsecond",""]]',
      ]) {
        expect(
          compatibleSettings({weatherTextFormatKey: invalid}, {}),
          isEmpty,
        );
      }
      await settings.setWeatherTextFormat(WeatherTextFormat.standard);
      await settings.importSettingsMap({weatherTextFormatKey: copy});
      expect(settings.weatherTextFormat.encode(), copy);
    },
  );
}
