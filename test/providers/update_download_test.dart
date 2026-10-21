import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
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
  _Client(this.response);
  @override
  Duration? connectionTimeout;
  @override
  Future<HttpClientRequest> getUrl(Uri uri) async => _Request(response);
  @override
  void close({bool force = false}) {}
}

class _Overrides extends HttpOverrides {
  final _Response response;
  _Overrides(this.response);
  @override
  HttpClient createHttpClient(SecurityContext? context) => _Client(response);
}

void main() {
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
