import 'package:flutter/material.dart';

/// Coverage is checked against the bundled font files and translated resources.
class AppFonts {
  static const families = <String, String>{
    'google-sans': 'Google Sans',
    'onest': 'Onest',
    'manrope': 'Manrope',
    'outfit': 'Outfit',
    'sans-serif': 'PanelSans',
    'serif': 'PanelSerif',
    'monospace': 'PanelMono',
    'sans-serif-condensed': 'PanelCondensed',
  };
  static const interfaceIds = [
    'system',
    'google-sans',
    'onest',
    'manrope',
    'outfit',
  ];
  static const panelIds = [
    'system',
    'sans-serif',
    'serif',
    'monospace',
    'sans-serif-condensed',
    'google-sans',
    'onest',
    'manrope',
    'outfit',
  ];
  static const _latin = {'en', 'de', 'es', 'fr', 'it', 'pt', 'tr'};

  static bool supports(String id, Locale locale) {
    if (id == 'system') return true;
    if (!families.containsKey(id)) return false;
    final language = locale.languageCode;
    return _latin.contains(language) ||
        id != 'outfit' && {'ru', 'uk'}.contains(language) ||
        id == 'google-sans' && language == 'hi';
  }

  static List<String> available(Locale locale, {bool panel = false}) =>
      (panel ? panelIds : interfaceIds)
          .where((id) => supports(id, locale))
          .toList();

  /// Preserve saved preferences across language switches; resolve only for display.
  static String effective(String id, Locale locale) => supports(id, locale)
      ? id
      : supports('manrope', locale)
      ? 'manrope'
      : 'system';

  static String? family(String id, Locale locale) =>
      families[effective(id, locale)];

  static TextStyle localize(TextStyle style, Locale locale) {
    final id = families.entries
        .where((e) => e.value == style.fontFamily)
        .firstOrNull
        ?.key;
    if (id == null || supports(id, locale)) return style;
    final resolved = family(id, locale);
    return style.copyWith(
      fontFamily: resolved ?? 'Roboto',
      fontFamilyFallback: const [],
    );
  }
}

/// Resolves the font below MaterialApp, where the actual UI locale is known.
class LanguageFontTheme extends StatelessWidget {
  final String font;
  final Widget child;
  const LanguageFontTheme({super.key, required this.font, required this.child});

  static ThemeData resolve(ThemeData theme, String font, Locale locale) {
    final family = AppFonts.family(font, locale);
    return family == null
        ? theme
        : theme.copyWith(
            textTheme: theme.textTheme.apply(fontFamily: family),
            primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: family),
            dialogTheme: theme.dialogTheme.copyWith(
              titleTextStyle: theme.dialogTheme.titleTextStyle?.copyWith(
                fontFamily: family,
              ),
              contentTextStyle: theme.dialogTheme.contentTextStyle?.copyWith(
                fontFamily: family,
              ),
            ),
            inputDecorationTheme: theme.inputDecorationTheme.copyWith(
              labelStyle: theme.inputDecorationTheme.labelStyle?.copyWith(
                fontFamily: family,
              ),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: resolve(theme, font, Localizations.localeOf(context)),
      child: child,
    );
  }
}
