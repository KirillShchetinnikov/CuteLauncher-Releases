import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/panel_clock_style.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/remote_panel_service.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flauncher/tile_appearance.dart';

void main() {
  test('panel typography inherits by default and preserves custom overrides', () {
    const base = TextStyle(fontSize: 24, fontFamily: 'PanelSerif');
    const custom = {
      'font': 'monospace', 'size': 12, 'weight': 700, 'italic': true,
      'animate': true, 'showColon': false, 'glow': true, 'spacing': 8,
      'clockOnRight': true, 'clockColor': 0xff112233,
    };
    const inherited = PanelClockStyle.panel(custom);
    expect(inherited.inheritsPanelTypography, isTrue);
    expect(inherited.textStyle(base).fontFamily, base.fontFamily);
    expect(inherited.textStyle(base).fontSize, 24);
    expect(inherited.textStyle(base).fontWeight, FontWeight.w400);
    expect(inherited.textStyle(base).fontStyle, FontStyle.normal);
    expect(inherited.animate, isTrue);
    expect(inherited.showColon, isFalse);
    expect(const PanelClockStyle.panel().animate, isFalse);
    expect(inherited.clockColor, const Color(0xff112233));
    expect(inherited.spacing, 8);
    expect(inherited.clockOnRight, isTrue);
    expect(inherited.textStyle(base).shadows, isNotEmpty);
    expect(inherited.values, custom);
    final own = PanelClockStyle.panel(PanelClockStyle.validValues({
      ...custom, 'inheritPanelTypography': false,
    }, combined: true));
    expect(own.inheritsPanelTypography, isFalse);
    expect(own.textStyle(base).fontFamily, 'PanelMono');
    expect(own.textStyle(base).fontSize, 12);
    expect(own.textStyle(base).fontWeight, FontWeight.w700);
    expect(own.textStyle(base).fontStyle, FontStyle.italic);
    expect(own.animate, isTrue);
    expect(own.showColon, isFalse);
    expect(PanelClockStyle.validValues({'inheritPanelTypography': 'false'}), isEmpty);
    // The wallpaper profile keeps its own typography regardless of this flag.
    expect(const PanelClockStyle(custom).textStyle(base).fontSize, 12);
  });
  test(
    'weight ranges resolve after locale fallback and normalize old selections',
    () {
      const base = TextStyle(fontFamily: 'PanelSans');
      const google = PanelClockStyle({'font': 'google-sans', 'weight': 900});
    expect(google.availableWeights(base), [400, 500, 700]);
      expect(google.textStyle(base).fontWeight, FontWeight.w700);
      expect(google.textStyle(base).fontVariations, isEmpty);
      const manrope = PanelClockStyle({'font': 'manrope', 'weight': 100});
      expect(manrope.availableWeights(base), [
        200,
        300,
        400,
        500,
        600,
        700,
        800,
      ]);
      expect(manrope.textStyle(base).fontWeight, FontWeight.w200);
      expect(manrope.textStyle(base).fontVariations!.single.value, 200);
      const outfit = PanelClockStyle({'font': 'outfit', 'weight': 900});
      expect(
        outfit.textStyle(base, locale: const Locale('ru')).fontFamily,
        'Manrope',
      );
      expect(
        outfit
            .textStyle(base, locale: const Locale('ru'))
            .fontVariations!
            .single
            .value,
        800,
      );
      expect(outfit.availableWeights(base, locale: const Locale('ja')), [
        400,
        700,
      ]);
    },
  );
  test('abandoned glass settings are discarded on import', () {
    expect(TileAppearance.validValues({'panelGlassForeground': true}), isEmpty);
    expect(
      PanelClockStyle.validValues({'preset': 'glass', 'glass': true}),
      isEmpty,
    );
  });
  test(
    'clock overrides validate bounds, fields and different font families',
    () {
      expect(
        PanelClockStyle.validValues({
          'size': 41,
          'radius': -1,
          'font': 'unknown',
          'color': -1,
          'clockColor': 0x100000000,
          'opacity': double.nan,
          'weight': 550,
          'glow': 'true',
          'hoursColor': -1,
          'minutesColor': 0x100000000,
          'showColon': 'false',
          'splitColors': 'false',
        }),
        isEmpty,
      );
      for (final font in PanelClockStyle.fonts.keys) {
        final clock = PanelClockStyle({
          'font': font,
          'size': 40,
          'color': 0xff123456,
        });
        final text = clock.textStyle(
          const TextStyle(fontSize: 18, color: Colors.white),
        );
        expect(text.fontFamily, PanelClockStyle.fonts[font]);
        expect(text.fontSize, 40);
        expect(text.color, const Color(0xff123456));
      }
      expect(PanelClockStyle.fonts.values.toSet().length, 12);
      expect(PanelClockStyle.fonts['outfit'], 'Outfit');
      expect(
        const PanelClockStyle({'opacity': .5}).background(Colors.transparent),
        Colors.transparent,
      );
      expect(
        const PanelClockStyle({
          'inheritBackground': false,
          'background': true,
          'opacity': .5,
        }).background(Colors.transparent).a,
        closeTo(.5, .01),
      );
      expect(
        const PanelClockStyle({'inheritBackground': false, 'background': false})
            .background(Colors.white),
        Colors.transparent,
      );
      expect(
        const PanelClockStyle({
          'inheritBackground': false,
          'background': true,
          'opacity': 0,
        }).backgroundEnabled(Colors.white),
        isTrue,
      );
    },
  );

  test(
    'shared background ignores custom color, opacity and radius until disabled',
    () {
      const values = {
        'backgroundColor': 0xffff0000,
        'opacity': .2,
        'radius': 0,
      };
      const inherited = Color(0x80445566);
      const clock = PanelClockStyle(values);
      expect(clock.inheritBackground, isTrue);
      expect(clock.background(inherited), inherited);
      expect(clock.radius(18), 18);
      final custom = PanelClockStyle({...values, 'inheritBackground': false});
      expect(custom.background(inherited).r, 1);
      expect(custom.background(inherited).a, closeTo(.2, .01));
      expect(custom.radius(18), 0);
    },
  );

  test('shared clock and calendar settings survive backup', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final appearance = AppearanceService(prefs);
    final remote = RemotePanelService(prefs);
    addTearDown(appearance.dispose);
    addTearDown(remote.dispose);
    expect(appearance.appearance.dateCalendar, isFalse);
    await appearance.set('panelClockStyle', {
      'font': 'serif',
      'size': 30,
      'background': false,
      'color': 0xff112233,
      'clockColor': 0xff778899,
      'hoursColor': 0xff123456,
      'minutesColor': 0xffabcdef,
      'showColon': false,
    });
    await appearance.set('panelDateCalendar', true);
    await appearance.set('dateTextColor', 0xff66bb88);
    await appearance.set('weatherTextColor', 0xff556677);
    await remote.set('clockStyle', {'font': 'monospace', 'size': 14});
    await remote.set('dateCalendar', false);
    remote.reload();
    expect(appearance.appearance.clockStyle.values['size'], 30);
    final imported = compatibleSettings({
      tileAppearanceKey: prefs.getString(tileAppearanceKey)!,
    }, {});
    final restored = TileAppearance.decode(imported[tileAppearanceKey]);
    expect(restored.clockStyle.values['size'], 30);
    expect(restored.clockStyle.textStyle(const TextStyle()).color, const Color(0xff112233));
    expect(restored.clockStyle.clockColor, const Color(0xff778899));
    expect(restored.dateTextColor, const Color(0xff66bb88));
    expect(restored.weatherTextColor, const Color(0xff556677));
    expect(restored.clockStyle.hoursColor, const Color(0xff123456));
    expect(restored.clockStyle.minutesColor, const Color(0xffabcdef));
    expect(restored.clockStyle.showColon, isFalse);
    expect(restored.dateCalendar, isTrue);
    expect(restored.active, isFalse);
    expect(
      jsonDecode(
        prefs.getString(RemotePanelService.preferenceKey)!,
      )['clockStyle']['font'],
      'monospace',
    );
  });
}
