import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/versioned_file_image.dart';
import 'package:flauncher/image_limits.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('replacing a wallpaper reloads its pixels through the resized image cache', () async {
    final root = await Directory.systemTemp.createTemp('cute-wallpaper-cache-');
    final file = File('${root.path}/wallpaper');
    Future<void> write(ui.Color color) async {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawRect(const ui.Rect.fromLTWH(0, 0, 1, 1), ui.Paint()..color = color);
      final picture = recorder.endRecording();
      final image = await picture.toImage(1, 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
      image.dispose(); picture.dispose();
    }
    Future<List<int>> pixels(int revision) async {
      final result = Completer<ImageInfo>();
      final stream = sizedImage(VersionedFileImage(file, revision), const ui.Size(1, 1), 1).resolve(ImageConfiguration.empty);
      final listener = ImageStreamListener((info, _) => result.complete(info), onError: (Object error, StackTrace? stack) => result.completeError(error));
      stream.addListener(listener);
      final info = await result.future;
      final bytes = await info.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      stream.removeListener(listener);
      info.dispose();
      return bytes!.buffer.asUint8List().toList();
    }
    try {
      await write(const ui.Color(0xffff0000));
      expect(await pixels(0), [255, 0, 0, 255]);
      await write(const ui.Color(0xff00ff00));
      expect(await pixels(1), [0, 255, 0, 255]);
    } finally { PaintingBinding.instance.imageCache.clear(); await root.delete(recursive: true); }
  });
}
