import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flauncher/image_limits.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transparent_image/transparent_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'total read timeout cancels the stream even while chunks keep arriving',
    () {
      fakeAsync((time) {
        var cancelled = false;
        final input = StreamController<List<int>>(
          onCancel: () async {
            cancelled = true;
          },
        );
        Object? failure;
        readBoundedImage(
          input.stream,
          timeout: const Duration(seconds: 8),
        ).then<void>(
          (_) => fail('incomplete image accepted'),
          onError: (Object error) {
            failure = error;
          },
        );
        time.flushMicrotasks();
        for (var i = 0; i < 8; i++) {
          input.add([i]);
          time.elapse(const Duration(seconds: 1));
        }
        time.flushMicrotasks();
        expect(failure, isA<TimeoutException>());
        expect(cancelled, isTrue);
        input.close();
        time.flushMicrotasks();
      });
    },
  );
  test('bounded stream accepts exact limit and rejects excess', () async {
    expect(
        await readBoundedImage(
            Stream.fromIterable([
              [1, 2],
              [3, 4]
            ]),
            limit: 4),
        [1, 2, 3, 4]);
    await expectLater(
        readBoundedImage(
            Stream.fromIterable([
              [1, 2],
              [3, 4]
            ]),
            limit: 3),
        throwsA(isA<ImageInputException>()));
  });
  test('invalid image fails without decoding pixels; valid header is accepted',
      () async {
    await validateImageBytes(kTransparentImage);
    await expectLater(validateImageBytes(kTransparentImage.sublist(0, 4)),
        throwsA(isA<ImageInputException>()));
  });
  test('decode dimensions use pixel ratio and cap each edge', () {
    final provider = MemoryImage(kTransparentImage);
    final resized = sizedImage(provider, const Size(200, 100), 2);
    expect(resized.width, 400);
    expect(resized.height, 200);
    expect(resized.policy, ResizeImagePolicy.fit);
    expect(resized.allowUpscaling, isFalse);
    expect(sizedImage(provider, const Size(10000, 10000), 2).width, 4096);
  });
}
