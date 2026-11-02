/// Allowlisted metadata; device names, addresses and arbitrary native fields never enter the report.
Map<String, Object> mediaCapabilities(dynamic raw) {
  Map map(dynamic value) => value is Map ? value : const {};
  List rows(dynamic value, int limit) => value is List ? value.take(limit).toList() : const [];
  Map<String, Object> numbers(Map source, List<String> keys) => {
    for (final key in keys)
      if (source[key] is num && (source[key] as num).isFinite &&
          source[key] >= 0 && source[key] <= 1000000000) key: source[key] as num,
  };
  List<int> integers(dynamic value) => rows(value, 64).whereType<int>()
      .where((v) => v >= 0 && v <= 1000000000).toList();
  Map<String, Object> mode(dynamic value) => numbers(map(value), ['width', 'height', 'refreshRateHz']);
  final source = map(raw);
  Map<String, Object> section(String key, Object Function(dynamic) parse) {
    final value = map(source[key]);
    return value['status'] == 'available' ? {'status': 'available', 'data': parse(value['data'])}
        : {'status': 'unavailable'};
  }
  String? token(dynamic value) => value is String &&
      RegExp(r'^[a-zA-Z0-9_.+/-]{1,160}$').hasMatch(value) ? value : null;
  return {
    'scope': 'reportedCapabilitiesOnly',
    'display': section('display', (value) {
      final display = map(value);
      return {'currentMode': mode(display['currentMode']),
        'modes': rows(display['modes'], 64).map(mode).toList(),
        'hdrTypes': integers(display['hdrTypes']).take(16).toList()};
    }),
    'decoders': section('decoders', (value) => [
      for (final entry in rows(value, 128).whereType<Map>())
        if (token(entry['name']) != null && token(entry['mime']) != null) {
          'name': token(entry['name'])!, 'mime': token(entry['mime'])!,
          'acceleration': ['hardware', 'software', 'unknown'].contains(entry['acceleration'])
              ? entry['acceleration'] : 'unknown',
          'status': entry['status'] == 'available' ? 'available' : 'unavailable',
          ...numbers(entry, ['maxWidth', 'maxHeight', 'maxFrameRateHz', 'maxChannels']),
          'profileLevels': [for (final p in rows(entry['profileLevels'], 32).whereType<Map>())
            numbers(p, ['profile', 'level'])],
        },
    ]),
    'audioOutputs': section('audioOutputs', (value) => [
      for (final entry in rows(value, 32).whereType<Map>()) {
        ...numbers(entry, ['type']), 'encodings': integers(entry['encodings']),
        'channelCounts': integers(entry['channelCounts']), 'sampleRatesHz': integers(entry['sampleRatesHz']),
      },
    ]),
  };
}
