import 'dart:async';
import 'dart:ui' as ui;

import 'package:flauncher/widgets/wallpaper_background.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _DelayedWallpaper extends ImageProvider<_DelayedWallpaper> {
  final frame = Completer<ImageInfo>();

  @override
  Future<_DelayedWallpaper> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _DelayedWallpaper key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(frame.future);

  void complete(Color color) {
    final recorder = ui.PictureRecorder();
    Canvas(recorder)
        .drawRect(const Rect.fromLTWH(0, 0, 2, 2), Paint()..color = color);
    final picture = recorder.endRecording();
    frame.complete(ImageInfo(image: picture.toImageSync(2, 2)));
    picture.dispose();
  }
}

void main() {
  for (final mode in ['cover', 'contain', 'blurred']) {
    for (final memorySaver in [false, true]) {
      testWidgets(
        'keeps the previous slide until decoded: $mode economy=$memorySaver',
        (tester) async {
          Future<void> show(ImageProvider? image) async {
            await tester.pumpWidget(
              MaterialApp(
                home: WallpaperBackground(
                  image: image,
                  mode: mode,
                  memorySaver: memorySaver,
                  gradient: const LinearGradient(
                    colors: [Colors.black, Colors.black],
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
          }

          List<ui.Image?> displayed() => tester
              .widgetList<RawImage>(find.byType(RawImage))
              .map((raw) => raw.image)
              .toList();

          final first = _DelayedWallpaper()..complete(Colors.red);
          await show(first);
          final previous = displayed();
          expect(previous, isNotEmpty);
          expect(previous.every((image) => image != null), isTrue);

          final second = _DelayedWallpaper();
          await show(second);
          expect(displayed(), previous);
          await tester.pump(const Duration(seconds: 2));
          expect(displayed(), previous);

          final third = _DelayedWallpaper();
          await show(third);
          second.complete(
            Colors.green,
          ); // A stale decode must not replace the slide.
          await tester.pumpAndSettle();
          expect(displayed(), previous);
          third.complete(const Color(0xff0000ff));
          await tester.pumpAndSettle();
          final replacement = displayed();
          expect(replacement.every((image) => image != null), isTrue);
          expect(replacement, isNot(previous));
          final bytes = await tester.runAsync(
            () async => (await replacement.last!.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!.buffer.asUint8List().take(4).toList(),
          );
          expect(bytes, [0, 0, 255, 255]);

          // Choosing a non-image source still removes the previous slide.
          await show(null);
          expect(find.byType(RawImage), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();
        },
      );
    }
  }
}
