import 'dart:async';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/slideshow_service.dart';
import 'package:flauncher/settings_import.dart';

void main() {
  testWidgets('sequential and shuffle cycles avoid repeats, skip corruption and retain last image', (tester) async {
    await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues({'background_source': 'gradient', 'slideshow_folder': 'content://fixture/tree/root'});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      var unavailable = false;
      var recursive = false;
      final read = <String>[];
      final service = SlideshowService(prefs, settings, random: Random(7),
        list: (_, include) async { recursive = include; if (unavailable) throw StateError('offline'); return ['a', 'b', 'c', 'zbad']; },
        read: (uri) async { read.add(uri); return uri == 'zbad' ? Uint8List(0) : kTransparentImage; });
      try {
        await settings.setBackgroundSource('slideshow');
        while (service.loading) { await Future<void>.delayed(const Duration(milliseconds: 1)); }
        expect(service.image, isNotNull);
        expect(recursive, isTrue);
        await service.advance(); await service.advance();
        expect(read.take(3), ['a', 'b', 'c']);
        final previous = service.image;
        await service.advance(); // corrupt tail of the cycle
        expect(service.failed, isTrue);
        expect(service.image, same(previous));
        await service.configure(randomOrder: true, recursive: false, interval: 30);
        expect(recursive, isFalse);
        expect(service.interval, 30);
        read.clear();
        for (var i = 0; i < 8; i++) { await service.advance(); }
        final good = read.where((uri) => uri != 'zbad').toList();
        for (var i = 1; i < good.length; i++) { expect(good[i], isNot(good[i - 1])); }
        unavailable = true;
        final last = service.image;
        await service.reload();
        expect(service.failed, isTrue);
        expect(service.image, same(last));
        service.didChangeAppLifecycleState(AppLifecycleState.paused);
        read.clear(); await service.advance();
        expect(read, isEmpty);
        expect(compatibleSettings({'slideshow_folder': 'content://other', 'slideshow_interval': 30}, {}), {'slideshow_interval': 30});
      } finally { service.dispose(); settings.dispose(); }
    });
  });

  testWidgets('late loading cannot change wallpaper after background or disposal', (tester) async {
    await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues({'background_source': 'gradient', 'slideshow_folder': 'content://fixture/tree/root'});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      final pending = Completer<Uint8List>();
      final service = SlideshowService(prefs, settings, list: (_, _) async => ['a'], read: (_) => pending.future);
      await settings.setBackgroundSource('slideshow');
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      pending.complete(kTransparentImage);
      while (service.loading) { await Future<void>.delayed(const Duration(milliseconds: 1)); }
      expect(service.image, isNull);
      service.dispose(); settings.dispose();
    });
  });

  testWidgets('folder cancellation preserves selection and replacement releases old grant', (tester) async {
    await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues({'slideshow_folder': 'content://old/tree/root'});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      final calls = <MethodCall>[];
      String? selected;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('me.efesser.flauncher/method'), (call) async {
          calls.add(call); return call.method == 'pickWallpaperFolder' ? selected : null;
        });
      final service = SlideshowService(prefs, settings);
      try {
        await service.pickFolder(); expect(service.folder, 'content://old/tree/root');
        selected = 'content://new/tree/root';
        await service.pickFolder(); expect(service.folder, selected);
        expect(calls.last.method, 'releaseWallpaperFolder');
        expect(calls.last.arguments, {'uri': 'content://old/tree/root'});
        await service.reset();
        expect(service.folder, isEmpty);
        expect(service.image, isNull);
        expect(calls.last.arguments, {'uri': 'content://new/tree/root'});
      } finally {
        service.dispose(); settings.dispose();
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('me.efesser.flauncher/method'), null);
      }
    });
  });
}
