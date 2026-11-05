import 'tile_image_geometry.dart';
import 'dart:convert';
import 'app_fonts.dart';
import 'panel_layout.dart';
import 'panel_clock_style.dart';

import 'package:flutter/material.dart';

const tileAppearanceKey = 'tile_appearance';

enum SettingsScrollbarMode { hidden, onScroll, always }

class TileAppearance {
  final Map<String, dynamic> values;
  const TileAppearance([this.values = const {}]);
  /// Resolved values for fields that may inherit from the common home style.
  dynamic homeFieldValue(String key) => switch (key) {
    'size' => tileSize,
    'aspectRatio' => aspectRatio,
    'bannerImageMode' => bannerImageMode.name,
    'iconImageMode' => iconImageMode.name,
    'horizontalGap' => horizontalGap,
    'verticalGap' => verticalGap,
    'iconScale' => iconScale,
    'labels' => labels,
    'labelPosition' => labelPosition,
    'labelSize' => labelSize,
    'labelColor' => color('labelColor')?.toARGB32() ?? 0xffffffff,
    'backgroundColor' => color('backgroundColor')?.toARGB32(),
    'opacity' => opacity,
    'shadow' => number('shadow') ?? 0,
    'blurTiles' => blurTiles,
    'sectionTitles' => sectionTitles,
    'sectionIcons' => sectionIcons,
    'sectionPadding' => number(key) ?? 0,
    'sectionBackground' => values[key] ?? 0,
    'sectionOpacity' => sectionOpacity,
    'sectionRadius' => sectionRadius,
    _ => values[key],
  };
  String get labels => values['labels'] as String? ?? 'none';
  bool get anchored => values['sectionScroll'] != 'free';
  double get sectionPosition => (number('sectionPosition') ?? 0.5).clamp(0, 0.70).toDouble();
  double get sectionGap => number('sectionGap') ?? 24;
  double get sectionOpacity => number('sectionOpacity') ?? 1;
  double get sectionRadius => number('sectionRadius') ?? 0;
  BoxDecoration sectionDecoration({Color? fallbackColor}) {
    final background = color('sectionBackground') ?? fallbackColor;
    return BoxDecoration(
      color: background?.withValues(alpha: background.a * sectionOpacity),
      borderRadius: BorderRadius.circular(sectionRadius),
    );
  }
  bool get sectionTitles => values['sectionTitles'] != false;
  bool get sectionIcons => values['sectionIcons'] == true;
  bool get active =>
      values.keys.any((key) => key != 'bannerImageMode' && key != 'iconImageMode' && key != 'imageMode' && key != 'fillBanner' && key != 'animateReordering' && key != 'labels' && !key.startsWith('section') && key != 'hideAbove' && key != 'inactiveOpacity' && !key.startsWith('panel') && !key.startsWith('settings') &&
          !key.startsWith('notice') && key != 'blurPanel' && key != 'focusAlignment');
  double? number(String key) => (values[key] as num?)?.toDouble();
  double get opacity => number('opacity') ?? 1;
  double get labelSize => number('labelSize') ?? 12;
  double get iconScale => number('iconScale') ?? 1;
  double get horizontalGap => number('horizontalGap') ?? 16;
  double get verticalGap => number('verticalGap') ?? 16;
  double get aspectRatio => number('aspectRatio') ?? 16 / 9;
  TileImageMode get bannerImageMode => switch (values['bannerImageMode']) {
    'cover' => TileImageMode.cover, 'edgeColor' => TileImageMode.edgeColor,
    'icon' => TileImageMode.icon, 'contain' => TileImageMode.contain,
    _ => TileImageMode.cover,
  };
  TileImageMode get iconImageMode => switch (values['iconImageMode']) {
    'cover' => TileImageMode.cover, 'edgeColor' => TileImageMode.edgeColor,
    _ => TileImageMode.contain,
  };
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
  String get informationAction => values['panelInformationAction'] as String? ??
      (values.containsKey('panelDateCalendar') ? (dateCalendar ? 'calendar' : 'none') : 'both');
  int get forecastDays => (number('panelForecastDays') ?? 5).toInt();
  bool get detailedForecast => values['panelForecastView'] == 'list';
  bool get panelWrapNavigation => values['panelWrapNavigation'] == true;
  bool get combinedInformation => values['panelCombinedInformation'] == true;
  bool get informationOnBackground => values['panelInformationPlacement'] == 'background';
  String informationPlacement(String id, {required bool visible}) {
    final placements = values['panelInformationPlacements'];
    if (placements is Map && placements[id] is String) return placements[id] as String;
    return !visible ? 'hidden' : informationOnBackground ? 'background' : 'panel';
  }
  PanelClockStyle get backgroundInformationStyle => PanelClockStyle(
    PanelClockStyle.validValues(values['panelBackgroundInformationStyle'] ?? values['panelInformationStyle'], combined: true));
  double get backgroundInformationSize => number('panelBackgroundInformationSize') ?? 96;
  bool get backgroundInformationAboveLandscape => values['panelBackgroundInformationAboveLandscape'] == true;
  bool get backgroundInformationAboveWeather => values['panelBackgroundInformationAboveWeather'] == true;
  static const defaultBackgroundInformationOrder = ['date', 'weather', 'time'];
  static List<String> cleanBackgroundInformationOrder(dynamic value) => [
    ...{if (value is List) ...value.whereType<String>().where(defaultBackgroundInformationOrder.contains)},
    ...defaultBackgroundInformationOrder.where((id) => value is! List || !value.contains(id)),
  ];
  List<String> get backgroundInformationOrder =>
      cleanBackgroundInformationOrder(values['panelBackgroundInformationOrder']);
  String get backgroundInformationAlignment => values['panelBackgroundInformationAlignment'] as String? ?? 'center';
  SettingsScrollbarMode get settingsScrollbarMode =>
      switch (values['settingsScrollbarMode']) {
        'hidden' => SettingsScrollbarMode.hidden,
        'onScroll' => SettingsScrollbarMode.onScroll,
        _ => SettingsScrollbarMode.always,
      };
  String get interfaceStyle => values['settingsInterfaceStyle'] as String? ?? 'standard';
  String get interfaceFont => values['settingsInterfaceFont'] as String? ??
      (interfaceStyle == 'standard' ? 'system' : 'outfit');
  PanelClockStyle get clockStyle => PanelClockStyle(PanelClockStyle.validValues(values['panelClockStyle']));
  PanelClockStyle get informationStyle => PanelClockStyle(
    PanelClockStyle.validValues(values['panelInformationStyle'] ?? values['panelClockStyle'], combined: true));
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
    fontFamily: panelFont == 'system' ? 'Roboto' : AppFonts.families[panelFont] ?? 'PanelSans',
    fontWeight: FontWeight.w400,
    color: panelTextColor,
  );
  TextStyle panelTextStyleFor(Locale locale) => AppFonts.localize(panelTextStyle, locale);
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
      'sectionOpacity': (0, 1), 'sectionRadius': (0, 64),
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
      'panelBackgroundInformationSize': (48, 144),
    };
    const choices = {
      'bannerImageMode': ['contain', 'cover', 'edgeColor', 'icon'],
      'iconImageMode': ['contain', 'cover', 'edgeColor'],
      'panelInformationPlacement': ['panel', 'background'],
      'panelBackgroundInformationAlignment': ['left', 'center', 'right'],
      'panelInformationAction': ['weather', 'calendar', 'both', 'none'],
      'panelForecastView': ['cards', 'list'],
      'noticeCorner': ['bottomRight', 'bottomLeft', 'topRight', 'topLeft'],
      'labelPosition': ['below', 'inside'],
      'labels': ['none', 'selected', 'all'], 'sectionScroll': ['free', 'anchored'],
      'focusEffect': ['scale', 'border', 'lift'],
      'focusBorderColor': ['accent', 'dynamic'],
      'focusBorderStyle': ['outline', 'glow', 'none'],
      'panelFont': AppFonts.panelIds,
      'settingsInterfaceStyle': ['standard', 'glass', 'soft', 'outline'],
      'settingsInterfaceFont': AppFonts.interfaceIds,
      'settingsScrollbarMode': ['hidden', 'onScroll', 'always'],
    };
    for (final entry in input.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String) continue;
      if (key == 'panelBackgroundInformationOrder' && value is List) {
        result[key] = cleanBackgroundInformationOrder(value);
        continue;
      }
      if (key == 'panelForecastDays' && value is int && [3, 5, 7].contains(value)) {
        result[key] = value;
        continue;
      }
      if (key == 'panelInformationPlacements' && value is Map) {
        result[key] = <String, String>{
          for (final id in ['time', 'date', 'weather'])
            if (['hidden', 'panel', 'background'].contains(value[id])) id: value[id] as String,
        };
        continue;
      }
      if (['panelClockStyle', 'panelInformationStyle', 'panelBackgroundInformationStyle'].contains(key) && value is Map) {
        result[key] = PanelClockStyle.validValues(value, combined: key != 'panelClockStyle');
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
            'settingsScrollbarAlwaysVisible',
            'panelTextBackground',
            'panelDateCalendar',
            'panelCombinedInformation',
            'panelBackgroundInformationAboveLandscape',
            'panelBackgroundInformationAboveWeather',
            'panelWrapNavigation',
          ].contains(key) &&
          value is bool) {
        result[key] = value;
      }
    }
    // Old shared settings become two explicit values. New banner-only edits
    // never manufacture an icon override or shadow its live inheritance.
    if (['contain', 'cover', 'edgeColor', 'icon'].contains(input['imageMode'])) {
      final shared = input['imageMode'] as String;
      result.putIfAbsent('bannerImageMode', () => shared);
      result.putIfAbsent('iconImageMode', () => shared == 'icon' ? 'edgeColor' : shared);
    } else if (input['fillBanner'] is bool) {
      result.putIfAbsent('bannerImageMode', () => input['fillBanner'] == true ? 'cover' : 'contain');
    }
    return result;
  }

  static TileAppearance decode(String? source) {
    try {
      final values = validValues(jsonDecode(source ?? '{}'));
      return TileAppearance(Map.unmodifiable(_migrateScrollbar(values)));
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
    return jsonEncode({...previous, ..._migrateScrollbar(validValues(input))});
  }

  static Map<String, dynamic> _migrateScrollbar(Map<String, dynamic> values) {
    // Keep the old field valid on the wire, but resolve it before merging.
    final legacy = values.remove('settingsScrollbarAlwaysVisible');
    if (legacy is bool) {
      values.putIfAbsent(
        'settingsScrollbarMode',
        () => legacy ? 'always' : 'onScroll',
      );
    }
    return values;
  }
}
