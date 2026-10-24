import 'package:flutter/material.dart';

/// Value labels wrap between words and shrink only when a whole word cannot fit.
class SettingsValueText extends StatelessWidget {
  final Text text;
  final TextAlign alignment;

  const SettingsValueText({
    super.key,
    required this.text,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final value = text.data;
    if (value == null || value.isEmpty) return text;
    final defaults = DefaultTextStyle.of(context);
    final style = defaults.style.merge(text.style);
    final scaler = text.textScaler ?? MediaQuery.textScalerOf(context);
    final direction = text.textDirection ?? Directionality.of(context);
    final locale = text.locale ?? Localizations.maybeLocaleOf(context);
    // Android's cached paragraph can trim Manrope's first line after a focus
    // repaint, even when its reported height fits. Keep font-sized headroom
    // inside the paragraph itself, including the first ascent/last descent.
    final manrope = style.fontFamily == 'Manrope';
    final heightBehavior =
        text.textHeightBehavior ??
        (manrope ? const TextHeightBehavior() : defaults.textHeightBehavior);
    StrutStyle? strut(TextStyle current) =>
        text.strutStyle ??
        (manrope
            ? StrutStyle.fromTextStyle(
                current,
                height: 1.5,
                forceStrutHeight: false,
              )
            : null);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth || constraints.maxWidth <= 0) {
          return text;
        }
        final matches = RegExp(r'\S+').allMatches(value).toList();
        final words = matches.map((m) => m.group(0)!).toList();
        if (words.isEmpty) return text;
        final painter = TextPainter(
          textDirection: direction,
          textScaler: scaler,
          locale: locale,
          textHeightBehavior: heightBehavior,
          strutStyle: strut(style),
        );
        var fittedStyle = style;
        double width(String label) {
          painter.strutStyle = strut(fittedStyle);
          painter.text = TextSpan(text: label, style: fittedStyle);
          painter.layout();
          return painter.width;
        }

        final available = constraints.maxWidth;
        final fontSize = style.fontSize ?? 14;
        bool fitsWholeWords() {
          if (words.any((word) => width(word) > available)) return false;
          painter.text = TextSpan(text: value, style: fittedStyle);
          painter.layout(maxWidth: available);
          for (final match in matches) {
            final boxes = painter.getBoxesForSelection(
              TextSelection(baseOffset: match.start, extentOffset: match.end),
            );
            if (boxes.any((box) => (box.top - boxes.first.top).abs() > 0.01)) {
              return false;
            }
          }
          return true;
        }

        if (!fitsWholeWords()) {
          var low = 0.0;
          var high = fontSize;
          for (var i = 0; i < 16; i++) {
            final size = (low + high) / 2;
            fittedStyle = style.copyWith(fontSize: size);
            if (fitsWholeWords()) {
              low = size;
            } else {
              high = size;
            }
          }
          fittedStyle = style.copyWith(fontSize: low);
        }
        painter.dispose();
        return Text(
          value,
          style: fittedStyle,
          textAlign: alignment,
          textDirection: direction,
          textScaler: scaler,
          locale: locale,
          softWrap: true,
          overflow: text.overflow,
          maxLines: text.maxLines,
          semanticsLabel: text.semanticsLabel,
          strutStyle: strut(fittedStyle),
          textWidthBasis: text.textWidthBasis,
          textHeightBehavior: heightBehavior,
        );
      },
    );
  }
}
