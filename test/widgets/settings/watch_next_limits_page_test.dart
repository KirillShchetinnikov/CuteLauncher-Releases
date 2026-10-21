import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/widgets/settings/watch_next_limits_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks.dart';
import '../../mocks.mocks.dart';

void main() {
  for (final locale in ['ru', 'en']) {
    testWidgets('source cap selected with D-pad persists in $locale', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService(await SharedPreferences.getInstance());
      final apps = MockAppsService(), watch = MockWatchNextService();
      when(apps.applications)
          .thenReturn([fakeApp(packageName: 'video', name: 'Video')]);
      when(watch.programs).thenReturn([]);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider<AppsService>.value(value: apps),
            ChangeNotifierProvider<WatchNextService>.value(value: watch),
          ],
          child: MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SizedBox(width: 340, child: WatchNextLimitsPage()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.byType(SimpleDialog), findsNothing);

      await tester.pumpAndSettle();
      expect(settings.watchNextAppLimits, {'video': 1});
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      settings.dispose();
    });
  }
}
