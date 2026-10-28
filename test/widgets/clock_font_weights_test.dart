import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/panel_clock_style.dart';
import 'package:flauncher/widgets/panel_clock.dart';
import 'package:flauncher/widgets/date_time_widget.dart';

void main() {
  testWidgets(
    'unmodified standalone clock also applies the variable weight axis',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PanelClock(style: PanelClockStyle(), format: 'HH:mm'),
          ),
        ),
      );
      final style = tester
          .widget<DateTimeWidget>(find.byType(DateTimeWidget))
          .textStyle!;
      expect(style.fontWeight, FontWeight.w400);
      expect(style.fontVariations!.single.value, 400);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'every offered bundled weight produces different real glyph pixels',
    (tester) async {
      await tester.runAsync(() async {
        final duplicates = <String>[];
        const files = {
          'Medeo Sans': ['medeo-sans'],
          'Medeo Mono': ['medeo-mono'],
          'Outfit': ['outfit'],
          'Onest': ['onest'],
          'Manrope': ['manrope'],
          'PanelSans': ['sans'],
          'PanelSerif': ['serif'],
          'PanelMono': ['mono'],
          'PanelCondensed': ['condensed'],
          'Google Sans': [
            'googlesans-400',
            'googlesans-500',
            'googlesans-600',
            'googlesans-700',
          ],
        };
        for (final entry in files.entries) {
          final loader = FontLoader(entry.key);
          for (final file in entry.value) {
            loader.addFont(
              Future.value(
                ByteData.sublistView(
                  File('assets/fonts/$file.ttf').readAsBytesSync(),
                ),
              ),
            );
          }
          await loader.load();
        }
        for (final font in PanelClockStyle.fonts.entries.where(
          (e) => e.key != 'system',
        )) {
          for (final italic in [false, true]) {
            Uint8List? previous;
            final weights = PanelClockStyle({'font': font.key})
                .availableWeights(const TextStyle());
            for (final weight in weights) {
              final style = PanelClockStyle({
                'font': font.key,
                'weight': weight,
                'italic': italic,
              }).textStyle(const TextStyle(fontSize: 48, color: Colors.white));
              final painter = TextPainter(
                text: TextSpan(text: '12:34 Aa', style: style),
                textDirection: TextDirection.ltr,
              )..layout();
              final recorder = ui.PictureRecorder();
              painter.paint(Canvas(recorder), const Offset(8, 8));
              final picture = recorder.endRecording();
              final bitmap = await picture.toImage(500, 96);
              final data = (await bitmap.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              ))!;
              final bytes = Uint8List.fromList(
                data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
              );
              expect(bytes.any((value) => value != 0), isTrue);
              if (previous != null) {
                if (listEquals(previous, bytes)) {
                  duplicates.add('${font.key}, italic=$italic, weight=$weight');
                }
              }
              expect(duplicates, isEmpty);
              previous = bytes;
              bitmap.dispose();
              picture.dispose();
              painter.dispose();
            }
          }
        }
      });
    },
  );
}
