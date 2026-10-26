import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/appearance_service.dart';
import '../../app_fonts.dart';

/// Shared appearance for settings and all side panels with settings/actions.
class SettingsPanelStyle extends StatelessWidget {
  /// Reserve space inside the paragraph, including its first and last line.
  /// Outer padding cannot protect glyphs in Android's cached text layers.
  static TextStyle? fullTextMetrics(TextStyle? style) =>
      style?.fontFamily == 'Manrope' && (style?.height ?? 0) < 1.5
      ? style!.copyWith(height: 1.5)
      : style;

  static TextTheme _fullTextTheme(TextTheme text) => TextTheme(
    displayLarge: fullTextMetrics(text.displayLarge),
    displayMedium: fullTextMetrics(text.displayMedium),
    displaySmall: fullTextMetrics(text.displaySmall),
    headlineLarge: fullTextMetrics(text.headlineLarge),
    headlineMedium: fullTextMetrics(text.headlineMedium),
    headlineSmall: fullTextMetrics(text.headlineSmall),
    titleLarge: fullTextMetrics(text.titleLarge),
    titleMedium: fullTextMetrics(text.titleMedium),
    titleSmall: fullTextMetrics(text.titleSmall),
    bodyLarge: fullTextMetrics(text.bodyLarge),
    bodyMedium: fullTextMetrics(text.bodyMedium),
    bodySmall: fullTextMetrics(text.bodySmall),
    labelLarge: fullTextMetrics(text.labelLarge),
    labelMedium: fullTextMetrics(text.labelMedium),
    labelSmall: fullTextMetrics(text.labelSmall),
  );

  final WidgetBuilder builder;

  const SettingsPanelStyle({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final appearance = context.watch<AppearanceService?>()?.appearance;
    // A dialog captures Theme at opening. Use the current MaterialApp theme,
    // rather than that snapshot or a still-interpolating AnimatedTheme.
    final base =
        context.findAncestorWidgetOfExactType<MaterialApp>()?.theme ??
        Theme.of(context);
    final localizedTheme = LanguageFontTheme.resolve(
      base,
      appearance?.interfaceFont ?? 'system',
      Localizations.localeOf(context),
    );
    final theme = localizedTheme.copyWith(
      textTheme: _fullTextTheme(localizedTheme.textTheme),
      primaryTextTheme: _fullTextTheme(localizedTheme.primaryTextTheme),
    );
    final textSize = appearance?.number('settingsTextSize') ?? 16;
    final foreground =
        appearance?.color('settingsTextColor') ?? theme.colorScheme.onSurface;
    final surface =
        (appearance?.color('settingsColor') ??
                theme.colorScheme.surface.withAlpha(255))
            .withValues(alpha: appearance?.number('settingsOpacity') ?? 1);
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          surface: surface,
          onSurface: foreground,
        ),
        textTheme: appearance?.color('settingsTextColor') == null
            ? theme.textTheme
            : theme.textTheme.apply(
                bodyColor: foreground,
                displayColor: foreground,
              ),
        iconTheme: appearance?.color('settingsTextColor') == null
            ? theme.iconTheme
            : theme.iconTheme.copyWith(color: foreground),
      ),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
            MediaQuery.textScalerOf(context).scale(16) / 16 * textSize / 16,
          ),
        ),
        child: DefaultTextStyle.merge(
          style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
          textHeightBehavior: const TextHeightBehavior(),
          child: Builder(builder: builder),
        ),
      ),
    );
  }
}
