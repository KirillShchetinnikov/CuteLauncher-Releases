import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/memory_settings_page.dart';
import 'package:flauncher/widgets/settings/settings_choice_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'manual limits remain visible and locked under the global switch',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'poster_cache_watch_next_disk': 128,
      });
      final settings = SettingsService(await SharedPreferences.getInstance());
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: settings,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (_, child) => Material(child: child),
            routes: {
              MemorySettingsPage.routeName: (_) => const MemorySettingsPage(),
            },
            home: const Scaffold(body: MemorySettingsSection()),
          ),
        ),
      );
      Future<void> open(String label) async {
        final text = find.text(label);
        await tester.ensureVisible(text);
        await tester.tap(text);
        await tester.pumpAndSettle();
      }

      await tester.pumpAndSettle();
      await open('Memory saving');
      expect(settings.memorySaverEnabled, isTrue);
      await open('Limits and caches');
      await open('Continue Watching');
      final choices = tester
          .widgetList<SettingsChoiceTile<int>>(
            find.byType(SettingsChoiceTile<int>),
          )
          .toList();
      expect(choices.map((tile) => tile.value), [1, 32]);
      expect(choices.every((tile) => !tile.enabled), isTrue);
      await open('Poster cache on disk');
      expect(find.byType(Dialog), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await open('Memory saving');
      await open('Limits and caches');
      await open('Continue Watching');
      expect(find.text('128 MiB'), findsOneWidget);
    },
  );
}
