import 'package:flutter/material.dart';

import '../weather_text_format.dart';

/// Use the same line limits before scaling the real widget or its preview.
double? weatherTextMaxWidth(
  WeatherTextFormat format, {
  double? backgroundScreenWidth,
}) => format.isStandard
    ? null
    : backgroundScreenWidth == null
    ? 300
    : backgroundScreenWidth * .75;

/// Keeps explicit line breaks while limiting the width of each custom line.
class WeatherDisplayText extends StatelessWidget {
  const WeatherDisplayText(
    this.text, {
    super.key,
    required this.style,
    this.maxWidth,
    this.singleLine = false,
    this.inlineIcon,
  });

  final String text;
  final TextStyle? style;
  final double? maxWidth;
  final bool singleLine;
  final Widget? inlineIcon;

  @override
  Widget build(BuildContext context) {
    final width = maxWidth;
    final display = singleLine ? text.replaceAll('\n', ' ') : text;
    Widget line(String value, {int? maxLines, TextOverflow? overflow}) {
      if (!value.contains(weatherInlineIcon)) {
        return Text(
          value,
          style: style,
          maxLines: maxLines,
          overflow: overflow,
        );
      }
      final parts = value.split(weatherInlineIcon);
      return Text.rich(
        TextSpan(
          children: [
            for (var i = 0; i < parts.length; i++) ...[
              if (i > 0 && inlineIcon != null)
                WidgetSpan(
                  child: inlineIcon!,
                  alignment: PlaceholderAlignment.middle,
                ),
              TextSpan(text: parts[i]),
            ],
          ],
        ),
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    if (width == null) return line(display, maxLines: singleLine ? 1 : null);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final value in display.split('\n'))
            // Custom output has at most two explicitly separated lines.
            // Each line keeps text and condition glyphs in the same flow.
            line(value, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
