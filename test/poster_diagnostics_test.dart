import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flauncher/diagnostics/poster_loads.dart';
import 'package:flauncher/diagnostics_store.dart';
import 'package:flauncher/image_limits.dart';
import 'package:flauncher/network_poster.dart';
import 'package:flutter_test/flutter_test.dart';

class _PendingClient implements HttpClient {
  final response = Completer<HttpClientRequest>();
  @override
  Future<HttpClientRequest> getUrl(Uri url) => response.future;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('queue and phases retain source, timings, network and lifecycle', () {
    var now = 0;
    final diagnostics = PosterLoads(() => now);
    diagnostics.lifecycle(PosterSource.appChannels, 'resumed');
    diagnostics.network(
      transport: 'Wifi',
      internetAccess: true,
      vpnActive: false,
    );
    final first = diagnostics.start(
      PosterSource.appChannels,
      'https://i.ytimg.com/private-video?token=secret',
      packageName: 'org.example.video',
    );
    now = 20;
    first.stage(PosterStage.connection);
    now = 30;
    final second = diagnostics.start(
      PosterSource.appChannels,
      'https://i.ytimg.com/second',
    );
    now = 100;
    final active = diagnostics.snapshot()['active'] as List;
    expect(active[0]['stageDurationsMs'], {'queue': 20, 'connection': 80});
    expect(active[1]['stage'], 'queue');
    expect(active[1]['sourceActiveAtStart'], 1);
    diagnostics.lifecycle(PosterSource.appChannels, 'paused');
    diagnostics.network(
      transport: 'Unknown',
      internetAccess: false,
      vpnActive: false,
    );
    first.error(TimeoutException('private-url', const Duration(seconds: 5)));
    first.finish(PosterOutcome.discarded);
    second.finish(PosterOutcome.discarded);
    final failure = (diagnostics.snapshot()['failures'] as List).single;
    expect(failure['stage'], 'connection');
    expect(failure['timeoutMs'], 5000);
    expect(failure['packageName'], 'org.example.video');
    expect(failure['networkAtStart']['internetAccess'], true);
    expect(failure['networkAtEnd']['internetAccess'], false);
    expect(failure['lifecycleAtEnd'], 'paused');
    expect(failure['endpointGroup'], 'youtubeImages');
    expect(diagnostics.snapshot()['active'], isEmpty);
    final text = jsonEncode(diagnostics.snapshot());
    for (final secret in [
      'private-video',
      'secret',
      'i.ytimg.com',
      'private-url',
    ]) {
      expect(text, isNot(contains(secret)));
    }
  });

  test(
    'opaque IDs correlate only within the session and snapshots are detached',
    () {
      final store = DiagnosticsStore();
      const uri =
          'http://user:password@192.168.0.55/private?token=value#fragment';
      store.posterLoads.start(PosterSource.appChannels, uri);
      store.posterLoads.start(PosterSource.watchNext, uri, thumbnail: true);
      final active =
          ((store.snapshot()['posterLoads'] as Map)['active'] as List);
      final id = active.first['imageId'];
      expect(active.last['imageId'], id);
      expect(active.last['endpointId'], active.first['endpointId']);
      (active.first as Map)['imageId'] = 'mutated';
      expect(
        ((store.snapshot()['posterLoads'] as Map)['active'] as List)
            .first['imageId'],
        id,
      );
      final pending = store.posterLoads.start(PosterSource.appChannels, uri);
      store.clear();
      pending.error(StateError('late'));
      pending.finish(PosterOutcome.failed);
      expect((store.snapshot()['posterLoads'] as Map)['failures'], isEmpty);
      store.posterLoads.start(PosterSource.appChannels, uri);
      expect(
        ((store.snapshot()['posterLoads'] as Map)['active'] as List)
            .single['imageId'],
        isNot(id),
      );
      final json = jsonEncode(store.snapshot());
      for (final secret in [
        '192.168',
        'password',
        '/private',
        'token',
        'fragment',
        'late',
      ]) {
        expect(json, isNot(contains(secret)));
      }
    },
  );

  test(
    'active and completed traces are bounded; success does not evict failures',
    () {
      final diagnostics = PosterLoads(() => 1);
      for (var i = 0; i < 100; i++) {
        diagnostics.start(PosterSource.appChannels, 'content://provider/$i');
      }
      expect(
        diagnostics.snapshot()['active'],
        hasLength(PosterLoads.activeLimit),
      );
      expect(diagnostics.snapshot()['omittedActive'], 68);
      for (var i = 0; i < 100; i++) {
        final trace = diagnostics.start(
          PosterSource.appChannels,
          'https://example.com/$i',
        );
        trace.error(const SocketException('Failed host lookup: private-host'));
        trace.finish(PosterOutcome.failed);
      }
      for (var i = 0; i < 100; i++) {
        diagnostics
            .start(PosterSource.watchNext, 'content://provider/$i')
            .finish(PosterOutcome.loaded);
      }
      expect(
        diagnostics.snapshot()['recent'],
        hasLength(PosterLoads.recentLimit),
      );
      expect(
        diagnostics.snapshot()['failures'],
        hasLength(PosterLoads.failureLimit),
      );
      expect(
        (diagnostics.snapshot()['failures'] as List).first['reason'],
        'dns',
      );
    },
  );

  test('failure categories do not expose arbitrary exception messages', () {
    final diagnostics = PosterLoads(() => 0);
    for (final (error, reason) in <(Object, String)>[
      (const SocketException('connection refused'), 'connection'),
      (const HandshakeException('certificate secret'), 'tls'),
      (const ImageInputException(ImageInputFailure.bytes), 'tooLarge'),
      (const ImageInputException(ImageInputFailure.dimensions), 'dimensions'),
      (const ImageInputException(), 'invalidImage'),
    ]) {
      final trace = diagnostics.start(
        PosterSource.watchNext,
        'https://example.com/image',
      );
      trace.stage(PosterStage.validation);
      trace.error(error);
      trace.finish(PosterOutcome.failed);
      expect(
        (diagnostics.snapshot()['failures'] as List).last['reason'],
        reason,
      );
    }
    expect(jsonEncode(diagnostics.snapshot()), isNot(contains('secret')));
    expect(
      () =>
          diagnostics.start(PosterSource.appChannels, 'https://host:bad/image'),
      returnsNormally,
    );
  });

  test(
    'connection timeout reports connection phase rather than headers or body',
    () {
      fakeAsync((time) {
        final diagnostics = PosterLoads(() => time.elapsed.inMilliseconds);
        final trace = diagnostics.start(
          PosterSource.appChannels,
          'https://example.com/image',
        );
        final client = _PendingClient();
        readNetworkPoster(
          client,
          Uri.parse('https://example.com/image'),
          trace: trace,
        ).then<void>(
          (_) => fail('unexpected success'),
          onError: (Object _) {
            trace.finish(PosterOutcome.failed);
          },
        );
        time.elapse(const Duration(seconds: 5));
        final failure = (diagnostics.snapshot()['failures'] as List).single;
        expect(failure['stage'], 'connection');
        expect(failure['reason'], 'timeout');
        expect(failure['durationMs'], 5000);
        expect(failure['receivedBytes'], 0);
      });
    },
  );
}
