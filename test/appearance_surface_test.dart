import 'package:flauncher/widgets/tile_theme_outline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/memory_resources.dart';
import 'package:flauncher/tile_appearance.dart';
import 'package:flauncher/widgets/appearance_surface.dart';

void main() {
  for (final effect in ['scale', 'border', 'lift']) {
    testWidgets('focus shadow defaults off and can be enabled for $effect', (tester) async {
      Future<void> show(bool enabled) => tester.pumpWidget(MaterialApp(
        home: SizedBox(width: 100, height: 100, child: AppearanceSurface(
          appearance: TileAppearance({'focusEffect': effect, if (enabled) 'focusShadow': true}),
          borderRadius: BorderRadius.zero, elevation: 12, focused: true,
          child: const SizedBox.expand(),
        )),
      ));
      double elevation() => tester.widget<Material>(find.descendant(
        of: find.byType(AppearanceSurface), matching: find.byType(Material))).elevation;
      await show(false);
      expect(elevation(), 0);
      await show(true);
      expect(elevation(), 12);
      await show(false);
      expect(elevation(), 0);
    });
  }
  testWidgets('economy caps only unfocused shadows and restores the original appearance', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService(await SharedPreferences.getInstance());
    final resources = MemoryResources(settings: settings);
    const appearance = TileAppearance({'shadow': 16, 'focusEffect': 'border', 'focusShadow': true});
    await tester.pumpWidget(ChangeNotifierProvider.value(value: resources,
      child: const MaterialApp(home: Column(children: [
        SizedBox(width: 100, height: 100, child: AppearanceSurface(appearance: appearance,
          borderRadius: BorderRadius.zero, elevation: 0, focused: false, child: SizedBox())),
        SizedBox(width: 100, height: 100, child: AppearanceSurface(appearance: appearance,
          borderRadius: BorderRadius.zero, elevation: 0, focused: true, child: SizedBox())),
      ]))));
    List<double> elevations() => tester.widgetList<Material>(find.descendant(
      of: find.byType(AppearanceSurface), matching: find.byType(Material))).map((m) => m.elevation).toList();
    expect(elevations(), [16, 16]);
    await settings.setMemorySaverEnabled(true); await tester.pump();
    expect(elevations(), [4, 16]);
    expect(appearance.number('shadow'), 16);
    await settings.setMemorySaverEnabled(false); await tester.pump();
    expect(elevations(), [16, 16]);
    await tester.pumpWidget(const SizedBox()); resources.dispose(); settings.dispose();
  });
  testWidgets('custom tile geometry uses the common accent outline', (tester) async {
    const accent = Color(0xff00aa77);
    await tester.pumpWidget(MaterialApp(theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: accent, primary: accent)),
      home: const SizedBox(width: 100, height: 100, child: AppearanceSurface(
        appearance: TileAppearance({'radius': 32}), borderRadius: BorderRadius.zero,
        elevation: 0, focused: true, child: SizedBox.expand()))));
    final paint = tester.widget<CustomPaint>(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is TileOutlinePainter));
    expect((paint.painter as TileOutlinePainter).color, brighterTileFocusColor(accent));
    expect(tester.takeException(), isNull);
  });

  testWidgets('memory saver disables both blurs and restores them when disabled', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService(await SharedPreferences.getInstance());
    final resources = MemoryResources(settings: settings);
    final appearance = TileAppearance.decode('{"blurTiles":true,"blurPanel":true}');
    await tester.pumpWidget(ChangeNotifierProvider.value(value: resources, child: MaterialApp(home: Column(children: [
      SizedBox(width: 100, height: 100, child: AppearanceSurface(appearance: appearance, borderRadius: BorderRadius.zero, elevation: 0, focused: false, child: const SizedBox.expand())),
      SizedBox(width: 100, height: 50, child: PanelAppearanceSurface(appearance: appearance, child: const SizedBox.expand())),
    ]))));
    expect(find.byType(BackdropFilter), findsNWidgets(2));
    await settings.setMemorySaverEnabled(true);
    await tester.pump();
    expect(find.byType(BackdropFilter), findsNothing);
    await settings.setMemorySaverEnabled(false);
    await tester.pump();
    expect(find.byType(BackdropFilter), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox());
    resources.dispose();
    settings.dispose();
  });
}
