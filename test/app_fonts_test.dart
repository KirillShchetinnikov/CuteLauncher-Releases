import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/app_fonts.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/panel_clock_style.dart';
import 'package:flauncher/tile_appearance.dart';
import 'package:flauncher/widgets/settings/language_font_choice.dart';

Set<int> fontCharacters(String path) {
  final bytes = ByteData.sublistView(File(path).readAsBytesSync());
  int u16(int o) => bytes.getUint16(o);
  int u32(int o) => bytes.getUint32(o);
  var base = 0;
  for (var o = 12; o < 12 + 16 * u16(4); o += 16) {
    if (u32(o) == 0x636d6170) base = u32(o + 8); // cmap
  }
  expect(base, greaterThan(0));
  final result = <int>{};
  for (var i = 0; i < u16(base + 2); i++) {
    final sub = base + u32(base + 8 + 8 * i);
    if (u16(sub) == 12) {
      for (var j = 0; j < u32(sub + 12); j++) {
        final o = sub + 16 + 12 * j;
        for (var c = u32(o); c <= u32(o + 4); c++) {
          result.add(c);
        }
      }
    } else if (u16(sub) == 4) {
      final n = u16(sub + 6) ~/ 2;
      final ends = sub + 14, starts = ends + 2 * n + 2;
      final delta = starts + 2 * n, offsets = delta + 2 * n;
      for (var j = 0; j < n; j++) {
        for (var c = u16(starts + 2 * j); c <= u16(ends + 2 * j); c++) {
          final r = u16(offsets + 2 * j);
          final glyph = r == 0
              ? (c + u16(delta + 2 * j)) % 65536
              : u16(offsets + 2 * j + r + 2 * (c - u16(starts + 2 * j)));
          if (glyph != 0) result.add(c);
        }
      }
    }
  }
  return result;
}

void main() {
  test('removed Pixel choices fall back safely without affecting other Medeo fonts', () {
    const locale = Locale('ru');
    expect(
      AppFonts.available(locale, panel: true),
      isNot(contains('medeo-pixel')),
    );
    expect(AppFonts.family('medeo-pixel', locale), 'Manrope');
    final values = TileAppearance.validValues({
      'settingsInterfaceFont': 'medeo-pixel',
      'panelFont': 'medeo-pixel',
    });
    expect(values, isEmpty);
    expect(PanelClockStyle.validValues({'font': 'medeo-pixel'}), isEmpty);
    expect(
      TileAppearance(values).panelTextStyleFor(locale).fontFamily,
      'PanelSans',
    );
    for (final id in ['medeo-sans', 'medeo-mono']) {
      expect(AppFonts.available(locale), contains(id));
      expect(
        TileAppearance.validValues({
          'settingsInterfaceFont': id,
        })['settingsInterfaceFont'],
        id,
      );
    }
  });

  test('Medeo clock weights match the bundled font axes', () {
    for (final id in ['medeo-sans', 'medeo-mono']) {
      expect(
        PanelClockStyle({'font': id}).availableWeights(const TextStyle()),
        [for (var weight = 100; weight <= 900; weight += 100) weight],
      );
    }
  });

  test('offered fonts cover actual translated letters and combining marks', () {
    const files = {
      'google-sans': [
        'googlesans-400',
        'googlesans-500',
        'googlesans-600',
        'googlesans-700',
      ],
      'medeo-sans': ['medeo-sans', 'medeo-sans-italic'],
      'medeo-mono': ['medeo-mono', 'medeo-mono-italic'],
      'onest': ['onest'],
      'manrope': ['manrope'],
      'outfit': ['outfit'],
      'sans-serif': ['sans'],
      'serif': ['serif'],
      'monospace': ['mono'],
      'sans-serif-condensed': ['condensed'],
    };
    final letters = RegExp(r'[\p{L}\p{M}]', unicode: true);
    for (final entry in files.entries) {
      for (final file in entry.value) {
        final characters = fontCharacters('assets/fonts/$file.ttf');
        for (final locale in AppLocalizations.supportedLocales) {
          if (!AppFonts.supports(entry.key, locale)) continue;
          final arb = jsonDecode(
            File('lib/l10n/app_${locale.languageCode}.arb').readAsStringSync(),
          ) as Map;
          final required = <int>{};
          for (final e in arb.entries) {
            if (e.key.toString().startsWith('@') || e.value is! String) {
              continue;
            }
            required.addAll(
              letters
                  .allMatches(e.value as String)
                  .expand((m) => m.group(0)!.runes),
            );
          }
          expect(
            required.difference(characters),
            isEmpty,
            reason: '$file / $locale',
          );
        }
      }
    }
    expect(AppFonts.available(const Locale('ru')), [
      'system',
      'medeo-sans',
      'medeo-mono',
      'google-sans',
      'onest',
      'manrope',
    ]);
    expect(AppFonts.available(const Locale('en')), contains('outfit'));
    expect(AppFonts.available(const Locale('ar')), ['system']);
    expect(AppFonts.available(const Locale('ja'), panel: true), ['system']);
  });

  test('saved fonts validate and resolve safely after language changes', () {
    for (final id in AppFonts.interfaceIds) {
      final values = TileAppearance.validValues({
        'settingsInterfaceFont': id,
        'panelFont': id,
      });
      expect(values['settingsInterfaceFont'], id);
      expect(values['panelFont'], id);
      final clock = PanelClockStyle.validValues({'font': id});
      expect(clock['font'], id);
    }
    final appearance = TileAppearance({'panelFont': 'outfit'});
    expect(
      appearance.panelTextStyleFor(const Locale('ru')).fontFamily,
      'Manrope',
    );
    expect(
      appearance.panelTextStyleFor(const Locale('ja')).fontFamily,
      'Roboto',
    );
    expect(
      appearance.panelTextStyleFor(const Locale('en')).fontFamily,
      'Outfit',
    );
    expect(appearance.values['panelFont'], 'outfit');
    expect(
      const PanelClockStyle({'font': 'outfit'})
          .textStyle(const TextStyle(), locale: const Locale('ru'))
          .fontFamily,
      'Manrope',
    );
    expect(AppFonts.family('outfit', const Locale('ru')), 'Manrope');
  });

  testWidgets('picker hides incompatible fonts and updates with locale', (
    tester,
  ) async {
    var language = const Locale('ru');
    String? selected;
    Future<void> show() async {
      await tester.pumpWidget(
        MaterialApp(
          locale: language,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LanguageFontChoice(
              title: 'Font',
              value: 'outfit',
              onChanged: (v) => selected = v,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Font'));
      await tester.pumpAndSettle();
    }

    await show();
    expect(find.text('Outfit'), findsNothing);
    expect(find.text('Google Sans'), findsOneWidget);
    expect(find.text('Onest'), findsOneWidget);
    expect(find.text('Medeo Sans'), findsOneWidget);
    expect(find.text('Medeo Mono'), findsOneWidget);
    expect(find.text('Medeo Pixel'), findsNothing);
    await tester.tap(find.text('Onest'));
    await tester.pumpAndSettle();
    expect(selected, 'onest');
    language = const Locale('en');
    await show();
    expect(find.text('Outfit'), findsWidgets);
  });

  testWidgets('theme uses resolved locale without changing saved preference', (
    tester,
  ) async {
    var language = const Locale('ru');
    String? family;
    Future<void> show() async {
      await tester.pumpWidget(
        MaterialApp(
          locale: language,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (_, child) =>
              LanguageFontTheme(font: 'outfit', child: child!),
          home: Builder(
            builder: (context) {
              family = Theme.of(context).textTheme.bodyMedium!.fontFamily;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await show();
    expect(family, 'Manrope');
    language = const Locale('en');
    await show();
    expect(family, 'Outfit');
  });
}
