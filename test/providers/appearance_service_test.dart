import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/tile_appearance.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flauncher/category_appearance.dart';

void main() {
  test('tape row count saves layout and rows together and survives reload', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = AppearanceService(prefs);
    addTearDown(service.dispose);
    await service.setCategoryTile(1, 'radius', 24);
    var notifications = 0;
    service.addListener(() {
      notifications++;
      expect(service.category(1).rows, 4);
      expect(service.category(1).layout, 'rows');
    });
    await service.setTapeRows(1, 4);
    expect(notifications, 1);
    final restored = AppearanceService(prefs);
    addTearDown(restored.dispose);
    expect(restored.category(1).rows, 4);
    expect(restored.tilesFor(1).number('radius'), 24);
    await restored.setTapeRows(1, 1);
    expect(restored.category(1).layout, 'row');
    expect(restored.category(1).rows, 1);
    expect(restored.category(2).values, isEmpty);
  });
  test('focus, animation and inactive opacity are global even with saved local overrides', () async {
    final saved = jsonEncode({'1': {'useGlobalTiles': false, 'tiles': {
      'focusEffect': 'scale', 'focusScale': 1.4, 'focusShadow': true,
      'focusLift': .2, 'focusBorderColor': 0xff112233,
      'focusBorderStyle': 'solid', 'focusPulse': true, 'focusTransition': true,
      'animateReordering': true, 'inactiveOpacity': .8, 'size': 144,
    }}});
    SharedPreferences.setMockInitialValues({categoryAppearanceKey: saved});
    final service = AppearanceService(await SharedPreferences.getInstance());
    addTearDown(service.dispose);
    await service.set('focusEffect', 'border');
    await service.set('animateReordering', false);
    await service.set('inactiveOpacity', .3);
    for (final id in [1, 2]) {
      expect(service.tilesFor(id).values['focusEffect'], 'border');
      expect(service.tilesFor(id).animateReordering, isFalse);
      expect(service.tilesFor(id).number('inactiveOpacity'), .3);
    }
    expect(service.tilesFor(1).tileSize, 144);
    final imported = compatibleSettings({categoryAppearanceKey: saved}, {});
    final local = CategoryAppearance.decode(imported[categoryAppearanceKey])['1']['tiles'] as Map;
    expect(local.keys, ['size']);
    await service.setCategoryTile(1, 'focusEffect', 'scale');
    expect(service.tilesFor(1).values['focusEffect'], 'border');
  });
  test('category padding ignores former global value and keeps local values', () async {
    SharedPreferences.setMockInitialValues({tileAppearanceKey: '{"sectionPadding":32}'});
    final service = AppearanceService(await SharedPreferences.getInstance());
    addTearDown(service.dispose);
    expect(service.tilesFor(1).number('sectionPadding'), isNull);
    await service.setCategoryTile(1, 'sectionPadding', 12);
    expect(service.tilesFor(1).number('sectionPadding'), 12);
    expect(service.tilesFor(2).number('sectionPadding'), isNull);
    await service.resetFields(['sectionPadding'], categoryId: 1);
    expect(service.tilesFor(1).number('sectionPadding'), isNull);
    await service.setCategory(1, 'padding', 8);
    expect(service.tilesFor(1).number('sectionPadding'), 8);
  });
  test('removed section memory is ignored when loading and importing settings', () {
    expect(TileAppearance.decode('{"rememberSection":true}').values, isEmpty);
    final imported = compatibleSettings(
      {tileAppearanceKey: '{"rememberSection":true}'}, {},
    );
    expect(TileAppearance.decode(imported[tileAppearanceKey]).values, isEmpty);
  });

  test('section position caps saved and imported values at 70 percent', () {
    expect(const TileAppearance().sectionPosition, 0.5);
    for (final value in [0, 0.5, 0.70, 0.8, 1]) {
      final expected = value.clamp(0, 0.70);
      expect(TileAppearance({'sectionPosition': value}).sectionPosition, expected);
      expect(TileAppearance.decode(jsonEncode({'sectionPosition': value})).sectionPosition, expected);
      final imported = compatibleSettings(
        {tileAppearanceKey: jsonEncode({'sectionPosition': value})}, {},
      );
      expect(TileAppearance.decode(imported[tileAppearanceKey]).sectionPosition, expected);
    }
  });

  test('section reset preserves other styles, category overrides and zero gaps through import', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = AppearanceService(prefs);
    addTearDown(service.dispose);
    await service.set('horizontalGap', 0);
    await service.set('verticalGap', 0);
    await service.set('noticeOpacity', .4);
    await service.set('settingsTextSize', 24);
    await service.setCategoryTile(1, 'horizontalGap', 0);
    final imported = compatibleSettings(
      {tileAppearanceKey: prefs.getString(tileAppearanceKey)}, {});
    expect(TileAppearance.decode(imported[tileAppearanceKey]).horizontalGap, 0);
    expect(TileAppearance.decode(imported[tileAppearanceKey]).verticalGap, 0);
    await service.resetFields(['noticeOpacity']);
    expect(service.appearance.number('noticeOpacity'), isNull);
    expect(service.appearance.number('settingsTextSize'), 24);
    expect(service.category(1).tiles['horizontalGap'], 0);
    await service.resetFields(['horizontalGap', 'verticalGap']);
    expect(service.appearance.horizontalGap, 16);
    expect(service.appearance.verticalGap, 16);
    expect(service.category(1).tiles['horizontalGap'], 0);
    expect(TileAppearance({'noticeWidth': 500, 'settingsTextSize': 20}).active, false);
    expect(TileAppearance.validValues({'noticeWidth': 9999, 'settingsOpacity': -1}), isEmpty);
  });

  test('category tile sizes are independent and survive global toggling and import', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = AppearanceService(prefs);
    addTearDown(service.dispose);
    await service.set('size', 128);
    await service.setUseGlobalTiles(1, false);
    await service.setCategoryTile(1, 'size', 80);
    await service.set('size', 160);
    expect(service.tilesFor(1).tileSize, 80);
    expect(service.tilesFor(2).tileSize, 160);
    await service.setUseGlobalTiles(1, true);
    expect(service.tilesFor(1).tileSize, 160);
    await service.setUseGlobalTiles(1, false);
    expect(service.tilesFor(1).tileSize, 80);
    final imported = compatibleSettings(
      {categoryAppearanceKey: prefs.getString(categoryAppearanceKey)},
      {categoryAppearanceKey: '{}'},
    );
    expect(CategoryAppearance.decode(imported[categoryAppearanceKey])['1']['tiles']['size'], 80);
    expect(service.category(1).useGlobalTiles, isFalse);
    await service.setCategoryTile(1, 'size', 1000);
    expect(service.tilesFor(1).tileSize, 80);
  });
  test(
    'appearance import preserves absent and invalid fields individually',
    () {
      final current = jsonEncode({
        'radius': 16,
        'opacity': 0.5,
        'iconScale': 0.8,
      });
      final result = compatibleSettings(
        {
          tileAppearanceKey: jsonEncode({
            'radius': -1,
            'opacity': 0,
            'iconScale': 'large',
            'labelSize': 16,
          }),
        },
        {tileAppearanceKey: current},
      );
      final appearance = TileAppearance.decode(result[tileAppearanceKey]);
      expect(appearance.number('radius'), 16);
      expect(appearance.opacity, 0);
      expect(appearance.iconScale, 0.8);
      expect(appearance.labelSize, 16);
      expect(
        compatibleSettings(
          {tileAppearanceKey: 'invalid'},
          {tileAppearanceKey: current},
        )[tileAppearanceKey],
        current,
      );
    },
  );

  test(
    'reset removes appearance only and preserves categories and other settings',
    () async {
      SharedPreferences.setMockInitialValues({
        'app_banner_shape': 'capsule',
        'show_app_names_below_icons': false,
        'unrelated': 'retained',
      });
      final prefs = await SharedPreferences.getInstance();
      final service = AppearanceService(prefs);
      try {
        await service.set('radius', 32);
        await service.set('opacity', 0.25);
        expect(service.appearance.opacity, 0.25);
        await service.reset();
        expect(service.appearance.active, isFalse);
        expect(prefs.getString('app_banner_shape'), 'capsule');
        expect(prefs.getBool('show_app_names_below_icons'), isFalse);
        expect(prefs.getString('unrelated'), 'retained');
      } finally {
        service.dispose();
      }
    },
  );

  test('bounds prevent extreme geometry and unknown settings', () {
    expect(
      TileAppearance.validValues({
        'radius': double.infinity,
        'horizontalGap': -1,
        'iconScale': 5,
        'labelSize': 200,
        'blurTiles': 'true',
        'unknown': 1,
      }),
      isEmpty,
    );
    expect(TileAppearance.decode('{"size":"large"}').columns(1), 1);
    expect(TileAppearance.decode('{"size":"compact"}').columns(12), 12);
  });

  test('panel settings survive persistence and backup without enabling tile overrides', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = AppearanceService(prefs);
    addTearDown(service.dispose);
    for (final entry in {
      'panelTextSize': 24,
      'panelFont': 'monospace',
      'panelTextBackground': false,
      'panelTextBackgroundColor': 0xff14532d,
      'panelTextColor': 0xff80cbc4,
      'panelSwapSides': true,
      'panelOpacity': 0,
      'panelTextBackgroundOpacity': .37,
      'panelButtonsOrder': [
        'network',
        'settings',
        'traffic',
        'inputs',
        'notifications',
        'systemSettings',
      ],
      'blurPanel': true,
    }.entries) {
      await service.set(entry.key, entry.value);
    }
    expect(service.appearance.active, isFalse);
    final imported = compatibleSettings({
      tileAppearanceKey: prefs.getString(tileAppearanceKey)!,
    }, {});
    final restored = TileAppearance.decode(imported[tileAppearanceKey]);
    expect(restored.values, service.appearance.values);
    expect(restored.panelItemBackground, Colors.transparent);
    expect(restored.panelTextStyle.fontFamily, 'PanelMono');
    await service.set('panelStyle', 'shared');
    await service.set('labelSize', 14);
    await service.set('labelColor', 0xff000000);
    await service.set('blurTiles', false);
    expect(service.appearance.panelTextSize, 24);
    expect(service.appearance.panelTextColor, const Color(0xff80cbc4));
    expect(service.appearance.blurPanel, isTrue);
    await service.set('panelStyle', 'independent');
    expect(service.appearance.panelTextSize, 24);
    expect(service.appearance.blurPanel, isTrue);
    expect(
      TileAppearance.validValues({
        'panelTextSize': 25,
        'panelFont': 'unknown',
        'panelTextColor': -1,
        'panelSwapSides': 1,
        'panelTextBackgroundOpacity': 1.01,
      }),
      isEmpty,
    );
  });
  test('side order survives backup, accepts mixed objects and ignores old swap', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = AppearanceService(prefs);
    addTearDown(service.dispose);
    await service.setPanelOrder(['time', 'network'], ['settings', 'date']);
    final imported = compatibleSettings({
      tileAppearanceKey: prefs.getString(tileAppearanceKey)!,
    }, {});
    final restored = TileAppearance.decode(imported[tileAppearanceKey]);
    expect(restored.panelLayout.left.take(2), ['time', 'network']);
    expect(restored.panelLayout.right.take(2), ['settings', 'date']);
    expect({...restored.panelLayout.left, ...restored.panelLayout.right}.length, 11);
    expect(restored.panelLayout.left, isNot(contains('settings')));
    expect(TileAppearance.decode('{"panelSwapSides":true}').values, isEmpty);
    await service.setPanelOrder([], [...TileAppearance.panelButtons, ...TileAppearance.panelInfo]);
    expect(AppearanceService(prefs).appearance.panelLayout.left, isEmpty);
  });

  test(
    'order removes duplicates and unknown objects, appends missing objects',
    () {
      final appearance = TileAppearance.decode(
        '{"panelButtonsOrder":["inputs","inputs","unknown",42,"settings"]}',
      );
      expect(appearance.panelOrder('panelButtonsOrder'), [
        'inputs',
        'settings',
        'systemSettings',
        'notifications',
        'sleepTimer',
        'nightMode',
        'network',
        'traffic',
      ]);
      expect(appearance.panelOrder('panelInfoOrder'), [
        'weather',
        'date',
        'time',
      ]);
    },
  );
  test(
    'item opacity affects background only and legacy shared style is ignored',
    () {
      final appearance = TileAppearance.decode(
        '{"panelStyle":"shared","labelSize":12,"panelTextSize":22,"panelTextBackgroundOpacity":0.37}',
      );
      expect(appearance.panelTextSize, 22);
      expect(appearance.panelItemBackground.a, closeTo(.37, .005));
      expect(appearance.panelTextColor.a, 1);
      expect(appearance.values.containsKey('panelStyle'), isFalse);
    },
  );
}
