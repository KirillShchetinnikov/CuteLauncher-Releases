import 'dart:typed_data';
import 'package:flauncher/image_byte_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LRU byte budget, replacement and oversized rejection', () {
    final evicted = <String>[];
    final cache =
        ImageByteCache(maximumBytes: 4, onEvict: (key, _) => evicted.add(key));
    cache['a'] = Uint8List(2);
    cache['b'] = Uint8List(2);
    expect(cache['a'], isNotNull);
    cache['c'] = Uint8List(2);
    expect(cache['b'], isNull);
    expect(evicted, ['b']);
    cache['huge'] = Uint8List(5);
    expect(cache.byteCount, 4);
    cache['a'] = Uint8List(1);
    expect(cache.byteCount, 3);
    cache.maximumBytes = 1;
    expect(cache.byteCount, lessThanOrEqualTo(1));
    cache.clear();
    expect(cache.byteCount, 0);
  });
  test('short view does not retain a larger backing buffer', () {
    final backing = Uint8List(1000);
    final cache = ImageByteCache(maximumBytes: 2);
    cache['view'] = Uint8List.sublistView(backing, 0, 2);
    expect(cache['view']!.buffer.lengthInBytes, 2);
    expect(cache.byteCount, 2);
  });

  test('entry bound includes empty negative results to prevent reload loops',
      () {
    final cache = ImageByteCache(maximumBytes: 100, maximumEntries: 2);
    for (final key in ['a', 'b', 'c']) {
      cache[key] = Uint8List(0);
    }
    expect(cache.length, 2);
    expect(cache['a'], isNull);
    expect(cache['c'], isEmpty);
  });
}
