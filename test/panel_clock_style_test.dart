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
  test(
    'clock overrides validate bounds, fields and different font families',
    () {
      expect(
        PanelClockStyle.validValues({
          'size': 41,
          'radius': -1,
          'font': 'unknown',
          'color': -1,
          'opacity': double.nan,
          'weight': 500,
          'glow': 'true',
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
      expect(PanelClockStyle.fonts.values.toSet().length, 9);
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
      final clock = PanelClockStyle(PanelClockStyle.presets['digital']!);
      expect(clock.textStyle(const TextStyle()).fontFamily, 'PanelMono');
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

  test('shared clock and separate calendar choices survive backup', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final appearance = AppearanceService(prefs);
    final remote = RemotePanelService(prefs);
    addTearDown(appearance.dispose);
    addTearDown(remote.dispose);
    expect(appearance.appearance.dateCalendar, isFalse);
    expect(remote.dateCalendar, isFalse);
    await appearance.set('panelClockStyle', {
      'font': 'serif',
      'size': 30,
      'background': false,
    });
    await appearance.set('panelDateCalendar', true);
    await remote.set('clockStyle', {'font': 'monospace', 'size': 14});
    await remote.set('dateCalendar', false);
    remote.reload();
    expect(appearance.appearance.clockStyle.values['size'], 30);
    expect(remote.dateCalendar, isFalse);
    final imported = compatibleSettings({
      tileAppearanceKey: prefs.getString(tileAppearanceKey)!,
    }, {});
    final restored = TileAppearance.decode(imported[tileAppearanceKey]);
    expect(restored.clockStyle.values['size'], 30);
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
