import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flauncher/app_artwork.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flauncher/widgets/app_artwork_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('small artwork softens edges, preserves uniform colours and bounds memory', () {
    final pixels = Uint8List(48 * 27 * 4);
    for (var y = 0; y < 27; y++) {
      for (var x = 0; x < 48; x++) {
        final p = (y * 48 + x) * 4;
        pixels[p] = x < 24 ? 255 : 0;
        pixels[p + 2] = x < 24 ? 0 : 255;
        pixels[p + 3] = 255;
      }
    }
    final soft = softenAppArtwork(pixels, 48, 27);
    expect(soft.lengthInBytes, 5184);
    expect(soft[(13 * 48 + 23) * 4], inExclusiveRange(0, 255));
    expect(soft[(13 * 48 + 23) * 4 + 2], greaterThan(0));
    expect(soft[0], 255);
    expect(pixels[(13 * 48 + 23) * 4 + 2], 0);
    expect(softenAppArtwork(Uint8List(4), 1, 1), [0, 0, 0, 255]);
    expect(() => softenAppArtwork(pixels, 1920, 1080), throwsArgumentError);
  });

  test('app background survives save, export/import and background reset', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);
    await settings.setBackgroundSource('app');
    expect(settings.backgroundSource, 'app');
    final restored = SettingsService(prefs);
    expect(restored.backgroundSource, 'app');
    final values = settings.exportSettingsMap();
    expect(values['background_source'], 'app');
    expect(compatibleSettings(values, {})['background_source'], 'app');
    await settings.setBackgroundSource('gradient');
    await settings.importSettingsMap(values);
    expect(settings.backgroundSource, 'app');
    await settings.resetAppearanceSection('background');
    expect(settings.backgroundSource, isNot('app'));
    settings.dispose();
    restored.dispose();
  });

  testWidgets('latest app produces a bounded texture without live blur and stops in background', (tester) async {
    Future<MemoryImage> picture(Color color) async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawColor(color, BlendMode.src);
      final drawing = recorder.endRecording();
      final image = await drawing.toImage(96, 54);
      try {
        final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        return MemoryImage(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      } finally { image.dispose(); drawing.dispose(); }
    }
    final images = await tester.runAsync(() async => [await picture(Colors.red), await picture(Colors.blue)]);
    final selected = ValueNotifier<ImageProvider?>(images!.first);
    await tester.pumpWidget(MaterialApp(home: AppArtworkBackground(images: selected,
      gradient: const LinearGradient(colors: [Colors.black, Colors.grey]))));
    selected.value = images.last;
    await tester.pump(const Duration(milliseconds: 130));
    for (var i = 0; i < 20 && find.byType(RawImage).evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump();
    }
    final texture = tester.widget<RawImage>(find.byType(RawImage)).image!;
    expect(texture.width, lessThanOrEqualTo(48));
    expect(texture.height, lessThanOrEqualTo(27));
    expect(find.byType(ImageFiltered), findsNothing);
    final data = await tester.runAsync(() => texture.toByteData(format: ui.ImageByteFormat.rawRgba));
    expect(data!.getUint8(2), 255);
    expect(data.getUint8(0), 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(texture.debugDisposed, isTrue);
    selected.value = images.first;
    await tester.pump(const Duration(seconds: 1));
    expect(texture.debugDisposed, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    for (var i = 0; i < 20 && find.byType(RawImage).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 130));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump();
    }
    expect(find.byType(RawImage), findsOneWidget);
    selected.value = MemoryImage(Uint8List.fromList([1, 2, 3]));
    await tester.pump(const Duration(milliseconds: 130));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    expect(find.byType(RawImage), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    selected.dispose();
  });
}
