import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/screensaver_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/back_button_actions.dart';
import 'package:flauncher/widgets/settings/appearance_settings_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/interface_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const channel = MethodChannel('me.efesser.flauncher/method');
  late SettingsService settings;
  late ScreensaverService screensaver;
  var canChoose = false;
  var canStart = false;
  var opens = 0;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsService(await SharedPreferences.getInstance());
    screensaver = ScreensaverService();
    canChoose = false;
    canStart = false;
    opens = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getScreensaverCapabilities') {
            return {'canChoose': canChoose, 'canStart': canStart};
          }
          if (call.method == 'openScreensaverSettings') {
            opens++;
            return true;
          }
          return true;
        });
  });
  tearDown(() {
    settings.dispose();
    screensaver.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> pump(WidgetTester tester, Widget page) async {
    await screensaver.refresh();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: screensaver),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: page),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Android TV picker and clock editor appear only with system selection',
    (tester) async {
      canChoose = true;
      await pump(tester, const AppearanceSettingsPage());
      expect(find.text('Screensaver Clock Style'), findsOneWidget);
      expect(find.text('Choose screensaver in Android TV'), findsOneWidget);
      await tester.tap(find.text('Choose screensaver in Android TV'));
      await tester.pumpAndSettle();
      expect(opens, 1);
      canChoose = false;
      await screensaver.refresh();
      await tester.pumpAndSettle();
      expect(find.text('Screensaver Clock Style'), findsNothing);
      expect(find.text('Choose screensaver in Android TV'), findsNothing);
      expect(find.byType(FocusableSettingsTile), findsNWidgets(4));
    },
  );

  testWidgets(
    'Google TV can offer Back launch without offering system selection',
    (tester) async {
      canStart = true;
      await pump(tester, const HomeParametersPage());
      await tester.ensureVisible(find.text('Back button action'));
      await tester.tap(find.text('Back button action'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Show screensaver'), findsOneWidget);
      await tester.tap(find.text('Show screensaver'));
      await tester.pumpAndSettle();
      expect(settings.backButtonAction, BACK_BUTTON_ACTION_SCREENSAVER);
      expect(find.byType(AlertDialog), findsNothing);
      await pump(tester, const AppearanceSettingsPage());
      expect(find.text('Choose screensaver in Android TV'), findsNothing);
    },
  );

  testWidgets(
    'unsupported saved Back action focuses Nothing and leaves saved preferences intact',
    (tester) async {
      await settings.setBackButtonAction(BACK_BUTTON_ACTION_SCREENSAVER);
      await pump(tester, const HomeParametersPage());
      await tester.ensureVisible(find.text('Back button action'));
      Focus.of(tester.element(find.text('Back button action'))).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Show screensaver'), findsNothing);
      final tiles = tester
          .widgetList<FocusableSettingsTile>(find.descendant(
            of: find.byType(AlertDialog), matching: find.byType(FocusableSettingsTile)))
          .toList();
      expect(tiles.first.autofocus, isTrue);
      expect(settings.backButtonAction, BACK_BUTTON_ACTION_SCREENSAVER);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(settings.backButtonAction, BACK_BUTTON_ACTION_SCREENSAVER);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show clock'));
      await tester.pumpAndSettle();
      expect(settings.backButtonAction, BACK_BUTTON_ACTION_CLOCK);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Back button action'), findsOneWidget);
      expect(Focus.of(tester.element(find.text('Back button action'))).hasFocus, isTrue);
    },
  );

  testWidgets(
    'home settings summary uses the effective Back action on this device',
    (tester) async {
      await settings.setBackButtonAction(BACK_BUTTON_ACTION_SCREENSAVER);
      await pump(tester, const HomeParametersPage());
      expect(find.text('Show screensaver'), findsNothing);
      canStart = true;
      await screensaver.refresh();
      await tester.pumpAndSettle();
      expect(find.text('Show screensaver'), findsOneWidget);
      expect(settings.backButtonAction, BACK_BUTTON_ACTION_SCREENSAVER);
    },
  );
}
