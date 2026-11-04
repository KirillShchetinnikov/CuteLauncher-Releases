import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flauncher/apod_wallpaper.dart';
import 'package:flauncher/image_limits.dart';
import 'package:flauncher/providers/online_wallpaper_service.dart';

class _RealNetwork extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('live NASA APOD feed and image download pass the launcher decoder and limits', () async {
    await HttpOverrides.runWithHttpOverrides(() async {
      final wallpaper = await fetchApodWallpaper();
      final bytes = await downloadWallpaper(wallpaper.uri);
      expect(bytes.length, inInclusiveRange(1, maximumImageInputBytes));
      expect(wallpaper.credit, contains('NASA APOD'));
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      try {
        expect(descriptor.width * descriptor.height, lessThanOrEqualTo(maximumImagePixels));
        // A daily image is not required to be 16:9 or Full HD.
        debugPrint('APOD ${wallpaper.date}: ${descriptor.width}x${descriptor.height}, ${bytes.length} bytes');
      } finally {
        descriptor.dispose();
        buffer.dispose();
      }
    }, _RealNetwork());
  }, skip: !const bool.fromEnvironment('APOD_LIVE'), timeout: const Timeout(Duration(seconds: 60)));
}
