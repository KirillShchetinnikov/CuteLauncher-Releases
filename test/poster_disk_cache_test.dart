import 'dart:io';

import 'package:flauncher/poster_disk_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transparent_image/transparent_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('retains source bytes across instances and distinguishes revalidation', () async {
    final root = await Directory.systemTemp.createTemp('poster-disk-test-');
    addTearDown(() => root.delete(recursive: true));
    final fetched = DateTime.now().subtract(const Duration(minutes: 2));
    final first = PosterDiskCache(() async => root);
    await first.write('content://source/poster', kTransparentImage, fetchedAt: fetched);

    final reopened = PosterDiskCache(() async => root);
    expect((await reopened.read('content://source/poster'))?.bytes, kTransparentImage);
    expect(
      (await reopened.read('content://source/poster', freshAfter: DateTime.now()))?.fresh,
      isFalse,
    );
    final refresh = DateTime.now();
    await reopened.write('content://source/poster', kTransparentImage, fetchedAt: refresh);
    expect((await reopened.read('content://source/poster', freshAfter: refresh))?.fresh, isTrue);
    expect((await reopened.stats())?.entries, 1);
    final size = (await reopened.stats())!.bytes;
    final other = await File('${root.path}/user-image.jpg').writeAsString('keep');
    expect(await reopened.clear(), size);
    expect(await other.readAsString(), 'keep');
    expect((await reopened.stats())?.entries, 0);
    expect(await reopened.clear(), 0);
    await reopened.remove('content://source/poster');
    expect(await reopened.read('content://source/poster'), isNull);
  });

  test('shrinking disk budget evicts the least recently used image', () async {
    final root = await Directory.systemTemp.createTemp('poster-disk-test-');
    addTearDown(() => root.delete(recursive: true));
    final cache = PosterDiskCache(() async => root);
    final fetched = DateTime.now().subtract(const Duration(seconds: 1));
    await cache.write('one', kTransparentImage, fetchedAt: fetched);
    await cache.write('two', kTransparentImage, fetchedAt: fetched);
    await cache.read('one');
    final stats = (await cache.stats())!;
    expect(stats.entries, 2);
    cache.maximumBytes = stats.bytes ~/ 2;
    expect((await cache.stats())?.entries, 1);
    expect(await cache.read('two'), isNull);
    expect((await cache.read('one'))?.bytes, kTransparentImage);
  });
}
