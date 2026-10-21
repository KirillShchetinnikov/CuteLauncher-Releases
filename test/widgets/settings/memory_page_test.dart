import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/memory_resources.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/memory_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryChannel extends FLauncherChannel {
  int calls = 0;
  @override
  Future<Map<String, dynamic>> getProcessMemoryUsage() async {
    calls++;
    return {
      'pssBytes': 20 * 1024 * 1024,
      'rssBytes': null,
      'graphicsBytes': 8 * 1024 * 1024,
    };
  }
}

void main() {
  testWidgets(
    'entry measures once, clear refreshes caches, submenu saves economy and refresh measures',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService(await SharedPreferences.getInstance());
      final resources = MemoryResources(settings: settings);
      var cached = 4 * 1024 * 1024;
      resources.register(
        Object(),
        clear: () => cached = 0,
        stats: () => MemoryCacheStats(cached, 1),
        breakdown: () => {
          MemoryCacheKind.appIcons: MemoryCacheStats(cached, 1),
        },
      );
      final channel = _MemoryChannel();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider.value(value: resources),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: MemoryPage(channel: channel)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(channel.calls, 1);
      expect(find.text('20.0 MiB'), findsOneWidget);
      expect(find.text('8.0 MiB'), findsOneWidget);
      expect(find.text('Unavailable'), findsOneWidget);
      expect(find.text('Image cache size: 4.0 MiB'), findsOneWidget);
      expect(find.text('4.0 MiB'), findsNWidgets(2));
      expect(find.text('Continue Watching posters'), findsOneWidget);
      await tester.ensureVisible(find.text('Clear image caches'));
      await tester.tap(find.text('Clear image caches'));
      await tester.pumpAndSettle();
      expect(cached, 0);
      expect(channel.calls, 1);
      expect(find.text('Image cache size: 0.0 MiB'), findsOneWidget);
      await tester.ensureVisible(find.text('Memory saving'));
      await tester.tap(find.text('Memory saving'));
      await tester.pumpAndSettle();
      expect(settings.memorySaverEnabled, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(settings.memorySaverEnabled, isTrue);
      expect(
        SettingsService(await SharedPreferences.getInstance())
            .memorySaverEnabled,
        isTrue,
      );
      expect(settings.exportSettingsMap()['memory_saver_enabled'], isTrue);
      Navigator.of(tester.element(find.byType(MemorySaverPage))).pop();
      await tester.pumpAndSettle();
      expect(channel.calls, 2);
      await tester.ensureVisible(find.text('Measure memory'));
      await tester.tap(find.text('Measure memory'));
      await tester.pumpAndSettle();
      expect(channel.calls, 3);
      await tester.pump(const Duration(minutes: 1));
      expect(channel.calls, 3); // No persistent polling.
      await settings.setMemorySaverEnabled(false);
      await tester.pumpWidget(const SizedBox());
      resources.dispose();
      settings.dispose();
    },
  );
}
