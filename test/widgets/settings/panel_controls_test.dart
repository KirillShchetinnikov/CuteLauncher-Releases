import 'package:flauncher/providers/remote_panel_service.dart';
import 'package:flauncher/panel_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/appearance_page.dart';
import 'package:flauncher/widgets/settings/panel_order_page.dart';
import 'package:flauncher/widgets/settings/color_palette_dialog.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';

void main() {
  late AppearanceService appearance;
  late SettingsService settings;
  late RemotePanelService panel;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    appearance = AppearanceService(prefs);
    settings = SettingsService(prefs);
    panel = RemotePanelService(prefs);
  });
  tearDown(() {
    appearance.dispose();
    settings.dispose();
    panel.dispose();
  });
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appearance),
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: panel),
        ],
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SizedBox(width: 350, child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final remote in [false, true]) {
    testWidgets('objects cross sides, keep focus and persist: remote=$remote', (tester) async {
      // Start with an empty left side, including disabled/unavailable objects.
      if (remote) {
        await panel.setPanelOrder([], PanelLayout.ids);
      } else {
        await appearance.setPanelOrder([], PanelLayout.ids);
      }
      await pump(tester, PanelOrderPage(remotePanel: remote));
      expect(find.text('Слева'), findsOneWidget);
      expect(find.text('Справа'), findsOneWidget);
      final tile = find.byKey(const ValueKey('settings'));
      final node = tester.widget<FocusableSettingsTile>(tile).focusNode!;
      node.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      final layout = remote ? panel.layout : appearance.appearance.panelLayout;
      expect(layout.left, ['settings']);
      expect(layout.right, isNot(contains('settings')));
      expect(node.hasFocus, isTrue);
      expect(tester.widget<FocusableSettingsTile>(tile).selected, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      final restored = remote
          ? RemotePanelService(panel.preferences).layout
          : AppearanceService(appearance.preferences).appearance.panelLayout;
      expect(restored.left, isEmpty);
      expect(restored.right.take(2), ['systemSettings', 'settings']);
      expect(node.hasFocus, isTrue);
      await Navigator.of(tester.element(find.byType(PanelOrderPage))).maybePop();
      await tester.pumpAndSettle();
      expect(tester.widget<FocusableSettingsTile>(tile).selected, isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('order help follows the list and is reachable with the remote', (tester) async {
    await pump(tester, const PanelOrderPage());
    final before = appearance.appearance.panelOrder('panelInfoOrder').toList();
    final last = find.byKey(ValueKey(before.last));
    tester.widget<FocusableSettingsTile>(last).focusNode!.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    final l = AppLocalizations.of(tester.element(find.byType(PanelOrderPage)))!;
    expect(find.text(l.panelOrderHint), findsOneWidget);
    expect(find.text('Подробнее'), findsNothing);
    expect(appearance.appearance.panelOrder('panelInfoOrder'), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'order includes disabled objects, moves with remote and Back exits move mode',
    (tester) async {
      await settings.setShowSystemSettingsInStatusBar(false);
      await pump(tester, const PanelOrderPage());
      expect(find.text('Настройки Android TV'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(appearance.appearance.panelOrder('panelButtonsOrder').take(2), [
        'systemSettings',
        'settings',
      ]);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(appearance.appearance.panelOrder('panelButtonsOrder').take(3), [
        'systemSettings',
        'inputs',
        'settings',
      ]);
      await Navigator.of(tester.element(find.byType(PanelOrderPage)))
          .maybePop();
      await tester.pumpAndSettle();
      expect(find.byType(PanelOrderPage), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(appearance.appearance.panelOrder('panelButtonsOrder').take(3), [
        'systemSettings',
        'inputs',
        'settings',
      ]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'sliders change transparency by one percent, vertical keys preserve values',
    (tester) async {
      await pump(tester, const AppearancePage(section: 'panel'));
      Focus.of(tester.element(find.text('Прозрачность панели'))).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(appearance.appearance.number('panelOpacity'), closeTo(.01, .0001));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(appearance.appearance.number('panelOpacity'), closeTo(.01, .0001));
      final textSlider = find.descendant(
        of: find.byKey(const Key('panel-text-transparency')),
        matching: find.byType(Slider),
      );
      await tester.ensureVisible(textSlider);
      Focus.of(
        tester.element(find.text('Прозрачность подложки текста и кнопок')),
      ).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(
        appearance.appearance.panelTextBackgroundOpacity,
        closeTo(.99, .0001),
      );
      expect(appearance.appearance.panelTextColor.a, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'palette has 100 unique colors and remote chooses the next cell',
    (tester) async {
      expect(appearancePalette.toSet().length, 100);
      await pump(tester, const AppearancePage(section: 'panel'));
      await tester.tap(find.text('Фон панели'));
      await tester.pumpAndSettle();
      expect(find.byType(ColorPaletteDialog), findsOneWidget);
      final grid = tester.widget<GridView>(find.byType(GridView));
      expect(
        (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
            .crossAxisCount,
        10,
      );
      expect(find.byType(InkWell), findsAtLeastNWidgets(100));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        appearance.appearance.color('panelColor')!.toARGB32(),
        appearancePalette[1],
      );
      expect(find.byType(ColorPaletteDialog), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
