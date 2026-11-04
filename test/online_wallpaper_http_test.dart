import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flauncher/bing_wallpaper.dart';
import 'package:flauncher/apod_wallpaper.dart';
import 'package:flauncher/image_limits.dart';
import 'package:flauncher/online_wallpaper_failure.dart';
import 'package:flauncher/providers/online_wallpaper_service.dart';
import 'package:flauncher/wallhaven_wallpaper.dart';
import 'package:flauncher/wallpaper_http.dart';
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
  final int? declaredLength;
  final String? location;
  _Response(
    this.bytes, {
    this.status = 200,
    this.declaredLength,
    this.location,
  });
  @override
  int get statusCode => status;
  @override
  int get contentLength => declaredLength ?? bytes.length;
  @override
  HttpHeaders get headers => _Headers(location);
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  Future<E> drain<E>([E? futureValue]) =>
      Stream<List<int>>.value(bytes).drain<E>(futureValue);
}

class _Request extends Fake implements HttpClientRequest {
  final _Response response;
  _Request(this.response);
  @override
  bool followRedirects = false;
  @override
  Future<HttpClientResponse> close() async => response;
}

class _Client extends Fake implements HttpClient {
  final _Response response;
  bool closed = false;
  _Client(this.response);
  @override
  Duration? connectionTimeout;
  @override
  String? userAgent;
  @override
  Future<HttpClientRequest> getUrl(Uri uri) async => _Request(response);
  @override
  void close({bool force = false}) {
    closed = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final uri = Uri.parse('https://private.example/image?token=secret');
  Future<T> withResponse<T>(
    _Response response,
    Future<T> Function() action,
  ) async {
    final client = _Client(response);
    try {
      return await HttpOverrides.runZoned(
        action,
        createHttpClient: (_) => client,
      );
    } finally {
      expect(client.closed, isTrue);
    }
  }

  Matcher failure(
    WallpaperFailureReason reason, {
    int? status,
    WallpaperStage? stage,
  }) => isA<WallpaperException>()
      .having((e) => e.reason, 'reason', reason)
      .having((e) => e.httpStatus, 'HTTP status', status)
      .having((e) => e.stage, 'stage', stage);

  test(
    'Bing, Wallhaven and image download preserve exact HTTP statuses',
    () async {
      for (final status in [302, 403, 404, 429, 503]) {
        for (final request in <Future<Object> Function()>[
          fetchBingWallpaper,
          fetchApodWallpaper,
          () => fetchWallhavenWallpaper('all', null),
          if (status != 302) () => downloadWallpaper(uri),
        ]) {
          await expectLater(
            withResponse(_Response([], status: status), request),
            throwsA(failure(WallpaperFailureReason.http, status: status)),
          );
        }
      }
    },
  );

  test(
    'metadata rejects oversized bodies with and without Content-Length',
    () async {
      for (final response in [
        _Response([], declaredLength: 512 * 1024 + 1),
        _Response(List.filled(512 * 1024 + 1, 32), declaredLength: -1),
      ]) {
        await expectLater(
          withResponse(
            response,
            () => requestWallpaperJson(uri, limit: 512 * 1024),
          ),
          throwsA(
            anyOf(
              failure(WallpaperFailureReason.tooLarge),
              isA<ImageInputException>(),
            ),
          ),
        );
      }
    },
  );

  test('bad metadata and empty selection remain distinguishable', () async {
    await expectLater(
      withResponse(_Response(utf8.encode('not json')), fetchBingWallpaper),
      throwsFormatException,
    );
    await expectLater(
      withResponse(
        _Response(utf8.encode('{"data":[]}')),
        () => fetchWallhavenWallpaper('all', null),
      ),
      throwsA(failure(WallpaperFailureReason.noImage)),
    );
  });

  test('image distinguishes redirects, unsafe redirects, size and decoder failures', () async {
    for (final (response, reason, stage) in [
      (_Response([], status: 302), WallpaperFailureReason.redirect, null),
      (
        _Response([], status: 302, location: 'http://private.example/secret'),
        WallpaperFailureReason.insecureUrl,
        null,
      ),
      (
        _Response([], status: 302, location: '/again'),
        WallpaperFailureReason.redirect,
        null,
      ),
      (
        _Response([], declaredLength: maximumImageInputBytes + 1),
        WallpaperFailureReason.tooLarge,
        null,
      ),
      (
        _Response([1, 2, 3]),
        WallpaperFailureReason.invalidImage,
        WallpaperStage.validation,
      ),
    ]) {
      await expectLater(
        withResponse(response, () => downloadWallpaper(uri)),
        throwsA(failure(reason, stage: stage)),
      );
    }
  });
}
