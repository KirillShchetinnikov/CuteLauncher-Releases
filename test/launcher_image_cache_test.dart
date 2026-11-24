import 'dart:async';
import 'dart:ui' as ui;

import 'package:flauncher/cover_memory_image.dart';
import 'package:flauncher/launcher_image_cache.dart';
import 'package:flauncher/providers/memory_resources.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/tile_image_geometry.dart';
import 'package:flauncher/widgets/tile_artwork.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';

class _LauncherTestBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  ImageCache createImageCache() => LauncherImageCache();
}

void main() {
  _LauncherTestBinding();
  final cache = PaintingBinding.instance.imageCache as LauncherImageCache;
  const configuration = ImageConfiguration.empty;

  setUp(() => configureLauncherImageCache());
  tearDown(
    () => cache
      ..clear()
      ..clearLiveImages(),
  );

  Map<String, int> partition(String label) => cache.partitions[label]!;

  Future<void> insert(Object key) async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawColor(Colors.white, ui.BlendMode.src);
    final picture = recorder.endRecording();
    final image = await picture.toImage(10, 10);
    picture.dispose();
    cache.putIfAbsent(
      key,
      () => OneFrameImageStreamCompleter(Future.value(ImageInfo(image: image))),
    );
    await Future<void>.delayed(Duration.zero);
    expect(cache.statusForKey(key).keepAlive, isTrue);
  }

  test(
    'poster byte pressure evicts only posters, including resized tile styles',
    () async {
      cache.maximumSizeBytes = 2000;
      final application = ResizeImage(
        MemoryImage(kTransparentImage),
        width: 10,
      );
      final appKey = await application.obtainKey(configuration);
      await insert(appKey);
      final cover = CoverMemoryImage(
        kTransparentImage,
        logicalSize: const Size(10, 10),
        pixelRatio: 1,
        focusScale: 1,
      );
      final coverKey = await cover.obtainKey(configuration);
      await insert(coverKey);
      final tileKey = await PosterTileImage(application)
          .obtainKey(configuration);
      await insert(tileKey);
      for (final width in [11, 12, 13]) {
        final poster = PosterTileImage(
          ResizeImage(MemoryImage(kTransparentImage), width: width),
        );
        await insert(await poster.obtainKey(configuration));
      }

      expect(cache.statusForKey(appKey).keepAlive, isTrue);
      expect(cache.statusForKey(coverKey).keepAlive, isFalse);
      expect(cache.statusForKey(tileKey).keepAlive, isFalse);
      expect(partition('applications')['bytes'], 400);
      expect(partition('posters')['bytes'], 1200);
      expect(cache.currentSizeBytes, 1600);
    },
  );

  test('profiles retain the combined budget and clear both caches under memory pressure', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService(await SharedPreferences.getInstance());
    final resources = MemoryResources(settings: settings);
    addTearDown(resources.dispose);
    addTearDown(settings.dispose);
    const mib = 1024 * 1024;
    expect(partition('applications')['maximumBytes'], 20 * mib);
    expect(partition('applications')['maximumEntries'], 40);
    expect(partition('posters')['maximumBytes'], 30 * mib);
    expect(partition('posters')['maximumEntries'], 60);

    await settings.setMemorySaverEnabled(true);
    for (final label in ['applications', 'posters']) {
      expect(partition(label)['maximumBytes'], 8 * mib);
      expect(partition(label)['maximumEntries'], 32);
    }
    final posterKey = await PosterTileImage(
      ResizeImage(MemoryImage(kTransparentImage), width: 10),
    ).obtainKey(configuration);
    await insert('application');
    await insert(posterKey);
    resources.didHaveMemoryPressure();
    expect(cache.currentSize, 0);
    expect(cache.containsKey('application'), isFalse);
    expect(cache.containsKey(posterKey), isFalse);
  });

  test(
    'sized poster uses Flutter decoding and lands in the poster cache',
    () async {
      final image = PosterTileImage(
        ResizeImage(MemoryImage(kTransparentImage), width: 10),
      );
      final stream = image.resolve(configuration);
      final decoded = Completer<void>();
      final listener = ImageStreamListener((info, _) {
        info.dispose();
        if (!decoded.isCompleted) decoded.complete();
      }, onError: (error, stack) => decoded.completeError(error, stack));
      stream.addListener(listener);
      try {
        await decoded.future.timeout(const Duration(seconds: 3));
        expect(partition('posters')['entries'], 1);
        expect(partition('applications')['entries'], 0);
      } finally {
        stream.removeListener(listener);
      }
    },
  );

  testWidgets(
    'poster tile marks the provider after sizing',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 80,
              height: 60,
              child: TileArtwork(
                image: MemoryImage(kTransparentImage),
                mode: TileImageMode.contain,
                borderRadius: BorderRadius.zero,
                isPoster: true,
              ),
            ),
          ),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image)).image;
      expect(image, isA<PosterTileImage>());
    },
  );
}
