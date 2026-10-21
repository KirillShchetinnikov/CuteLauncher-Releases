import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/models/weather_data.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/section_names.dart';
import 'package:flauncher/weather_warning_text.dart';
import 'package:flauncher/widgets/settings/continue_watching_card_size_page.dart';
import 'package:flauncher/widgets/settings/continue_watching_max_items_page.dart';
import 'package:flauncher/widgets/settings/screensaver_clock_style_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'mocks.mocks.dart';

void main() {
  test('Russian resources preserve custom names and format warnings', () async {
    await initializeDateFormatting();
    final ru = await AppLocalizations.delegate.load(const Locale('ru'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(localizedSectionName('TV Apps', ru), 'Приложения для ТВ');
    expect(localizedSectionName('Favorites', ru), 'Избранное');
    expect(localizedSectionName('Мои фильмы', en), 'Мои фильмы');
    expect(localizedSectionName('My custom section', ru), 'My custom section');
    const weather = WeatherData(hasWarning: true, warningType: WeatherWarningType.rain,
        warningDayIndex: 0, warningPrecipProbability: 80);
    expect(localizedWeatherWarning(weather, ru, DateTime(2026, 10, 2)), '80% Дождь сегодня');
    expect(localizedWeatherWarning(weather, en, DateTime(2026, 10, 2)), '80% Rain today');
    expect(ContinueWatchingCardSizePage.cardSizePresets(ru)[6].$2,
        '135 dp • Стандартный (по умолчанию)');
    expect(ru.importConfirm, contains('сохранят текущие значения'));
  });

  for (final entry in <(Widget, String, String)>[
    (const ScreensaverClockStylePage(), 'Минималистичный', 'Minimal'),
    (const ContinueWatchingCardSizePage(), 'Размер карточек', 'Card Size'),
    (const ContinueWatchingMaxItemsPage(), 'Максимальное число карточек', 'Maximum Items'),
  ]) {
    testWidgets('settings page translates and updates locale: ${entry.$3}', (tester) async {
      final settings = MockSettingsService();
      when(settings.screensaverClockStyle).thenReturn('minimal');
      when(settings.themes).thenReturn('modern');
      when(settings.continueWatchingCardSize).thenReturn('135');
      when(settings.continueWatchingMaxItems).thenReturn(15);
      Widget app(Locale locale) => ChangeNotifierProvider<SettingsService>.value(
        value: settings,
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: Center(child: SizedBox(width: 420, height: 540, child: entry.$1))),
        ),
      );
      await tester.pumpWidget(app(const Locale('ru')));
      await tester.pumpAndSettle();
      expect(find.text(entry.$2), findsNWidgets(entry.$1 is ScreensaverClockStylePage ? 1 : 2));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(app(const Locale('en')));
      await tester.pumpAndSettle();
      expect(find.text(entry.$3), findsNWidgets(entry.$1 is ScreensaverClockStylePage ? 1 : 2));
      expect(find.text(entry.$2), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
