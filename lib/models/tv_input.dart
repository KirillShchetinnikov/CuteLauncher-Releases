enum TvInputType { tuner, hdmi, av, other }

class TvInput {
  static final _hdmiNumber = RegExp(
    r'HDMI\s*[-_]?\s*(\d+)',
    caseSensitive: false,
  );
  static final _portLabel = RegExp(
    r'^HDMI\s*[-_]?\s*\d+(\s*\([^)]*\))?$',
    caseSensitive: false,
  );

  /// Merge a port with its single CEC device, then sort by physical port number.
  static List<TvInput> ordered(Iterable<TvInput> inputs) {
    final raw = inputs.toList();
    final children = <String, List<TvInput>>{};
    for (final input in raw) {
      if (input.type == TvInputType.hdmi && input.parentId != null) {
        children.putIfAbsent(input.parentId!, () => []).add(input);
      }
    }
    final merged = <String, TvInput>{};
    final hidden = <String>{};
    for (final input in raw) {
      final devices = children[input.id];
      if (input.type != TvInputType.hdmi ||
          input.parentId != null ||
          devices == null ||
          devices.length != 1) {
        continue;
      }
      final device = devices.single;
      // A CEC chain with several distinct devices must remain individually selectable.
      if (children.containsKey(device.id)) continue;
      final name = (device.cecLabel ?? device.label).trim();
      merged[input.id] = TvInput(
        id: input.id,
        label: name.isNotEmpty && !_portLabel.hasMatch(name)
            ? name
            : input.label,
        type: input.type,
        standardLabel: input.standardLabel ?? input.label,
        cecLabel: name.isNotEmpty && !_portLabel.hasMatch(name) ? name : null,
        portNumber: input.portNumber ?? _port(input.label) ?? device.portNumber,
        aliases: List.unmodifiable({
          ...input.aliases,
          device.id,
          ...device.aliases,
        }),
      );
      hidden.add(device.id);
    }
    final result = [
      for (final input in raw)
        if (!hidden.contains(input.id)) merged[input.id] ?? input,
    ];
    final hdmi = result
        .where((input) => input.type == TvInputType.hdmi)
        .indexed
        .toList();
    int? port(TvInput input) {
      return input.portNumber ?? _port(input.label);
    }

    hdmi.sort((a, b) {
      final first = port(a.$2), second = port(b.$2);
      if (first == null && second == null) return a.$1.compareTo(b.$1);
      if (first == null) return 1;
      if (second == null) return -1;
      final comparison = first.compareTo(second);
      return comparison == 0 ? a.$1.compareTo(b.$1) : comparison;
    });
    var index = 0;
    for (var i = 0; i < result.length; i++) {
      if (result[i].type == TvInputType.hdmi) result[i] = hdmi[index++].$2;
    }
    return result;
  }

  final String id;
  final String label;
  final TvInputType type;
  final String? parentId;
  final int? portNumber;
  final List<String> aliases;
  final String? standardLabel, cecLabel;
  final String icon;

  TvInput({
    required this.id,
    required this.label,
    required this.type,
    this.parentId,
    this.portNumber,
    this.aliases = const [],
    this.standardLabel,
    this.cecLabel,
    this.icon = 'default',
  });

  TvInput withPresentation({required String label, required String icon}) =>
      TvInput(
        id: id,
        label: label,
        type: type,
        parentId: parentId,
        portNumber: portNumber,
        aliases: aliases,
        standardLabel: standardLabel ?? this.label,
        cecLabel: cecLabel,
        icon: icon,
      );

  bool matchesId(String value) => id == value || aliases.contains(value);

  static int? _port(String label) {
    final match = _hdmiNumber.firstMatch(label);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  factory TvInput.fromMap(Map<dynamic, dynamic> map) {
    final int typeInt = map['type'] as int? ?? 1000;
    TvInputType type;
    if (typeInt == 1007) {
      type = TvInputType.hdmi;
    } else if (typeInt == 0 || typeInt == 2 || typeInt == 3) {
      type = TvInputType.tuner;
    } else if (typeInt >= 1001 && typeInt <= 1004) {
      type = TvInputType.av;
    } else {
      type = TvInputType.other;
    }

    String text(String key) => (map[key] as String? ?? '').trim();
    final systemLabel = text('label');
    final customLabel = text('customLabel');
    return TvInput(
      id: map['id'] as String? ?? '',
      label: customLabel.isNotEmpty ? customLabel : systemLabel,
      standardLabel: customLabel.isNotEmpty ? customLabel : systemLabel,
      cecLabel: text('parentId').isEmpty ? null : systemLabel,
      type: type,
      parentId: text('parentId').isEmpty ? null : text('parentId'),
      portNumber: _port(systemLabel),
    );
  }
}
