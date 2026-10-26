import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/sleep_timer_service.dart';
import 'package:flauncher/sleep_timer_configuration.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/menu_header_action.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/settings_text_tile.dart';
import 'package:flauncher/widgets/settings/sleep_timer_settings_page.dart';
import 'package:flauncher/widgets/sleep_timer_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SettingsService settings;
  late SleepTimerService timer;
  final calls = <MethodCall>[];
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsService(await SharedPreferences.getInstance());
    timer = SleepTimerService();
    timer.didChangeAppLifecycleState(AppLifecycleState.paused);
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SleepTimerService.channel, (call) async {
          calls.add(call);
          return {'remainingMs': 90061000, 'exactAllowed': true, 'error': ''};
        });
  });
  tearDown(() {
    timer.dispose();
    settings.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SleepTimerService.channel, null);
  });

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: timer),
        ],
        child: MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: Material(child: child!),
          ),
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text).last;
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  for (final scale in [1.0, 1.6]) {
    testWidgets('timer title stays on one line at scale $scale', (
      tester,
    ) async {
      await pump(
        tester,
        const SleepTimerMenu(anchor: Rect.fromLTWH(20, 0, 40, 56)),
        scale: scale,
      );
      final l = AppLocalizations.of(
        tester.element(find.byType(SleepTimerMenu)),
      )!;
      final title = find.text(l.sleepTimer);
      final paragraph = tester.renderObject<RenderParagraph>(title);
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: l.sleepTimer.length),
      );
      expect(boxes.map((box) => box.top).toSet(), hasLength(1));
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('three options save, display selector and large text fit', (
    tester,
  ) async {
    await pump(tester, const SleepTimerSettingsPage(), scale: 1.6);
    await tapText(tester, 'Настройки');
    await tapText(tester, 'Показывать секунды');
    await tapText(tester, 'Закрывать виджет после выбора таймера');
    await tapText(tester, 'Показывать при активном таймере');
    await tapText(tester, 'Оставшееся время и время отключения');
    final config = settings.sleepTimerConfiguration;
    expect(config.showSeconds, false);
    expect(config.closeAfterSelection, false);
    expect(config.display, 'both');
    expect(calls, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'remote moves between lists; Back ends moving; delete and reset keep active alarm',
    (tester) async {
      await timer.selectSeconds(90061);
      await settings.setSleepTimerConfiguration(
        SleepTimerConfiguration(
          presets: [
            const SleepTimerPreset('default_600', 600),
            const SleepTimerPreset('custom', 61, visible: false),
          ],
        ),
      );
      await pump(tester, const SleepTimerPresetsPage());
      final row = find.byKey(const ValueKey('default_600'));
      tester.widget<FocusableSettingsTile>(row).focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(settings.sleepTimerConfiguration.presets.first.visible, false);
      expect(
        tester.widget<FocusableSettingsTile>(row).focusNode!.hasFocus,
        true,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(tester.widget<FocusableSettingsTile>(row).selected, false);
      await tester.tap(row);
      await tester.pumpAndSettle();
      await tapText(tester, 'Удалить');
      await tapText(tester, 'Удалить');
      expect(settings.sleepTimerConfiguration.presets.map((p) => p.id), [
        'custom',
      ]);
      await tapText(tester, 'Сбросить таймеры');
      await tapText(tester, 'Сбросить таймеры');
      expect(settings.sleepTimerConfiguration.presets.length, 13);
      expect(calls.length, 1);
      expect(timer.active, true);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'custom duration editor creates and changes seconds above six hours',
    (tester) async {
      await settings.setSleepTimerConfiguration(
        SleepTimerConfiguration(presets: []),
      );
      await pump(tester, const SleepTimerPresetsPage());
      await tapText(tester, 'Добавить таймер');
      Future<void> input(String title, String value) async {
        final tile = tester
            .widgetList<SettingsTextTile>(find.byType(SettingsTextTile))
            .firstWhere((t) => t.title == title);
        tile.onChanged(value);
        await tester.pump();
      }

      await input('Часы', '25');
      await input('Минуты', '1');
      await input('Секунды', '1');
      await tapText(tester, 'Сохранить');
      expect(settings.sleepTimerConfiguration.presets.single.seconds, 90061);
      await tapText(tester, '25:01:01');
      await input('Секунды', '2');
      await tapText(tester, 'Сохранить');
      expect(settings.sleepTimerConfiguration.presets.single.seconds, 90062);
      expect(calls, isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'widget uses visible presets, keeps open when configured, gear restores focus',
    (tester) async {
      await settings.setSleepTimerConfiguration(
        SleepTimerConfiguration(
          closeAfterSelection: false,
          presets: [
            const SleepTimerPreset('custom', 90061),
            const SleepTimerPreset('hidden', 60, visible: false),
          ],
        ),
      );
      await pump(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showLauncherDialog<void>(
              context: context,
              styleDialog: false,
              builder: (_) =>
                  const SleepTimerMenu(anchor: Rect.fromLTWH(20, 0, 40, 56)),
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tapText(tester, 'open');
      expect(find.text('1 мин'), findsNothing);
      await tapText(tester, '25:01:01');
      expect(find.byType(SleepTimerMenu), findsOneWidget);
      expect(calls.last.method, 'startDuration');
      expect(calls.last.arguments, {'seconds': 90061});
      await tester.tap(find.byType(MenuHeaderAction));
      await tester.pumpAndSettle();
      expect(find.byType(SleepTimerSettingsPage), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(SleepTimerSettingsPage), findsNothing);
      expect(
        tester
            .widget<MenuHeaderAction>(find.byType(MenuHeaderAction))
            .focusNode!
            .hasFocus,
        true,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
