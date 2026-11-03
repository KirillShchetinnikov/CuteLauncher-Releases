import '../tile_appearance.dart';
import 'dart:convert';
import '../panel_layout.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Separate from the home screen's panel appearance and visibility.
class RemotePanelService extends ChangeNotifier {
  static const preferenceKey = 'remote_panel_configuration';
  static const ids = PanelLayout.ids;
  final SharedPreferences preferences;
  Map<String, dynamic> _data = {};
  final _previewOwners = <Object>{};
  bool _disposed = false;
  int _generation = 0;
  Future<void>? _pending;
  bool get previewActive => _previewOwners.isNotEmpty;
  void setSettingsPreview(Object owner, bool visible) {
    if (_disposed) return;
    final changed = visible ? _previewOwners.add(owner) : _previewOwners.remove(owner);
    if (changed) notifyListeners();
  }
  @override
  void dispose() {
    _disposed = true;
    _previewOwners.clear();
    super.dispose();
  }
  RemotePanelService(this.preferences) { reload(); }
  void reload() {
    if (_disposed) return;
    ++_generation;
    try { _data = Map<String, dynamic>.from(jsonDecode(preferences.getString(preferenceKey) ?? '{}') as Map); }
    catch (_) { _data = {}; }
    notifyListeners();
  }
  PanelLayout get layout => _data.containsKey('leftOrder') || _data.containsKey('rightOrder')
      ? PanelLayout(_data['leftOrder'], _data['rightOrder'])
      : _data.containsKey('order') ? PanelLayout(order, const []) : PanelLayout(null, null);
  List<String> get order {
    final stored = PanelLayout.clean(_data['order']);
    return [...stored, ...ids.where((id) => !stored.contains(id))];
  }
  Future<void> _change(Map<String, dynamic> Function() update) {
    final generation = _generation;
    Future<void> save() async {
      if (_disposed || generation != _generation) return;
      final next = update();
      final savedGrouping = _stored(preferences)['combinedInformation'];
      if (savedGrouping is bool) {
        next.putIfAbsent('combinedInformation', () => savedGrouping);
      }
      final previous = preferences.getString(preferenceKey);
      final encoded = jsonEncode(next);
      try {
        if (!await preferences.setString(preferenceKey, encoded)) {
          throw StateError('Panel settings unavailable');
        }
      } catch (_) {
        // Failed platform writes still mutate SharedPreferences' local cache.
        if (generation == _generation && preferences.getString(preferenceKey) == encoded) {
          try {
            if (previous == null) {
              await preferences.remove(preferenceKey);
            } else {
              await preferences.setString(preferenceKey, previous);
            }
          } catch (_) { /* Keep the original save error. */ }
        }
        rethrow;
      }
      if (_disposed || generation != _generation) return;
      _data = next;
      notifyListeners();
    }
    final task = _pending == null ? save() : _pending!.then((_) => save());
    // A failed write must not prevent a later independent change from saving.
    late final Future<void> pending;
    pending = task.catchError((Object _) {}).whenComplete(() {
      if (identical(_pending, pending)) _pending = null;
    });
    _pending = pending;
    return task;
  }
  Future<void> setPanelOrder(List<String> left, List<String> right) {
    final savedLeft = List<String>.of(left), savedRight = List<String>.of(right);
    return _change(() => {..._data, 'leftOrder': savedLeft, 'rightOrder': savedRight}..remove('order'));
  }
  bool visible(String id) => (id == 'system' || id == 'networkSpeed') && _data['${id}Enabled'] != true
      ? false : !(_data['hidden'] is List && (_data['hidden'] as List).contains(id));
  static const appearanceKeys = ['panelColor', 'panelOpacity', 'panelTextBackground',
    'panelTextBackgroundColor', 'panelTextBackgroundOpacity', 'panelTextColor',
    'panelTextSize', 'panelFont'];
  bool get inheritAppearance => _data['inheritAppearance'] != false;
  static Map<String, dynamic> _stored(SharedPreferences preferences) {
    try {
      return Map<String, dynamic>.from(jsonDecode(preferences.getString(preferenceKey) ?? '{}') as Map);
    } catch (_) { return {}; }
  }
  // Freeze the formerly shared choice before the home setting changes.
  static Future<void> preserveLegacyGrouping(SharedPreferences preferences, bool value) async {
    final stored = _stored(preferences);
    if (stored['combinedInformation'] is bool) return;
    if (!await preferences.setString(preferenceKey, jsonEncode({...stored, 'combinedInformation': value}))) {
      throw StateError('Panel settings unavailable');
    }
  }
  bool combinedInformation(bool legacy) {
    final value = _data['combinedInformation'] ?? _stored(preferences)['combinedInformation'];
    return value is bool ? value : legacy;
  }
  TileAppearance get ownAppearance {
    final values = TileAppearance.validValues(_data['appearance'])
      ..removeWhere((key, _) => !appearanceKeys.contains(key));
    return TileAppearance(values);
  }
  TileAppearance appearanceFor(TileAppearance home) => TileAppearance({
    ...(inheritAppearance ? home : ownAppearance).values,
    'panelCombinedInformation': combinedInformation(home.combinedInformation),
    'panelInformationStyle': home.informationStyle.values,
    'blurPanel': false, 'panelWrapNavigation': home.panelWrapNavigation,
  });
  Future<void> setAppearance(String key, dynamic value) async {
    if (!appearanceKeys.contains(key)) return;
    await _change(() => {..._data, 'appearance': {...ownAppearance.values, ...TileAppearance.validValues({key: value})}});
  }
  Future<void> resetAppearance() => _change(() => {..._data, 'inheritAppearance': true}..remove('appearance'));
  Future<void> set(String key, Object value) => _change(() => {..._data, key: value});
  Future<void> show(String id, bool value) => _change(() => {..._data,
      if (id == 'system' || id == 'networkSpeed') '${id}Enabled': true,
      'hidden': [for (final entry in ids) if (entry == id ? !value : !visible(entry)) entry],
    });
}
