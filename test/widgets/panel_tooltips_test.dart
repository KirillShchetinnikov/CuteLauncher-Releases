import 'dart:ui' show PointerDeviceKind;

import 'package:flauncher/backup_sync_groups.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/menu_header_action.dart';
import 'package:flauncher/widgets/panel_tooltip.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/settings_style_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<SettingsService> settings() async {
    SharedPreferences.setMockInitialValues({});
    final result = SettingsService(await SharedPreferences.getInstance());
    addTearDown(result.dispose);
    return result;
  }

  test(
    'tooltips default off, persist, validate backup and reset with menu style',
    () async {
      final service = await settings();
      expect(service.panelTooltipsEnabled, isFalse);
      await service.setPanelTooltipsEnabled(true);
      final restored = SettingsService(await SharedPreferences.getInstance());
      addTearDown(restored.dispose);
      expect(restored.panelTooltipsEnabled, isTrue);
      final backup = service.exportSettingsMap();
      await service.setPanelTooltipsEnabled(false);
      await service.importSettingsMap(backup);
      expect(service.panelTooltipsEnabled, isTrue);
      await service.importSettingsMap({'panel_tooltips_enabled': 'invalid'});
      expect(service.panelTooltipsEnabled, isTrue);
      expect(
        backupSyncPartGroup('setting:panel_tooltips_enabled'),
        BackupSyncGroup.menuLayout,
      );
      await service.resetAppearanceSection('settings');
      expect(service.panelTooltipsEnabled, isFalse);
    },
  );

  testWidgets('shared switch changes the setting from the style page', (
    tester,
  ) async {
    final service = await settings();
    final appearance = AppearanceService(await SharedPreferences.getInstance());
    addTearDown(appearance.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: service),
          ChangeNotifierProvider.value(value: appearance),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SettingsStylePage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l = AppLocalizations.of(
      tester.element(find.byType(SettingsStylePage)),
    )!;
    final toggle = find.widgetWithText(RoundedSwitchListTile, l.panelTooltips);
    expect(toggle, findsOneWidget);
    expect(tester.widget<RoundedSwitchListTile>(toggle).value, isFalse);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(service.panelTooltipsEnabled, isTrue);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(service.panelTooltipsEnabled, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'live preference hides focus and hover hints without losing actions',
    (tester) async {
      final service = await settings();
      final semantics = tester.ensureSemantics();
      final focus = FocusNode();
      addTearDown(focus.dispose);
      var pressed = 0;
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: service,
          child: MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  MenuHeaderAction(
                    focusNode: focus,
                    autofocus: true,
                    tooltip: 'Настройки панели',
                    icon: const Icon(Icons.settings),
                    onPressed: () => pressed++,
                  ),
                  const PanelTooltip(
                    message: 'Состояние',
                    child: Icon(Icons.info),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isTrue);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Настройки панели'), findsNothing);
      expect(find.bySemanticsLabel('Настройки панели'), findsOneWidget);
      final primary = FocusManager.instance.primaryFocus;
      await service.setPanelTooltipsEnabled(true);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Настройки панели'), findsOneWidget);
      expect(FocusManager.instance.primaryFocus, same(primary));
      await service.setPanelTooltipsEnabled(false);
      await tester.pumpAndSettle();
      expect(find.text('Настройки панели'), findsNothing);
      expect(FocusManager.instance.primaryFocus, same(primary));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(pressed, 1);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(
        location: tester.getCenter(find.byIcon(Icons.info)),
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Состояние'), findsNothing);
      expect(find.bySemanticsLabel('Состояние'), findsOneWidget);
      await service.setPanelTooltipsEnabled(true);
      await tester.pumpAndSettle();
      await mouse.moveTo(const Offset(1, 500));
      await mouse.moveTo(tester.getCenter(find.byIcon(Icons.info)));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Состояние'), findsOneWidget);
      await service.setPanelTooltipsEnabled(false);
      await tester.pumpAndSettle();
      expect(find.text('Состояние'), findsNothing);
      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    },
  );
}
