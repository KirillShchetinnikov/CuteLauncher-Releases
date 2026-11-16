import 'dart:convert';

import 'package:flauncher/app_image_type.dart';
import 'package:flauncher/diagnostics_store.dart';
import 'package:flauncher/home_tile_diagnostics.dart';
import 'package:flauncher/providers/memory_resources.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'app aliases are local and both the alias map and history are bounded',
    () {
      var elapsedMs = 0;
      final trace = HomeTileDiagnostics(() => ++elapsedMs);
      for (var app = 0; app < HomeTileDiagnostics.appLimit + 1; app++) {
        trace.read(
          'private.package$app',
          AppImageType.Banner,
          HomeTileRead.read,
        );
      }
      for (var event = 0; event < HomeTileDiagnostics.eventLimit; event++) {
        trace.read(
          'private.package0',
          AppImageType.Icon,
          HomeTileRead.cacheHit,
        );
      }
      final snapshot = trace.snapshot();
      final events = snapshot['events'] as List<Map<String, Object>>;
      expect(events, hasLength(HomeTileDiagnostics.eventLimit));
      expect(snapshot['omittedEvents'], HomeTileDiagnostics.appLimit + 1);
      expect(events.every((event) => event['app'] == 1), isTrue);
      expect(jsonEncode(snapshot), isNot(contains('private.package')));
      trace.clear();
      expect(trace.snapshot()['events'], isEmpty);
      expect(trace.snapshot()['omittedEvents'], 0);
      expect(events, hasLength(HomeTileDiagnostics.eventLimit));
    },
  );

  test('tile recording is opt-in and includes lifecycle and cache-clear causes', () {
    final store = DiagnosticsStore.instance;
    store.clear();
    addTearDown(store.clear);
    final resources = MemoryResources();
    addTearDown(resources.dispose);
    store.startRecording();

    resources.didChangeAppLifecycleState(AppLifecycleState.hidden);
    resources.didChangeAppLifecycleState(AppLifecycleState.paused);
    resources.didHaveMemoryPressure();
    resources.didChangeAppLifecycleState(AppLifecycleState.resumed);

    final report = store.snapshot(extended: true);
    expect(store.snapshot(), isNot(contains('homeTileImages')));
    final history = report['homeTileImages'] as Map<String, Object>;
    final events = history['events'] as List<Map<String, Object>>;
    expect(events.map((event) => event['event']), [
      'lifecycle',
      'cacheClear',
      'lifecycle',
    ]);
    expect(events.first['foreground'], isFalse);
    expect(events[1]['reason'], 'memoryPressure');
    expect(events.last['foreground'], isTrue);
    store.clear();
    expect((store.snapshot(extended: true)['homeTileImages'] as Map)['events'], isEmpty);
  });
}
