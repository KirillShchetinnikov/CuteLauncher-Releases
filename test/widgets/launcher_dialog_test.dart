import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/settings/adb_action_confirmation.dart';
import 'package:flauncher/widgets/settings/settings_menu_layout.dart';
import 'package:flauncher/widgets/side_panel_dialog.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/models/app.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/widgets/add_to_category_dialog.dart';
import 'package:flauncher/widgets/settings/donate_dialog.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'panel_backdrop_assertions.dart';
import 'package:flutter_test/flutter_test.dart';

Finder get _surface => find
    .descendant(
      of: find.byType(Dialog).last,
      matching: find.byWidgetPredicate(
        (w) => w is Material && w.type == MaterialType.card,
      ),
    )
    .first;

class _Settings extends ChangeNotifier implements SettingsService {
  @override
  final bool settingsMenuOnRight;
  @override
  bool get appKeyClickEnabled => false;
  @override
  String get accentColorHex => '9674FF';
  _Settings(this.settingsMenuOnRight);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Apps extends ChangeNotifier implements AppsService {
  @override
  List<Category> get categories => [Category(name: 'Видео')];
  int additions = 0;
  @override
  Future<void> addToCategory(
    App application,
    Category category, {
    bool shouldNotifyListeners = true,
  }) async => additions++;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _open(
  WidgetTester tester, {
  bool? onRight,
  Widget? content,
}) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final child = Builder(
    builder: (context) => TextButton(
      autofocus: true,
      onPressed: () => showLauncherDialog<void>(
        context: context,
        builder: (context) => LauncherAlertDialog(
          title: const Text('Редактор'),
          content: content ?? const Text('Москва'),
          actions: [
            LauncherDialogButton(
              autofocus: true,
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
          ],
        ),
      ),
      child: const Text('Открыть'),
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          primary: Colors.green,
        ),
      ),
      home: Scaffold(
        body: onRight == null
            ? child
            : SettingsMenuLayout(onRight: onRight, child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('replacement dialog gets its own immediate 50 percent barrier', (tester) async {
    await _open(tester, content: Builder(builder: (context) => TextButton(
      onPressed: () {
        Navigator.of(context).pop();
        showLauncherDialog<void>(context: context,
          builder: (_) => const LauncherAlertDialog(title: Text('Replacement')));
      },
      child: const Text('Replace'),
    )));
    await tester.tap(find.text('Replace'));
    await tester.pump();
    expect(find.text('Replacement'), findsOneWidget);
    expectSinglePanelBackdrop(tester);
    await tester.pumpAndSettle();
  });

  testWidgets('nested dialogs share one immediate 50 percent barrier', (tester) async {
    await _open(tester, content: Builder(builder: (context) => TextButton(
      onPressed: () => showLauncherDialog<void>(context: context,
        builder: (_) => const LauncherAlertDialog(title: Text('Nested'))),
      child: const Text('Next'),
    )));
    expectSinglePanelBackdrop(tester);
    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(find.text('Nested'), findsOneWidget);
    expectSinglePanelBackdrop(tester);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Nested'), findsNothing);
    expectSinglePanelBackdrop(tester);
    await tester.pumpAndSettle();
  });

  testWidgets('dialog actions show only the focused outline', (tester) async {
    final cancel = FocusNode();
    final confirm = FocusNode();
    addTearDown(cancel.dispose);
    addTearDown(confirm.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              LauncherDialogButton(
                focusNode: cancel,
                autofocus: true,
                onPressed: () {},
                child: const Text('Cancel'),
              ),
              LauncherDialogButton(
                focusNode: confirm,
                primary: true,
                danger: true,
                onPressed: () {},
                child: const Text('Confirm'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    void checkOutline(String label, bool focused) {
      final material = tester.widget<Material>(
        find.descendant(
          of: find.widgetWithText(TextButton, label),
          matching: find.byType(Material),
        ),
      );
      expect(material.color, Colors.transparent);
      final border = (material.shape! as OutlinedBorder).side;
      expect(border.color.a, focused ? 1 : 0);
    }

    checkOutline('Cancel', true);
    checkOutline('Confirm', false);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(confirm.hasFocus, isTrue);
    checkOutline('Cancel', false);
    checkOutline('Confirm', true);
  });

  for (final settingsOpen in [false, true]) {
    testWidgets(
      'category selection uses correct window and saves once; settings=$settingsOpen',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final apps = _Apps();
        final settings = _Settings(false);
        addTearDown(apps.dispose);
        addTearDown(settings.dispose);
        final open = Builder(
          builder: (context) => TextButton(
            child: const Text('Открыть'),
            onPressed: () => showLauncherDialog<void>(
              context: context,
              builder: (_) => AddToCategoryDialog(
                App(
                  packageName: 'demo',
                  name: 'Видео',
                  version: '1',
                  hidden: false,
                ),
              ),
            ),
          ),
        );
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AppsService>.value(value: apps),
              ChangeNotifierProvider<SettingsService>.value(value: settings),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: settingsOpen
                    ? SettingsMenuLayout(onRight: false, child: open)
                    : open,
              ),
            ),
          ),
        );
        await tester.tap(find.text('Открыть'));
        await tester.pumpAndSettle();
        expect(
          find.byType(LauncherAlertDialog),
          settingsOpen ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(SidePanelDialog),
          settingsOpen ? findsNothing : findsOneWidget,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(apps.additions, 1);
        expect(find.byType(AddToCategoryDialog), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final right in [false, true]) {
    testWidgets('QR window fits narrow remaining TV area right=$right', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(640, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings = _Settings(right);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsService>.value(
          value: settings,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SettingsMenuLayout(
                onRight: right,
                child: Builder(
                  builder: (context) => TextButton(
                    child: const Text('Открыть'),
                    onPressed: () => showLauncherDialog<void>(
                      context: context,
                      builder: (_) => const DonateDialog(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Открыть'));
      await tester.pumpAndSettle();
      final rect = tester.getRect(_surface);
      expect(rect.width, lessThanOrEqualTo(196));
      expect(rect.height, lessThanOrEqualTo(328));
      expect(tester.takeException(), isNull);
    });
    testWidgets('side menu follows saved setting right=$right', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsService>.value(
          value: _Settings(right),
          child: const MaterialApp(
            home: Scaffold(body: SidePanelDialog(child: Text('Действия'))),
          ),
        ),
      );
      final rect = tester.getRect(
        find
            .descendant(
              of: find.byType(SidePanelDialog),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(rect.center.dx, right ? greaterThan(640) : lessThan(640));
      expect(tester.takeException(), isNull);
    });

    testWidgets('wide and nested dialog stay in same free area right=$right', (
      tester,
    ) async {
      await _open(
        tester,
        onRight: right,
        content: SizedBox(
          width: 2000,
          child: Builder(
            builder: (context) => TextButton(
              child: const Text('Следующее окно'),
              onPressed: () => showLauncherDialog<void>(
                context: context,
                builder: (_) => const LauncherAlertDialog(
                  title: Text('Вложенное'),
                  content: Text('Детали'),
                ),
              ),
            ),
          ),
        ),
      );
      final wide = tester.getRect(_surface);
      expect(wide.width, closeTo(836, .1));
      await tester.tap(find.text('Следующее окно'));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(_surface).center.dx,
        closeTo(right ? 434 : 846, .1),
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Следующее окно'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
    testWidgets('compact dialog centers in free area; settings right=$right', (
      tester,
    ) async {
      await _open(tester, onRight: right);
      final rect = tester.getRect(_surface);
      expect(rect.center.dx, closeTo(right ? 434 : 846, .1));
      expect(rect.width, lessThan(800));
      expect(rect.height, lessThan(400));
      expect(
        right ? rect.right : rect.left,
        right ? lessThan(868) : greaterThan(412),
      );
      final closeFocus = FocusManager.instance.primaryFocus;
      expect(closeFocus?.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'large body fits free area and keyboard; settings right=$right',
      (tester) async {
        await _open(
          tester,
          onRight: right,
          content: Column(
            children: [for (var i = 0; i < 40; i++) Text('Строка $i')],
          ),
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 240);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        final rect = tester.getRect(_surface);
        expect(rect.bottom, lessThanOrEqualTo(480));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(
          right ? rect.right : rect.left,
          right ? lessThan(868) : greaterThan(412),
        );
        expect(find.text('Отмена').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('without settings dialog uses whole screen center', (
    tester,
  ) async {
    await _open(tester);
    expect(tester.getRect(_surface).center.dx, closeTo(640, .1));
    expect(tester.takeException(), isNull);
  });

  for (final confirm in [false, true]) {
    testWidgets(
      'ADB dismissal without Cancel has no notice; confirm=$confirm',
      (tester) async {
        bool? result;
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async => result = await confirmAdbAction(
                    context,
                    'ADB',
                    'overlay',
                    [],
                  ),
                  child: const Text('Открыть'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Открыть'));
        await tester.pumpAndSettle();
        if (confirm) {
          await tester.tap(find.text('Применить'));
        } else {
        await tester.binding.handlePopRoute();
        }
        await tester.pumpAndSettle();
        expect(result, confirm);
        expect(find.text('Действие отменено'), findsNothing);
        expect(find.byType(LauncherAlertDialog), findsNothing);
      },
    );
  }

  testWidgets(
    'ADB cancellation focus and command disclosure never execute action',
    (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => result = await confirmAdbAction(
                  context,
                  'Главный экран',
                  'home',
                  ['test-command'],
                ),
                child: const Text('Открыть'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Открыть'));
      await tester.pumpAndSettle();
      expect(find.text('adb shell test-command').hitTestable(), findsNothing);
      expect(FocusManager.instance.primaryFocus?.context?.widget, isA<Focus>());
      await tester.tap(find.text('Показать команды ADB'));
      await tester.pumpAndSettle();
      expect(find.text('adb shell test-command').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
      expect(find.text('Действие отменено'), findsOneWidget);
      expect(find.byType(LauncherAlertDialog), findsNothing);
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Действие отменено'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
