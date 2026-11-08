import 'package:flauncher/models/weather_data.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/widgets/weather_status_bar_widget.dart';
import 'package:flauncher/widgets/weather_glyph.dart';
import 'package:flauncher/tile_appearance.dart';
import 'package:flauncher/weather_text_format.dart';
import 'package:flauncher/weather_format_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flauncher/custom_traversal_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../mocks.mocks.dart';

void main() {
  late MockSettingsService mockSettingsService;
  late MockWeatherService mockWeatherService;

  final testWeatherWithWarning = WeatherData.fromJsonString('''
  {
    "currentTemp": 27,
    "currentConditionCode": 800,
    "currentCondition": "Clear",
    "forecasts": [
      {
        "conditionCode": 500,
        "precipProbability": 80,
        "minTemp": 20,
        "maxTemp": 30
      }
    ]
  }
  ''');

  setUp(() {
    mockSettingsService = MockSettingsService();
    mockWeatherService = MockWeatherService();

    when(mockSettingsService.showWeatherInStatusBar).thenReturn(true);
    when(mockSettingsService.useFahrenheit).thenReturn(false);
    when(mockSettingsService.weatherTextFormat).thenReturn(WeatherTextFormat.standard);
    when(mockWeatherService.hasWeather).thenReturn(true);
    when(mockWeatherService.stale).thenReturn(false);
    when(mockWeatherService.weatherData).thenReturn(testWeatherWithWarning);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsService>.value(value: mockSettingsService),
            ChangeNotifierProvider<WeatherService>.value(value: mockWeatherService),
          ],
          child: const WeatherStatusBarWidget(),
        ),
      ),
    );
  }

  testWidgets('renders harmonized styling when weather warnings is disabled', (tester) async {
    when(mockSettingsService.showWeatherWarnings).thenReturn(false);

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('27°C'), findsOneWidget);

    final textWidget = tester.widget<Text>(find.text('27°C'));
    expect(textWidget.style?.color, Colors.white);
    expect(textWidget.style?.fontWeight, FontWeight.w400);

    final iconWidget = tester.widget<WeatherGlyph>(find.byType(WeatherGlyph));
    expect(iconWidget.condition, WeatherCondition.sun);
    expect(iconWidget.pack, WeatherIconPack.outline);
    expect(iconWidget.color, Colors.white);

    final container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    final boxDecoration = container.decoration as BoxDecoration;
    final border = boxDecoration.border as Border;
    expect(border.top.color, Colors.transparent);
    expect(border.top.width, 2.0);
  });

  testWidgets('template warnings are inline, unique and suppressed for stale data', (tester) async {
    when(mockSettingsService.showWeatherWarnings).thenReturn(true);
    when(mockSettingsService.weatherTextFormat).thenReturn(parseWeatherTemplate('{TEMP} ({WARN})').format!);
    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.text('27°C (80% Rain today)'), findsOneWidget);
    expect(find.byType(WeatherGlyph), findsNothing);
    when(mockWeatherService.stale).thenReturn(true);
    await tester.pumpWidget(KeyedSubtree(key: const ValueKey('stale'), child: createWidgetUnderTest()));
    expect(find.text('27°C'), findsOneWidget);
    expect(find.textContaining('Rain'), findsNothing);
  });

  testWidgets('renders two custom weather lines inside one panel button', (tester) async {
    when(mockSettingsService.showWeatherWarnings).thenReturn(false);
    when(mockSettingsService.weatherTextFormat).thenReturn(
      WeatherTextFormat.fromBlocks(const [
        WeatherTextBlock(WeatherTextField.temperature),
        WeatherTextBlock(WeatherTextField.lineBreak),
        WeatherTextBlock(WeatherTextField.feelsLike, before: '(', after: ')'),
      ])!,
    );
    when(mockWeatherService.weatherData).thenReturn(
      const WeatherData(currentTemp: 6, feelsLikeTemp: 0),
    );
    await tester.pumpWidget(createWidgetUnderTest());
    final first = tester.getRect(find.text('6°C'));
    final second = tester.getRect(find.text('(0°C)'));
    final button = tester.getRect(find.byType(AnimatedContainer));
    expect(first.bottom, lessThanOrEqualTo(second.top));
    expect(button.contains(first.center), isTrue);
    expect(button.contains(second.center), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders harmonized styling and current icon when weather warnings is enabled', (tester) async {
    when(mockSettingsService.showWeatherWarnings).thenReturn(true);

    await tester.pumpWidget(createWidgetUnderTest());

    // Warning text is included in displayText without altering colors/outline/icon
    expect(find.text('27°C • 80% Rain today'), findsOneWidget);

    final textWidget = tester.widget<Text>(find.text('27°C • 80% Rain today'));
    expect(textWidget.style?.color, Colors.white);
    expect(textWidget.style?.fontWeight, FontWeight.w400);

    // Current condition icon remains sunny, not overridden by warning
    final iconWidget = tester.widget<WeatherGlyph>(find.byType(WeatherGlyph));
    expect(iconWidget.condition, WeatherCondition.sun);
    expect(iconWidget.pack, WeatherIconPack.outline);
    expect(iconWidget.color, Colors.white);

    // Border remains subtle white with width 1.0, not amber
    final container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    final boxDecoration = container.decoration as BoxDecoration;
    final border = boxDecoration.border as Border;
    expect(border.top.color, Colors.transparent);
    expect(border.top.width, 2.0);
  });
  testWidgets(
    'weather without a supplied action skips focus and never opens an external app',
    (tester) async {
      when(mockSettingsService.showWeatherWarnings).thenReturn(false);
      when(mockWeatherService.openBreezyWeather()).thenAnswer((_) async => true);
      final before = FocusNode();
      final after = FocusNode();
      addTearDown(before.dispose);
      addTearDown(after.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiProvider(
              providers: [
                ChangeNotifierProvider<SettingsService>.value(
                  value: mockSettingsService,
                ),
                ChangeNotifierProvider<WeatherService>.value(
                  value: mockWeatherService,
                ),
              ],
              child: FocusTraversalGroup(
                policy: RowByRowTraversalPolicy(),
                child: Row(
                  children: [
                    TextButton(
                      focusNode: before,
                      autofocus: true,
                      onPressed: () {},
                      child: const Text('Before'),
                    ),
                    const WeatherStatusBarWidget(),
                    TextButton(
                      focusNode: after,
                      onPressed: () {},
                      child: const Text('After'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(after.hasFocus, true);
      expect(find.descendant(of: find.byType(WeatherStatusBarWidget), matching: find.byType(Focus)), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(before.hasFocus, true);
      await tester.tap(find.text('27°C'));
      await tester.pumpAndSettle();
      verifyNever(mockWeatherService.openBreezyWeather());
      expect(before.hasFocus, true);
    },
  );
}
