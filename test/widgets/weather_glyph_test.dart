import 'dart:ui' as ui;
import 'dart:io';

import 'package:flauncher/models/weather_data.dart';
import 'package:flauncher/tile_appearance.dart';
import 'package:flauncher/widgets/weather_glyph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/design_fixture.dart';

void main() {
  testWidgets(
    'every custom set paints distinct conditions using the selected tint',
    (tester) async {
      const capture = bool.fromEnvironment('WEATHER_ICON_CAPTURE');
      if (capture) await loadDesignFonts(tester);
      const tint = Color(0xff3978ba);
      final packs = WeatherIconPack.values
          .where((pack) => pack != WeatherIconPack.standard)
          .toList();
      await tester.pumpWidget(
        MaterialApp(
          home: Wrap(
            children: [
              for (final pack in packs)
                for (final condition in WeatherCondition.values)
                  WeatherGlyph(
                    key: ValueKey((pack, condition)),
                    condition: condition,
                    pack: pack,
                    size: 24,
                    color: tint,
                  ),
            ],
          ),
        ),
      );

      await tester.runAsync(() async {
        final masks = <(WeatherIconPack, WeatherCondition), String>{};
        final sheet = capture ? ui.PictureRecorder() : null;
        final sheetCanvas = sheet == null ? null : Canvas(sheet);
        sheetCanvas?.drawColor(const Color(0xfff2f5fa), BlendMode.src);
        void caption(String text, Offset offset, double width) {
          final label = TextPainter(
            text: TextSpan(text: text, style: const TextStyle(
              fontFamily: 'Roboto', fontSize: 11, color: Color(0xff263547))),
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: width);
          label.paint(sheetCanvas!, offset);
          label.dispose();
        }
        for (final pack in packs) {
          for (final condition in WeatherCondition.values) {
            final glyph = find.byKey(ValueKey((pack, condition)));
            final painter = tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: glyph,
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter!;
            if (sheetCanvas != null) {
              final x = 118.0 + condition.index * 66;
              final y = packs.indexOf(pack) * 74.0;
              if (condition == WeatherCondition.values.first) {
                caption(switch (pack) {
                  WeatherIconPack.outline => 'Контурные',
                  WeatherIconPack.solid => 'С заливкой',
                  WeatherIconPack.duotone => 'Двухтонные',
                  WeatherIconPack.pixel => 'Пиксельные',
                  WeatherIconPack.geometric => 'Геометрические',
                  WeatherIconPack.circled => 'В круге',
                  _ => pack.name,
                }, Offset(12, y + 20), 100);
              }
              sheetCanvas.save();
              sheetCanvas.translate(x + 12, y + 5);
              painter.paint(sheetCanvas, const Size.square(36));
              sheetCanvas.restore();
              caption(switch (condition) {
                WeatherCondition.unknown => 'Нет данных',
                WeatherCondition.sun => 'Солнце',
                WeatherCondition.moon => 'Ночь',
                WeatherCondition.partlyCloudy => 'Солнце\nи облака',
                WeatherCondition.cloudy => 'Облака',
                WeatherCondition.rain => 'Дождь',
                WeatherCondition.snow => 'Снег',
                WeatherCondition.storm => 'Гроза',
                WeatherCondition.fog => 'Туман',
                WeatherCondition.wind => 'Ветер',
              }, Offset(x, y + 46), 64);
            }
            final recorder = ui.PictureRecorder();
            painter.paint(Canvas(recorder), const Size.square(24));
            final picture = recorder.endRecording();
            final image = picture.toImageSync(24, 24);
            try {
              final data = (await image.toByteData())!;
              final alpha = <int>[];
              for (var i = 0; i < data.lengthInBytes; i += 4) {
                alpha.add(data.getUint8(i + 3));
                if (alpha.last == 255) expect(data.getUint32(i), 0x3978baff);
              }
              expect(
                alpha.where((a) => a == 255).length,
                greaterThan(5),
                reason: '$pack $condition',
              );
              if (pack == WeatherIconPack.duotone) {
                expect(
                  alpha.where((a) => a >= 120 && a <= 124).length,
                  greaterThan(5),
                );
              }
              expect(alpha.first, 0);
              masks[(pack, condition)] = String.fromCharCodes(alpha);
            } finally {
              image.dispose();
              picture.dispose();
            }
          }
        }
        expect(masks.values.toSet(), hasLength(masks.length));
        if (sheet != null) {
          final picture = sheet.endRecording();
          final image = picture.toImageSync(780, packs.length * 74);
          try {
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File('.local/weather-icons-preview.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(png!.buffer.asUint8List());
          } finally {
            image.dispose();
            picture.dispose();
          }
        }
      });
    },
  );
}
