import 'dart:convert';
import 'panel_layout.dart';
import 'panel_clock_style.dart';

import 'package:flutter/material.dart';

const tileAppearanceKey = 'tile_appearance';

class TileAppearance {
  final Map<String, dynamic> values;
  const TileAppearance([this.values = const {}]);
  String get labels => values['labels'] as String? ?? 'none';
  bool get anchored => values['sectionScroll'] != 'free';
  double get sectionPosition => (number('sectionPosition') ?? 0.5).clamp(0, 0.70).toDouble();
  double get sectionGap => number('sectionGap') ?? 24;
  bool get sectionTitles => values['sectionTitles'] != false;
  bool get sectionIcons => values['sectionIcons'] == true;
  bool get active =>
      values.keys.any((key) => key != 'animateReordering' && key != 'labels' && !key.startsWith('section') && key != 'hideAbove' && key != 'inactiveOpacity' && !key.startsWith('panel') && !key.startsWith('settings') &&
          !key.startsWith('notice') && key != 'blurPanel' && key != 'focusAlignment');
  double? number(String key) => (values[key] as num?)?.toDouble();
  double get opacity => number('opacity') ?? 1;
  double get labelSize => number('labelSize') ?? 12;
  double get iconScale => number('iconScale') ?? 1;
  double get horizontalGap => number('horizontalGap') ?? 16;
  double get verticalGap => number('verticalGap') ?? 16;
  double get aspectRatio => number('aspectRatio') ?? 16 / 9;
  Color? color(String key) =>
      values[key] is int ? (key == 'sectionBackground' ? Color(values[key] as int) : Color(values[key] as int).withAlpha(255)) : null;
  TextStyle get labelStyle {
    final foreground = color('labelColor') ?? Colors.white;
    return TextStyle(
      fontSize: labelSize,
      color: foreground,
      shadows: [
        Shadow(
          color: foreground.computeLuminance() > 0.5
              ? Colors.black
              : Colors.white,
          blurRadius: 3,
        ),
      ],
    );
  }

  Color get labelBackground =>
      (color('labelColor') ?? Colors.white).computeLuminance() > 0.5
      ? Colors.black.withValues(alpha: 0.70)
      : Colors.white.withValues(alpha: 0.85);
  String get labelPosition => values['labelPosition'] as String? ?? 'below';
  String get focusEffect => values['focusEffect'] == 'shadow' ? 'border' : values['focusEffect'] as String? ?? 'scale';
  double get focusStrength => number('focusStrength') ?? 0.1;
  double get focusScale => focusEffect == 'scale' ? (number('focusScale') ?? focusStrength) : 0;
  bool get showFocusShadow => values['focusShadow'] == true;
  bool get animateReordering => values['animateReordering'] != false;
  double get focusLift => (number('focusLift') ?? 10).clamp(0, 25).toDouble();
  String focusBorderStyle({bool legacyHidden = false}) =>
      values['focusBorderStyle'] as String? ?? (legacyHidden ? 'none' : 'outline');
  bool get dynamicFocusColor => values['focusBorderColor'] == 'dynamic';
  bool get blurTiles => values['blurTiles'] == true;
  bool get blurPanel => values['blurPanel'] == true;
  bool get dateCalendar => values['panelDateCalendar'] == true;
  PanelClockStyle get clockStyle => PanelClockStyle(PanelClockStyle.validValues(values['panelClockStyle']));
  double get panelTextSize => number('panelTextSize') ?? 18;
  String get panelFont => values['panelFont'] as String? ?? 'sans-serif';
  Color get panelTextColor => color('panelTextColor') ?? Colors.white;
  double get panelTextBackgroundOpacity =>
      number('panelTextBackgroundOpacity') ?? 1;
  Color get panelItemBackground => values['panelTextBackground'] == false
      ? Colors.transparent
      : (color('panelTextBackgroundColor') ?? const Color(0xff242935))
            .withValues(alpha: panelTextBackgroundOpacity);

  static const panelButtons = PanelLayout.buttons;
  static const panelInfo = PanelLayout.information;
  PanelLayout get panelLayout => PanelLayout(values['panelButtonsOrder'], values['panelInfoOrder']);
  List<String> panelOrder(String key) => key == 'panelButtonsOrder'
      ? panelLayout.left : panelLayout.right;

  TextStyle get panelTextStyle => TextStyle(
    fontSize: panelTextSize,
    fontFamily: switch (panelFont) {
      'serif' => 'PanelSerif',
      'monospace' => 'PanelMono',
      'sans-serif-condensed' => 'PanelCondensed',
      _ => 'PanelSans',
    },
    fontWeight: FontWeight.w400,
    color: panelTextColor,
  );
  double get tileSize => number('size') ?? 128;
  double get focusAlignment => number('focusAlignment') ?? 0.5;
  int columns(int base, {double? width}) =>
      number('size') == null || width == null
      ? base
      : ((width - 32 + horizontalGap) /
                (tileSize * aspectRatio + horizontalGap))
            .floor()
            .clamp(1, 12);

  static Map<String, dynamic> validValues(dynamic input) {
    if (input is! Map) return {};
    final result = <String, dynamic>{};
    const ranges = {
      'size': (64, 256),
      'sectionPosition': (0, 1), 'sectionGap': (0, 96),
      'sectionPadding': (0, 64), 'inactiveOpacity': (0, 1),
      'radius': (0, 100),
      'horizontalGap': (0, 48),
      'verticalGap': (0, 48),
      'settingsOpacity': (0, 1),
      'settingsTextSize': (12, 24),
      'noticeOpacity': (0, 1),
      'noticeTextSize': (12, 24),
      'noticeWidth': (240, 600),
      'opacity': (0, 1),
      'shadow': (0, 16),
      'labelSize': (10, 20),
      'iconScale': (0.5, 1),
      'focusStrength': (0, 0.15),
      'focusScale': (0, 0.5),
      // Accept the old range when loading settings/backups, then cap below.
      'focusLift': (0, 50),
      'focusAlignment': (0, 1),
      'panelOpacity': (0, 1),
      'panelTextBackgroundOpacity': (0, 1),
      'panelTextSize': (10, 24),
    };
    const choices = {
      'labelPosition': ['below', 'inside'],
      'labels': ['none', 'selected', 'all'], 'sectionScroll': ['free', 'anchored'],
      'focusEffect': ['scale', 'border', 'lift'],
      'focusBorderColor': ['accent', 'dynamic'],
      'focusBorderStyle': ['outline', 'glow', 'none'],
      'panelFont': ['sans-serif', 'serif', 'monospace', 'sans-serif-condensed'],
    };
    for (final entry in input.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String) continue;
      if (key == 'panelClockStyle' && value is Map) {
        result[key] = PanelClockStyle.validValues(value);
        continue;
      }
      if (key == 'focusEffect' && value == 'shadow') {
        result[key] = 'border';
        continue;
      }
      if ((key == 'panelButtonsOrder' || key == 'panelInfoOrder') &&
          value is List) {
        result[key] = PanelLayout.clean(value);
      }
      if (value == null &&
          [
            'radius',
            'backgroundColor',
            'sectionBackground',
            'labelColor',
            'shadow',
            'panelColor',
          ].contains(key)) {
        result[key] = null;
        continue;
      }
      if (ranges.containsKey(key) &&
          value is num &&
          value.isFinite &&
          value >= ranges[key]!.$1 &&
          value <= ranges[key]!.$2) {
        result[key] = key == 'focusLift' ? value.clamp(0, 25)
            : key == 'sectionPosition' ? value.clamp(0, 0.70) : value;
      }
      if (choices.containsKey(key) && choices[key]!.contains(value)) {
        result[key] = value;
      }
      if ([
            'backgroundColor',
            'sectionBackground',
            'labelColor',
            'panelColor',
            'panelTextColor',
            'panelTextBackgroundColor',
            'settingsColor',
            'settingsTextColor',
            'noticeColor',
            'noticeTextColor',
          ].contains(key) &&
          value is int &&
          value >= 0 &&
          value <= 0xffffffff) {
        result[key] = value;
      }
      if (key == 'aspectRatio' &&
          value is num &&
          [1, 4 / 3, 16 / 9].contains(value)) {
        result[key] = value;
      }
      if ([
            'sectionTitles', 'sectionIcons', 'hideAbove',
            'focusPulse', 'focusTransition', 'animateReordering',
            'focusShadow',
            'blurTiles',
            'blurPanel',
            'panelTextBackground',
            'panelDateCalendar',
          ].contains(key) &&
          value is bool) {
        result[key] = value;
      }
    }
    return result;
  }

  static TileAppearance decode(String? source) {
    try {
      return TileAppearance(
        Map.unmodifiable(validValues(jsonDecode(source ?? '{}'))),
      );
    } catch (_) {
      return const TileAppearance();
    }
  }

  static String merge(String current, String incoming) {
    final previous = decode(current).values;
    dynamic input;
    try {
      input = jsonDecode(incoming);
    } catch (_) {
      return current;
    }
    return jsonEncode({...previous, ...validValues(input)});
  }
}
