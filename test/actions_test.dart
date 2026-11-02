import 'package:flauncher/actions.dart';
import 'package:flauncher/key_sounds.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'mocks.mocks.dart';

void main() {
  for (final home in [false, true]) {
    for (final homeSounds in [false, true]) {
      testWidgets('directional sound respects scope Home=$home, Home sounds=$homeSounds', (tester) async {
        SharedPreferences.setMockInitialValues({
          'home_key_click_enabled': homeSounds,
          'app_key_click_enabled': !homeSounds,
        });
        final settings = SettingsService(await SharedPreferences.getInstance());
        var clicks = 0;
        const channel = MethodChannel('me.efesser.flauncher/method');
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'playClickSound') clicks++;
          return null;
        });
        addTearDown(() {
          settings.dispose();
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
        });
        Widget controls = Builder(builder: (context) => Actions(
          actions: {DirectionalFocusIntent: SoundFeedbackDirectionalFocusAction(context)},
          child: const Row(children: [
            Focus(autofocus: true, child: SizedBox(width: 100, height: 100)),
            Focus(child: SizedBox(width: 100, height: 100)),
          ]),
        ));
        if (home) controls = HomeKeySoundScope(child: controls);
        await tester.pumpWidget(ChangeNotifierProvider.value(
          value: settings,
          child: MaterialApp(home: Scaffold(body: controls)),
        ));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(clicks, (home ? homeSounds : !homeSounds) ? 1 : 0);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  group('SoundFeedbackDirectionalFocusAction', () {
    late MockSettingsService mockSettingsService;

    setUp(() {
      mockSettingsService = MockSettingsService();
    });

    testWidgets('plays sound when appKeyClickEnabled is true', (WidgetTester tester) async {
      when(mockSettingsService.appKeyClickEnabled).thenReturn(true);

      late BuildContext actionContext;

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<SettingsService>.value(value: mockSettingsService),
            ],
            child: Builder(
              builder: (context) {
                actionContext = context;
                return Focus(
                  autofocus: true,
                  child: Container(
                    width: 100,
                    height: 100,
                    color: Colors.red,
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Invoke the action directly to simulate focus movement
      final action = SoundFeedbackDirectionalFocusAction(actionContext);
      action.invoke(const DirectionalFocusIntent(TraversalDirection.down));

      await tester.pumpAndSettle();

      verify(mockSettingsService.appKeyClickEnabled).called(1);
    });

    testWidgets('silent for tap when appKeyClickEnabled is false', (WidgetTester tester) async {
      when(mockSettingsService.appKeyClickEnabled).thenReturn(false);

      late BuildContext actionContext;

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<SettingsService>.value(value: mockSettingsService),
            ],
            child: Builder(
              builder: (context) {
                actionContext = context;
                return Focus(
                  autofocus: true,
                  child: Container(
                    width: 100,
                    height: 100,
                    color: Colors.red,
                  ),
                );
              },
            ),
          ),
        ),
      );

      final action = SoundFeedbackDirectionalFocusAction(actionContext);

      action.invoke(const DirectionalFocusIntent(TraversalDirection.down));

      await tester.pumpAndSettle();

      verify(mockSettingsService.appKeyClickEnabled).called(1);
    });
  });
}
