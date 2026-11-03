import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/cover_memory_image.dart';

Future<Uint8List> source(int width, int height) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawColor(const ui.Color(0xff456789), ui.BlendMode.src);
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

Future<ui.Size> decodedSize(CoverMemoryImage provider) async {
  final result = Completer<ui.Size>();
  final stream = provider.resolve(ImageConfiguration.empty);
  late ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      result.complete(
        ui.Size(info.image.width.toDouble(), info.image.height.toDouble()),
      );
      info.dispose();
      stream.removeListener(listener);
    },
    onError: (Object error, StackTrace? stack) =>
        result.completeError(error, stack),
  );
  stream.addListener(listener);
  return result.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  test(
    'portrait and wide sources cover the enlarged card at physical resolution',
    () async {
      for (final dimensions in [(800, 1200), (2400, 600), (1600, 900)]) {
        final bytes = await source(dimensions.$1, dimensions.$2);
        final provider = CoverMemoryImage(
          bytes,
          logicalSize: const ui.Size(320, 180),
          pixelRatio: 2,
          focusScale: 1.2,
        );
        final decoded = await decodedSize(provider);
        expect(decoded.width, greaterThanOrEqualTo(768));
        expect(decoded.height, greaterThanOrEqualTo(432));
        expect(
          decoded.aspectRatio,
          closeTo(dimensions.$1 / dimensions.$2, .01),
        );
      }
    },
  );

  test(
    'small sources are never enlarged and extreme aspect ratios remain bounded',
    () async {
      final small = await source(80, 120);
      expect(
        await decodedSize(
          CoverMemoryImage(
            small,
            logicalSize: const ui.Size(320, 180),
            pixelRatio: 2,
            focusScale: 1.2,
          ),
        ),
        const ui.Size(80, 120),
      );
      final tall = await source(300, 3000);
      expect(
        await decodedSize(
          CoverMemoryImage(
            tall,
            logicalSize: const ui.Size(320, 180),
            pixelRatio: 2,
            focusScale: 1.2,
          ),
        ),
        const ui.Size(205, 2048),
      );
    },
  );

  test(
    'cache identity includes decode geometry and reuses identical requests',
    () async {
      final bytes = await source(80, 120);
      CoverMemoryImage provider(double scale, {double ratio = 2}) =>
          CoverMemoryImage(
            bytes,
            logicalSize: const ui.Size(320, 180),
            pixelRatio: ratio,
            focusScale: scale,
          );
      expect(provider(1.2), provider(1.2));
      expect(provider(1.2).hashCode, provider(1.2).hashCode);
      expect(provider(1.2), isNot(provider(1)));
      expect(provider(1.2), isNot(provider(1.2, ratio: 1)));
      expect(provider(1.2), isNot(MemoryImage(bytes)));
    },
  );
}
