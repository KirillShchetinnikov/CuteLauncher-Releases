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
import 'package:flauncher/widgets/settings/section_style_page.dart';

void main() {
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
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(service.tilesFor(1).number('sectionPadding'), 4);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
  });
}
