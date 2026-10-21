import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../tile_appearance.dart';
import '../category_appearance.dart';

class AppearanceService extends ChangeNotifier {
  final focusedAppImage = ValueNotifier<ImageProvider?>(null);
  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    focusedAppImage.dispose();
    _previewTiles.clear();
    _previewCategories.clear();
    super.dispose();
  }
  final Map<Object, Rect? Function()> _previewTiles = {};
  final Map<Object, int> _previewCategories = {};
  Object? focusPreviewTile;
  void registerPreviewTile(Object key, Rect? Function() bounds, {int? categoryId}) {
    _previewTiles[key] = bounds;
    if (categoryId != null) _previewCategories[key] = categoryId;
  }
  void unregisterPreviewTile(Object key) {
    _previewTiles.remove(key);
    _previewCategories.remove(key);
    if (focusPreviewTile == key) endFocusPreview();
  }
  void beginFocusPreview(Rect visible, {int? categoryId}) {
    Object? selected;
    double score = double.infinity;
    for (final entry in _previewTiles.entries) {
      if (categoryId != null && _previewCategories[entry.key] != categoryId) continue;
      final bounds = entry.value();
      if (bounds == null || !visible.contains(bounds.topLeft) || !visible.contains(bounds.bottomRight)) continue;
      final distance = (bounds.center - visible.center).distanceSquared;
      if (distance < score) { selected = entry.key; score = distance; }
    }
    if (focusPreviewTile == selected) return;
    focusPreviewTile = selected;
    notifyListeners();
  }
  void endFocusPreview() {
    if (focusPreviewTile == null) return;
    focusPreviewTile = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) notifyListeners();
    });
  }
  final SharedPreferences preferences;
  AppearanceService(this.preferences);
  TileAppearance get appearance {
    final stored = TileAppearance.decode(preferences.getString(tileAppearanceKey));
    return TileAppearance({
      if (preferences.containsKey('show_app_names_below_icons'))
        'labels': preferences.getBool('show_app_names_below_icons') == true ? 'all' : 'none',
      if (preferences.containsKey('show_category_titles'))
        'sectionTitles': preferences.getBool('show_category_titles'),
      ...stored.values,
    });
  }
  TileAppearance tilesFor(int id) {
    final style = category(id);
    return TileAppearance({...({...appearance.values}..remove('sectionPadding')),
      if (style.values.containsKey('padding')) 'sectionPadding': style.padding,
      if (style.values.containsKey('background')) 'sectionBackground': style.values['background'],
      if (!style.useGlobalTiles) ...style.tiles});
  }
  Future<void> setCategoryTile(int id, String key, dynamic value) async {
    final values = {...category(id).values, 'useGlobalTiles': false,
      'tiles': {...(category(id).useGlobalTiles ? <String, dynamic>{} : category(id).tiles),
        ...TileAppearance.validValues({key: value})}};
    final all = CategoryAppearance.decode(preferences.getString(categoryAppearanceKey));
    all['$id'] = CategoryAppearance.validValues(values);
    if (!await preferences.setString(categoryAppearanceKey, jsonEncode(all))) throw StateError('Unable to save category');
    notifyListeners();
  }
  Future<void> inheritField(int id, String key) async {
    await resetFields([key], categoryId: id);
  }
  Future<void> resetCategoryLayout(int id, {required bool grid}) async {
    final all = CategoryAppearance.decode(preferences.getString(categoryAppearanceKey));
    all['$id'] = {...category(id).values, 'layout': grid ? 'grid' : 'row',
      'columns': grid ? 6 : 0, 'rows': 2, 'maxRows': grid ? 3 : 0};
    if (!await preferences.setString(categoryAppearanceKey, jsonEncode(all))) throw StateError('Unable to reset layout');
    notifyListeners();
  }
  Future<void> resetCategoryStyle(int id) async {
    final all = CategoryAppearance.decode(preferences.getString(categoryAppearanceKey));
    final fields = {...category(id).values}..remove('tiles')..remove('padding')..remove('background');
    fields['useGlobalTiles'] = true; all['$id'] = fields;
    if (!await preferences.setString(categoryAppearanceKey, jsonEncode(all))) throw StateError('Unable to reset category');
    notifyListeners();
  }
  Future<void> setUseGlobalTiles(int id, bool useGlobal) async {
    await setCategory(id, 'useGlobalTiles', useGlobal);
  }
  CategoryAppearance category(int id) => CategoryAppearance(
    (CategoryAppearance.decode(preferences.getString(categoryAppearanceKey))['$id'] as Map<String, dynamic>?) ?? {});
  Future<void> setTapeRows(int id, int rows) async {
    if (id <= 0 || rows < 1 || rows > 6) return;
    final values = CategoryAppearance.decode(preferences.getString(categoryAppearanceKey));
    values['$id'] = {...category(id).values,
      'layout': rows == 1 ? 'row' : 'rows', 'rows': rows};
    if (!await preferences.setString(categoryAppearanceKey, jsonEncode(values))) {
      throw StateError('Unable to save tape rows');
    }
    notifyListeners();
  }
  Future<void> setCategory(int id, String key, dynamic value) async {
    if (id <= 0) return;
    final values = CategoryAppearance.decode(preferences.getString(categoryAppearanceKey));
    values['$id'] = {...category(id).values, ...CategoryAppearance.validValues({key: value})};
    if (!await preferences.setString(categoryAppearanceKey, jsonEncode(values))) throw StateError('Unable to save category appearance');
    notifyListeners();
  }
  Future<void> set(String key, dynamic value) async {
    final next = {...appearance.values, ...TileAppearance.validValues({key: value})};
    if (!await preferences.setString(tileAppearanceKey, jsonEncode(next))) throw StateError('Unable to save appearance');
    notifyListeners();
  }
  Future<void> setPanelOrder(List<String> left, List<String> right) async {
    final next = {...appearance.values,
      'panelButtonsOrder': left, 'panelInfoOrder': right};
    if (!await preferences.setString(tileAppearanceKey, jsonEncode(next))) {
      throw StateError('Unable to save panel order');
    }
    notifyListeners();
  }
  Future<void> reset() async {
    final navigation = {...appearance.values}..removeWhere((key, _) => !['sectionScroll', 'sectionPosition'].contains(key));
    navigation.addAll({'labels': 'none', 'sectionTitles': true});
    if (!await preferences.setString(tileAppearanceKey, jsonEncode(navigation))) throw StateError('Unable to reset appearance');
    final all = CategoryAppearance.decode(preferences.getString(categoryAppearanceKey));
    for (final id in all.keys.toList()) {
      all[id] = {...(all[id] as Map<String, dynamic>)}..remove('tiles')..remove('padding')..remove('background')..remove('useGlobalTiles');
    }
    if (!await preferences.setString(categoryAppearanceKey, jsonEncode(all))) throw StateError('Unable to reset category appearance');
    notifyListeners();
  }
  void reload() => notifyListeners();
  Future<void> resetFields(Iterable<String> keys, {int? categoryId}) async {
    if (categoryId != null) {
      final tiles = {...category(categoryId).tiles}..removeWhere((key, _) => keys.contains(key));
      final fields = {...category(categoryId).values, 'tiles': tiles};
      if (keys.contains('sectionPadding')) fields.remove('padding');
      if (keys.contains('sectionBackground')) fields.remove('background');
      final all = CategoryAppearance.decode(preferences.getString(categoryAppearanceKey));
      all['$categoryId'] = fields;
      if (!await preferences.setString(categoryAppearanceKey, jsonEncode(all))) throw StateError('Unable to reset fields');
      notifyListeners();
      return;
    }
    final next = {...appearance.values}..removeWhere((key, _) => keys.contains(key));
    if (keys.contains('labels')) next['labels'] = 'none';
    if (keys.contains('sectionTitles')) next['sectionTitles'] = true;
    if (!await preferences.setString(tileAppearanceKey, jsonEncode(next))) {
      throw StateError('Unable to reset appearance section');
    }
    notifyListeners();
  }
}
