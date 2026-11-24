import 'dart:async';
import 'dart:typed_data';

import 'package:flauncher/poster_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reorders pending loads by live focus and discards obsolete demand', () async {
    final queue = PosterQueue();
    addTearDown(queue.close);
    final completed = <String>[];
    final one = Completer<Uint8List?>();
    final two = Completer<Uint8List?>();
    var oldPriority = 1;
    var newPriority = 0;
    Future<Uint8List?> load(String name, int Function() priority, [Future<Uint8List?>? result]) =>
        queue.load(PosterDemand()..add(priority), () async {
          completed.add(name);
          return result == null ? Uint8List(1) : await result;
        });

    final active = [
      load('first', () => 1, one.future),
      load('second', () => 1, two.future),
    ];
    await Future<void>.delayed(Duration.zero);
    final old = load('old row', () => oldPriority);
    final visible = load('visible', () => 1);
    final focused = load('new focus', () => newPriority);
    oldPriority = -1;
    newPriority = 3;
    one.complete(null);
    expect(await old, isNull);
    await focused;
    await visible;
    expect(completed, ['first', 'second', 'new focus', 'visible']);
    two.complete(null);
    await Future.wait(active);
  });
}
