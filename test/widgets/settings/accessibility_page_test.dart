import 'adb_test_compatibility.dart';
import 'package:flutter/services.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/launcher_state.dart';
import 'package:flauncher/widgets/settings/accessibility_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:flauncher/providers/settings_service.dart';
import '../../mocks.mocks.dart';

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('cutelauncher/auto_launch'), (_) async => {'mode': 'off'});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('cutelauncher/adb'), (_) async => {'compatibility': supportedAdbCompatibility, 'port': 5555});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('me.efesser.flauncher/method'), (_) async => false);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('cutelauncher/auto_launch'), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('cutelauncher/adb'), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('me.efesser.flauncher/method'), null);
  });
  setUpAll(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.single.physicalSize = Size(1280, 720);
    binding.platformDispatcher.views.single.devicePixelRatio = 1.0;
    binding.platformDispatcher.textScaleFactorTestValue = 0.8;
  });

  testWidgets("AccessibilityPage renders correctly when default launcher", (tester) async {
    final appsService = MockAppsService();
    final launcherState = LauncherState();
    final settingsService = MockSettingsService();

    when(appsService.isDefaultLauncher()).thenAnswer((_) async => true);
    when(settingsService.appHighlightAnimationEnabled).thenReturn(true);
    when(settingsService.appKeyClickEnabled).thenReturn(false);
    when(settingsService.backButtonAction).thenReturn('');
    when(settingsService.startOnBoot).thenReturn(false);
    when(settingsService.accentColorHex).thenReturn("7C4DFF");

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppsService>.value(value: appsService),
          ChangeNotifierProvider<LauncherState>.value(value: launcherState),
          ChangeNotifierProvider<SettingsService>.value(value: settingsService),
        ],
        builder: (_, _) => MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: AccessibilityPage()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text("Launcher and TV controls"), findsOneWidget);
    expect(find.byWidgetPredicate((widget) => widget is Icon &&
        widget.semanticLabel == 'Default launcher: Enabled'), findsOneWidget);
    expect(find.text("Open system default launcher setting"), findsNothing);
    await tester.ensureVisible(find.text("Default launcher"));
    await tester.tap(find.text("Default launcher")); await tester.pumpAndSettle();
    expect(find.text("Open system default launcher setting"), findsOneWidget);
  });

  testWidgets("AccessibilityPage renders correctly when not default launcher", (tester) async {
    final appsService = MockAppsService();
    final launcherState = LauncherState();
    final settingsService = MockSettingsService();

    when(appsService.isDefaultLauncher()).thenAnswer((_) async => false);
    when(settingsService.appHighlightAnimationEnabled).thenReturn(true);
    when(settingsService.appKeyClickEnabled).thenReturn(false);
    when(settingsService.backButtonAction).thenReturn('');
    when(settingsService.startOnBoot).thenReturn(false);
    when(settingsService.accentColorHex).thenReturn("7C4DFF");

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppsService>.value(value: appsService),
          ChangeNotifierProvider<LauncherState>.value(value: launcherState),
          ChangeNotifierProvider<SettingsService>.value(value: settingsService),
        ],
        builder: (_, _) => MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: AccessibilityPage()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text("Launcher and TV controls"), findsOneWidget);
    expect(find.byWidgetPredicate((widget) => widget is Icon &&
        widget.semanticLabel == 'Default launcher: Disabled'), findsOneWidget);
  });
}
