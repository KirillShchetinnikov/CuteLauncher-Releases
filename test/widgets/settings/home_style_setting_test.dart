import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/settings_help.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/models/app.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/appearance_page.dart';
import 'package:flauncher/widgets/settings/home_style_setting.dart';
import 'package:flauncher/widgets/settings/settings_value_stepper.dart';

import '../../mocks.mocks.dart';

void main() {
  late AppearanceService appearance;
  late SettingsService settings;
  late MockAppsService apps;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    appearance = AppearanceService(prefs);
    settings = SettingsService(prefs);
    apps = MockAppsService();
    when(apps.categories)
        .thenReturn([Category(id: 1, name: 'Grid', type: CategoryType.grid)]);
  });
  tearDown(() {
    appearance.dispose();
    settings.dispose();
  });
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppearanceService>.value(value: appearance),
          ChangeNotifierProvider<SettingsService>.value(value: settings),
          ChangeNotifierProvider<AppsService>.value(value: apps),
        ],
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'global size is blocked for a fixed grid, enabled by Auto, saved size retained',
    (tester) async {
      await appearance.set('size', 160);
      await pump(tester, const AppearancePage());
      // Locate by value to avoid relying on translated wording.
      final finder = find.byWidgetPredicate(
        (w) => w is SettingsValueStepper && w.options.contains(256),
      );
      expect(tester.widget<SettingsValueStepper>(finder).enabled, isFalse);
      await appearance.setCategory(1, 'columns', 0);
      await tester.pumpAndSettle();
      expect(tester.widget<SettingsValueStepper>(finder).enabled, isTrue);
      expect(appearance.appearance.tileSize, 160);
      await tester.pumpWidget(const SizedBox());
    },
  );
  Widget control(String field, {int? id}) => HomeStyleSetting(
    categoryId: id,
    field: field,
    builder: (enabled) => SettingsValueStepper(
      title: field,
      value: 12,
      options: const [12, 14],
      label: (v) => '$v',
      enabled: enabled,
      onChanged: (_) {},
    ),
  );
  testWidgets(
    'mixed global scope respects per-field inheritance and re-enables after reset',
    (tester) async {
      when(apps.categories).thenReturn([
        Category(id: 1, name: 'Fixed', type: CategoryType.grid),
        Category(id: 2, name: 'Auto'),
      ]);
      await pump(tester, control('size'));
      bool enabled() => tester
          .widget<SettingsValueStepper>(find.byType(SettingsValueStepper))
          .enabled;
      expect(enabled(), isTrue);
      expect(find.textContaining('Размер меняется только'), findsNothing);
      await toggleSettingsHelp(tester, 'Размер меняется только');
      expect(find.textContaining('Размер меняется только'), findsOneWidget);
      await appearance.setCategoryTile(2, 'size', 200);
      await tester.pumpAndSettle();
      expect(enabled(), isFalse);
      await appearance.inheritField(2, 'size');
      await tester.pumpAndSettle();
      expect(enabled(), isTrue);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'empty Auto and hidden sections do not unlock size for a visible grid',
    (tester) async {
      final grid = Category(id: 1, name: 'Grid', type: CategoryType.grid);
      grid.applications.add(
        App(packageName: 'app', name: 'App', version: '1', hidden: false),
      );
      when(apps.categories).thenReturn([
        grid,
        Category(id: 2, name: 'Empty'),
        Category(id: 3, name: 'Hidden', visible: false),
      ]);
      await pump(tester, control('size'));
      expect(
        tester
            .widget<SettingsValueStepper>(find.byType(SettingsValueStepper))
            .enabled,
        isFalse,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'global dependent field follows local label mode, not global label mode',
    (tester) async {
      await appearance.setCategoryTile(1, 'labels', 'all');
      await pump(tester, control('labelPosition'));
      expect(
        tester
            .widget<SettingsValueStepper>(find.byType(SettingsValueStepper))
            .enabled,
        isTrue,
      );
      await appearance.setCategoryTile(1, 'labels', 'selected');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SettingsValueStepper>(find.byType(SettingsValueStepper))
            .enabled,
        isFalse,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('local blocked value can still be reset to inherited', (
    tester,
  ) async {
    await appearance.setCategoryTile(1, 'size', 200);
    await pump(tester, control('size', id: 1));
    expect(
      tester
          .widget<SettingsValueStepper>(find.byType(SettingsValueStepper))
          .enabled,
      isFalse,
    );
    await tester.tap(find.text('Своё значение · вернуть общее'));
    await tester.pumpAndSettle();
    expect(appearance.category(1).tiles.containsKey('size'), isFalse);
    expect(
      tester
          .widget<SettingsValueStepper>(find.byType(SettingsValueStepper))
          .enabled,
      isFalse,
    );
    await tester.pumpWidget(const SizedBox());
  });
}
