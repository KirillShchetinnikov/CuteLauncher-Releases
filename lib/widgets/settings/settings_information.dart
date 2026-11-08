import 'package:flutter/material.dart';

import '../../theme/settings_info_tokens.dart';

enum SettingsMessageKind { info, warning, error }

/// A visible fact about the current control or operation, never hidden as help.
/// Actions remain separate standard settings controls.
class SettingsMessage extends StatelessWidget {
  const SettingsMessage({
    super.key,
    required this.text,
    this.kind = SettingsMessageKind.info,
    this.icon,
  });

  final String text;
  final SettingsMessageKind kind;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _InformationBody(
      icon:
          icon ??
          switch (kind) {
            SettingsMessageKind.info => Icons.info_outline_rounded,
            SettingsMessageKind.warning => Icons.warning_amber_rounded,
            SettingsMessageKind.error => Icons.error_outline_rounded,
          },
      iconColor: switch (kind) {
        SettingsMessageKind.info => colors.onSurface,
        SettingsMessageKind.warning => colors.tertiary,
        SettingsMessageKind.error => colors.error,
      },
      surface: true,
      liveRegion: kind == SettingsMessageKind.error,
      child: Text(text),
    );
  }
}

/// A short, visible empty-list state. General explanations belong in SettingsHelp.
class SettingsEmptyState extends StatelessWidget {
  const SettingsEmptyState({super.key, required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) =>
      _InformationBody(icon: icon, surface: false, child: Text(text));
}

/// Remote instructions retain the original localized reading order and wording.
/// Only universal key names and directional glyphs receive a keycap background;
/// punctuation and prose are not parsed into artificial actions or sentences.
class SettingsControlHint extends StatelessWidget {
  const SettingsControlHint({super.key, required this.text});

  final String text;
  static final _keys = RegExp(
    r'[◄►▲▼](?:\s*/\s*[◄►▲▼])*|\b(?:OK|Back)(?:\s*/\s*(?:OK|Back))*\b',
  );

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final spans = <InlineSpan>[];
    var start = 0;
    for (final match in _keys.allMatches(text)) {
      spans.add(TextSpan(text: text.substring(start, match.start)));
      spans.add(
        TextSpan(
          // Keep a key pair together visually without altering spoken text.
          text: match.group(0)!.replaceAll(' ', '\u00a0'),
          semanticsLabel: match.group(0),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            backgroundColor: color.withValues(
              alpha: color.a * SettingsInfoTokens.keyOpacity,
            ),
          ),
        ),
      );
      start = match.end;
    }
    spans.add(TextSpan(text: text.substring(start)));
    return _InformationBody(
      icon: Icons.settings_remote_outlined,
      surface: true,
      compact: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final inherited = DefaultTextStyle.of(context);
          final style = inherited.style.copyWith(
            fontSize: SettingsInfoTokens.controlHintFontSize,
            height: inherited.style.fontFamily == 'Manrope' ? 1.5 : 1.3,
          );
          final scaler = MediaQuery.textScalerOf(context);
          final painter = TextPainter(
            textDirection: Directionality.of(context),
            textScaler: scaler,
            locale: Localizations.maybeLocaleOf(context),
            textHeightBehavior: inherited.textHeightBehavior,
            maxLines: SettingsInfoTokens.controlHintLines,
          );
          bool fits(double size) {
            painter.text = TextSpan(
              style: style.copyWith(fontSize: size),
              children: spans,
            );
            painter.layout(maxWidth: constraints.maxWidth);
            return !painter.didExceedMaxLines;
          }

          // Fit the full translation rather than clipping long instructions.
          var size = SettingsInfoTokens.controlHintFontSize;
          if (!fits(size)) {
            var lower = 0.0, upper = size;
            for (var i = 0; i < 12; i++) {
              final candidate = (lower + upper) / 2;
              if (fits(candidate)) {
                lower = candidate;
              } else {
                upper = candidate;
              }
            }
            size = lower;
          }
          painter.dispose();
          return Text.rich(
            TextSpan(children: spans),
            style: style.copyWith(fontSize: size),
            textScaler: scaler,
            maxLines: SettingsInfoTokens.controlHintLines,
          );
        },
      ),
    );
  }
}

class _InformationBody extends StatelessWidget {
  const _InformationBody({
    required this.icon,
    required this.surface,
    required this.child,
    this.iconColor,
    this.liveRegion = false,
    this.compact = false,
  });

  final IconData icon;
  final Color? iconColor;
  final bool surface;
  final bool liveRegion;
  final bool compact;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      liveRegion: liveRegion,
      child: Padding(
        padding: compact
            ? SettingsInfoTokens.controlHintMargin
            : SettingsInfoTokens.margin,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surface
                ? colors.onSurface.withValues(
                    alpha:
                        colors.onSurface.a * SettingsInfoTokens.surfaceOpacity,
                  )
                : null,
            borderRadius: BorderRadius.circular(SettingsInfoTokens.radius),
          ),
          child: Padding(
            padding: compact
                ? SettingsInfoTokens.controlHintPadding
                : SettingsInfoTokens.padding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    icon,
                    size: compact
                        ? SettingsInfoTokens.controlHintIconSize
                        : SettingsInfoTokens.iconSize,
                    color: iconColor ?? colors.onSurface,
                  ),
                ),
                SizedBox(
                  width: compact
                      ? SettingsInfoTokens.controlHintGap
                      : SettingsInfoTokens.gap,
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
