import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../location_coordinates.dart';
import '../launcher_dialog.dart';
import 'settings_choice_tile.dart';
import 'settings_text_input_dialog.dart';

class ManualLocationInputTile extends StatelessWidget {
  const ManualLocationInputTile({
    super.key,
    required this.value,
    required this.onChanged,
    this.busy = false,
  });

  final ManualLocationInput value;
  final ValueChanged<ManualLocationInput> onChanged;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SettingsChoiceTile<ManualLocationInput>(
      title: l.manualLocationInput,
      value: value,
      options: ManualLocationInput.values,
      label: (input) => switch (input) {
        ManualLocationInput.city => l.manualLocationCity,
        ManualLocationInput.coordinates => l.manualLocationCoordinates,
      },
      busy: busy,
      onChanged: onChanged,
    );
  }
}

String locationCoordinatesLabel(
  AppLocalizations l,
  LocationCoordinates? point,
) => point == null
    ? l.settingsValueNotSet
    : '${point.latitude.toStringAsFixed(3)}, ${point.longitude.toStringAsFixed(3)}';

Future<LocationCoordinates?> showLocationCoordinatesDialog(
  BuildContext context,
  LocationCoordinates? initial,
) async {
  final l = AppLocalizations.of(context)!;
  LocationCoordinates? parse(String value) {
    final parts = value.split(',');
    if (parts.length != 2) return null;
    return coordinatesFrom(
      double.tryParse(parts[0].trim()),
      double.tryParse(parts[1].trim()),
    );
  }

  final result = await showLauncherDialog<String>(
    context: context,
    builder: (_) => SettingsTextInputDialog(
      title: l.weatherServerCoordinates,
      helper: l.weatherServerCoordinatesHint,
      initialValue: initial == null
          ? ''
          : '${initial.latitude}, ${initial.longitude}',
      validator: (value) =>
          parse(value) == null ? l.weatherServerCoordinatesHint : null,
      maxLength: 64,
    ),
  );
  return result == null ? null : parse(result);
}
