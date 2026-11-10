import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../tile_appearance.dart';
import '../information_formats.dart';
import 'remote_panel_service.dart';
import '../category_appearance.dart';
import '../models/category.dart';
import '../launcher_defaults.dart';
import '../panel_clock_style.dart';
import '../background_information_geometry.dart';

class AppearanceService extends ChangeNotifier {
  static const _labelFields = {'labels', 'labelPosition', 'labelSize', 'labelColor'};
  static const _contentLabelDefaults = {'labels': 'all', 'labelPosition': 'below'};
  final focusedAppImage = ValueNotifier<ImageProvider?>(null);
  final informationBounds = ValueNotifier<Rect?>(null);
  final backgroundInformationMetrics = ValueNotifier<BackgroundInformationMetrics?>(null);
  Object? _informationMetricsOwner;
  void reportBackgroundInformationMetrics(Object owner, BackgroundInformationMetrics? metrics) {
    if (_disposed || (metrics == null && owner != _informationMetricsOwner)) return;
    _informationMetricsOwner = metrics == null ? null : owner;
    backgroundInformationMetrics.value = metrics;
  }
  void reportInformationBounds(Rect? bounds) {
    if (!_disposed) informationBounds.value = bounds;
  }
  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    focusedAppImage.dispose();
    informationBounds.dispose();
    backgroundInformationMetrics.dispose();
    _informationMetricsOwner = null;
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
    final clockBehavior = decodeInformationClockBehavior(
      preferences.get(sharedInformationClockBehaviorKey),
    ) ?? legacyInformationClockBehavior(
      stored,
      showTime: preferences.getBool('show_time_in_status_bar') ?? true,
    );
    return TileAppearance({
      if (preferences.containsKey('show_app_names_below_icons'))
        'labels': preferences.getBool('show_app_names_below_icons') == true ? 'all' : 'none',
      if (preferences.containsKey('show_category_titles'))
        'sectionTitles': preferences.getBool('show_category_titles'),
      ...stored.values,
    }, clockBehavior);
  }

  InformationClockBehavior get informationClockBehavior =>
      appearance.informationClockBehavior!;

  Future<void> setInformationClockBehavior(InformationClockBehavior value) async {
    if (!await preferences.setString(sharedInformationClockBehaviorKey, jsonEncode(value.toMap()))) {
      throw StateError('Unable to save information clock behavior');
    }
    notifyListeners();
  }
  TileAppearance tilesFor(int id, {Category? contentSource}) {
    final style = category(id);
    final local = style.useGlobalTiles ? const <String, dynamic>{} : style.tiles;
    final source = local['contentAppTileStyle'];
    final appTiles = source == true || source is int;
    final ownLabels = appTiles && local['contentUseSourceLabels'] == false;
    final linked = contentSource != null && !contentSource.isAppChannels &&
            contentSource.id != id && contentSource.id == source
        ? category(contentSource.id)
        : const CategoryAppearance();
    final common = appearance;
    final resolved = TileAppearance({
      ...({...common.values}
        ..remove('sectionPadding')
        ..remove('contentAppTileStyle')
        ..remove('contentUseSourceLabels')),
      if (!linked.useGlobalTiles)
        for (final entry in linked.tiles.entries)
          if (!entry.key.startsWith('section') &&
              entry.key != 'contentAppTileStyle' &&
              entry.key != 'contentUseSourceLabels')
            entry.key: entry.value,
      if (style.values.containsKey('padding')) 'sectionPadding': style.padding,
      if (style.values.containsKey('background')) 'sectionBackground': style.values['background'],
      for (final entry in local.entries)
        if (!appTiles || entry.key.startsWith('section') ||
            entry.key == 'contentAppTileStyle' || entry.key == 'contentUseSourceLabels')
          entry.key: entry.value,
    });
    if (!ownLabels) return resolved;
    return resolved.withContentLabels(TileAppearance({
      ...common.values,
      ..._contentLabelDefaults,
      for (final entry in local.entries)
        if (_labelFields.contains(entry.key)) entry.key: entry.value,
    }));
  }
  Future<void> setCategoryTile(int id, String key, dynamic value) async {
    if (id <= 0 && id != ContinueWatchingSection.sectionId) return;
    final valid = CategoryAppearance.validValues({'tiles': {key: value}})['tiles'] as Map<String, dynamic>;
    if (!valid.containsKey(key)) return;
    final categoryStyle = category(id);
    final local = categoryStyle.useGlobalTiles ? const <String, dynamic>{} : categoryStyle.tiles;
    final ownLabel = local['contentUseSourceLabels'] == false && _labelFields.contains(key);
    final defaults = switch (key) {
      'sectionPadding' || 'contentAppTileStyle' || 'contentUseSourceLabels' => const TileAppearance(),
      'labels' || 'labelPosition' when ownLabel => const TileAppearance(_contentLabelDefaults),
      _ => appearance,
    };
    // Explicit local size and color stay independent even if they match today.
    final retainValue = ownLabel && !_contentLabelDefaults.containsKey(key);
    if (!retainValue && TileAppearance({...defaults.values, ...valid}).homeFieldValue(key) ==
        defaults.homeFieldValue(key)) {
      await inheritField(id, key);
      return;
    }
    final values = {...categoryStyle.values, 'useGlobalTiles': false,
      'tiles': {...local, ...valid}};
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
    all['$id'] = {'layout': grid ? 'grid' : 'row',
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
  CategoryAppearance category(int id) {
    final saved = CategoryAppearance.decode(preferences.getString(categoryAppearanceKey))['$id'];
    if (saved is Map<String, dynamic>) return CategoryAppearance(saved);
    if (id != ContinueWatchingSection.sectionId) return const CategoryAppearance();

    // An explicit old size remains a local override until the user resets it.
    final legacy = preferences.getString(legacyWatchNextCardSizeKey);
    final size = switch (legacy) {
      'compact' => 112,
      'large' => 157,
      final value? => int.tryParse(value),
      _ => null,
    };
    if (size == null) return const CategoryAppearance();
    return CategoryAppearance({
      'useGlobalTiles': false,
      'tiles': {'size': size.clamp(64, 256)},
    });
  }
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
    final previous = appearance;
    if (key == 'panelCombinedInformation' && value is bool) {
      await RemotePanelService.preserveLegacyGrouping(preferences, previous.combinedInformation);
    }
    final update = TileAppearance.validValues({key: value});
    final position = update['panelBackgroundInformationAlignment'];
    if (position != null && position != previous.backgroundInformationPosition) {
      update['panelBackgroundInformationOffset'] = 0;
      update['panelBackgroundInformationContentAlignment'] = previous.backgroundInformationAlignment;
    }
    final next = {...previous.values,
      if (key == 'panelInformationStyle' && !previous.values.containsKey('panelBackgroundInformationStyle'))
        'panelBackgroundInformationStyle': previous.backgroundInformationStyle.values,
      ...update};
    if (!await preferences.setString(tileAppearanceKey, jsonEncode(next))) throw StateError('Unable to save appearance');
    notifyListeners();
  }
  Future<void> setInformationAppearance(String key, dynamic value, {bool background = false}) {
    final profileKey = TileAppearance.informationAppearanceKey(background);
    return set(profileKey, {...?appearance.values[profileKey] as Map<String, dynamic>?, key: value});
  }
  Future<void> resetInformationTypography() => set('panelInformationStyle', {
    ...({...appearance.informationStyle.values}
      ..removeWhere((key, _) => PanelClockStyle.typographyKeys.contains(key))),
    for (final entry in (LauncherDefaults.appearance['panelInformationStyle']
        as Map<String, dynamic>).entries)
      if (PanelClockStyle.typographyKeys.contains(entry.key)) entry.key: entry.value,
  });
  Future<void> resetInformationColors({bool background = false}) async {
    final current = appearance;
    final styleKey = background ? 'panelBackgroundInformationStyle' : 'panelInformationStyle';
    final profileKey = TileAppearance.informationAppearanceKey(background);
    final style = background ? current.backgroundInformationStyle : current.informationStyle;
    final next = {
      ...current.values,
      // Keep an older wallpaper profile which still inherits the panel style.
      if (!background && !current.values.containsKey('panelBackgroundInformationStyle'))
        'panelBackgroundInformationStyle': current.backgroundInformationStyle.values,
      styleKey: {...style.values}
        ..removeWhere((key, _) => PanelClockStyle.colorsAndEffectsKeys.contains(key)),
      profileKey: {
        ...?current.values[profileKey] as Map<String, dynamic>?,
        // Explicit defaults mask legacy colors stored outside the profile.
        for (final key in TileAppearance.informationAppearanceKeys)
          key: LauncherDefaults.appearance[key],
      },
    };
    if (!await preferences.setString(tileAppearanceKey, jsonEncode(next))) {
      throw StateError('Unable to reset information colors');
    }
    notifyListeners();
  }
  Future<void> resetBackgroundInformationLayout() => resetFields(const [
    'panelBackgroundInformationOrder',
    'panelBackgroundInformationAlignment',
    'panelBackgroundInformationContentAlignment',
    'panelBackgroundInformationOffset',
    'panelBackgroundInformationVerticalOffset',
    'panelBackgroundInformationSize',
    'panelBackgroundInformationAboveLandscape',
    'panelBackgroundInformationAboveWeather',
  ]);
  Future<void> setPanelOrder(List<String> left, List<String> right) async {
    final next = {...appearance.values,
      'panelButtonsOrder': left, 'panelInfoOrder': right};
    if (!await preferences.setString(tileAppearanceKey, jsonEncode(next))) {
      throw StateError('Unable to save panel order');
    }
    notifyListeners();
  }
  Future<void> setBackgroundInformationVerticalOffset(num value) async {
    final current = appearance;
    final update = TileAppearance.validValues({'panelBackgroundInformationVerticalOffset': value});
    if (update.isEmpty) return;
    final metrics = backgroundInformationMetrics.value;
    final fields = {...current.values, ...update};
    // Preserve the visible size when moving an old, oversized block.
    if (metrics != null && metrics.requestedSize == current.backgroundInformationSize &&
        metrics.verticalOffset == current.backgroundInformationVerticalOffset) {
      fields['panelBackgroundInformationSize'] = math.min(
        current.backgroundInformationSize, metrics.effectiveSize,
      ).clamp(1, BackgroundInformationGeometry.maximumStoredSize);
    }
    if (!await preferences.setString(tileAppearanceKey,
        jsonEncode(TileAppearance.validValues(fields)))) {
      throw StateError('Unable to save background position');
    }
    notifyListeners();
  }
  Future<void> reset() async {
    final navigation = {...appearance.values}..removeWhere((key, _) => !['sectionScroll', 'sectionPosition'].contains(key));
    navigation.addAll({...LauncherDefaults.appearance, 'sectionTitles': true});
    if (!await preferences.setString(tileAppearanceKey, jsonEncode(navigation))) throw StateError('Unable to reset appearance');
    final all = CategoryAppearance.decode(preferences.getString(categoryAppearanceKey));
    all.putIfAbsent('${ContinueWatchingSection.sectionId}', () => <String, dynamic>{});
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
    for (final key in keys) {
      if (LauncherDefaults.appearance.containsKey(key)) next[key] = LauncherDefaults.appearance[key];
    }
    if (keys.contains('sectionTitles')) next['sectionTitles'] = true;
    if (!await preferences.setString(tileAppearanceKey, jsonEncode(next))) {
      throw StateError('Unable to reset appearance section');
    }
    notifyListeners();
  }
}
