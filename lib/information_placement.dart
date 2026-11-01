import 'providers/settings_service.dart';
import 'providers/remote_panel_service.dart';
import 'tile_appearance.dart';

/// One resolved home composition for rendering, settings and ordering.
/// Old visibility flags and the old whole-block placement remain importable.
class InformationPlacement {
  static const ids = ['time', 'date', 'weather'];
  static const destinations = ['hidden', 'panel', 'background'];
  final Map<String, String> values;

  InformationPlacement(TileAppearance appearance, SettingsService settings)
    : values = {
        for (final id in ids)
          id: appearance.informationPlacement(
            id,
            visible: switch (id) {
              'time' => settings.showTimeInStatusBar,
              'date' => settings.showDateInStatusBar,
              _ => settings.showWeatherInStatusBar,
            },
          ),
      };

  bool onPanel(String id) => values[id] == 'panel';
  bool onBackground(String id) => values[id] == 'background';
  Set<String> get excludedFromPanel => ids.where((id) => !onPanel(id)).toSet();
  bool get hasBackground => values.containsValue('background');
}

/// Effective grouping and actions depend on the visible members of this panel.
class InformationPanelComposition {
  final Set<String> members;
  final bool requested;
  InformationPanelComposition(
    TileAppearance appearance,
    SettingsService settings, {
    RemotePanelService? remote,
  }) : members = remote == null
           ? InformationPlacement.ids
                 .where(InformationPlacement(appearance, settings).onPanel)
                 .toSet()
           : InformationPlacement.ids.where(remote.visible).toSet(),
       requested =
           remote?.combinedInformation(appearance.combinedInformation) ??
           appearance.combinedInformation;
  bool get canCombine => members.length >= 2;
  bool get combined => requested && canCombine;
  Set<String> get excluded =>
      InformationPlacement.ids.toSet().difference(members);
  String get action => members.contains('weather')
      ? (members.contains('date') || members.contains('time')
            ? 'both'
            : 'weather')
      : 'calendar';
}
