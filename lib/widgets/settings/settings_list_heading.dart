import 'package:flutter/material.dart';

import '../../theme/settings_section_tokens.dart';
import 'settings_panel_style.dart';

/// A non-interactive list heading with a neutral rule after its final text line.
/// Unlike SettingsSection, this does not wrap the list or select a group style.
class SettingsListHeading extends StatelessWidget {
  const SettingsListHeading({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    if (title.isEmpty) return const SizedBox.shrink();
    final defaults = DefaultTextStyle.of(context);
    final style = SettingsPanelStyle.fullTextMetrics(
      defaults.style.merge(Theme.of(context).textTheme.titleMedium),
    )!;
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final locale = Localizations.maybeLocaleOf(context);
    const heightBehavior = TextHeightBehavior();
    final strut = style.fontFamily == 'Manrope'
        ? StrutStyle.fromTextStyle(style, height: 1.5)
        : null;
    final text = Text(
      title,
      style: style,
      textAlign: TextAlign.start,
      textDirection: direction,
      textScaler: scaler,
      locale: locale,
      textHeightBehavior: heightBehavior,
      strutStyle: strut,
      softWrap: true,
      overflow: TextOverflow.visible,
    );
    return Semantics(
      container: true,
      header: true,
      child: Padding(
        padding: SettingsSectionTokens.listHeadingPadding,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const gap = SettingsSectionTokens.listHeadingRuleGap;
            const reserve = gap + SettingsSectionTokens.listHeadingMinRule;
            if (!constraints.hasBoundedWidth ||
                constraints.maxWidth <= reserve) {
              return text;
            }
            // Measure exactly the same paragraph as the Text below. The rule
            // follows the last word even when a translation wraps onto two lines.
            final painter = TextPainter(
              text: TextSpan(text: title, style: style),
              textDirection: direction,
              textAlign: TextAlign.start,
              textScaler: scaler,
              locale: locale,
              textHeightBehavior: heightBehavior,
              strutStyle: strut,
            )..layout(
              minWidth: constraints.maxWidth - reserve,
              maxWidth: constraints.maxWidth - reserve,
            );
            final lastLine = painter.computeLineMetrics().last;
            final left = direction == TextDirection.ltr
                ? lastLine.left + lastLine.width + gap
                : 0.0;
            final right = direction == TextDirection.rtl
                ? constraints.maxWidth - (reserve + lastLine.left - gap)
                : 0.0;
            final top =
                lastLine.baseline + (lastLine.descent - lastLine.ascent) / 2;
            painter.dispose();
            final color =
                style.color ?? Theme.of(context).colorScheme.onSurface;
            return SizedBox(
              width: constraints.maxWidth,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: reserve),
                    child: SizedBox(
                      width: constraints.maxWidth - reserve,
                      child: text,
                    ),
                  ),
                  Positioned(
                    left: left,
                    right: right,
                    top: top,
                    child: ExcludeSemantics(
                      child: ColoredBox(
                        key: const ValueKey('settings-list-heading-rule'),
                        color: color.withValues(
                          alpha:
                              color.a *
                              SettingsSectionTokens.listHeadingRuleOpacity,
                        ),
                        child: const SizedBox(
                          height: SettingsSectionTokens.dividerWidth,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
