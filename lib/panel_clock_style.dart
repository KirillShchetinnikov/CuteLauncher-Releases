import 'package:flutter/material.dart';

import 'app_fonts.dart';

/// Validated overrides for the shared panel clock; omitted fields inherit the panel.
class PanelClockStyle {
  final Map<String, dynamic> values;
  const PanelClockStyle([this.values = const {}]);
  static const fonts = {'system': 'Roboto', ...AppFonts.families};
  // Match the wght axes of the bundled variable fonts and the actual static faces.
  static const _variableWeightRanges = <String, (int, int)>{
    'Medeo Sans': (100, 900),
    'Medeo Mono': (100, 900),
    'Outfit': (100, 900),
    'Onest': (100, 900),
    'Manrope': (200, 800),
    'PanelSans': (100, 900),
    'PanelSerif': (100, 900),
    'PanelMono': (100, 700),
    'PanelCondensed': (100, 900),
  };
  TextStyle _localizedBase(TextStyle inherited, Locale? locale) {
    final style = inherited.copyWith(
      fontFamily: fonts[values['font']] ?? inherited.fontFamily,
    );
    return locale == null ? style : AppFonts.localize(style, locale);
  }

  static List<int> _weights(String? family) {
    final range = _variableWeightRanges[family];
    if (range != null) {
      return [for (var w = range.$1; w <= range.$2; w += 100) w];
    }
    // 600 and 700 select identical upright glyphs in the bundled family.
    if (family == 'Google Sans') return const [400, 500, 700];
    // System/fallback fonts guarantee normal and bold, without duplicate faces.
    return const [400, 700];
  }

  List<int> availableWeights(TextStyle inherited, {Locale? locale}) =>
      _weights(_localizedBase(inherited, locale).fontFamily);
  String get preset => values['italic'] == true ? 'italic' : 'default';
  static const fontStyles = <String, Map<String, dynamic>>{
    'default': {'italic': false},
    'italic': {'italic': true},
  };
  Map<String, dynamic> withFontStyle(String id) => {
    ...values,
    ...?fontStyles[id],
    'preset': id,
  };
  bool get clockOnRight => values['clockOnRight'] == true;
  double get spacing => (values['spacing'] as num?)?.toDouble() ?? 12;
  bool get inheritBackground => values['inheritBackground'] != false;
  bool get animate => values['animate'] != false;
  double size(double inherited) =>
      (values['size'] as num?)?.toDouble() ?? inherited;
  double radius(double inherited) => inheritBackground
      ? inherited
      : (values['radius'] as num?)?.toDouble() ?? inherited;
  bool backgroundEnabled(Color inherited) => inheritBackground
      ? inherited.a > 0
      : values['background'] as bool? ?? true;
  Color background(Color inherited) => inheritBackground
      ? inherited
      : !backgroundEnabled(inherited)
      ? Colors.transparent
      : (values['backgroundColor'] is int
                ? Color(values['backgroundColor'])
                : inherited.withAlpha(255))
            .withValues(alpha: (values['opacity'] as num?)?.toDouble() ?? 1);
  TextStyle textStyle(TextStyle inherited, {Locale? locale}) {
    final base = _localizedBase(inherited, locale);
    final requested = values['weight'] as int? ?? 400;
    final weight = _weights(
      base.fontFamily,
    ).reduce((a, b) => (b - requested).abs() <= (a - requested).abs() ? b : a);
    final color = values['color'] is int
        ? Color(values['color'])
        : inherited.color;
    return base.copyWith(
      fontSize: size(inherited.fontSize ?? 18),
      fontWeight: FontWeight.values[weight ~/ 100 - 1],
      fontVariations: _variableWeightRanges.containsKey(base.fontFamily)
          ? [FontVariation('wght', weight.toDouble())]
          : const [],
      fontStyle: values['italic'] == true ? FontStyle.italic : FontStyle.normal,
      color: color,
      shadows: values['glow'] == true
          ? [Shadow(color: color ?? Colors.white, blurRadius: 8)]
          : const [],
    );
  }

  static Map<String, dynamic> validValues(
    dynamic input, {
    bool combined = false,
  }) {
    if (input is! Map) return {};
    final result = <String, dynamic>{};
    for (final entry in input.entries) {
      final key = entry.key, value = entry.value;
      if (key is! String) continue;
      if (key == 'preset' && fontStyles.containsKey(value) ||
          key == 'font' && fonts.containsKey(value) ||
          key == 'weight' &&
              [for (var w = 100; w <= 900; w += 100) w].contains(value) ||
          [
                'background',
                'inheritBackground',
                'glow',
                'animate',
                'italic',
                'clockOnRight',
              ].contains(key) &&
              value is bool) {
        result[key] = value;
      }
      if (['color', 'backgroundColor'].contains(key) &&
          value is int &&
          value >= 0 &&
          value <= 0xffffffff) {
        result[key] = value;
      }
      final range = switch (key) {
        'size' => (10, combined ? 24 : 40),
        'spacing' => (0, 32),
        'radius' => (0, 26),
        'opacity' => (0, 1),
        _ => null,
      };
      if (range != null &&
          value is num &&
          value.isFinite &&
          value >= range.$1 &&
          value <= range.$2) {
        result[key] = value;
      }
    }
    return result;
  }
}
