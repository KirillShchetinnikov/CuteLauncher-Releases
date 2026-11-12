import 'package:flauncher/city_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled catalog resolves Cyrillic and Latin aliases offline', () async {
    final moscow = (await CitySearch.shared.search(
      'Москва',
      language: 'ru',
    )).first;
    expect(moscow.label, 'Москва, Россия');
    expect(moscow.latitude, closeTo(55.75, 0.02));
    final petersburg = (await CitySearch.shared.search(
      'Piter',
      language: 'ru',
    )).first;
    expect(petersburg.label, startsWith('Санкт-Петербург,'));
    expect(petersburg.longitude, closeTo(30.31, 0.02));
  });

  test(
    'bundled cities omit the country only for the configured regions',
    () async {
      final search = CitySearch.shared;
      final russian = await search.search('Донецк', language: 'ru');
      expect(russian.map((city) => city.label), [
        'Донецк, Rostov, Россия',
        'Донецк, Донецкая область',
      ]);
      final qualified = await search.search('Donetsk, Donetsk Oblast');
      expect(qualified.single.label, 'Donetsk, Donetsk Oblast');
      expect(qualified.single.latitude, closeTo(48, 0.1));
      expect(
        (await search.search(
          'Донецк, Донецкая область',
          language: 'ru',
        )).single.label,
        'Донецк, Донецкая область',
      );
    },
  );

  test(
    'GeoNames omits countries by region code across search languages',
    () async {
      final places = [
        ('Simferopol', 'Krim', 'UA', '11', 'Simferopol, Krim'),
        (
          'Sewastopol',
          'Stadt Sewastopol',
          'UA',
          '20',
          'Sewastopol, Stadt Sewastopol',
        ),
        ('Donezk', 'Oblast Donezk', 'UA', '05', 'Donezk, Oblast Donezk'),
        ('Luhansk', 'Oblast Luhansk', 'UA', '14', 'Luhansk, Oblast Luhansk'),
        (
          'Saporischschja',
          'Oblast Saporischschja',
          'UA',
          '26',
          'Saporischschja, Oblast Saporischschja',
        ),
        ('Cherson', 'Oblast Cherson', 'UA', '08', 'Cherson, Oblast Cherson'),
        ('Donezk', 'Rostow', 'RU', '61', 'Donezk, Rostow, Russland'),
        ('Lugansk', 'Pawlodar', 'KZ', '11', 'Lugansk, Pawlodar, Kasachstan'),
      ];
      final countries = {'UA': 'Ukraine', 'RU': 'Russland', 'KZ': 'Kasachstan'};
      final search = CitySearch(
        loadCatalog: () async => '',
        request: (uri) async {
          expect(uri.queryParameters['lang'], 'de');
          return {
            'geonames': [
              for (final (name, region, country, code, _) in places)
                {
                  'name': name,
                  'adminName1': region,
                  'adminCode1': code,
                  'countryCode': country,
                  'countryName': countries[country],
                  'lat': '48.0',
                  'lng': '37.8',
                },
            ],
          };
        },
        username: 'test',
      );
      final results = await search.search('Donezk', language: 'de');
      expect(
        results.map((city) => city.label),
        places.map((place) => place.$5),
      );
      expect(results.first.toMap(), {
        'city': 'Simferopol, Krim',
        'latitude': 48.0,
        'longitude': 37.8,
      });
    },
  );

  test(
    'local matches rank exact names and honor qualifiers without a request',
    () async {
      final search = CitySearch(
        loadCatalog: () async =>
            'Moscow Mills\t\tMissouri\tUnited States\tUS\t38.94\t-90.92\t\n'
            'Moscow\tМосква\tMoscow\tRussia\tRU\t55.75\t37.62\tMoskva\n'
            'Moscow\t\tIdaho\tUnited States\tUS\t46.73\t-117\t',
        request: (_) async => throw StateError('Unexpected GeoNames request'),
        username: 'test',
      );
      final exact = await search.search(' Moscow ');
      expect(exact.map((city) => city.label), [
        'Moscow, Russia',
        'Moscow, Idaho, United States',
      ]);
      final qualified = await search.search('Moscow, Idaho, United States');
      expect(qualified.single.latitude, 46.73);
      expect((await search.search('Moskva')).single.latitude, 55.75);
    },
  );

  test(
    'local miss sends one HTTPS request and maps GeoNames coordinates',
    () async {
      final requests = <Uri>[];
      final search = CitySearch(
        loadCatalog: () async => '',
        request: (uri) async {
          requests.add(uri);
          return {
            'geonames': [
              {
                'name': 'Териберка',
                'adminName1': 'Мурманская область',
                'countryName': 'Россия',
                'lat': '69.16088',
                'lng': '35.14527',
              },
            ],
          };
        },
        username: 'test',
      );
      expect(await search.search('Т'), isEmpty);
      final result = (await search.search('Териберка', language: 'ru')).single;
      expect(result.label, 'Териберка, Мурманская область, Россия');
      expect(result.latitude, 69.16088);
      expect(result.longitude, 35.14527);
      final request = requests.single;
      expect(request.scheme, 'https');
      expect(request.host, 'secure.geonames.org');
      expect(request.path, '/searchJSON');
      expect(request.queryParameters, containsPair('username', 'test'));
      expect(request.queryParameters, containsPair('name', 'Териберка'));
      expect(request.queryParameters, containsPair('featureClass', 'P'));
      expect(request.queryParameters, containsPair('lang', 'ru'));
    },
  );

  test('GeoNames quota and empty results remain distinguishable', () async {
    var data = <String, dynamic>{
      'status': {'value': 18},
    };
    final search = CitySearch(
      loadCatalog: () async => '',
      request: (_) async => data,
      username: 'test',
    );
    await expectLater(search.search('Териберка'), throwsStateError);
    data = {'geonames': []};
    expect(await search.search('Териберка'), isEmpty);
  });
}
