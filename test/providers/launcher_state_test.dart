import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/launcher_state.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/screensaver_service.dart';
import 'package:flutter/services.dart';
import 'package:flauncher/widgets/settings/back_button_actions.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../mocks.mocks.dart';

void main() {
  group('LauncherState handleBackNavigation', () {
    late MockAppsService mockAppsService;
    late MockSettingsService mockSettingsService;
    late LauncherState launcherState;
    late ScreensaverService screensaver;
    bool canStartScreensaver = true;
    int startCalls = 0;

    setUp(() async {
      mockAppsService = MockAppsService();
      mockSettingsService = MockSettingsService();
      launcherState = LauncherState();
      canStartScreensaver = true;
      startCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('me.efesser.flauncher/method'), (call) async {
        if (call.method == 'getScreensaverCapabilities') return {'canStart': canStartScreensaver};
        if (call.method == 'startAmbientMode') { startCalls++; return true; }
        return null;
      });
      screensaver = ScreensaverService();
      await screensaver.refresh();
    });

    tearDown(() {
      screensaver.dispose();
      launcherState.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('me.efesser.flauncher/method'), null);
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AppsService>.value(value: mockAppsService),
          ChangeNotifierProvider<SettingsService>.value(value: mockSettingsService),
          ChangeNotifierProvider<LauncherState>.value(value: launcherState),
          ChangeNotifierProvider<ScreensaverService>.value(value: screensaver),
        ],
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              return GestureDetector(
                onTap: () {
                  launcherState.handleBackNavigation(context);
                },
                child: const Text('Tap Me'),
              );
            },
          ),
        ),
      );
    }

    testWidgets('handleBackNavigation opens clock when action is BACK_BUTTON_ACTION_CLOCK', (WidgetTester tester) async {
      when(mockSettingsService.backButtonAction).thenReturn(BACK_BUTTON_ACTION_CLOCK);
      when(mockAppsService.isDefaultLauncher()).thenAnswer((_) async => true);

      // Force refresh to apply isDefaultLauncher locally if not kDebugMode
      await launcherState.refresh(mockAppsService);

      expect(launcherState.launcherVisible, isTrue);

      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();

      expect(launcherState.launcherVisible, isFalse);
    });

    testWidgets('handleBackNavigation starts screensaver when action is BACK_BUTTON_ACTION_SCREENSAVER', (WidgetTester tester) async {
      when(mockSettingsService.backButtonAction).thenReturn(BACK_BUTTON_ACTION_SCREENSAVER);
      when(mockAppsService.isDefaultLauncher()).thenAnswer((_) async => true);

      // Force refresh
      await launcherState.refresh(mockAppsService);

      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();

      expect(startCalls, 1);
    });

    testWidgets('saved screensaver action is inert when system launch is unavailable', (tester) async {
      canStartScreensaver = false;
      await screensaver.refresh();
      when(mockSettingsService.backButtonAction).thenReturn(BACK_BUTTON_ACTION_SCREENSAVER);
      when(mockAppsService.isDefaultLauncher()).thenAnswer((_) async => true);
      await launcherState.refresh(mockAppsService);
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();
      expect(startCalls, 0);
      expect(launcherState.launcherVisible, isTrue);
    });

    testWidgets('handleBackNavigation does nothing when action is BACK_BUTTON_ACTION_NOTHING', (WidgetTester tester) async {
      when(mockSettingsService.backButtonAction).thenReturn(BACK_BUTTON_ACTION_NOTHING);
      when(mockAppsService.isDefaultLauncher()).thenAnswer((_) async => true);

      // Force refresh
      await launcherState.refresh(mockAppsService);

      expect(launcherState.launcherVisible, isTrue);

      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();

      expect(launcherState.launcherVisible, isTrue);
      verifyNever(mockAppsService.startAmbientMode());
    });
  });

  group('LauncherState toggleLauncherVisibility', () {
    late LauncherState launcherState;

    setUp(() {
      launcherState = LauncherState();
    });

    test('initial launcherVisible state is true', () {
      expect(launcherState.launcherVisible, isTrue);
    });

    test('toggleLauncherVisibility changes launcherVisible from true to false', () {
      launcherState.toggleLauncherVisibility();
      expect(launcherState.launcherVisible, isFalse);
    });

    test('toggleLauncherVisibility changes launcherVisible from false back to true', () {
      launcherState.toggleLauncherVisibility();
      expect(launcherState.launcherVisible, isFalse);

      launcherState.toggleLauncherVisibility();
      expect(launcherState.launcherVisible, isTrue);
    });

    test('toggleLauncherVisibility calls notifyListeners', () {
      bool listenersNotified = false;
      launcherState.addListener(() {
        listenersNotified = true;
      });

      launcherState.toggleLauncherVisibility();

      expect(listenersNotified, isTrue);
    });
  });
}
