import 'dart:async';
import 'dart:typed_data';

import 'package:flauncher/models/watch_next_program.dart';
import 'package:flauncher/providers/foreground_work.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/tile_appearance.dart';
import 'package:flauncher/widgets/app_content_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';

import '../flauncher_test.dart' as fixtures;

Widget harness(
  Future<Uint8List?> Function() load, {
  bool enabled = true,
  String uri = 'content://poster/1',
  ForegroundWork? work,
  VoidCallback? invalidate,
}) => MultiProvider(
  providers: [
    ChangeNotifierProvider<SettingsService>.value(
      value: fixtures.mkSettingsService(),
    ),
    Provider<ForegroundWork?>.value(value: work),
  ],
  child: MaterialApp(
    home: Scaffold(
      body: TickerMode(
        enabled: enabled,
        child: ContentPreviewCard(
          program: WatchNextProgram.fromMap({'id': 1, 'posterArtUri': uri}),
          title: 'Poster',
          style: const TileAppearance(),
          size: const Size(240, 135),
          loadPoster: load,
          invalidatePoster: invalidate,
          onOpen: (_) async {},
        ),
      ),
    ),
  ),
);

void main() {
  for (final failure in ['null', 'empty', 'throw']) {
    testWidgets('poster retries $failure and stops after success', (
      tester,
    ) async {
      var calls = 0;
      Future<Uint8List?> load() async {
        if (++calls > 1) return kTransparentImage;
        if (failure == 'throw') throw StateError('temporary');
        return failure == 'empty' ? Uint8List(0) : null;
      }

      await tester.pumpWidget(harness(load));
      await tester.pump(const Duration(milliseconds: 1999));
      expect(calls, 1);
      await tester.pump(const Duration(milliseconds: 1));
      expect(calls, 2);
      await tester.pump(const Duration(minutes: 1));
      expect(calls, 2);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('failed poster backs off and stops on dispose', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      harness(() async {
        calls++;
        return null;
      }),
    );
    for (final seconds in [2, 4, 8, 16, 30, 30]) {
      final before = calls;
      await tester.pump(Duration(seconds: seconds - 1));
      expect(calls, before);
      await tester.pump(const Duration(seconds: 1));
      expect(calls, before + 1);
    }
    await tester.pumpWidget(const SizedBox());
    final before = calls;
    await tester.pump(const Duration(minutes: 1));
    expect(calls, before);
  });

  testWidgets('empty URI never retries', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      harness(() async {
        calls++;
        return null;
      }, uri: ''),
    );
    await tester.pump(const Duration(minutes: 1));
    expect(calls, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('hidden and background cards suspend retries', (tester) async {
    var calls = 0;
    Future<Uint8List?> load() async {
      calls++;
      return null;
    }

    await tester.pumpWidget(harness(load));
    await tester.pumpWidget(harness(load, enabled: false));
    await tester.pump(const Duration(minutes: 1));
    expect(calls, 1);
    await tester.pumpWidget(harness(load));
    await tester.pump(const Duration(seconds: 2));
    expect(calls, 2);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(minutes: 1));
    expect(calls, 2);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 4));
    expect(calls, 3);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('retry waits for remote input to settle', (tester) async {
    var calls = 0;
    final work = ForegroundWork(now: tester.binding.clock.now)..homeReady();
    await tester.pumpWidget(
      harness(() async {
        calls++;
        return null;
      }, work: work),
    );
    await tester.pump(const Duration(seconds: 2));
    work.deferForInput();
    await tester.pump(const Duration(milliseconds: 349));
    expect(calls, 1);
    await tester.pump(const Duration(milliseconds: 1));
    expect(calls, 2);
    await tester.pumpWidget(const SizedBox());
    work.dispose();
  });

  testWidgets('late old source cannot replace a recovered poster', (
    tester,
  ) async {
    final old = Completer<Uint8List?>();
    var calls = 0;
    await tester.pumpWidget(
      harness(() {
        calls++;
        return old.future;
      }),
    );
    await tester.pumpWidget(
      harness(() async {
        calls++;
        return kTransparentImage;
      }, uri: 'content://poster/2'),
    );
    old.complete(null);
    await tester.pump(const Duration(minutes: 1));
    expect(calls, 2);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('decode failure evicts bad bytes and reloads the poster', (
    tester,
  ) async {
    var calls = 0, evictions = 0;
    await tester.pumpWidget(
      harness(
        () async =>
            ++calls == 1 ? Uint8List.fromList([1, 2, 3]) : kTransparentImage,
        invalidate: () {
          evictions++;
        },
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () async => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(evictions, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(calls, 2);
    await tester.pump();
    await tester.runAsync(
      () async => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    await tester.pump(const Duration(minutes: 1));
    expect(calls, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
