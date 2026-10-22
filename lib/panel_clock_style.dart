import 'package:flutter/material.dart';

import 'app_fonts.dart';

/// Validated overrides for the shared panel clock; omitted fields inherit the panel.
class PanelClockStyle {
  final Map<String, dynamic> values;
  const PanelClockStyle([this.values = const {}]);
  static const fonts = {'system': 'Roboto', ...AppFonts.families};
  static const presets = <String, Map<String, dynamic>>{
    'default': {},
    'minimal': {
      'inheritBackground': false,
      'font': 'sans-serif',
      'weight': 300,
      'background': false,
      'size': 22,
    },
    'elegant': {
      'inheritBackground': false,
      'font': 'serif',
      'weight': 400,
      'color': 0xffffd54f,
      'background': false,
      'size': 24,
    },
    'digital': {
      'inheritBackground': false,
      'font': 'monospace',
      'weight': 700,
      'color': 0xff80efb0,
      'background': true,
      'backgroundColor': 0xff101820,
      'opacity': 1.0,
      'radius': 4.0,
      'size': 26,
    },
    'neon': {
      'inheritBackground': false,
      'font': 'sans-serif-condensed',
      'weight': 400,
      'color': 0xffd7a9ff,
      'background': false,
      'glow': true,
      'size': 26,
    },
  };
  String get preset => values['preset'] as String? ?? 'default';
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
    final color = values['color'] is int
        ? Color(values['color'])
        : inherited.color;
    final style = inherited.copyWith(
      fontSize: size(inherited.fontSize ?? 18),
      fontFamily: fonts[values['font']] ?? inherited.fontFamily,
      fontWeight: switch (values['weight']) {
        300 => FontWeight.w300,
        700 => FontWeight.w700,
        _ => FontWeight.w400,
      },
      color: color,
      shadows: values['glow'] == true
          ? [Shadow(color: color ?? Colors.white, blurRadius: 8)]
          : const [],
    );
    return locale == null ? style : AppFonts.localize(style, locale);
  }

  static Map<String, dynamic> validValues(dynamic input) {
    if (input is! Map) return {};
    final result = <String, dynamic>{};
    for (final entry in input.entries) {
      final key = entry.key, value = entry.value;
      if (key is! String) continue;
      if (key == 'preset' && [...presets.keys, 'custom'].contains(value) ||
          key == 'font' && fonts.containsKey(value) ||
          key == 'weight' && [300, 400, 700].contains(value) ||
          [
                'background',
                'inheritBackground',
                'glow',
                'animate',
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
        'size' => (10, 40),
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
