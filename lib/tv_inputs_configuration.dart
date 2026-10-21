import 'dart:convert';

import 'models/tv_input.dart';

const tvInputsConfigurationKey = 'tv_inputs_configuration';
const tvInputIcons = [
  'default',
  'hdmi',
  'tv',
  'game',
  'computer',
  'receiver',
  'disc',
  'stream',
];

class TvInputOverride {
  final String name, icon;
  const TvInputOverride({this.name = '', this.icon = 'default'});
  Map<String, String> toJson() => {'name': name, 'icon': icon};
}

class TvInputsConfiguration {
  final bool useCecNames;
  final Map<String, TvInputOverride> overrides;
  const TvInputsConfiguration({
    this.useCecNames = true,
    this.overrides = const {},
  });

  TvInputsConfiguration copyWith({
    bool? useCecNames,
    String? id,
    TvInputOverride? value,
  }) {
    final entries = {...overrides};
    if (id != null && value != null) {
      if (value.name.trim().isEmpty && value.icon == 'default') {
        entries.remove(id);
      } else {
        entries[id] = value;
      }
    }
    return TvInputsConfiguration(
      useCecNames: useCecNames ?? this.useCecNames,
      overrides: Map.unmodifiable(entries),
    );
  }

  List<TvInput> present(Iterable<TvInput> inputs) => [
    for (final input in TvInput.ordered(inputs))
      input.withPresentation(
        label: overrides[input.id]?.name.isNotEmpty == true
            ? overrides[input.id]!.name
            : useCecNames && input.cecLabel != null
            ? input.cecLabel!
            : input.standardLabel ?? input.label,
        icon: overrides[input.id]?.icon ?? 'default',
      ),
  ];

  String encode() => jsonEncode({
    'useCecNames': useCecNames,
    'overrides': overrides.map((key, value) => MapEntry(key, value.toJson())),
  });

  static TvInputsConfiguration parse(Map raw) {
    final useCec = raw['useCecNames'] ?? true, entries = raw['overrides'] ?? {};
    if (useCec is! bool || entries is! Map || entries.length > 128) {
      throw const FormatException();
    }
    final result = <String, TvInputOverride>{};
    for (final entry in entries.entries) {
      final id = entry.key, value = entry.value;
      if (id is! String || id.isEmpty || id.length > 512 || value is! Map) {
        throw const FormatException();
      }
      final name = value['name'] ?? '', icon = value['icon'] ?? 'default';
      if (name is! String ||
          name.length > 80 ||
          icon is! String ||
          !tvInputIcons.contains(icon)) {
        throw const FormatException();
      }
      result[id] = TvInputOverride(name: name.trim(), icon: icon);
    }
    return TvInputsConfiguration(
      useCecNames: useCec,
      overrides: Map.unmodifiable(result),
    );
  }

  static TvInputsConfiguration decode(String? value) {
    try {
      return parse(jsonDecode(value ?? '') as Map);
    } catch (_) {
      return const TvInputsConfiguration();
    }
  }
}
