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
  Future<void> setPanelOrder(List<String> left, List<String> right) async {
    final next = {..._data, 'leftOrder': left, 'rightOrder': right}..remove('order');
    if (!await preferences.setString(preferenceKey, jsonEncode(next))) {
      throw StateError('Panel settings unavailable');
    }
    _data = next;
    notifyListeners();
  }
  bool visible(String id) => !((_data['hidden'] as List?) ?? []).contains(id);
  static const appearanceKeys = ['panelColor', 'panelOpacity', 'panelTextBackground',
    'panelTextBackgroundColor', 'panelTextBackgroundOpacity', 'panelTextColor',
    'panelTextSize', 'panelFont'];
  bool get inheritAppearance => _data['inheritAppearance'] != false;
  TileAppearance get ownAppearance {
    final values = TileAppearance.validValues(_data['appearance'])
      ..removeWhere((key, _) => !appearanceKeys.contains(key));
    return TileAppearance(values);
  }
  TileAppearance appearanceFor(TileAppearance home) => TileAppearance({
    ...(inheritAppearance ? home : ownAppearance).values,
    'panelCombinedInformation': home.combinedInformation,
    'panelInformationStyle': home.informationStyle.values,
    'blurPanel': false, 'panelWrapNavigation': home.panelWrapNavigation,
  });
  Future<void> setAppearance(String key, dynamic value) async {
    if (!appearanceKeys.contains(key)) return;
    await set('appearance', {...ownAppearance.values, ...TileAppearance.validValues({key: value})});
  }
  Future<void> resetAppearance() async {
    final next = {..._data, 'inheritAppearance': true}..remove('appearance');
    if (!await preferences.setString(preferenceKey, jsonEncode(next))) {
      throw StateError('Panel settings unavailable');
    }
    _data = next;
    notifyListeners();
  }
  Future<void> set(String key, Object value) async {
    final next = {..._data, key: value};
    if (!await preferences.setString(preferenceKey, jsonEncode(next))) throw StateError('Panel settings unavailable');
    _data = next; notifyListeners();
  }
  Future<void> show(String id, bool value) => set('hidden', [for (final entry in ids) if (entry == id ? !value : !visible(entry)) entry]);
}
