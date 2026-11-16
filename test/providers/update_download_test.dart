import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flauncher/image_limits.dart';
import 'package:flauncher/providers/update_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _Headers extends Fake implements HttpHeaders {
  final String? location;
  _Headers(this.location);
  @override
  String? value(String name) => location;
}

class _Response extends Fake implements HttpClientResponse {
  final List<int> bytes;
  final int status;
  final String? location;
  _Response(this.bytes, {this.status = 200, this.location});
  @override
  int get statusCode => status;
  @override
  int get contentLength => bytes.length;
  @override
  HttpHeaders get headers => _Headers(location);
  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      Stream<List<int>>.value(bytes).listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  @override
  Future<E> drain<E>([E? futureValue]) =>
      Stream<List<int>>.value(bytes).drain<E>(futureValue);
}

class _RequestHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _Request extends Fake implements HttpClientRequest {
  final _Response response;
  _Request(this.response);
  @override
  bool followRedirects = false;
  @override
  HttpHeaders get headers => _RequestHeaders();
  @override
  Future<HttpClientResponse> close() async => response;
}

class _Client extends Fake implements HttpClient {
  final _Response response;

  _Client(this.response);

  Uri? requestedUri;
  @override
  Duration? connectionTimeout;
  @override
  Future<HttpClientRequest> getUrl(Uri uri) async {
    requestedUri = uri;
    return _Request(response);
  }
  @override
  void close({bool force = false}) {}
}

class _Overrides extends HttpOverrides {
  final _Response response;

  _Overrides(this.response);

  late final _Client client = _Client(response);
  @override
  HttpClient createHttpClient(SecurityContext? context) => client;
}

void main() {
  group('Release lookup HTTP diagnostics', () {
    setUp(() {
      final previous = HttpOverrides.current;
      addTearDown(() => HttpOverrides.global = previous);
    });

    for (final status in [301, 403, 429, 500]) {
      test('preserves HTTP $status without the response body', () async {
        HttpOverrides.global = _Overrides(
          _Response(utf8.encode('private response body'), status: status),
        );
        await expectLater(
          fetchAppRelease(),
          throwsA(isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Release unavailable (HTTP $status)',
          )),
        );
      });
    }

    test('retains missing repository and successful list behavior', () async {
      HttpOverrides.global = _Overrides(_Response([], status: 404));
      expect(await fetchAppRelease(), isNull);
      HttpOverrides.global = _Overrides(_Response(utf8.encode('[]')));
      expect(await fetchAppRelease(), {'releases': []});
    });
  });

  group('Release notes', () {
    const tag = 'v1.2.0-test.2+15';
    setUp(() {
      final previous = HttpOverrides.current;
      addTearDown(() => HttpOverrides.global = previous);
    });

    for (final language in ['ru', 'en', 'de']) {
      test(
        'loads only the offered tag in the language for $language',
        () async {
          final notes = language == 'ru'
              ? '- Новые настройки.'
              : '- New settings.';
          final response = _Overrides(
            _Response(
              utf8.encode(
                [
                  '## v1.2.0-test.2+16 — 2026-11-16',
                  '- Wrong build.',
                  '## $tag — 2026-11-16',
                  '',
                  notes,
                  '',
                  '## v1.2.0-test.1 — 2026-11-15',
                  '- Older update.',
                ].join('\r\n'),
              ),
            ),
          );
          HttpOverrides.global = response;
          expect(await fetchAppReleaseNotes(tag, language), notes);
          final uri = response.client.requestedUri!;
          expect(uri.scheme, 'https');
          expect(uri.host, 'raw.githubusercontent.com');
          expect(uri.pathSegments, [
            ...updateRepository.split('/'),
            tag,
            'CHANGELOG_${language == 'ru' ? 'RU' : 'EN'}.md',
          ]);
        },
      );
    }

    test('handles missing files and missing or empty tag entries', () async {
      HttpOverrides.global = _Overrides(_Response([], status: 404));
      expect(await fetchAppReleaseNotes(tag, 'en'), isNull);
      HttpOverrides.global = _Overrides(
        _Response(
          utf8.encode('## v1.2.0 — 2026-11-16\n\n- Different release.\n'),
        ),
      );
      expect(await fetchAppReleaseNotes(tag, 'en'), isNull);
      HttpOverrides.global = _Overrides(
        _Response(
          utf8.encode(
            '## $tag — 2026-11-16\n\n## v1.2.0 — 2026-11-16\n- Different release.\n',
          ),
        ),
      );
      expect(await fetchAppReleaseNotes(tag, 'en'), isNull);
    });

    test('rejects redirects and oversized changelogs', () async {
      HttpOverrides.global = _Overrides(_Response([], status: 302));
      await expectLater(fetchAppReleaseNotes(tag, 'en'), throwsFormatException);
      HttpOverrides.global = _Overrides(
        _Response(List.filled(512 * 1024 + 1, 0)),
      );
      await expectLater(
        fetchAppReleaseNotes(tag, 'en'),
        throwsA(isA<ImageInputException>()),
      );
    });
  });

  test('Download validates size and SHA256 before replacing the cached APK',
      () async {
    final previous = HttpOverrides.current;
    final root = await Directory.systemTemp.createTemp('update-download');
    addTearDown(() async {
      HttpOverrides.global = previous;
      await root.delete(recursive: true);
    });
    final target = File('${root.path}/update.apk');
    await target.writeAsBytes([9]);
    final uri = Uri.parse(
        'https://github.com/$updateRepository/releases/download/v1.1.0/app.apk');
    HttpOverrides.global = _Overrides(_Response([1, 2, 3]));
    await expectLater(
        downloadAppRelease(AppRelease('1.1.0', uri, 3, 'wrong'), root, (_) {}),
        throwsFormatException);
    expect(await target.readAsBytes(), [9]);
    expect(await File('${root.path}/update.tmp').exists(), isFalse);
    final progress = <double>[];
    final file = await downloadAppRelease(
        AppRelease('1.1.0', uri, 3, sha256.convert([1, 2, 3]).toString()),
        root,
        progress.add);
    expect(await file.readAsBytes(), [1, 2, 3]);
    expect(progress.last, 1);
    HttpOverrides.global = _Overrides(_Response([1, 2, 3, 4]));
    await expectLater(
        downloadAppRelease(AppRelease('1.2.0', uri, 3, null), root, (_) {}),
        throwsFormatException);
    expect(await target.readAsBytes(), [1, 2, 3]);
    HttpOverrides.global = _Overrides(
        _Response([], status: 302, location: 'http://github.com/app.apk'));
    await expectLater(
        downloadAppRelease(AppRelease('1.2.0', uri, 3, null), root, (_) {}),
        throwsFormatException);
    expect(await target.readAsBytes(), [1, 2, 3]);
  });
}
