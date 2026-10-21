import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flauncher/content_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transparent_image/transparent_image.dart';

void main() {
  test(
    'content equality survives rereads but changes with bytes or scale',
    () async {
      final first = await contentImage(Uint8List.fromList([1, 2, 3]));
      final reread = await contentImage(Uint8List.fromList([1, 2, 3]));
      final changed = await contentImage(Uint8List.fromList([1, 2, 4]));
      final scaled = await contentImage(
        Uint8List.fromList([1, 2, 3]),
        scale: 2,
      );
      expect(first, reread);
      expect(first.hashCode, reread.hashCode);
      expect(first, isNot(changed));
      expect(first, isNot(scaled));
      expect(first, isNot(MemoryImage(first.bytes)));
      expect(MemoryImage(first.bytes), isNot(first));
    },
  );

  test(
    'large inputs fingerprint off-thread and concurrent rereads agree',
    () async {
      final bytes = Uint8List.fromList(
        List.generate(100000, (index) => index % 251),
      );
      final images = await Future.wait(
        List.generate(6, (_) => contentImage(Uint8List.fromList(bytes))),
      );
      expect(images.every((image) => image == images.first), isTrue);
      expect(images.first.fingerprint, sha256.convert(bytes).toString());
    },
  );

  testWidgets('encoded LRU rereads reuse the actual decoded cache entry', (
    tester,
  ) async {
    final cache = PaintingBinding.instance.imageCache;
    cache.clear();
    cache.clearLiveImages();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox).first);
    for (var reread = 0; reread < 12; reread++) {
      await tester.runAsync(() async {
        final provider = await contentImage(
          Uint8List.fromList(kTransparentImage),
        );
        await precacheImage(
          ResizeImage(provider, width: 40, height: 40),
          context,
        );
      });
      await tester.pump();
      expect(cache.currentSize, 1);
      expect(cache.pendingImageCount, 0);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    cache.clear();
    cache.clearLiveImages();
  });
}
