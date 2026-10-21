import 'dart:convert';
import 'dart:io';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/language_names.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'all supported languages have complete resources and matching placeholders',
    () {
      Map<String, dynamic> read(String locale) =>
          jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
              as Map<String, dynamic>;
      final en = read('en');
      final keys = en.keys.where((k) => !k.startsWith('@')).toSet();
      final locales = AppLocalizations.supportedLocales
          .map((locale) => locale.languageCode).toSet();
      final resources = Directory('lib/l10n').listSync().whereType<File>()
          .where((file) => file.path.endsWith('.arb'))
          .map((file) => file.uri.pathSegments.last
              .replaceFirst('app_', '').replaceFirst('.arb', '')).toSet();
      expect(locales, resources);
      final placeholder = RegExp(r'\{([A-Za-z_]\w*)(?:\}|,)');
      for (final locale in locales) {
        expect(languageNames[locale], isNotEmpty, reason: locale);
        final translated = read(locale);
        expect(translated.keys.where((k) => !k.startsWith('@')).toSet(),
            keys, reason: locale);
        for (final key in keys) {
          expect((translated[key] as String).trim(), isNotEmpty,
              reason: '$locale.$key');
          expect(
            placeholder.allMatches(translated[key]).map((m) => m[1]).toSet(),
            placeholder.allMatches(en[key]).map((m) => m[1]).toSet(),
            reason: '$locale.$key',
          );
        }
      }
    },
  );
  test('all languages load and interpolate names, counts and plural messages', () async {
    for (final locale in AppLocalizations.supportedLocales) {
      final l = await AppLocalizations.delegate.load(locale);
      expect(l.openNamedApp('Example App'), contains('Example App'));
      expect(l.syncStyleParameters(17), contains('17'));
      for (final hours in [0, 1, 2, 3, 5, 12, 21]) {
        final text = l.sleepTimerHours(hours);
        expect(text, isNotEmpty, reason: '$locale: $hours');
        expect(text, isNot(contains('{')), reason: '$locale: $hours');
      }
      expect(l.backgroundSource, isNotEmpty);
      expect(AppLocalizations.supportedLocales, contains(Locale(locale.languageCode)));
    }
  });
  test('Android Russian resources cover all native labels', () {
    Set<String> names(String folder) => RegExp(r'<string name="([^"]+)"')
        .allMatches(
          File('android/app/src/main/res/$folder/strings.xml')
              .readAsStringSync(),
        )
        .map((m) => m[1]!)
        .toSet();
    expect(names('values-ru'), names('values'));
  });
}
