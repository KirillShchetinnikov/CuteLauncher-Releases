import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/notification_popup_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'popup mirrors theme and bottom corner follows menu and lifecycle',
    (tester) async {
      SharedPreferences.setMockInitialValues({'settings_menu_on_right': true});
      final settings = SettingsService(await SharedPreferences.getInstance());
      addTearDown(settings.dispose);
      final payloads = <Map<dynamic, dynamic>>[];
      const channel = MethodChannel('me.efesser.flauncher/method');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'setNotificationPopupPresentation') {
          payloads.add(call.arguments as Map<dynamic, dynamic>);
        }
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final theme = ThemeData.dark();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: settings,
          child: MaterialApp(
            theme: theme,
            home: const NotificationPopupPresentation(child: SizedBox()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(payloads.last['left'], false);
      expect(
        payloads.last['background'],
        theme.colorScheme.surface.toARGB32(),
      );
      expect(
        payloads.last['foreground'],
        theme.colorScheme.onSurface.toARGB32(),
      );
      NotificationPopupPresentation.settingsDepth.value++;
      await tester.pumpAndSettle();
      expect(payloads.last['left'], true);
      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );
      await tester.pumpAndSettle();
      expect(payloads.last['left'], false);
      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await tester.pumpAndSettle();
      expect(payloads.last['left'], true);
      NotificationPopupPresentation.settingsDepth.value--;
      await tester.pumpAndSettle();
      expect(payloads.last['left'], false);
    },
  );
}
