import 'dart:convert';

import 'package:flutter/material.dart';
import 'tile_appearance.dart';

const categoryAppearanceKey = 'category_appearance';

class CategoryAppearance {
  final Map<String, dynamic> values;
  const CategoryAppearance([this.values = const {}]);
  double get padding => (values['padding'] as num?)?.toDouble() ?? 0;
  int get maxRows => values['maxRows'] as int? ?? 0;
  String get layout => values['layout'] as String? ?? 'auto';
  int get columns => values['columns'] as int? ?? 0;
  String resolvedLayout(bool legacyRow) => switch (layout) {
    'row' => 'row', 'rows' => 'rows', 'grid' => 'grid',
    'columns' => 'grid', _ => values.containsKey('layout') ? 'grid' : legacyRow ? 'row' : 'grid',
  };
  int resolvedColumns({required bool legacyRow, required int legacyColumns}) =>
      values.containsKey('columns') ? columns
          : layout == 'columns' || (resolvedLayout(legacyRow) == 'grid' && !values.containsKey('layout')) ? legacyColumns : 0;
  int get rows => values['rows'] as int? ?? 2;
  bool get useGlobalTiles => values['useGlobalTiles'] != false;
  Map<String, dynamic> get tiles =>
      TileAppearance.validValues(values['tiles'])
        ..removeWhere((key, _) => key.startsWith('focus') ||
            key == 'animateReordering' || key == 'inactiveOpacity');
  Color? get background =>
      values['background'] is int ? Color(values['background'] as int) : null;

  static Map<String, dynamic> validValues(dynamic input) {
    if (input is! Map) return {};
    final result = <String, dynamic>{};
    for (final entry in input.entries) {
      final v = entry.value;
      if (entry.key == 'layout' && ['auto', 'columns', 'rows', 'row', 'grid'].contains(v)) {
        result['layout'] = v;
      }
      if (entry.key == 'columns' && v is int && v >= 0 && v <= 12) result['columns'] = v;
      if (entry.key == 'rows' && v is int && v >= 1 && v <= 10) {
        result['rows'] = v;
      }
      if (entry.key == 'useGlobalTiles' && v is bool) {
        result['useGlobalTiles'] = v;
      }
      if (entry.key == 'tiles' && v is Map) {
        const keys = ['size', 'aspectRatio', 'radius', 'horizontalGap',
          'verticalGap', 'iconScale', 'labels', 'labelPosition', 'labelSize', 'labelColor',
          'backgroundColor', 'opacity', 'shadow', 'blurTiles', 'sectionPadding', 'sectionBackground',
          'sectionTitles', 'sectionIcons'];
        result['tiles'] = TileAppearance.validValues(v)
          ..removeWhere((key, _) => !keys.contains(key));
      }
      if (entry.key == 'padding' && v is num && v.isFinite && v >= 0 && v <= 64) {
        result['padding'] = v;
      }
      if (entry.key == 'maxRows' && v is int && v >= 0 && v <= 10) {
        result['maxRows'] = v;
      }
      if (entry.key == 'background' && v is int && v >= 0 && v <= 0xffffffff) {
        result['background'] = v;
      }
    }
    return result;
  }

  static Map<String, dynamic> decode(String? input) {
    try {
      final data = jsonDecode(input ?? '{}');
      if (data is! Map) return {};
      return {
        for (final entry in data.entries)
          if (entry.key is String &&
              int.tryParse(entry.key) != null &&
              int.parse(entry.key) > 0 &&
              entry.value is Map)
            entry.key as String: validValues(entry.value),
      };
    } catch (_) {
      return {};
    }
  }
}
