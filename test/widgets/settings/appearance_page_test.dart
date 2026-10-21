import 'package:flauncher/widgets/settings/settings_percentage_slider.dart';
import 'package:flauncher/providers/remote_panel_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/appearance_page.dart';

void main() {
  testWidgets('remote appearance inherits, edits independently and resets', (tester) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final panel = RemotePanelService(prefs);
    final appearance = AppearanceService(prefs);
    final settings = SettingsService(prefs);
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider.value(value: panel),
      ChangeNotifierProvider.value(value: appearance),
      ChangeNotifierProvider.value(value: settings),
    ], child: MaterialApp(locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: AppearancePage(section: 'panel', remotePanel: true)))));
    await tester.pumpAndSettle();
    final l = AppLocalizations.of(tester.element(find.byType(AppearancePage)))!;
    expect(find.text(l.panelBackground), findsNothing);
    await tester.tap(find.text(l.remotePanelInheritAppearance));
    await tester.pumpAndSettle();
    expect(panel.inheritAppearance, isFalse);
    expect(find.text(l.panelBackground), findsOneWidget);
    expect(find.text(l.autoHideTopPanel), findsNothing);
    expect(find.text(l.panelBlur), findsNothing);
    final slider = tester.widget<SettingsPercentageSlider>(find.byKey(const Key('panel-transparency')));
    slider.onChanged(.25);
    await tester.pumpAndSettle();
    expect(panel.ownAppearance.number('panelOpacity'), .75);
    expect(appearance.appearance.number('panelOpacity'), isNull);
    await tester.tap(find.text(l.remotePanelInheritAppearance));
    await tester.pumpAndSettle();
    expect(find.text(l.panelBackground), findsNothing);
    await tester.tap(find.text(l.remotePanelInheritAppearance));
    await tester.pumpAndSettle();
    expect(panel.ownAppearance.number('panelOpacity'), .75);
    await tester.tap(find.text(l.resetStyleSection));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.resetStyleSection).last);
    await tester.pumpAndSettle();
    expect(panel.inheritAppearance, isTrue);
    expect(panel.ownAppearance.values, isEmpty);
    expect(find.text(l.panelBackground), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    panel.dispose(); appearance.dispose(); settings.dispose();
  });
  testWidgets('reordering animation switch persists and applies to all sections', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final appearance = AppearanceService(prefs);
    final settings = SettingsService(prefs);
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider.value(value: appearance),
      ChangeNotifierProvider.value(value: settings),
    ], child: MaterialApp(locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: AppearancePage(section: 'focus')))));
    expect(appearance.appearance.animateReordering, isTrue);
    final toggle = find.text('Animate tile reordering');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(toggle, 150);
    await tester.pumpAndSettle();
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    expect(toggle.hitTestable(), findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(AppearanceService(prefs).appearance.animateReordering, isFalse);
    expect(appearance.tilesFor(1).animateReordering, isFalse);
    await appearance.setCategoryTile(1, 'animateReordering', true);
    expect(appearance.tilesFor(1).animateReordering, isFalse);
    expect(appearance.tilesFor(2).animateReordering, isFalse);
    await appearance.inheritField(1, 'animateReordering');
    expect(appearance.tilesFor(1).animateReordering, isFalse);
    await appearance.resetFields(['animateReordering']);
    expect(appearance.appearance.animateReordering, isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    appearance.dispose(); settings.dispose();
  });
  testWidgets('remote changes numeric values without a dialog or preview within a TV side panel', (tester) async {
    tester.view.physicalSize = const Size(700, 1080);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'show_app_names_below_icons': true});
    final prefs = await SharedPreferences.getInstance();
    final appearance = AppearanceService(prefs);
    final settings = SettingsService(prefs);
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider.value(value: appearance), ChangeNotifierProvider.value(value: settings),
    ], child: MaterialApp(locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: AppearancePage()))));
    await tester.pumpAndSettle();
    expect(find.text('Пример приложения'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(appearance.appearance.tileSize, 136);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(appearance.appearance.tileSize, 128);
    expect(find.byType(SimpleDialog), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(appearance.appearance.aspectRatio, 4 / 3);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(appearance.appearance.number('radius'), 32);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(appearance.appearance.horizontalGap, 18);
    await appearance.set('horizontalGap', 48);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(appearance.appearance.horizontalGap, 48);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(appearance.appearance.horizontalGap, 46);

    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    appearance.dispose(); settings.dispose();
  });
}
