import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/language_names.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/app_language_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  late SettingsService settingsService;
  late SharedPreferences sharedPreferences;

  setUp(() async {
    SharedPreferencesStorePlatform.instance = InMemorySharedPreferencesStore.empty();
    sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.clear();
    settingsService = SettingsService(sharedPreferences);
  });

  Widget buildSubject([String language = 'en']) {
    return MaterialApp(
      locale: Locale(language),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChangeNotifierProvider<SettingsService>.value(
        value: settingsService,
        child: const Scaffold(
          body: AppLanguagePage(),
        ),
      ),
    );
  }

  testWidgets('only complete languages are offered, with stable autonyms', (tester) async {
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(),
        languageNames.keys.toSet());
    for (final language in ['en', 'ru', 'ar']) {
      await tester.pumpWidget(buildSubject(language));
      await tester.pumpAndSettle();
      final list = tester.widget<ListView>(find.byType(ListView));
      final rows = (list.childrenDelegate as SliverChildListDelegate).children;
      final labels = rows.whereType<FocusableSettingsTile>()
          .map((row) => (row.title as Text).data).toList();
      expect(labels, containsAll(languageNames.values));
      expect(Directionality.of(tester.element(find.byType(AppLanguagePage))),
          language == 'ar' ? TextDirection.rtl : TextDirection.ltr);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('every offered language can be selected and system default restored', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    for (final language in languageNames.entries) {
      await tester.scrollUntilVisible(find.text(language.value), 200);
      await tester.tap(find.text(language.value));
      await tester.pumpAndSettle();
      expect(settingsService.appLanguage, language.key);
      expect(settingsService.appLocale, Locale(language.key));
    }
    final l = AppLocalizations.of(tester.element(find.byType(AppLanguagePage)))!;
    await tester.scrollUntilVisible(find.text(l.systemDefault), -200);
    await tester.tap(find.text(l.systemDefault));
    await tester.pumpAndSettle();
    expect(settingsService.appLanguage, isEmpty);
    expect(settingsService.appLocale, isNull);
  });
}
