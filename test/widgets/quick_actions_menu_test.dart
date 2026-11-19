import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/screensaver_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/slideshow_service.dart';
import 'package:flauncher/quick_actions.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/menu_header_action.dart';
import 'package:flauncher/widgets/quick_actions_menu.dart';
import 'package:flauncher/widgets/settings/quick_actions_settings_page.dart';
import 'package:flauncher/widgets/tv_power_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';

void main() {
  testWidgets('gear edits the list and a power command requires confirmation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);
    addTearDown(settings.dispose);
    final calls = <String>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(TvPowerAction.channel, (call) async {
      calls.add(call.method);
      return true;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(TvPowerAction.channel, null),
    );
    await open(tester, settings);
    await tester.tap(find.byType(MenuHeaderAction));
    await tester.pumpAndSettle();
    expect(find.byType(QuickActionsSettingsPage), findsOneWidget);
    await tester.tap(find.text('Refresh wallpaper'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey(QuickAction.wallpaper)), findsNothing);
    expect(calls, isEmpty);
    final reloaded = SettingsService(prefs);
    addTearDown(reloaded.dispose);
    expect(reloaded.quickActions, [
      QuickAction.sleep,
      QuickAction.shutdown,
      QuickAction.reboot,
      QuickAction.screensaver,
    ]);

    final reboot = find.byKey(const ValueKey(QuickAction.reboot));
    await tester.tap(reboot);
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
    final dialog = find.byType(LauncherAlertDialog);
    expect(Focus.of(tester.element(find.text('Cancel'))).hasFocus, isTrue);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
    await tester.tap(find.byKey(const ValueKey(QuickAction.shutdown)));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: dialog,
        matching: find.widgetWithText(LauncherDialogButton, 'Turn off device'),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, ['shutdown']);
    expect(find.byType(QuickActionsMenu), findsNothing);
  });

  testWidgets('remote reorders commands and keeps disabled items in place', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      quickActionsItemsKey: ['sleep', 'reboot', 'wallpaper'],
    });
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);
    addTearDown(settings.dispose);
    await open(tester, settings);
    await tester.tap(find.byType(MenuHeaderAction));
    await tester.pumpAndSettle();
    expect(find.byType(QuickActionsOrderPage), findsOneWidget);
    final sleep = find.byKey(const ValueKey(QuickAction.sleep));
    await tester.longPress(sleep);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    final reloaded = SettingsService(prefs);
    addTearDown(reloaded.dispose);
    expect(reloaded.quickActionsOrder.take(3), [
      QuickAction.shutdown,
      QuickAction.reboot,
      QuickAction.sleep,
    ]);
    expect(reloaded.quickActions, [
      QuickAction.reboot,
      QuickAction.sleep,
      QuickAction.wallpaper,
    ]);
    expect(reloaded.exportSettingsMap()[quickActionsItemsKey], [
      'sleep',
      'reboot',
      'wallpaper',
    ]);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(QuickActionsOrderPage), findsOneWidget);
    final shutdown = find.byKey(const ValueKey(QuickAction.shutdown));
    await tester.ensureVisible(shutdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Turn off device').hitTestable());
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(QuickActionsOrderPage), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey(QuickAction.shutdown))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey(QuickAction.reboot))).dy,
      ),
    );
  });

  testWidgets(
    'screensaver reports an unavailable launch and closes after success',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        quickActionsItemsKey: ['screensaver'],
      });
      final settings = SettingsService(await SharedPreferences.getInstance());
      final screensaver = ScreensaverService();
      addTearDown(settings.dispose);
      addTearDown(screensaver.dispose);
      const channel = MethodChannel('me.efesser.flauncher/method');
      final messenger = tester.binding.defaultBinaryMessenger;
      var allowLaunch = false;
      var launches = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getScreensaverCapabilities') {
          return {'canStart': true};
        }
        if (call.method == 'startAmbientMode') {
          launches++;
          return allowLaunch;
        }
        throw MissingPluginException(call.method);
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      await screensaver.refresh();
      await open(tester, settings, screensaver: screensaver);
      final action = find.byKey(const ValueKey(QuickAction.screensaver));
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.text('The screensaver cannot be started.'), findsOneWidget);
      expect(action, findsOneWidget);
      allowLaunch = true;
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(launches, 2);
      expect(find.byType(QuickActionsMenu), findsNothing);
    },
  );

  testWidgets('wallpaper action advances the active slideshow once', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'background_source': 'slideshow',
      'slideshow_folder': 'content://fixture/tree/folder',
      quickActionsItemsKey: ['wallpaper'],
    });
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);
    final read = <String>[];
    late SlideshowService slideshow;
    Future<void> waitForSlide() async {
      for (var i = 0; slideshow.loading && i < 100; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(slideshow.loading, isFalse);
    }

    try {
      await tester.runAsync(() async {
        slideshow = SlideshowService(
          prefs,
          settings,
          list: (_, _) async => ['first', 'second'],
          read: (uri) async {
            read.add(uri);
            return kTransparentImage;
          },
        );
        await waitForSlide();
      });
      expect(read, ['first']);
      await open(tester, settings, slideshow: slideshow);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey(QuickAction.wallpaper)));
        await waitForSlide();
      });
      await tester.pumpAndSettle();
      expect(read, ['first', 'second']);
      expect(slideshow.version, 2);
      expect(settings.backgroundSource, 'slideshow');
      expect(find.byType(QuickActionsMenu), findsNothing);
    } finally {
      await tester.pumpWidget(const SizedBox());
      slideshow.dispose();
      settings.dispose();
    }
  });
}

Future<void> open(
  WidgetTester tester,
  SettingsService settings, {
  SlideshowService? slideshow,
  ScreensaverService? screensaver,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        if (slideshow != null) ChangeNotifierProvider.value(value: slideshow),
        if (screensaver != null)
          ChangeNotifierProvider.value(value: screensaver),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => showLauncherDialog<void>(
                  context: context,
                  useSafeArea: false,
                  styleDialog: false,
                  barrierColor: Colors.transparent,
                  builder: (_) => const QuickActionsMenu(
                    anchor: Rect.fromLTWH(40, 0, 40, 56),
                  ),
                ),
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}
