import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class CitySearchResult {
  const CitySearchResult(this.label, this.latitude, this.longitude);

  final String label;
  final double latitude;
  final double longitude;

  Map<String, dynamic> toMap() => {
    'city': label,
    'latitude': latitude,
    'longitude': longitude,
  };
}

class CitySearch {
  CitySearch({
    required this.loadCatalog,
    required this.request,
    required this.username,
  });

  static final shared = CitySearch(
    loadCatalog: () => rootBundle.loadString('assets/cities.tsv', cache: false),
    request: _requestGeoNames,
    username: const String.fromEnvironment(
      'GEONAMES_USERNAME',
      defaultValue: 'kipik1',
    ),
  );

  final Future<String> Function() loadCatalog;
  final Future<Map<String, dynamic>> Function(Uri) request;
  final String username;
  Future<String>? _catalog;
  static final _wordSeparator = RegExp(r'[\s\-‐‑–—]+');
  // Keys are the admin1 labels in the bundled GeoNames catalog. The codes
  // identify the same regions in localized online search results.
  static const _regionsWithoutCountry = {
    'Crimea': (code: '11', english: 'Crimea', russian: 'Крым'),
    'Sevastopol City': (
      code: '20',
      english: 'Sevastopol City',
      russian: 'Город Севастополь',
    ),
    'Donetsk': (
      code: '05',
      english: 'Donetsk Oblast',
      russian: 'Донецкая область',
    ),
    'Luhansk': (
      code: '14',
      english: 'Luhansk Oblast',
      russian: 'Луганская область',
    ),
    'Zaporizhzhia': (
      code: '26',
      english: 'Zaporizhzhia Oblast',
      russian: 'Запорожская область',
    ),
    'Kherson': (
      code: '08',
      english: 'Kherson Oblast',
      russian: 'Херсонская область',
    ),
  };

  Future<List<CitySearchResult>> search(
    String query, {
    String language = 'en',
    bool exactName = false,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2 || trimmed.length > 200) return [];
    final parts = trimmed
        .split(',')
        .map(_normalize)
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty || parts.first.length < 2) return [];
    final catalog = await (_catalog ??= _loadCatalog());
    final input = (
      catalog: catalog,
      parts: parts,
      russian: language == 'ru',
      exactName: exactName,
    );
    final local = catalog.length > 50 * 1024
        ? await compute(_findLocalCities, input)
        : _findLocalCities(input);
    if (local.isNotEmpty) return local;

    if (username.isEmpty) {
      throw StateError('GeoNames account is not configured');
    }
    final data = await request(
      Uri.https('secure.geonames.org', '/searchJSON', {
        if (parts.length > 1) ...{
          'q': trimmed.replaceAll(',', ' '),
          'isNameRequired': 'true',
        } else if (exactName)
          'name_equals': trimmed
        else
          'name': trimmed,
        'username': username,
        'featureClass': 'P',
        'maxRows': '8',
        'lang': language,
      }),
    );
    if (data['status'] != null) throw StateError('GeoNames search failed');
    final places = data['geonames'];
    if (places is! List) {
      throw const FormatException('Missing GeoNames results');
    }
    return places.map((place) {
      if (place is! Map) throw const FormatException('Invalid GeoNames place');
      final name = place['name'];
      final region = place['adminName1'];
      final regionWithoutCountry = place['countryCode'] == 'UA'
          ? _regionsWithoutCountry[region] ??
                _regionsWithoutCountry.values
                    .where((candidate) => candidate.code == place['adminCode1'])
                    .firstOrNull
          : null;
      return _result(
        name,
        regionWithoutCountry != null &&
                (region is! String || region.trim().isEmpty || region == name)
            ? (language == 'ru'
                  ? regionWithoutCountry.russian
                  : regionWithoutCountry.english)
            : region,
        regionWithoutCountry != null ? null : place['countryName'],
        place['lat'],
        place['lng'],
      );
    }).toList();
  }

  Future<String> _loadCatalog() async {
    try {
      return await loadCatalog();
    } catch (_) {
      _catalog = null;
      rethrow;
    }
  }

  static List<CitySearchResult> _findLocalCities(
    ({String catalog, List<String> parts, bool russian, bool exactName}) input,
  ) {
    final exact = <CitySearchResult>[];
    final prefix = <CitySearchResult>[];
    for (final line in const LineSplitter().convert(input.catalog)) {
      final [
        name,
        russianName,
        region,
        country,
        countryCode,
        lat,
        lon,
        aliases,
      ] = line.split(
        '\t',
      );
      final names = [
        name,
        russianName,
        ...aliases.split('|'),
      ].map(_normalize).toList();
      final query = input.parts.first;
      final isExact = names.contains(query);
      if (!isExact &&
          (input.exactName ||
              exact.isNotEmpty ||
              prefix.length == 8 ||
              !names.any((alias) => alias.startsWith(query)))) {
        continue;
      }
      final regionWithoutCountry = countryCode == 'UA'
          ? _regionsWithoutCountry[region]
          : null;
      if (input.parts.length > 1) {
        final area = _normalize(
          '$region ${regionWithoutCountry?.english ?? ''} ${regionWithoutCountry?.russian ?? ''} '
          '$country $countryCode ${countryCode == 'RU' ? 'Россия' : ''}',
        );
        if (!input.parts.skip(1).every(area.contains)) continue;
      }
      (isExact ? exact : prefix).add(
        _result(
          input.russian && russianName.isNotEmpty ? russianName : name,
          regionWithoutCountry == null
              ? (region == name ? '' : region)
              : (input.russian
                    ? regionWithoutCountry.russian
                    : regionWithoutCountry.english),
          regionWithoutCountry != null
              ? null
              : (input.russian && countryCode == 'RU' ? 'Россия' : country),
          lat,
          lon,
        ),
      );
      if (exact.length == 8) break;
    }
    return exact.isNotEmpty ? exact : prefix;
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .trim()
      .replaceAll('ё', 'е')
      .replaceAll(_wordSeparator, ' ');

  static CitySearchResult _result(
    Object? name,
    Object? region,
    Object? country,
    Object? lat,
    Object? lon,
  ) {
    final latitude = double.tryParse('$lat');
    final longitude = double.tryParse('$lon');
    if (name is! String ||
        name.trim().isEmpty ||
        latitude == null ||
        !latitude.isFinite ||
        latitude.abs() > 90 ||
        longitude == null ||
        !longitude.isFinite ||
        longitude.abs() > 180) {
      throw const FormatException('Invalid city coordinates or name');
    }
    final label = [name, region, country]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toSet()
        .join(', ');
    return CitySearchResult(label, latitude, longitude);
  }

  static Future<Map<String, dynamic>> _requestGeoNames(Uri uri) async {
    const timeout = Duration(seconds: 5);
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      return await (() async {
        final request = await client.getUrl(uri);
        request.followRedirects = false;
        final response = await request.close();
        if (response.statusCode != HttpStatus.ok) {
          throw StateError('GeoNames HTTP ${response.statusCode}');
        }
        final bytes = <int>[];
        await for (final chunk in response) {
          if (bytes.length + chunk.length > 128 * 1024) {
            throw const FormatException('GeoNames response too large');
          }
          bytes.addAll(chunk);
        }
        return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      })().timeout(timeout);
    } finally {
      client.close(force: true);
    }
  }
}
