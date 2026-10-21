import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/widgets/settings/weather_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/weather_sources.dart';

import '../../mocks.mocks.dart';

class _Paths extends PathProviderPlatform {
  final String path;
  _Paths(this.path);
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

class _Transport implements WeatherTransport {
  final requests = <Uri>[];
  @override
  Future<Map<String, dynamic>> request(Uri uri, {String? key}) async {
    requests.add(uri);
    return {};
  }
}

void main() {
  late WeatherService service;
  late SettingsService settings;
  late StreamController<dynamic> events;
  late Directory directory;
  late PathProviderPlatform originalPaths;
  late _Transport transport;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('weather-ui-');
    originalPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _Paths(directory.path);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final channel = MockFLauncherChannel();
    events = StreamController<dynamic>.broadcast();
    when(channel.isBreezyWeatherInstalled()).thenAnswer((_) async => false);
    when(channel.getLatestWeatherData()).thenAnswer((_) async => null);
    when(
      channel.addWeatherChangedListener(any),
    ).thenAnswer((call) => events.stream.listen(call.positionalArguments[0]));
    transport = _Transport();
    service = WeatherService(channel, preferences: prefs, transport: transport);
    settings = SettingsService(prefs);
    while (!service.initialized) {
      await Future<void>.delayed(Duration.zero);
    }
  });
  tearDown(() async {
    service.dispose();
    settings.dispose();
    await events.close();
    PathProviderPlatform.instance = originalPaths;
    await directory.delete(recursive: true);
  });
  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: service),
          ChangeNotifierProvider.value(value: settings),
        ],
        child: const MaterialApp(
          locale: Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: WeatherPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> waitFor(WidgetTester tester, bool Function() ready) async {
    for (var attempt = 0; attempt < 100 && !ready(); attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(ready(), isTrue);
    await tester.pumpAndSettle();
  }

  Finder tile(String label) =>
      find.widgetWithText(FocusableSettingsTile, label);

  for (final source in ['Open-Meteo', 'OpenWeather', 'Яндекс Погода (REST)']) {
    testWidgets(
      '$source selection only chooses the source; parameters stay separate',
      (tester) async {
        await mount(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(
          tester
              .widgetList<FocusableSettingsTile>(
                find.descendant(
                  of: find.byType(AlertDialog),
                  matching: find.byType(FocusableSettingsTile),
                ),
              )
              .map((button) => (button.title as Text).data)
              .toList(),
          [
            'Open-Meteo',
            'OpenWeather',
            'Яндекс Погода (REST)',
            'Breezy Weather',
          ],
        );
        await tester.tap(find.text(source));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNothing);
        expect(tile('Местоположение'), findsOneWidget);
        expect(tile('Получить местоположение'), findsOneWidget);
        expect(tile('Название города'), findsNothing);
        expect(service.canRefresh, isFalse);
        await tester.ensureVisible(tile('Проверить обновления'));
        expect(
          tester
              .widget<FocusableSettingsTile>(tile('Проверить обновления'))
              .enabled,
          isFalse,
        );
        expect(transport.requests, isEmpty);
      },
    );
  }
  testWidgets(
    'location mode is separate and city search matches solar settings',
    (tester) async {
      const citiesChannel = MethodChannel('cutelauncher/night');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      var searches = 0;
      messenger.setMockMethodCallHandler(citiesChannel, (call) async {
        expect(call.method, 'cities');
        expect(call.arguments['language'], 'en');
        searches++;
        return searches == 1
            ? []
            : [
                {
                  'city': 'Moscow, Russia',
                  'latitude': 55.75583,
                  'longitude': 37.61778,
                },
                {
                  'city': 'Moscow, Idaho, United States',
                  'latitude': 46.73239,
                  'longitude': -117.00017,
                },
              ];
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(citiesChannel, null),
      );
      await tester.runAsync(
        () => service.configure(
          const WeatherConfiguration(source: WeatherSource.yandex),
        ),
      );
      await mount(tester);
      await tester.tap(tile('Местоположение'));
      await tester.pumpAndSettle();
      final dialog = find.byType(AlertDialog);
      expect(
        find.descendant(
          of: dialog,
          matching: find.text('Получить автоматически'),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(of: dialog, matching: find.text('Ввести вручную')),
      );
      await waitFor(
        tester,
        () => tile('Название города').evaluate().isNotEmpty,
      );
      await tester.pumpAndSettle();
      expect(tile('Получить местоположение'), findsNothing);
      expect(tile('Название города'), findsOneWidget);
      expect(searches, 0);
      expect(service.canRefresh, isFalse);
      await tester.tap(tile('Название города'));
      await tester.pumpAndSettle();
      expect(find.text('Выбрать город'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration!.hintText,
        isNull,
      );
      await tester.enterText(find.byType(TextField), 'WrongCityDefinitely');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(
        find.text('Города не найдены. Попробуйте другое название.'),
        findsOneWidget,
      );
      expect(service.configuration.location, isEmpty);
      expect(transport.requests, isEmpty);
      await tester.enterText(find.byType(TextField), 'Moscow');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Moscow, Idaho, United States'));
      await waitFor(
        tester,
        () => find
            .descendant(
              of: find.byType(WeatherPage),
              matching: find.text('Moscow, Idaho, United States'),
            )
            .evaluate()
            .isNotEmpty,
      );
      expect(service.configuration.cityLatitude, 46.73239);
      expect(service.configuration.cityLongitude, -117.00017);
      expect(transport.requests, isEmpty); // Yandex still requires a key.
      await tester.tap(tile('Местоположение'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Получить автоматически'),
        ),
      );
      await waitFor(
        tester,
        () => tile('Получить местоположение').evaluate().isNotEmpty,
      );
      await tester.pumpAndSettle();
      expect(tile('Название города'), findsNothing);
      expect(tile('Получить местоположение'), findsOneWidget);
      expect(service.configuration.cityLatitude, 46.73239);
      expect(service.configuration.location, 'Moscow, Idaho, United States');
      expect(service.canRefresh, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('API key editor hides keys; missing location prevents requests', (
    tester,
  ) async {
    await tester.runAsync(
      () => service.configure(
        const WeatherConfiguration(source: WeatherSource.openWeather),
      ),
    );
    await mount(tester);
    for (final key in ['replacement-test-key', '']) {
      await tester.ensureVisible(tile('API-ключ OpenWeather'));
      await tester.tap(tile('API-ключ OpenWeather'));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isTrue);
      expect(field.controller!.text, isEmpty);
      await tester.enterText(find.byType(TextField), key);
      await tester.runAsync(() async {
        await tester.tap(find.text('ОК'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      final saved = File('${directory.path}/weather-api-key-openweather');
      await waitFor(
        tester,
        () => key.isEmpty
            ? !saved.existsSync()
            : saved.existsSync() && saved.readAsStringSync() == key,
      );
      expect(
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return service.hasApiKey(source: WeatherSource.openWeather);
        }),
        key.isNotEmpty,
      );
      expect(service.canRefresh, isFalse);
      expect(transport.requests, isEmpty);
    }
  });
  testWidgets(
    'automatic location shows immutable coordinates and handles denied permission',
    (tester) async {
      const channel = MethodChannel('cutelauncher/weather_location');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => {'latitude': 55.75583, 'longitude': 37.61778},
      );
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      await tester.runAsync(
        () => service.configure(
          const WeatherConfiguration(source: WeatherSource.yandex),
        ),
      );
      await mount(tester);
      await tester.tap(tile('Получить местоположение'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pumpAndSettle();
      expect(find.text('55.756, 37.618'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(service.configuration.validCoordinates, isTrue);
      expect(service.canRefresh, isFalse);
      expect(transport.requests, isEmpty);
      messenger.setMockMethodCallHandler(
        channel,
        (_) async =>
            throw PlatformException(code: 'LOCATION_PERMISSION_DENIED'),
      );
      await tester.tap(tile('Получить местоположение'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Разрешите доступ к местоположению в настройках Android и повторите попытку.',
        ),
        findsOneWidget,
      );
      expect(service.configuration.latitude, 55.75583);
      expect(service.locating, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
