import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/category_appearance.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flauncher/tile_appearance.dart';
import 'package:flauncher/widgets/settings/section_style_page.dart';

void main() {
  test('section background validates, imports and preserves independent overrides', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = AppearanceService(prefs);
    addTearDown(service.dispose);
    await service.set('sectionBackground', 0x80123456);
    await service.set('sectionOpacity', .5);
    await service.set('sectionRadius', 24);
    await service.setCategoryTile(1, 'sectionRadius', 64);
    expect(service.category(1).tiles, {'sectionRadius': 64});
    expect(service.tilesFor(1).sectionOpacity, .5);
    expect(service.tilesFor(2).sectionRadius, 24);
    final imported = compatibleSettings({
      tileAppearanceKey: prefs.getString(tileAppearanceKey),
      categoryAppearanceKey: prefs.getString(categoryAppearanceKey),
    }, {});
    final global = TileAppearance.decode(imported[tileAppearanceKey]);
    expect(global.sectionRadius, 24);
    expect(global.sectionDecoration().color!.a, closeTo(128 / 255 * .5, .001));
    expect(CategoryAppearance.decode(imported[categoryAppearanceKey])['1']['tiles'],
        {'sectionRadius': 64});
    for (final value in [-1, 65, double.nan, double.infinity, '24']) {
      expect(TileAppearance.validValues({'sectionRadius': value}), isEmpty);
    }
    for (final value in [-.1, 1.1, double.nan, double.infinity, '0.5']) {
      expect(TileAppearance.validValues({'sectionOpacity': value}), isEmpty);
    }
    await service.resetFields(['sectionOpacity', 'sectionRadius'], categoryId: 1);
    expect(service.tilesFor(1).sectionRadius, 24);
    expect(service.appearance.values['sectionBackground'], 0x80123456);
    expect(const TileAppearance().sectionOpacity, 1);
    expect(const TileAppearance().sectionRadius, 0);
    expect(const TileAppearance().sectionDecoration(fallbackColor: Color(0x80123456)).color,
        const Color(0x80123456));
    expect(const TileAppearance({'sectionBackground': 0, 'sectionOpacity': .5})
        .sectionDecoration().color!.a, 0);
  });

  test('category styles persist independently, import validates fields and reset clears them', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = AppearanceService(prefs);
    await service.setCategory(1, 'padding', 32);
    await service.setCategory(1, 'maxRows', 2);
    await service.setCategory(1, 'background', 0x807c4dff);
    await service.setCategory(2, 'padding', 8);
    await service.setCategory(2, 'maxRows', -1);
    final restored = AppearanceService(prefs);
    expect(restored.category(1).maxRows, 2);
    expect(restored.category(1).background!.toARGB32(), 0x807c4dff);
    expect(restored.category(2).padding, 8);
    expect(restored.category(2).maxRows, 0);
    final current = prefs.getString(categoryAppearanceKey)!;
    final imported = compatibleSettings({categoryAppearanceKey: jsonEncode({
      '1': {'padding': -1, 'maxRows': 0}, 'bad': {'padding': 10},
    })}, {categoryAppearanceKey: current});
    final values = CategoryAppearance.decode(imported[categoryAppearanceKey]);
    expect(values['1']['padding'], 32);
    expect(values['1']['maxRows'], 0);
    expect(values.containsKey('bad'), isFalse);
    expect(compatibleSettings({categoryAppearanceKey: 'invalid'}, {}), isEmpty);
    await service.reset();
    expect(service.category(1).padding, 0);
    expect(service.category(1).maxRows, 2);
    service.dispose(); restored.dispose();
  });
  testWidgets('category editor saves with remote and wraps long Russian labels', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final service = AppearanceService(await SharedPreferences.getInstance());
    await tester.pumpWidget(ChangeNotifierProvider.value(value: service,
      child: const MaterialApp(locale: Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SizedBox(width: 380, child: SectionStylePage(categoryId: 1))))));
    await tester.pumpAndSettle();
    final l = AppLocalizations.of(tester.element(find.byType(SectionStylePage)))!;
    final padding = find.text(l.categoryPadding);
    await tester.ensureVisible(padding);
    Focus.of(tester.element(padding)).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(service.tilesFor(1).number('sectionPadding'), 4);
    final alignment = find.text('Выровнять заголовки по плиткам');
    await tester.ensureVisible(alignment);
    await tester.tap(alignment);
    await tester.pumpAndSettle();
    expect(service.tilesFor(1).sectionTitleAligned, isTrue);
    expect(service.tilesFor(2).sectionTitleAligned, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
  });
}
