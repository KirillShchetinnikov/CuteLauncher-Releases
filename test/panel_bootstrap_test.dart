import 'package:flauncher/main.dart' as launcher;
import 'package:flauncher/providers/remote_panel_service.dart';
import 'package:flauncher/widgets/remote_panel.dart';
import 'package:flauncher/widgets/recent_apps_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final recent in [false, true]) {
    testWidgets('panel entry point keeps home services dormant: recent=$recent', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final panel = RemotePanelService(prefs);
      for (final id in RemotePanelService.ids) {
        await panel.show(id, id == 'settings');
      }
      panel.dispose();
      final calls = <String>[];
      final messenger = tester.binding.defaultBinaryMessenger;
      final channels = [
        'me.efesser.flauncher/method',
        'me.efesser.flauncher/event_apps',
        'me.efesser.flauncher/event_tv_inputs',
        'me.efesser.flauncher/event_notifications',
        'me.efesser.flauncher/event_weather',
        'cutelauncher/night',
        'cutelauncher/night_panel_state',
        'cutelauncher/tcl_blue_light',
        'cutelauncher/sleep_timer',
        'cutelauncher/recent_apps',
        remotePanelChannel.name,
        'dev.fluttercommunity.plus/package_info',
      ];
      for (final name in channels) {
        messenger.setMockMethodCallHandler(MethodChannel(name), (call) async {
          calls.add('$name/${call.method}');
          if (call.method == 'getPackageName') return 'com.leanbitlab.ltvL';
          if (call.method == 'getTvInputs' || call.method == 'getActiveNotifications') return [];
          if (name == 'cutelauncher/night') return {'presentationReady': true};
          if (name == 'cutelauncher/recent_apps') return {'status': 'success', 'apps': []};
          if (call.method == 'isBreezyWeatherInstalled' || call.method.startsWith('check')) return false;
          return null;
        });
      }
      final onError = FlutterError.onError;
      final errorBuilder = ErrorWidget.builder;
      final cache = PaintingBinding.instance.imageCache;
      final oldBytes = cache.maximumSizeBytes, oldSize = cache.maximumSize;
      try {
        await (recent ? launcher.recentAppsMain() : launcher.remotePanelMain());
      } finally {
        FlutterError.onError = onError;
        ErrorWidget.builder = errorBuilder;
      }
      await tester.pumpAndSettle();
      expect(find.byType(recent ? RecentAppsPanel : RemotePanel), findsOneWidget);
      expect(calls, contains('${remotePanelChannel.name}/ready'));
      expect(calls.where((call) => call.contains('package_info')), isEmpty);
      expect(calls.where((call) => call.contains('sleep_timer')), isEmpty);
      expect(calls.where((call) => call.endsWith('/checkWriteSettingsPermission')), isEmpty);
      expect(calls.where((call) => call.endsWith('/getApplications')), isEmpty);
      expect(cache.maximumSizeBytes, 8 * 1024 * 1024);
      expect(cache.maximumSize, 20);
      expect(tester.takeException(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(calls.where((call) => call == '${remotePanelChannel.name}/close'), hasLength(1));
      expect(calls.where((call) => call.endsWith('/getApplications')), isEmpty);
      await tester.pumpWidget(const SizedBox());
      remotePanelChannel.setMethodCallHandler(null);
      for (final name in channels) {
        messenger.setMockMethodCallHandler(MethodChannel(name), null);
      }
      cache.maximumSizeBytes = oldBytes;
      cache.maximumSize = oldSize;
    });
  }
}
